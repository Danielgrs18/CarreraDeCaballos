import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fondo de tapete verde: degradado radial, trama fina de fieltro y viñeteado
/// en los bordes.
class Tapete extends StatelessWidget {
  final Widget child;

  const Tapete({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.0,
          colors: [
            AppColors.tapeteClaro,
            AppColors.tapete,
            AppColors.tapeteOscuro,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      // La trama va en su propia capa: si compartiera capa con el tablero se
      // repintarían sus cientos de líneas con cada carta que sale.
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _TramaFieltro(),
                isComplex: true,
                willChange: false,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _TramaFieltro extends CustomPainter {
  const _TramaFieltro();

  @override
  void paint(Canvas canvas, Size size) {
    final trama = Paint()
      ..color = Colors.black.withValues(alpha: 0.055)
      ..strokeWidth = 1;

    const paso = 7.0;
    for (var d = -size.height; d < size.width + size.height; d += paso) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        trama,
      );
    }

    final brillo = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (var d = -size.height; d < size.width + size.height; d += paso) {
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        brillo,
      );
    }
  }

  @override
  bool shouldRepaint(_TramaFieltro oldDelegate) => false;
}
