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

  static bool get hayDonacion => donacion.isNotEmpty;
}
