/// Enlaces externos que enseña el menú.
///
/// Una cadena vacía significa "sin configurar": la entrada correspondiente
/// no aparece, en vez de llevar a ninguna parte.
class Enlaces {
  const Enlaces._();

  /// Página para apoyar el proyecto: Ko-fi, Buy Me a Coffee, PayPal.me,
  /// GitHub Sponsors... la que sea.
  ///
  /// PENDIENTE: pegar aquí la dirección propia. Mientras siga vacía, el
  /// menú no enseña la entrada de apoyo. No se pone ninguna de ejemplo a
  /// propósito: un enlace de donación equivocado manda dinero a otro.
  static const donacion = '';

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
