import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Los ajustes generales de la app: los que valen en todas las pantallas y
/// se recuerdan de una sesión a otra.
///
/// Hay una única instancia compartida, [ajustesApp], porque el menú se abre
/// desde cualquier sitio y todas las pantallas tienen que ver lo mismo.
class AjustesApp extends ChangeNotifier {
  static const _claveSilencio = 'silencio';
  static const _claveVibracion = 'vibracion';
  static const _clavePantalla = 'pantalla_encendida';

  var _silencio = false;
  var _vibracion = true;
  var _pantallaEncendida = true;

  /// Sin efectos de sonido. Todavía no hay ninguno que callar, pero la
  /// preferencia se guarda ya para que valga en cuanto los haya.
  bool get silencio => _silencio;

  set silencio(bool valor) {
    if (valor == _silencio) return;
    _silencio = valor;
    _guardar(_claveSilencio, valor);
  }

  /// El pequeño toque al destapar carta a mano.
  bool get vibracion => _vibracion;

  set vibracion(bool valor) {
    if (valor == _vibracion) return;
    _vibracion = valor;
    _guardar(_claveVibracion, valor);
  }

  /// Impedir que la pantalla se apague sola durante la carrera. Viene
  /// puesto porque en automático es fácil dejar el móvil sin tocar.
  bool get pantallaEncendida => _pantallaEncendida;

  set pantallaEncendida(bool valor) {
    if (valor == _pantallaEncendida) return;
    _pantallaEncendida = valor;
    _guardar(_clavePantalla, valor);
  }

  /// Recupera lo que hubiera guardado. Si no hay dónde guardar —los tests,
  /// o una plataforma sin el plugin detrás— se queda con los valores de
  /// fábrica: no poder recordar un ajuste no es motivo para no arrancar.
  Future<void> cargar() async {
    try {
      final guardado = await SharedPreferences.getInstance();
      _silencio = guardado.getBool(_claveSilencio) ?? _silencio;
      _vibracion = guardado.getBool(_claveVibracion) ?? _vibracion;
      _pantallaEncendida =
          guardado.getBool(_clavePantalla) ?? _pantallaEncendida;
      notifyListeners();
    } catch (_) {
      // Sin almacén: los valores de fábrica sirven igual.
    }
  }

  void _guardar(String clave, bool valor) {
    // Primero se avisa, que la interfaz no tiene por qué esperar al disco.
    notifyListeners();
    SharedPreferences.getInstance()
        .then((guardado) => guardado.setBool(clave, valor))
        .catchError((_) => false);
  }

  /// Devuelve los ajustes a como vienen de fábrica. Entre test y test hace
  /// falta, porque la instancia es única y sobrevive a todos.
  @visibleForTesting
  void reiniciar() {
    _silencio = false;
    _vibracion = true;
    _pantallaEncendida = true;
    notifyListeners();
  }
}

/// Los ajustes de esta sesión, compartidos por toda la app.
final ajustesApp = AjustesApp();
