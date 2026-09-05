import 'carta.dart';

/// Uno de los 4 corredores: el caballo (11) de cada palo.
class Caballo {
  final Palo palo;

  /// 0 = cajón de salida. Cada avance suma un paso.
  int posicion;

  Caballo(this.palo, {this.posicion = 0});

  /// La carta física que representa a este corredor sobre el tapete.
  Carta get carta => Carta(palo, Valores.caballo);

  bool haLlegado(int meta) => posicion >= meta;

  void avanzar() => posicion++;

  /// Retrocede un paso. Nunca baja del cajón de salida.
  void retroceder() {
    if (posicion > 0) posicion--;
  }
}
