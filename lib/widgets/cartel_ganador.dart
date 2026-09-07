import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/carta.dart';
import '../theme/app_theme.dart';
import 'paint/palos.dart';

/// Pantalla de victoria: el palo ganador en grande, su emblema y el botón
/// para cerrar la partida.
class CartelGanador extends StatefulWidget {
  final Palo palo;
  final VoidCallback onFinalizar;

  /// Reinicia la partida sin salir de la mesa.
  final VoidCallback onRevancha;

  /// Nombres de los jugadores que iban a este palo. Solo hay en la partida
  /// personalizada, y puede quedar vacío si el palo que ganó no lo había
  /// elegido nadie.
  final List<String> ganadores;

  const CartelGanador({
    super.key,
    required this.palo,
    required this.onFinalizar,
    required this.onRevancha,
    this.ganadores = const [],
  });

  @override
  State<CartelGanador> createState() => _CartelGanadorState();
}

class _CartelGanadorState extends State<CartelGanador>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  late final Animation<double> _entrada = CurvedAnimation(
    parent: _control,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _fundido = CurvedAnimation(
    parent: _control,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.dePalo(widget.palo);
    // Los verdes y azules del palo se pierden sobre el tapete: se aclaran.
    final colorTexto = Color.lerp(color, AppColors.oroClaro, 0.45)!;

    return LayoutBuilder(
      builder: (context, restricciones) {
        final alto = restricciones.maxHeight;
        final ancho = restricciones.maxWidth;
        final emblema =
            math.min(alto * 0.5, ancho * 0.26).clamp(72.0, 190.0);
        final tipoNombre =
            math.min(alto * 0.17, ancho * 0.1).clamp(26.0, 62.0);

        return FadeTransition(
          opacity: _fundido,
          child: Container(
            color: Colors.black.withValues(alpha: 0.72),
            alignment: Alignment.center,
            // Con muchos jugadores la lista de nombres crece: que el
            // cartel pueda desplazarse antes que desbordar.
            child: SingleChildScrollView(
              child: ScaleTransition(
                scale: _entrada,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 34, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      radius: 1.1,
                      colors: [AppColors.tapeteClaro, AppColors.tapeteOscuro],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.oro, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 46,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmblemaPalo(palo: widget.palo, tamano: emblema),
                      const SizedBox(width: 26),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.palo.nombre.toUpperCase(),
                                maxLines: 1,
                                style: AppTheme.tituloDisplay.copyWith(
                                  fontSize: tipoNombre,
                                  letterSpacing: tipoNombre * 0.09,
                                  color: AppColors.oroClaro,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'GANA',
                                maxLines: 1,
                                style: AppTheme.tituloDisplay.copyWith(
                                  fontSize: tipoNombre * 0.72,
                                  letterSpacing: tipoNombre * 0.16,
                                  color: colorTexto,
                                ),
                              ),
                            ),
                            if (widget.ganadores.isNotEmpty)
                              _Ganadores(
                                nombres: widget.ganadores,
                                color: color,
                                anchoMaximo: ancho * 0.5,
                              ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                ElevatedButton(
                                  onPressed: widget.onRevancha,
                                  child: const Text('Revancha'),
                                ),
                                OutlinedButton(
                                  onPressed: widget.onFinalizar,
                                  child: const Text('Finalizar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Los jugadores que iban al palo ganador, en chapitas del color del palo.
class _Ganadores extends StatelessWidget {
  final List<String> nombres;
  final Color color;
  final double anchoMaximo;

  const _Ganadores({
    required this.nombres,
    required this.color,
    required this.anchoMaximo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: math.max(anchoMaximo, 140)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nombres.length == 1 ? 'GANADOR' : 'GANADORES',
              style: TextStyle(
                fontFamily: AppTheme.familiaTitulo,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: AppColors.oroClaro.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final nombre in nombres)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      nombre,
                      style: const TextStyle(
                        fontFamily: AppTheme.familiaTitulo,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.oroClaro,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
