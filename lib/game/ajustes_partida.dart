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
