import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../game/ajustes_app.dart';
import '../game/ajustes_partida.dart';
import '../game/campeonato.dart';
import '../game/logica_juego.dart';
import '../game/sonido.dart';
import '../models/carta.dart';
import '../models/jugador.dart';
import '../theme/app_theme.dart';
import '../widgets/ajustes_personalizada.dart';
import '../widgets/cartel_clasificacion.dart';
import '../widgets/cartel_ganador.dart';
import '../widgets/carta_espanola.dart';
import '../widgets/controles_juego.dart';
import '../widgets/mazo.dart';
import '../widgets/pista.dart';
import '../widgets/selector_palo.dart';
import '../widgets/tapete.dart';

enum _Fase { preparado, corriendo, terminado }

/// La mesa de juego: se ve en horizontal y con la pantalla completa.
class GameScreen extends StatefulWidget {
  /// Qué se puede configurar antes de dar la salida. La carrera en sí es
  /// la misma en las tres modalidades.
  final ModalidadPartida modalidad;

  const GameScreen({super.key, this.modalidad = ModalidadPartida.rapida});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late LogicaJuego _logica;

  var _fase = _Fase.preparado;
  var _modo = ModoJuego.manual;
  var _velocidad = Velocidad.normal;

  // Solo se usan en el 1 contra 1; por defecto van en palos distintos.
  var _jugador1 = Palo.oros;
  var _jugador2 = Palo.copas;

  // Se usan en la partida personalizada y en el campeonato.
  var _pasos = LongitudPista.porDefecto;
  List<Jugador> _jugadores = const [
    Jugador(nombre: 'Jugador 1', palo: Palo.oros),
  ];

  // Solo en el campeonato: cuántas carreras se corren y el marcador que
  // las va sumando. Fuera de esa modalidad el marcador se queda en null.
  var _rondas = NumeroRondas.porDefecto;
  Campeonato? _campeonato;

  /// La carrera no se detiene con el primer puesto, sino que sigue hasta
  /// repartirlos todos. El campeonato lo necesita para puntuar; en los
  /// demás modos lo activa el botón del cartel de victoria.
  var _hastaElFinal = false;

  Timer? _reloj;
  int _turno = 0;
  Palo? _destacado;
  String? _aviso;

  /// Mantiene la pantalla encendida mientras corre la carrera. Si la
  /// plataforma no lo soporta (o no hay plugin detrás, como en los tests)
  /// se ignora: no poder evitar que se apague la pantalla no es motivo
  /// para tumbar la partida.
  void _mantenerPantallaEncendida(bool encendida) {
    final activar = encendida && ajustesApp.pantallaEncendida;
    WakelockPlus.toggle(enable: activar).catchError((_) {});
  }

  /// Los ajustes generales pueden cambiar a media partida desde el menú:
  /// apagar la pantalla siempre encendida tiene que notarse al momento.
  void _ajustesCambiados() {
    _mantenerPantallaEncendida(_fase == _Fase.corriendo);
  }

  /// Una pista nueva, con los palos y el largo que toquen según la
  /// modalidad. En la personalizada corren los 4 caballos igual que en la
  /// partida rápida: los jugadores solo se reparten los palos.
  LogicaJuego _nuevaPartida() => switch (widget.modalidad) {
        ModalidadPartida.rapida => LogicaJuego(),
        ModalidadPartida.unoContraUno =>
          LogicaJuego(palos: [_jugador1, _jugador2]),
        ModalidadPartida.personalizada ||
        ModalidadPartida.campeonato =>
          LogicaJuego(pasos: _pasos),
      };

  @override
  void initState() {
    super.initState();
    _logica = _nuevaPartida();
    // En la mesa manda la carrera: la guitarra de los menús se calla.
    sonido.ambientar(Musica.ninguna);
    ajustesApp.addListener(_ajustesCambiados);
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
    sonido.ambientar(Musica.ambiente);
    ajustesApp.removeListener(_ajustesCambiados);
    WidgetsBinding.instance.removeObserver(this);
    _mantenerPantallaEncendida(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Todos los menús de la app son verticales, vengas de donde vengas
    // (menú principal o catálogo de modos): se deja siempre así al salir.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
    setState(() {
      _fase = _Fase.corriendo;
      _hastaElFinal = widget.modalidad.correHastaElFinal;
      if (widget.modalidad == ModalidadPartida.campeonato) {
        _campeonato = Campeonato(rondas: _rondas, jugadores: _jugadores);
      }
    });
    _sincronizarReloj();
    sonido.barajar();
    sonido.ambientar(Musica.carrera);
    // En modo automático es fácil dejar el móvil apoyado sin tocarlo: que
    // la pantalla no se apague sola a media carrera.
    _mantenerPantallaEncendida(true);
  }

  void _sacarCarta() {
    if (_fase != _Fase.corriendo || _logica.agotada) return;

    final resultado = _logica.jugarTurno();
    // Normalmente la carrera se cierra con el primer puesto. Si se ha
    // pedido verla entera, sigue hasta que no quede nadie que pueda
    // avanzar: o han llegado todos, o a los que faltan no les quedan
    // cartas con las que moverse.
    final parar =
        resultado.agotada || (resultado.ganador != null && !_hastaElFinal);

    // El mazo se ha acabado y se vuelven a barajar los descartes.
    if (resultado.mazoReciclado) sonido.barajar();

    setState(() {
      _turno++;
      _destacado = resultado.avanza;
      _aviso = _redactarAviso(resultado);
      if (parar) _cerrarCarrera();
    });

    if (parar) {
      _pararReloj();
      _mantenerPantallaEncendida(false);
      // Con el cartel en pantalla, el galope de fondo sobraría.
      sonido.ambientar(Musica.ninguna);
    }
  }

  /// Da la carrera por terminada. En el campeonato apunta de paso los
  /// puntos de la ronda. Se llama desde dentro de un `setState`.
  void _cerrarCarrera() {
    _fase = _Fase.terminado;
    final campeonato = _campeonato;
    if (campeonato != null && !campeonato.terminado) {
      campeonato.anotar(_logica);
    }
  }

  /// Reanuda la carrera ya decidida para repartir los puestos que faltan.
  void _continuar() {
    setState(() {
      _hastaElFinal = true;
      _fase = _Fase.corriendo;
      _aviso = null;
    });
    sonido.ambientar(Musica.carrera);
    _sincronizarReloj();
    _mantenerPantallaEncendida(true);
  }

  void _sacarCartaAMano() {
    if (ajustesApp.vibracion) HapticFeedback.selectionClick();
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

  /// Sale de la mesa. En plena carrera pide confirmación primero —tanto si
  /// se pulsa la flecha de la app como el gesto o botón de atrás del
  /// sistema, que se interceptan igual en el `PopScope` del build.
  Future<void> _finalizar() async {
    if (_fase == _Fase.corriendo) {
      final salir = await _confirmarSalida();
      if (salir != true || !mounted) return;
      // El PopScope de abajo tiene canPop:false mientras _fase siga siendo
      // "corriendo" (todavía no ha cambiado, aunque el usuario ya haya
      // confirmado), y eso bloquea también a maybePop, no solo al gesto
      // del sistema: hay que forzar el pop en vez de pedirlo educadamente.
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<bool?> _confirmarSalida() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tapeteOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.oro, width: 1.4),
        ),
        title: Text(
          '¿Salir de la carrera?',
          style: AppTheme.tituloDisplay.copyWith(fontSize: 18),
        ),
        content: Text(
          'Se perderá el progreso de esta partida.',
          style: TextStyle(color: AppColors.oroClaro.withValues(alpha: 0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir jugando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  /// Vuelve a la pantalla de "Comenzar" con una pista nueva, sin salir de
  /// la mesa. El modo y la velocidad elegidos se mantienen.
  void _revancha() {
    _pararReloj();
    _mantenerPantallaEncendida(false);
    setState(() {
      _logica = _nuevaPartida();
      _fase = _Fase.preparado;
      _turno = 0;
      _destacado = null;
      _aviso = null;
      _hastaElFinal = false;
      // Volver al velo de salida es empezar de cero: el campeonato
      // anterior queda cerrado y se monta otro al dar la salida.
      _campeonato = null;
    });
  }

  /// Tiende una pista nueva y da la salida sin pasar por el velo: entre
  /// rondas de un campeonato no hay nada que volver a configurar.
  void _siguienteRonda() {
    _pararReloj();
    setState(() {
      _logica = _nuevaPartida();
      _fase = _Fase.corriendo;
      _turno = 0;
      _destacado = null;
      _aviso = null;
      _hastaElFinal = true;
    });
    // Pista nueva: se barajan las cartas otra vez.
    sonido.barajar();
    sonido.ambientar(Musica.carrera);
    _sincronizarReloj();
    _mantenerPantallaEncendida(true);
  }

  // --- Elección de jugadores (1 contra 1) ---------------------------------

  void _elegirJugador1(Palo palo) {
    setState(() {
      _jugador1 = palo;
      // Si justo era el palo del otro jugador, este pasa al primero libre.
      if (_jugador2 == palo) {
        _jugador2 = Palo.values.firstWhere((p) => p != palo);
      }
      _logica = _nuevaPartida();
    });
  }

  void _elegirJugador2(Palo palo) {
    setState(() {
      _jugador2 = palo;
      _logica = _nuevaPartida();
    });
  }

  // --- Ajustes de la partida personalizada --------------------------------

  void _cambiarPasos(int pasos) {
    if (pasos == _pasos) return;
    setState(() {
      _pasos = pasos;
      _logica = _nuevaPartida();
    });
  }

  void _cambiarRondas(int rondas) {
    if (rondas == _rondas) return;
    setState(() => _rondas = rondas);
  }

  /// Sin `setState` a propósito: la lista solo se lee al cantar el ganador,
  /// que ya llega con su propio repintado. Así escribir un nombre no
  /// reconstruye el tablero entero con cada tecla.
  void _cambiarJugadores(List<Jugador> jugadores) => _jugadores = jugadores;

  /// Quiénes iban a un palo. Solo la personalizada y el campeonato tienen
  /// jugadores con nombre: en las otras modalidades gana el palo a secas,
  /// sin nadie a quien atribuírselo.
  List<String> _jugadoresDe(Palo palo) {
    if (!widget.modalidad.tieneJugadores) return const [];
    return [
      for (final jugador in _jugadores)
        if (jugador.palo == palo) jugador.nombre,
    ];
  }

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
    return PopScope(
      // Fuera de carrera no hay nada que perder: se sale sin preguntar.
      // En carrera, se bloquea el pop automático y se pasa por el mismo
      // diálogo de confirmación que usa la flecha de la barra superior.
      canPop: _fase != _Fase.corriendo,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _finalizar();
      },
      child: Scaffold(
        body: Tapete(
          child: SafeArea(
            // Si el móvil no llega a girar —rotación bloqueada, o un
            // sistema que ignora la petición— el tablero se gira por su
            // cuenta antes que salir aplastado en vertical.
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
      ),
    );
  }

  Widget _tablero() {
    final cartel = _cartelFinal();

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
              rotulo: _rotuloRonda,
              // El menú tapa la mesa: en automático las cartas seguirían
              // saliendo a ciegas detrás del diálogo.
              onAbrirMenu: _pararReloj,
              onCerrarMenu: _sincronizarReloj,
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
        if (cartel != null) Positioned.fill(child: cartel),
      ],
    );
  }

  /// La ronda que se corre, para la barra superior del campeonato.
  String? get _rotuloRonda {
    final campeonato = _campeonato;
    if (campeonato == null) return null;
    return 'Ronda ${campeonato.rondaActual} de ${campeonato.rondas}';
  }

  /// Lo que se echa encima de la mesa al acabar la carrera: el palo
  /// ganador, la clasificación completa o el marcador del campeonato,
  /// según lo que se haya jugado.
  Widget? _cartelFinal() {
    if (_fase != _Fase.terminado) return null;

    final campeonato = _campeonato;
    if (campeonato != null) return _cartelDeRonda(campeonato);

    final ganador = _logica.ganador;
    if (ganador == null) return null;

    if (!_hastaElFinal) {
      return CartelGanador(
        palo: ganador,
        onFinalizar: _finalizar,
        onRevancha: _revancha,
        // Si ya no queda nadie que pueda avanzar no hay nada que seguir:
        // el botón sobra y el cartel se queda con la revancha.
        onContinuar: _logica.agotada ? null : _continuar,
        ganadores: _jugadoresDe(ganador),
      );
    }

    return CartelClasificacion(
      titulo: 'Clasificación',
      subtitulo: 'Gana ${ganador.nombre}',
      puestos: _puestosDeLaCarrera(),
      acciones: [
        ElevatedButton(
          onPressed: _revancha,
          child: const Text('Revancha'),
        ),
        OutlinedButton(
          onPressed: _finalizar,
          child: const Text('Finalizar'),
        ),
      ],
    );
  }

  /// El orden de llegada de la carrera: primero los que cruzaron, en el
  /// orden en que lo hicieron, y al final los que se quedaron sin cartas.
  List<PuestoClasificacion> _puestosDeLaCarrera() => [
        for (final palo in _logica.clasificacion)
          PuestoClasificacion(palo: palo, nombres: _jugadoresDe(palo)),
        for (final palo in _logica.descolgados)
          PuestoClasificacion(
            palo: palo,
            nombres: _jugadoresDe(palo),
            llegado: false,
          ),
      ];

  /// El marcador del campeonato tras la ronda recién corrida.
  Widget _cartelDeRonda(Campeonato campeonato) {
    final ronda = campeonato.ultimaRonda;
    final total = campeonato.puntosPorPalo;
    final palos = _logica.caballos.keys.toList()
      ..sort((a, b) => (total[b] ?? 0).compareTo(total[a] ?? 0));

    final puestos = [
      for (final palo in palos)
        PuestoClasificacion(
          palo: palo,
          nombres: _jugadoresDe(palo),
          puntos: total[palo] ?? 0,
          // Lo apagado de la fila mide el campeonato, no la última
          // carrera: lo de esta ronda se cuenta aquí al lado.
          detalle: _logica.haLlegado(palo)
              ? '+${ronda[palo] ?? 0}'
              : 'no llegó',
        ),
    ];

    if (!campeonato.terminado) {
      return CartelClasificacion(
        titulo: 'Ronda ${campeonato.rondasCorridas} de ${campeonato.rondas}',
        subtitulo: 'Marcador del campeonato',
        puestos: puestos,
        acciones: [
          ElevatedButton.icon(
            onPressed: _siguienteRonda,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Siguiente ronda'),
          ),
          OutlinedButton(
            onPressed: _finalizar,
            child: const Text('Finalizar'),
          ),
        ],
      );
    }

    return CartelClasificacion(
      titulo: 'Campeonato',
      subtitulo: _cantarCampeones(campeonato),
      puestos: puestos,
      acciones: [
        ElevatedButton(
          onPressed: _revancha,
          child: const Text('Otro campeonato'),
        ),
        OutlinedButton(
          onPressed: _finalizar,
          child: const Text('Finalizar'),
        ),
      ],
    );
  }

  String _cantarCampeones(Campeonato campeonato) {
    final campeones = campeonato.campeones;
    if (campeones.isEmpty) return 'Fin del campeonato';
    final nombres = campeones.map((j) => j.nombre).join(', ');
    return campeones.length == 1 ? 'Gana $nombres' : 'Empate: $nombres';
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
                  mostrarPuestos: _hastaElFinal,
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
              gradient: ajustesApp.pano.gradientePanel,
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
                if (widget.modalidad == ModalidadPartida.unoContraUno) ...[
                  const SizedBox(height: 14),
                  _selectorJugadores(),
                ],
                const SizedBox(height: 14),
                // La personalizada trae bastantes ajustes: en horizontal
                // sobra ancho, así que van al lado de la salida en vez de
                // empujarla fuera de pantalla.
                if (widget.modalidad.tieneJugadores)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AjustesPersonalizada(
                        pasos: _pasos,
                        onPasos: _cambiarPasos,
                        jugadoresIniciales: _jugadores,
                        onJugadores: _cambiarJugadores,
                        rondas: widget.modalidad == ModalidadPartida.campeonato
                            ? _rondas
                            : null,
                        onRondas:
                            widget.modalidad == ModalidadPartida.campeonato
                                ? _cambiarRondas
                                : null,
                      ),
                      const SizedBox(width: 26),
                      _accionesSalida(),
                    ],
                  )
                else
                  _accionesSalida(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// El botón de salida y, debajo, cómo se van a destapar las cartas.
  Widget _accionesSalida() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    );
  }

  /// Los dos selectores del 1 contra 1: el segundo excluye lo que ya haya
  /// elegido el primero, así nunca pueden coincidir.
  Widget _selectorJugadores() {
    final disponiblesJugador2 =
        Palo.values.where((p) => p != _jugador1).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _etiquetaJugador('Jugador 1'),
        const SizedBox(height: 6),
        SelectorPalo(
          opciones: Palo.values,
          seleccionado: _jugador1,
          onCambio: _elegirJugador1,
        ),
        const SizedBox(height: 12),
        _etiquetaJugador('Jugador 2'),
        const SizedBox(height: 6),
        SelectorPalo(
          opciones: disponiblesJugador2,
          seleccionado: _jugador2,
          onCambio: _elegirJugador2,
        ),
      ],
    );
  }

  Widget _etiquetaJugador(String texto) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTheme.familiaTitulo,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: AppColors.oroClaro.withValues(alpha: 0.65),
      ),
    );
  }
}
