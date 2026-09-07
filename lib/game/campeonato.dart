import '../models/carta.dart';
import '../models/jugador.dart';
import 'logica_juego.dart';

/// Cuántas rondas puede tener un campeonato. Con una sola no habría
/// campeonato que valga, y más de 10 se hace larguísimo de una sentada.
class NumeroRondas {
  const NumeroRondas._();

  static const minimo = 2;
  static const maximo = 10;
  static const porDefecto = 3;
}

/// Un campeonato: varias carreras seguidas con la misma pista y los mismos
/// jugadores, repartiendo puntos por puesto de llegada. Gana quien más
/// puntos sume al cabo de todas las rondas.
///
/// No sabe nada de cómo se corre una carrera: solo recoge la clasificación
/// que le entrega [LogicaJuego] al terminar cada una.
class Campeonato {
  final int rondas;
  final List<Jugador> jugadores;

  /// Puntos de cada palo en cada ronda ya corrida, en orden.
  final List<Map<Palo, int>> _rondasCorridas = [];

  Campeonato({required this.rondas, required this.jugadores})
      : assert(rondas >= 1, 'Un campeonato necesita al menos una ronda');

  int get rondasCorridas => _rondasCorridas.length;

  /// La ronda que se está jugando ahora, contando desde 1.
  int get rondaActual =>
      terminado ? rondas : _rondasCorridas.length + 1;

  bool get terminado => _rondasCorridas.length >= rondas;

  /// Los puntos que reparte una carrera: el primero se lleva tantos como
  /// caballos haya, y de ahí para abajo. Quien no llega no puntúa.
  static Map<Palo, int> repartir(LogicaJuego carrera) {
    final total = carrera.caballos.length;
    return {
      for (final palo in carrera.caballos.keys) palo: 0,
      for (var i = 0; i < carrera.clasificacion.length; i++)
        carrera.clasificacion[i]: total - i,
    };
  }

  /// Anota el resultado de una carrera ya terminada.
  void anotar(LogicaJuego carrera) {
    assert(!terminado, 'El campeonato ya ha acabado');
    _rondasCorridas.add(repartir(carrera));
  }

  /// Lo que sumó cada palo en la última ronda corrida.
  Map<Palo, int> get ultimaRonda =>
      _rondasCorridas.isEmpty ? const {} : _rondasCorridas.last;

  /// Puntos acumulados de cada palo en todo el campeonato.
  Map<Palo, int> get puntosPorPalo {
    final total = <Palo, int>{};
    for (final ronda in _rondasCorridas) {
      ronda.forEach((palo, puntos) {
        total[palo] = (total[palo] ?? 0) + puntos;
      });
    }
    return total;
  }

  int puntosDe(Jugador jugador) => puntosPorPalo[jugador.palo] ?? 0;

  /// Los jugadores ordenados de más a menos puntos. Los que van con el
  /// mismo palo suman lo mismo y quedan juntos.
  List<Jugador> get clasificacion {
    final orden = [...jugadores];
    orden.sort((a, b) => puntosDe(b).compareTo(puntosDe(a)));
    return orden;
  }

  /// Quien más puntos suma. Puede ser más de uno si hay empate arriba.
  List<Jugador> get campeones {
    if (jugadores.isEmpty) return const [];
    final mejor = jugadores.map(puntosDe).reduce((a, b) => a > b ? a : b);
    return [
      for (final jugador in jugadores)
        if (puntosDe(jugador) == mejor) jugador,
    ];
  }
}
