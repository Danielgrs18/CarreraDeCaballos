import 'dart:math';

import '../models/carta.dart';
import 'ajustes_partida.dart';
import 'campeonato.dart';

/// Una sala privada: una partida concreta que varios amigos pueden ver a la
/// vez desde sus móviles.
///
/// No hace falta servidor. La carrera está determinada por completo por la
/// semilla y por cómo esté montada la mesa, así que basta con que todos
/// tengan esos datos para ver exactamente la misma partida, carta por carta
/// y con el mismo ganador. El código de sala no es más que eso escrito de
/// forma que se pueda dictar por teléfono.
class Sala {
  /// A qué se juega: cualquiera de los modos de la app.
  final ModalidadPartida modalidad;

  /// Largo de la pista. En la partida rápida y en el 1 contra 1 es el de
  /// siempre, porque esos modos no lo dejan tocar.
  final int pasos;

  /// Rondas del campeonato. En los demás modos no pinta nada.
  final int rondas;

  /// Los dos palos del 1 contra 1. En los demás modos corren los cuatro.
  final List<Palo> palos;

  final int semilla;

  const Sala({
    required this.modalidad,
    required this.pasos,
    required this.rondas,
    required this.palos,
    required this.semilla,
  });

  /// Alfabeto de Crockford: base 32 sin la I, la L, la O ni la U. Las tres
  /// primeras se confunden al leerlas con el 1 y el 0, y la U se quita para
  /// no formar palabrotas sin querer.
  static const _digitos = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Cinco dígitos dan 33 millones de carreras distintas por configuración.
  static const _largoSemilla = 5;
  static const _limiteSemilla = 32 * 32 * 32 * 32 * 32;

  /// Modo, pista, un dígito de extras y la semilla.
  static const largoCodigo = 3 + _largoSemilla;

  /// Los modos que se pueden jugar en sala, en el orden en que se guardan
  /// dentro del código. **No se reordena**: cambiaría el significado de los
  /// códigos que la gente ya tenga apuntados.
  static const modalidades = [
    ModalidadPartida.rapida,
    ModalidadPartida.unoContraUno,
    ModalidadPartida.personalizada,
    ModalidadPartida.campeonato,
  ];

  /// Una sala nueva con la mesa que se le pida y una carrera al azar.
  factory Sala.nueva({
    ModalidadPartida modalidad = ModalidadPartida.rapida,
    int pasos = LongitudPista.porDefecto,
    int rondas = NumeroRondas.porDefecto,
    List<Palo> palos = const [Palo.oros, Palo.copas],
    Random? random,
  }) {
    assert(modalidades.contains(modalidad), 'Ese modo no se juega en sala');
    return Sala(
      modalidad: modalidad,
      pasos: pasos,
      rondas: rondas,
      palos: palos,
      semilla: (random ?? Random()).nextInt(_limiteSemilla),
    );
  }

  /// El código para compartir, de ocho caracteres.
  String get codigo =>
      _aBase32(modalidades.indexOf(modalidad), 1) +
      _aBase32(pasos, 1) +
      _aBase32(_extra, 1) +
      _aBase32(semilla, _largoSemilla);

  /// El dígito que cambia de significado según el modo: en el 1 contra 1
  /// guarda qué dos palos corren; en el campeonato, cuántas rondas.
  int get _extra => switch (modalidad) {
        ModalidadPartida.unoContraUno => _indiceDelPar(palos),
        ModalidadPartida.campeonato => rondas,
        _ => 0,
      };

  /// Lee un código tecleado o pegado. Devuelve `null` si no es válido, que
  /// es lo que hay que enseñarle al usuario en vez de una partida
  /// cualquiera.
  ///
  /// Se perdona todo lo que se perdona sin ambigüedad: minúsculas, espacios,
  /// guiones, y la I o la L por 1 y la O por 0, que es como la gente copia
  /// los códigos a mano.
  static Sala? desdeCodigo(String texto) {
    final limpio = texto
        .toUpperCase()
        .replaceAll(RegExp('[^0-9A-Z]'), '')
        .replaceAll(RegExp('[IL]'), '1')
        .replaceAll('O', '0');
    if (limpio.length != largoCodigo) return null;

    final indiceModo = _deBase32(limpio.substring(0, 1));
    final pasos = _deBase32(limpio.substring(1, 2));
    final extra = _deBase32(limpio.substring(2, 3));
    final semilla = _deBase32(limpio.substring(3));
    if (indiceModo == null ||
        pasos == null ||
        extra == null ||
        semilla == null) {
      return null;
    }
    if (indiceModo >= modalidades.length) return null;
    if (pasos < LongitudPista.minimo || pasos > LongitudPista.maximo) {
      return null;
    }

    final modalidad = modalidades[indiceModo];

    var rondas = NumeroRondas.porDefecto;
    var palos = const [Palo.oros, Palo.copas];
    switch (modalidad) {
      case ModalidadPartida.unoContraUno:
        final par = _parDelIndice(extra);
        if (par == null) return null;
        palos = par;
      case ModalidadPartida.campeonato:
        if (extra < NumeroRondas.minimo || extra > NumeroRondas.maximo) {
          return null;
        }
        rondas = extra;
      default:
        // En los modos sin extras, cualquier cosa distinta de 0 es que el
        // código viene estropeado.
        if (extra != 0) return null;
    }

    return Sala(
      modalidad: modalidad,
      pasos: pasos,
      rondas: rondas,
      palos: palos,
      semilla: semilla,
    );
  }

  /// La dirección que abre esta sala directamente.
  Uri enlaceDesde(Uri base) => base.replace(queryParameters: {'sala': codigo});

  /// El generador de la carrera de la ronda indicada, contando desde 0. Dos
  /// dispositivos con el mismo código sacan las cartas en el mismo orden, y
  /// cada ronda del campeonato es una carrera distinta pero igual para
  /// todos.
  Random generador({int ronda = 0}) => Random(semilla + ronda * 7919);

  /// Cómo se llama este modo en la pantalla de crear sala.
  String get nombreModalidad => switch (modalidad) {
        ModalidadPartida.rapida => 'Partida rápida',
        ModalidadPartida.unoContraUno => '1 contra 1',
        ModalidadPartida.personalizada => 'Partida personalizada',
        ModalidadPartida.campeonato => 'Campeonato',
      };

  /// Los palos que corren de verdad en esta sala.
  List<Palo> get palosEnCarrera =>
      modalidad == ModalidadPartida.unoContraUno ? palos : Palo.values;

  // --- Los dos palos del 1 contra 1, en un solo dígito ---------------------

  /// Hay 12 pares ordenados de palos distintos, así que caben de sobra.
  static int _indiceDelPar(List<Palo> palos) {
    final a = palos[0].index;
    final b = palos[1].index;
    return a * 3 + (b > a ? b - 1 : b);
  }

  static List<Palo>? _parDelIndice(int indice) {
    if (indice < 0 || indice >= 12) return null;
    final a = indice ~/ 3;
    final resto = indice % 3;
    final b = resto >= a ? resto + 1 : resto;
    return [Palo.values[a], Palo.values[b]];
  }

  // --- Base 32 -------------------------------------------------------------

  static String _aBase32(int valor, int largo) {
    final crudo = valor.toRadixString(32).padLeft(largo, '0');
    return [
      for (final c in crudo.split('')) _digitos[int.parse(c, radix: 32)],
    ].join();
  }

  static int? _deBase32(String texto) {
    var valor = 0;
    for (final c in texto.split('')) {
      final indice = _digitos.indexOf(c);
      if (indice < 0) return null;
      valor = valor * 32 + indice;
    }
    return valor;
  }

  @override
  bool operator ==(Object other) =>
      other is Sala &&
      other.modalidad == modalidad &&
      other.pasos == pasos &&
      other.rondas == rondas &&
      other.semilla == semilla &&
      // En orden: el código guarda el par tal cual, y leerlo tiene que
      // devolver exactamente la misma sala.
      other.palos.length == palos.length &&
      Iterable<int>.generate(palos.length)
          .every((i) => other.palos[i] == palos[i]);

  @override
  int get hashCode =>
      Object.hash(modalidad, pasos, rondas, semilla, Object.hashAll(palos));

  @override
  String toString() => 'Sala($codigo, $nombreModalidad)';
}
