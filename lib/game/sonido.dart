import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'ajustes_app.dart';

/// Lo que puede estar sonando de fondo.
enum Musica {
  /// Silencio: la mesa con el cartel de victoria, por ejemplo.
  ninguna(null, 0),

  /// Guitarra española, en los menús.
  ambiente('audio/ambiente.wav', 0.42),

  /// La corneta sobre el galope, mientras se corre.
  carrera('audio/carrera.wav', 0.5);

  const Musica(this.fichero, this.volumen);

  final String? fichero;
  final double volumen;
}

/// El sonido de la app: una música de fondo en bucle y algún efecto suelto.
///
/// Todo lo que hace es de "usar y olvidar": si el aparato no tiene audio, si
/// el plugin no está (los tests), o si el navegador se niega, no pasa nada
/// más que quedarse callado. Nunca tumba la partida por no poder sonar.
class Sonido {
  Sonido._() {
    // Silenciar desde el menú tiene que notarse al momento.
    ajustesApp.addListener(_sincronizar);
  }

  // Perezosos a propósito: construir un AudioPlayer toca los canales de
  // plataforma, y el objeto `sonido` se crea al importarlo, que puede ser
  // antes de que exista el binding (los tests lo hacen).
  late final AudioPlayer _fondo = AudioPlayer();
  late final AudioPlayer _efectos = AudioPlayer();

  var _deseada = Musica.ninguna;
  var _sonando = Musica.ninguna;

  /// Los navegadores no dejan sonar nada hasta que el usuario toca algo en
  /// la página. Hasta entonces ni se intenta: se apunta lo que debería
  /// sonar y se arranca en cuanto haya un gesto.
  var _desbloqueado = false;

  /// Si las reglas permiten sonar ahora mismo: ya hubo gesto del usuario y
  /// no está silenciado. Es la política, no el aparato: ver [desactivado].
  bool get puedeSonar => _desbloqueado && !ajustesApp.silencio;

  /// Apaga el sonido de raíz, sin llegar a tocar el plugin. Los tests lo
  /// ponen: ahí no hay audio detrás, y los fallos del plugin llegan por
  /// caminos asíncronos que no se pueden atrapar desde aquí.
  @visibleForTesting
  static bool desactivado = false;

  /// Deja sonando lo que toque en cada pantalla.
  void ambientar(Musica musica) {
    if (musica == _deseada) return;
    _deseada = musica;
    _sincronizar();
  }

  /// El barajeo, al empezar una partida y al reciclar el mazo.
  void barajar() {
    if (desactivado || !puedeSonar) return;
    _intentar(() => _efectos.play(
          AssetSource('audio/barajeo.wav'),
          volume: 0.8,
        ));
  }

  /// Se llama con el primer toque del usuario en cualquier parte de la app.
  /// A partir de ahí el navegador ya nos deja sonar.
  void desbloquear() {
    if (_desbloqueado) return;
    _desbloqueado = true;
    _sincronizar();
  }

  void _sincronizar() {
    if (desactivado) return;
    final objetivo = puedeSonar ? _deseada : Musica.ninguna;
    if (objetivo == _sonando) return;
    _sonando = objetivo;

    final fichero = objetivo.fichero;
    if (fichero == null) {
      _intentar(() => _fondo.stop());
      return;
    }
    _intentar(() async {
      await _fondo.setReleaseMode(ReleaseMode.loop);
      await _fondo.play(AssetSource(fichero), volume: objetivo.volumen);
    });
  }

  /// Lanza la operación sin esperarla y se traga cualquier fallo: quedarse
  /// sin sonido no puede romper nada de lo que hay por encima.
  void _intentar(Future<void> Function() operacion) {
    try {
      operacion().catchError((_) {});
    } catch (_) {
      // Ni plugin ni aparato de audio: se sigue en silencio.
    }
  }

  /// Devuelve el sonido a como arranca la app: callado y a la espera del
  /// primer gesto. Entre test y test hace falta, porque la instancia es
  /// única y sobrevive a todos.
  @visibleForTesting
  void reiniciar() {
    _desbloqueado = false;
    _deseada = Musica.ninguna;
    _sonando = Musica.ninguna;
    if (!desactivado) _intentar(() => _fondo.stop());
  }
}

/// El sonido de esta sesión, compartido por toda la app.
final sonido = Sonido._();
