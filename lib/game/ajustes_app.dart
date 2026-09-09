import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cosmeticos.dart';

/// Los ajustes generales de la app: los que valen en todas las pantallas y
/// se recuerdan de una sesión a otra.
///
/// Hay una única instancia compartida, [ajustesApp], porque el menú se abre
/// desde cualquier sitio y todas las pantallas tienen que ver lo mismo.
class AjustesApp extends ChangeNotifier {
  static const _claveSilencio = 'silencio';
  static const _claveVibracion = 'vibracion';
  static const _clavePantalla = 'pantalla_encendida';
  static const _clavePano = 'pano';
  static const _claveDorso = 'dorso';

  var _silencio = false;
  var _vibracion = true;
  var _pantallaEncendida = true;
  var _pano = PanoTapete.verde;
  var _dorso = DorsoBaraja.granate;

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

  /// El paño de la mesa.
  PanoTapete get pano => _pano;

  set pano(PanoTapete valor) {
    if (valor == _pano) return;
    _pano = valor;
    _guardarTexto(_clavePano, valor.name);
  }

  /// El dorso de la baraja.
  DorsoBaraja get dorso => _dorso;

  set dorso(DorsoBaraja valor) {
    if (valor == _dorso) return;
    _dorso = valor;
    _guardarTexto(_claveDorso, valor.name);
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
      _pano = _buscar(
        PanoTapete.values,
        guardado.getString(_clavePano),
        _pano,
      );
      _dorso = _buscar(
        DorsoBaraja.values,
        guardado.getString(_claveDorso),
        _dorso,
      );
      notifyListeners();
    } catch (_) {
      // Sin almacén: los valores de fábrica sirven igual.
    }
  }

  /// Busca el valor guardado entre los que existen hoy. Si se guardó un
  /// cosmético que luego se ha quitado o renombrado, se cae al de siempre
  /// en vez de reventar al arrancar.
  static T _buscar<T extends Enum>(List<T> valores, String? nombre, T porDefecto) {
    for (final valor in valores) {
      if (valor.name == nombre) return valor;
    }
    return porDefecto;
  }

  void _guardarTexto(String clave, String valor) {
    notifyListeners();
    SharedPreferences.getInstance()
        .then((guardado) => guardado.setString(clave, valor))
        .catchError((_) => false);
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
    _pano = PanoTapete.verde;
    _dorso = DorsoBaraja.granate;
    notifyListeners();
  }
}

/// Los ajustes de esta sesión, compartidos por toda la app.
final ajustesApp = AjustesApp();
