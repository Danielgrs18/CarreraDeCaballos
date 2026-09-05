import 'dart:math';
import 'carta.dart';

/// Baraja española de 40 cartas.
class Baraja {
  const Baraja._();

  /// Las cartas de los [palos] indicados, sin barajar. Con los 4 palos por
  /// defecto son las 40 de la baraja completa; con menos, sirve para
  /// carreras reducidas (por ejemplo, 1 contra 1 con solo 2 palos).
  static List<Carta> completa({List<Palo> palos = Palo.values}) => [
        for (final palo in palos)
          for (final valor in Valores.todos) Carta(palo, valor),
      ];

  static void barajar(List<Carta> cartas, [Random? random]) {
    cartas.shuffle(random ?? Random());
  }
}
