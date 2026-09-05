import 'dart:math';
import 'carta.dart';

/// Baraja española de 40 cartas.
class Baraja {
  const Baraja._();

  /// Las 40 cartas, sin barajar.
  static List<Carta> completa() => [
        for (final palo in Palo.values)
          for (final valor in Valores.todos) Carta(palo, valor),
      ];

  static void barajar(List<Carta> cartas, [Random? random]) {
    cartas.shuffle(random ?? Random());
  }
}
