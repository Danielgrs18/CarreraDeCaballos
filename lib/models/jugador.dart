import 'carta.dart';

/// Un jugador de una partida personalizada: un nombre y el palo al que se
/// juega. Varios jugadores pueden compartir el mismo palo, y puede haber
/// palos que no haya elegido nadie —los cuatro caballos corren igual—.
class Jugador {
  final String nombre;
  final Palo palo;

  const Jugador({required this.nombre, required this.palo});

  @override
  bool operator ==(Object other) =>
      other is Jugador && other.nombre == nombre && other.palo == palo;

  @override
  int get hashCode => Object.hash(nombre, palo);

  @override
  String toString() => '$nombre ($palo)';
}
