/// Con qué reglas de mesa se juega. La lógica de la carrera es la misma en
/// todas: solo cambian cuántos caballos corren y de qué largo es la pista.
enum ModalidadPartida {
  /// Los 4 palos, pista de largo fijo.
  rapida,

  /// Solo 2 palos, elegidos por los jugadores en el velo de salida.
  unoContraUno,

  /// Los 4 palos, con la pista y la lista de jugadores configurables.
  personalizada,
}

/// Cuánto puede medir la pista en una partida personalizada. Por debajo de
/// 2 la carrera no da ni para una mano; por encima de 12 las casillas se
/// estrechan tanto que las cartas de paso dejan de leerse.
class LongitudPista {
  const LongitudPista._();

  static const minimo = 2;
  static const maximo = 12;
  static const porDefecto = 6;
}

/// Cómo se destapan las cartas durante la carrera.
enum ModoJuego {
  manual('Manual'),
  automatico('Automático');

  const ModoJuego(this.etiqueta);
  final String etiqueta;
}

/// Las tres velocidades del modo automático.
enum Velocidad {
  lenta('Lenta', 1400),
  normal('Normal', 750),
  rapida('Rápida', 330);

  const Velocidad(this.etiqueta, this._ms);
  final String etiqueta;
  final int _ms;

  /// Tiempo entre carta y carta.
  Duration get intervalo => Duration(milliseconds: _ms);

  /// Duración de las animaciones del tablero: siempre algo más corta que el
  /// intervalo, para que el caballo llegue a su casilla antes de la
  /// siguiente carta.
  Duration get animacion =>
      Duration(milliseconds: (_ms * 0.62).round().clamp(140, 420));
}
