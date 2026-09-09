import 'package:flutter/painting.dart';

/// El paño de la mesa. Son tres tonos del mismo color: el degradado del
/// fondo va del claro al oscuro, y los recuadros que se echan encima
/// (velo de salida, carteles, menú) usan los mismos para no desentonar.
enum PanoTapete {
  verde('Verde', Color(0xFF177A4B), Color(0xFF0E5A38), Color(0xFF063722)),
  burdeos('Burdeos', Color(0xFF7A2230), Color(0xFF5A1522), Color(0xFF340A13)),
  azul('Azul', Color(0xFF1B5578), Color(0xFF123C57), Color(0xFF0A2436)),
  grafito('Grafito', Color(0xFF3A4247), Color(0xFF262C30), Color(0xFF14181B));

  const PanoTapete(this.etiqueta, this.claro, this.medio, this.oscuro);

  final String etiqueta;
  final Color claro;
  final Color medio;
  final Color oscuro;

  /// El degradado de los recuadros que se apoyan sobre el tapete.
  Gradient get gradientePanel => RadialGradient(
        radius: 1.2,
        colors: [claro, oscuro],
      );
}

/// El dorso de la baraja. Cambia el color de la cartulina; el grabado —el
/// filete dorado, la celosía y el medallón— es el mismo en todos, que es
/// lo que les da aire de baraja de verdad.
enum DorsoBaraja {
  granate('Granate', Color(0xFFA8202E), Color(0xFF8A1420), Color(0xFF5E0C15)),
  bosque('Bosque', Color(0xFF1E7A4E), Color(0xFF13603C), Color(0xFF093A24)),
  indigo('Índigo', Color(0xFF35557E), Color(0xFF264066), Color(0xFF14263F)),
  ebano('Ébano', Color(0xFF3A3632), Color(0xFF272320), Color(0xFF141210));

  const DorsoBaraja(this.etiqueta, this.claro, this.medio, this.oscuro);

  final String etiqueta;
  final Color claro;
  final Color medio;
  final Color oscuro;
}
