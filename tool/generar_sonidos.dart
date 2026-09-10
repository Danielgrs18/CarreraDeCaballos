// Genera los tres sonidos de la app en assets/audio/. No se descarga nada:
// se sintetizan por código, igual que las cartas se pintan por código. Así
// no hay licencias que respetar, los ficheros son diminutos y la melodía se
// puede retocar cambiando una tabla de notas.
//
//   dart run tool/generar_sonidos.dart
//
// Produce:
//   ambiente.wav  guitarra española en bucle, para los menús
//   barajeo.wav   cartas barajeándose, al empezar y al reciclar el mazo
//   carrera.wav   la corneta de carreras sobre un galope, en bucle
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// 22050 Hz es de sobra para esto y ocupa la mitad que 44100. El tamaño
/// importa: esto se descarga en el navegador.
const _frecuencia = 22050;

// --- Utilidades de síntesis ----------------------------------------------

/// Notas por su nombre, en herzios. Solo las que hacen falta.
const _notas = <String, double>{
  'E2': 82.41,
  'F2': 87.31,
  'G2': 98.00,
  'A2': 110.00,
  'C3': 130.81,
  'D3': 146.83,
  'E3': 164.81,
  'F3': 174.61,
  'G3': 196.00,
  'Gs3': 207.65,
  'A3': 220.00,
  'B3': 246.94,
  'C4': 261.63,
  'D4': 293.66,
  'E4': 329.63,
  'F4': 349.23,
  'G4': 392.00,
  'Gs4': 415.30,
  'A4': 440.00,
  'B4': 493.88,
  'C5': 523.25,
  'E5': 659.25,
  'G5': 784.00,
};

double _nota(String nombre) =>
    _notas[nombre] ?? (throw ArgumentError('Nota desconocida: $nombre'));

/// Un lienzo de audio al que se le van sumando sonidos en el instante que
/// toque. Trabaja en coma flotante y solo al final se ajusta y se convierte
/// a enteros, que es como no se acumulan recortes por el camino.
class _Pista {
  final List<double> muestras;

  _Pista(double segundos)
      : muestras = List.filled((segundos * _frecuencia).round(), 0.0);

  int get largo => muestras.length;

  /// Suma [sonido] a partir del segundo [desde]. Lo que se salga por el
  /// final da la vuelta y entra por el principio: así el bucle empalma sin
  /// costura, porque la cola de las últimas notas suena bajo las primeras.
  void mezclar(List<double> sonido, double desde, {bool envolver = true}) {
    final inicio = (desde * _frecuencia).round();
    for (var i = 0; i < sonido.length; i++) {
      final pos = inicio + i;
      if (pos < largo) {
        muestras[pos] += sonido[i];
      } else if (envolver) {
        muestras[pos % largo] += sonido[i];
      }
    }
  }

  /// Normaliza a [pico] para aprovechar el margen sin llegar a saturar.
  void normalizar(double pico) {
    var maximo = 0.0;
    for (final m in muestras) {
      maximo = math.max(maximo, m.abs());
    }
    if (maximo == 0) return;
    final factor = pico / maximo;
    for (var i = 0; i < largo; i++) {
      muestras[i] *= factor;
    }
  }

  /// Entrada y salida suaves, para los sonidos que no van en bucle.
  void desvanecerExtremos(double segundos) {
    final n = (segundos * _frecuencia).round();
    for (var i = 0; i < n && i < largo; i++) {
      final factor = i / n;
      muestras[i] *= factor;
      muestras[largo - 1 - i] *= factor;
    }
  }
}

/// Cuerda pulsada (Karplus-Strong): se arranca de una ráfaga de ruido y se
/// va promediando, que es como suena una cuerda al apagarse. Cuatro líneas
/// y suena a guitarra de verdad.
List<double> _cuerda(double herzios, double segundos, {double volumen = 1}) {
  final largoBucle = (_frecuencia / herzios).round();
  final aleatorio = math.Random(largoBucle * 7919);
  final bucle = List<double>.generate(
    largoBucle,
    (_) => aleatorio.nextDouble() * 2 - 1,
  );

  final total = (segundos * _frecuencia).round();
  final salida = List<double>.filled(total, 0);
  // Cuanto más aguda la nota, antes se apaga: como en una cuerda real.
  final apagado = 0.996 - (herzios / 12000).clamp(0.0, 0.02);

  for (var i = 0; i < total; i++) {
    final actual = bucle[i % largoBucle];
    salida[i] = actual * volumen;
    final siguiente = bucle[(i + 1) % largoBucle];
    bucle[i % largoBucle] = (actual + siguiente) * 0.5 * apagado;
  }
  return salida;
}

/// Corneta: los metales tienen muchos armónicos y un ataque rápido. Se
/// suman los primeros cinco con pesos decrecientes.
List<double> _corneta(double herzios, double segundos, {double volumen = 1}) {
  final total = (segundos * _frecuencia).round();
  final salida = List<double>.filled(total, 0);
  const pesos = [1.0, 0.55, 0.38, 0.22, 0.12];

  for (var i = 0; i < total; i++) {
    final t = i / _frecuencia;
    final avance = i / total;

    // Ataque corto y caída sostenida hasta apagarse al final.
    final envolvente = avance < 0.06
        ? avance / 0.06
        : math.pow(1 - (avance - 0.06) / 0.94, 1.4).toDouble();

    var valor = 0.0;
    for (var h = 0; h < pesos.length; h++) {
      valor += pesos[h] * math.sin(2 * math.pi * herzios * (h + 1) * t);
    }
    // Un vibrato muy leve, que si no suena a sintetizador de juguete.
    final vibrato = 1 + 0.006 * math.sin(2 * math.pi * 5.2 * t);
    salida[i] = valor * envolvente * volumen * 0.28 * vibrato;
  }
  return salida;
}

/// Un casco contra la tierra: golpe grave y seco con algo de tierra suelta.
List<double> _casco(double segundos, double volumen, int semilla) {
  final total = (segundos * _frecuencia).round();
  final salida = List<double>.filled(total, 0);
  final aleatorio = math.Random(semilla);
  var filtro = 0.0;

  for (var i = 0; i < total; i++) {
    final t = i / _frecuencia;
    final caida = math.exp(-t * 26);
    // El cuerpo del golpe: un tono grave que además baja de altura.
    final cuerpo = math.sin(2 * math.pi * (95 - 45 * t * 8).clamp(45, 95) * t);
    // La tierra: ruido pasado por un filtro para quitarle el siseo agudo.
    final ruido = aleatorio.nextDouble() * 2 - 1;
    filtro += (ruido - filtro) * 0.35;
    salida[i] = (cuerpo * 0.8 + filtro * 0.45) * caida * volumen;
  }
  return salida;
}

/// El roce de las cartas al pasar unas sobre otras: ruido filtrado con una
/// subida y bajada rápidas.
List<double> _roce(double segundos, double volumen, int semilla) {
  final total = (segundos * _frecuencia).round();
  final salida = List<double>.filled(total, 0);
  final aleatorio = math.Random(semilla);
  var grave = 0.0;
  var agudo = 0.0;

  for (var i = 0; i < total; i++) {
    final avance = i / total;
    // Campana: ni empieza ni acaba de golpe.
    final envolvente = math.sin(math.pi * avance);
    final ruido = aleatorio.nextDouble() * 2 - 1;
    // Paso banda a mano: al ruido se le quita lo muy grave y lo muy agudo,
    // que es donde vive el "papel" y no el siseo.
    grave += (ruido - grave) * 0.55;
    agudo += (grave - agudo) * 0.06;
    salida[i] = (grave - agudo) * envolvente * volumen;
  }
  return salida;
}

// --- Los tres sonidos ----------------------------------------------------

/// Guitarra española en bucle: cadencia andaluza (Am-G-F-E), que es "el"
/// giro español, arpegiada despacio. Doce segundos, suave y sin melodía
/// que se haga pesada al repetirse.
_Pista _ambiente() {
  const duracion = 12.0;
  final pista = _Pista(duracion);

  const acordes = [
    ['A2', 'A3', 'C4', 'E4', 'A4'],
    ['G2', 'G3', 'B3', 'D4', 'G4'],
    ['F2', 'F3', 'A3', 'C4', 'F4'],
    ['E2', 'E3', 'Gs3', 'B3', 'E4'],
  ];

  final compas = duracion / acordes.length;
  for (var c = 0; c < acordes.length; c++) {
    final base = c * compas;
    final cuerdas = acordes[c];

    // El bajo primero, y encima el arpegio subiendo y volviendo.
    pista.mezclar(_cuerda(_nota(cuerdas[0]), 3.4, volumen: 0.62), base);

    const patron = [1, 2, 3, 4, 3, 2];
    for (var p = 0; p < patron.length; p++) {
      final cuando = base + 0.34 + p * (compas - 0.34) / patron.length;
      pista.mezclar(
        _cuerda(_nota(cuerdas[patron[p]]), 2.6, volumen: 0.34),
        cuando,
      );
    }
  }

  pista.normalizar(0.5);
  return pista;
}

/// Barajeo: dos riffles y un golpe seco de mazo al cuadrar las cartas.
_Pista _barajeo() {
  final pista = _Pista(1.5);
  final aleatorio = math.Random(4242);

  // Cada riffle son muchos roces cortos muy seguidos, acelerando.
  for (var riffle = 0; riffle < 2; riffle++) {
    final inicio = 0.05 + riffle * 0.52;
    for (var i = 0; i < 26; i++) {
      final avance = i / 26;
      final cuando = inicio + avance * 0.34 - avance * avance * 0.06;
      pista.mezclar(
        _roce(0.028, 0.5 + aleatorio.nextDouble() * 0.5, riffle * 100 + i),
        cuando,
        envolver: false,
      );
    }
    // El mazo cerrándose de golpe al final del riffle.
    pista.mezclar(
      _roce(0.09, 0.9, 900 + riffle),
      inicio + 0.34,
      envolver: false,
    );
  }

  // Y el taco cuadrado contra la mesa.
  pista.mezclar(_casco(0.14, 0.5, 77), 1.18, envolver: false);

  pista.normalizar(0.72);
  pista.desvanecerExtremos(0.012);
  return pista;
}

/// La carrera: la llamada de corneta sobre un galope, en bucle.
///
/// El galope de un caballo son tres golpes y un silencio —"pa-ta-pám,
/// pausa"—, no un pulso regular; es lo que lo hace reconocible.
_Pista _carrera() {
  const duracion = 8.0;
  final pista = _Pista(duracion);

  // Ocho compases de galope.
  const compas = 1.0;
  for (var c = 0; c < duracion ~/ compas; c++) {
    final base = c * compas;
    // Los tres cascos del galope, el primero más marcado.
    pista.mezclar(_casco(0.2, 0.95, c * 3), base);
    pista.mezclar(_casco(0.2, 0.62, c * 3 + 1), base + 0.19);
    pista.mezclar(_casco(0.2, 0.72, c * 3 + 2), base + 0.36);
  }

  // La llamada: solo notas de la serie armónica, que es lo único que puede
  // dar una corneta de verdad. De ahí el "tirorí tirorí tirororí".
  const melodia = <(String, double, double)>[
    // (nota, cuándo entra, cuánto dura)
    ('G4', 0.00, 0.18),
    ('C5', 0.18, 0.18),
    ('E5', 0.36, 0.42),
    ('G4', 1.00, 0.18),
    ('C5', 1.18, 0.18),
    ('E5', 1.36, 0.42),
    ('G4', 2.00, 0.16),
    ('C5', 2.16, 0.16),
    ('E5', 2.32, 0.16),
    ('G5', 2.48, 0.62),
    ('E5', 3.20, 0.20),
    ('C5', 3.40, 0.20),
    ('G4', 3.60, 0.56),
    // Segunda vuelta, media octava de respiro y remate.
    ('C5', 5.00, 0.18),
    ('E5', 5.18, 0.18),
    ('G5', 5.36, 0.44),
    ('E5', 6.00, 0.18),
    ('C5', 6.18, 0.18),
    ('G4', 6.36, 0.20),
    ('C5', 6.60, 0.80),
  ];

  for (final (nombre, cuando, duracionNota) in melodia) {
    pista.mezclar(
      _corneta(_nota(nombre), duracionNota + 0.16, volumen: 0.85),
      cuando,
    );
  }

  pista.normalizar(0.62);
  return pista;
}

// --- Escritura del WAV ---------------------------------------------------

Uint8List _wav(_Pista pista) {
  final n = pista.largo;
  final datos = ByteData(44 + n * 2);

  void texto(int desplazamiento, String s) {
    for (var i = 0; i < s.length; i++) {
      datos.setUint8(desplazamiento + i, s.codeUnitAt(i));
    }
  }

  texto(0, 'RIFF');
  datos.setUint32(4, 36 + n * 2, Endian.little);
  texto(8, 'WAVE');
  texto(12, 'fmt ');
  datos.setUint32(16, 16, Endian.little); // tamaño del bloque fmt
  datos.setUint16(20, 1, Endian.little); // PCM sin comprimir
  datos.setUint16(22, 1, Endian.little); // mono
  datos.setUint32(24, _frecuencia, Endian.little);
  datos.setUint32(28, _frecuencia * 2, Endian.little); // bytes por segundo
  datos.setUint16(32, 2, Endian.little); // bytes por muestra
  datos.setUint16(34, 16, Endian.little); // bits por muestra
  texto(36, 'data');
  datos.setUint32(40, n * 2, Endian.little);

  for (var i = 0; i < n; i++) {
    final valor = (pista.muestras[i].clamp(-1.0, 1.0) * 32767).round();
    datos.setInt16(44 + i * 2, valor, Endian.little);
  }
  return datos.buffer.asUint8List();
}

Future<void> _guardar(_Pista pista, String ruta) async {
  final fichero = File(ruta);
  await fichero.parent.create(recursive: true);
  await fichero.writeAsBytes(_wav(pista));

  var maximo = 0.0;
  var suma = 0.0;
  for (final m in pista.muestras) {
    maximo = math.max(maximo, m.abs());
    suma += m * m;
  }
  final segundos = pista.largo / _frecuencia;
  final eficaz = math.sqrt(suma / pista.largo);
  // ignore: avoid_print
  print(
    '$ruta  ${segundos.toStringAsFixed(2)}s  '
    '${(await fichero.length() / 1024).round()} KB  '
    'pico ${maximo.toStringAsFixed(3)}  medio ${eficaz.toStringAsFixed(3)}',
  );
}

Future<void> main() async {
  await _guardar(_ambiente(), 'assets/audio/ambiente.wav');
  await _guardar(_barajeo(), 'assets/audio/barajeo.wav');
  await _guardar(_carrera(), 'assets/audio/carrera.wav');
}
