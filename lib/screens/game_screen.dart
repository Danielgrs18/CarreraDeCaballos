import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/ajustes_partida.dart';
import '../game/logica_juego.dart';
import '../models/carta.dart';
import '../theme/app_theme.dart';
import '../widgets/cartel_ganador.dart';
import '../widgets/carta_espanola.dart';
import '../widgets/controles_juego.dart';
import '../widgets/mazo.dart';
import '../widgets/pista.dart';
import '../widgets/tapete.dart';

enum _Fase { preparado, corriendo, terminado }

/// La mesa de juego: se ve en horizontal y con la pantalla completa.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final LogicaJuego _logica = LogicaJuego();

  var _fase = _Fase.preparado;
  var _modo = ModoJuego.manual;
  var _velocidad = Velocidad.normal;

  Timer? _reloj;
  int _turno = 0;
  Palo? _destacado;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pedida dentro de initState, la rotación se pierde en algunos móviles
    // porque la actividad aún se está montando: se pide tras el primer
    // fotograma, que es cuando el sistema la respeta de forma fiable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al irse a segundo plano se detiene el automático; al volver, sigue.
    if (state == AppLifecycleState.resumed) {
      _sincronizarReloj();
    } else {
      _pararReloj();
    }
  }

  // --- Partida -----------------------------------------------------------

  void _comenzar() {
    setState(() => _fase = _Fase.corriendo);
    _sincronizarReloj();
  }

  void _sacarCarta() {
    if (_fase != _Fase.corriendo || _logica.terminada) return;

    final resultado = _logica.jugarTurno();

    setState(() {
      _turno++;
      _destacado = resultado.avanza;
      _aviso = _redactarAviso(resultado);
      if (resultado.ganador != null) _fase = _Fase.terminado;
    });

    if (resultado.ganador != null) _pararReloj();
  }

  void _sacarCartaAMano() {
    HapticFeedback.selectionClick();
    _sacarCarta();
  }

  String? _redactarAviso(ResultadoTurno resultado) {
    if (resultado.revelaciones.isNotEmpty) {
      final r = resultado.revelaciones.last;
      return 'Paso ${r.paso}: ${r.carta}.\n${r.palo.nombre} retrocede.';
    }
    if (resultado.mazoReciclado) {
      return 'Mazo agotado:\nse rebarajan los descartes.';
    }
    return null;
  }

  void _finalizar() => Navigator.of(context).maybePop();

  // --- Reloj del modo automático ------------------------------------------

  /// Deja el temporizador acorde al modo, la velocidad y la fase actuales.
  void _sincronizarReloj() {
    _pararReloj();
    if (_fase != _Fase.corriendo || _modo != ModoJuego.automatico) return;
    _reloj = Timer.periodic(_velocidad.intervalo, (_) => _sacarCarta());
  }

  void _pararReloj() {
    _reloj?.cancel();
    _reloj = null;
  }

  void _cambiarModo(ModoJuego modo) {
    setState(() => _modo = modo);
    _sincronizarReloj();
  }

  void _cambiarVelocidad(Velocidad velocidad) {
    setState(() => _velocidad = velocidad);
    _sincronizarReloj();
  }

  // --- Interfaz ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Tapete(
        child: SafeArea(
          // Si el móvil no llega a girar —rotación bloqueada, o un sistema
          // que ignora la petición— el tablero se gira por su cuenta antes
          // que salir aplastado en vertical.
          child: LayoutBuilder(
            builder: (context, restricciones) {
              final enVertical =
                  restricciones.maxHeight > restricciones.maxWidth;

              return RotatedBox(
                quarterTurns: enVertical ? 1 : 0,
                child: _tablero(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tablero() {
    final ganador = _logica.ganador;

    return Stack(
      children: [
        Column(
          children: [
            ControlesJuego(
              modo: _modo,
              velocidad: _velocidad,
              habilitado: _fase != _Fase.terminado,
              cartasEnMazo: _logica.cartasEnMazo,
              onModo: _cambiarModo,
              onVelocidad: _cambiarVelocidad,
              onSalir: _finalizar,
              mostrarSelectorModo: _fase != _Fase.preparado,
            ),
            // El velo de salida tapa solo la mesa: así se puede elegir
            // modo y velocidad antes de dar la salida.
            Expanded(
              child: Stack(
                children: [
                  _mesa(),
                  if (_fase == _Fase.preparado) _veloSalida(),
                ],
              ),
            ),
          ],
        ),
        if (_fase == _Fase.terminado && ganador != null)
          Positioned.fill(
            child: CartelGanador(palo: ganador, onFinalizar: _finalizar),
          ),
      ],
    );
  }

  Widget _mesa() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: LayoutBuilder(
        builder: (context, restricciones) {
          // El mazo se dimensiona por el alto libre, dejando sitio al rótulo
          // y al aviso del último suceso.
          final anchoMazo =
              ((restricciones.maxHeight - 70) * kProporcionCarta)
                  .clamp(38.0, 72.0);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: anchoMazo * 2 + 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MazoWidget(
                      ultimaCarta: _logica.ultimaCarta,
                      cartasRestantes: _logica.cartasEnMazo,
                      anchoCarta: anchoMazo,
                      turno: _turno,
                      onSacar: _puedeSacarAMano ? _sacarCartaAMano : null,
                      invitaATocar: _puedeSacarAMano,
                    ),
                    const SizedBox(height: 6),
                    Expanded(child: _panelAviso()),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PistaWidget(
                  logica: _logica,
                  duracionAnimacion: _modo == ModoJuego.automatico
                      ? _velocidad.animacion
                      : const Duration(milliseconds: 380),
                  destacado: _destacado,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool get _puedeSacarAMano =>
      _fase == _Fase.corriendo && _modo == ModoJuego.manual;

  Widget _panelAviso() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: _aviso == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(_aviso),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.rojoOscuro.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.oro.withValues(alpha: 0.55),
                ),
              ),
              child: Text(
                _aviso!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.25,
                  color: AppColors.oroClaro.withValues(alpha: 0.95),
                ),
              ),
            ),
    );
  }

  /// Velo inicial: el tablero ya está tendido y en un recuadro se elige el
  /// modo de juego antes de dar la salida.
  Widget _veloSalida() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(30, 16, 30, 18),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                radius: 1.2,
                colors: [AppColors.tapeteClaro, AppColors.tapeteOscuro],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.oro, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 28,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Elige tu caballo ganador',
                  textAlign: TextAlign.center,
                  style: AppTheme.tituloDisplay.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  'Las cartas deciden la carrera',
                  style: TextStyle(
                    fontFamily: AppTheme.familiaTitulo,
                    fontSize: 12,
                    letterSpacing: 1.6,
                    color: AppColors.oroClaro.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 150,
                  height: 1,
                  color: AppColors.oro.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _comenzar,
                  child: const Text('Comenzar'),
                ),
                const SizedBox(height: 16),
                GrupoPildoras<ModoJuego>(
                  valores: ModoJuego.values,
                  seleccionado: _modo,
                  etiqueta: (m) => m.etiqueta,
                  onCambio: _cambiarModo,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _modo == ModoJuego.automatico
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            GrupoPildoras<Velocidad>(
                              valores: Velocidad.values,
                              seleccionado: _velocidad,
                              etiqueta: (v) => v.etiqueta,
                              onCambio: _cambiarVelocidad,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
