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

  const CartelGanador({
    super.key,
    required this.palo,
    required this.onFinalizar,
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
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: widget.onFinalizar,
                            child: const Text('Finalizar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
