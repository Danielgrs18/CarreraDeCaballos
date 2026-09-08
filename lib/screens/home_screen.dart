import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/carta.dart';
import '../theme/app_theme.dart';
import '../widgets/carta_espanola.dart';
import '../widgets/menu_app.dart';
import '../widgets/tapete.dart';
import 'game_screen.dart';
import 'modos_juego_screen.dart';

/// Menú principal.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _restaurarVertical();
  }

  /// El menú se ve en vertical; la carrera gira a horizontal por su cuenta.
  void _restaurarVertical() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _partidaRapida() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
    if (mounted) _restaurarVertical();
  }

  void _desbloquearMas() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Próximamente'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _modosJuego() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ModosJuegoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Tapete(
        child: SafeArea(
          child: Stack(
            children: [
              _contenido(),
              // El menú, en la esquina, por encima del contenido: aquí no
              // hay barra superior donde colgarlo.
              const Positioned(top: 0, right: 4, child: BotonMenuApp()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final compacto = restricciones.maxHeight < 560;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compacto) ...[
                  const _AbanicoCaballos(),
                  const SizedBox(height: 28),
                ],
                Text(
                  'CARRERA\nDE CABALLOS',
                  textAlign: TextAlign.center,
                  style: AppTheme.tituloDisplay.copyWith(
                    fontSize: compacto ? 28 : 36,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 120,
                  height: 2,
                  color: AppColors.oro.withValues(alpha: 0.7),
                ),
                SizedBox(height: compacto ? 28 : 44),
                _BotonMenu(
                  texto: 'Partida rápida',
                  onPressed: _partidaRapida,
                ),
                const SizedBox(height: 16),
                _BotonMenu(
                  texto: 'Modos de juego',
                  secundario: true,
                  onPressed: _modosJuego,
                ),
                const SizedBox(height: 16),
                _BotonMenu(
                  texto: 'Desbloquear más',
                  secundario: true,
                  onPressed: _desbloquearMas,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BotonMenu extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final bool secundario;

  const _BotonMenu({
    required this.texto,
    required this.onPressed,
    this.secundario = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: secundario
          ? OutlinedButton(onPressed: onPressed, child: Text(texto))
          : ElevatedButton(onPressed: onPressed, child: Text(texto)),
    );
  }
}

/// Los cuatro caballos abiertos en abanico, como reclamo del menú.
class _AbanicoCaballos extends StatelessWidget {
  const _AbanicoCaballos();

  @override
  Widget build(BuildContext context) {
    const ancho = 84.0;
    final palos = Palo.values;

    return SizedBox(
      width: ancho * 3.1,
      height: altoCarta(ancho) * 1.12,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < palos.length; i++)
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.translationValues(
                  (i - (palos.length - 1) / 2) * 46.0, 0.0, 0.0)
                ..rotateZ((i - (palos.length - 1) / 2) * 0.19),
              child: Transform.translate(
                offset: Offset(
                  0,
                  -math.cos((i - (palos.length - 1) / 2) * 0.5) * 6,
                ),
                child: CartaEspanola(
                  carta: Carta(palos[i], Valores.caballo),
                  ancho: ancho,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
