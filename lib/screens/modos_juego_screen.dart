import 'package:flutter/material.dart';

import '../game/ajustes_partida.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_app.dart';
import '../widgets/tapete.dart';
import 'game_screen.dart';

Widget _abrirUnoVsUno(BuildContext context) =>
    const GameScreen(modalidad: ModalidadPartida.unoContraUno);

Widget _abrirPersonalizada(BuildContext context) =>
    const GameScreen(modalidad: ModalidadPartida.personalizada);

Widget _abrirCampeonato(BuildContext context) =>
    const GameScreen(modalidad: ModalidadPartida.campeonato);

/// Un modo de juego que se podrá elegir desde esta pantalla. Si [pantalla]
/// es `null`, todavía no está listo y tocarlo solo avisa "próximamente".
class _ModoDisponible {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final WidgetBuilder? pantalla;

  const _ModoDisponible({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    this.pantalla,
  });

  bool get disponible => pantalla != null;
}

const _modos = <_ModoDisponible>[
  _ModoDisponible(
    titulo: '1 contra 1',
    descripcion: 'Cada jugador elige un palo y se juega la carrera',
    icono: Icons.people_alt_rounded,
    pantalla: _abrirUnoVsUno,
  ),
  _ModoDisponible(
    titulo: 'Campeonato',
    descripcion: 'Varias carreras seguidas: puntúan todos los que llegan',
    icono: Icons.emoji_events_rounded,
    pantalla: _abrirCampeonato,
  ),
  _ModoDisponible(
    titulo: 'Partida personalizada',
    descripcion: 'Elige el largo de la pista y quién juega con cada palo',
    icono: Icons.tune_rounded,
    pantalla: _abrirPersonalizada,
  ),
];

/// Catálogo de modos de juego.
class ModosJuegoScreen extends StatelessWidget {
  const ModosJuegoScreen({super.key});

  void _proximamente(BuildContext context, String modo) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$modo: próximamente'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _abrir(BuildContext context, _ModoDisponible modo) {
    if (modo.pantalla != null) {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: modo.pantalla!));
    } else {
      _proximamente(context, modo.titulo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Tapete(
        child: SafeArea(
          child: Column(
            children: [
              _cabecera(context),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      itemCount: _modos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final modo = _modos[i];
                        return _TarjetaModo(
                          modo: modo,
                          onTap: () => _abrir(context, modo),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecera(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.oroClaro,
            tooltip: 'Volver',
          ),
          Expanded(
            child: Text(
              'Modos de juego',
              textAlign: TextAlign.center,
              style: AppTheme.tituloDisplay.copyWith(fontSize: 22),
            ),
          ),
          // Ocupa el mismo ancho que el botón de volver, así que además
          // de servir de menú centra el título de verdad.
          const BotonMenuApp(),
        ],
      ),
    );
  }
}

class _TarjetaModo extends StatelessWidget {
  final _ModoDisponible modo;
  final VoidCallback onTap;

  const _TarjetaModo({required this.modo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.rojoOscuro.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.oro.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(modo.icono, color: AppColors.oroClaro, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modo.titulo,
                      style: const TextStyle(
                        fontFamily: AppTheme.familiaTitulo,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.oroClaro,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      modo.descripcion,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.oroClaro.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (modo.disponible)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.oroClaro.withValues(alpha: 0.8),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.oroClaro.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Pronto',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: AppColors.oroClaro.withValues(alpha: 0.75),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
