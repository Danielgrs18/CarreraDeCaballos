/// Enlaces externos que enseña el menú.
///
/// Una cadena vacía significa "sin configurar": la entrada correspondiente
/// no aparece, en vez de llevar a ninguna parte.
class Enlaces {
  const Enlaces._();

  /// Página para apoyar el proyecto.
  ///
  /// Es un PayPal.Me a propósito, y no la dirección de correo: el nombre de
  /// usuario no se puede rastrear para mandar spam, y el correo en un
  /// repositorio público sí. Si algún día se cambia por otra pasarela, basta
  /// con sustituir esta línea; vaciarla esconde la entrada del menú.
  static const donacion = 'https://www.paypal.me/danielgrs18';

  /// El repositorio, que es público.
  static const codigo = 'https://github.com/Danielgrs18/CarreraDeCaballos';

  /// Dónde vive la web. Se usa para armar los enlaces de sala cuando no se
  /// puede leer la dirección del navegador (móvil).
  ///
  /// OJO: si algún día se pone dominio propio hay que cambiarla aquí y en
  /// las etiquetas OpenGraph de web/index.html.
  static const web = 'https://danielgrs18.github.io/CarreraDeCaballos/';

  /// La dirección de la que colgar un código de sala: la que se esté
  /// mirando si estamos en el navegador, y la de la web si no.
  static Uri get deLaWeb {
    final actual = Uri.base;
    if (actual.scheme == 'http' || actual.scheme == 'https') {
      return actual.replace(queryParameters: {}, fragment: '');
    }
    return Uri.parse(web);
  }

  static bool get hayDonacion => donacion.isNotEmpty;
}
