/// Los 4 palos de la baraja española.
enum Palo {
  oros('Oros', 'los'),
  copas('Copas', 'las'),
  espadas('Espadas', 'las'),
  bastos('Bastos', 'los');

  const Palo(this.nombre, this.articulo);

  /// Nombre para mostrar en pantalla ("Oros").
  final String nombre;

  /// Artículo determinado plural, para frases tipo "Ganan los Oros".
  final String articulo;

  /// "Ganan los Oros" / "Ganan las Copas".
  String get fraseVictoria => 'Ganan $articulo $nombre';
}

/// Valores de la baraja española de 40 cartas.
/// No existen el 8 ni el 9: tras el 7 vienen Sota (10), Caballo (11) y Rey (12).
class Valores {
  static const as = 1;
  static const sota = 10;
  static const caballo = 11;
  static const rey = 12;

  /// Los 10 valores de cada palo, en orden.
  static const todos = <int>[1, 2, 3, 4, 5, 6, 7, sota, caballo, rey];
}

/// Una carta concreta de la baraja española.
class Carta {
  final Palo palo;
  final int valor;

  const Carta(this.palo, this.valor);

  bool get esAs => valor == Valores.as;
  bool get esSota => valor == Valores.sota;
  bool get esCaballo => valor == Valores.caballo;
  bool get esRey => valor == Valores.rey;

  /// Las figuras se pintan con dibujo en lugar de con la retícula de pintas.
  bool get esFigura => valor >= Valores.sota;

  /// Nombre de la figura, o `null` si es una carta numérica.
  String? get nombreFigura {
    switch (valor) {
      case Valores.sota:
        return 'Sota';
      case Valores.caballo:
        return 'Caballo';
      case Valores.rey:
        return 'Rey';
      default:
        return null;
    }
  }

  /// Etiqueta corta de las esquinas. En la baraja española las figuras
  /// también llevan su número (10, 11, 12), no una letra.
  String get indice => '$valor';

  @override
  String toString() => '${nombreFigura ?? valor} de ${palo.nombre}';

  @override
  bool operator ==(Object other) =>
      other is Carta && other.palo == palo && other.valor == valor;

  @override
  int get hashCode => Object.hash(palo, valor);
}
