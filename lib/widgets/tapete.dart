import 'package:flutter/material.dart';

import '../game/ajustes_app.dart';

/// Fondo de tapete: degradado radial del color elegido en Personalizar,
/// con una trama fina de fieltro encima.
class Tapete extends StatelessWidget {
  final Widget child;

  const Tapete({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Escucha por su cuenta en vez de esperar a que alguien de arriba se
    // reconstruya: el tapete se monta en sitios que son const.
    return ListenableBuilder(
      listenable: ajustesApp,
      builder: (context, _) => _fondo(),
    );
  }

  Widget _fondo() {
    final pano = ajustesApp.pano;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 1.0,
          colors: [pano.claro, pano.medio, pano.oscuro],
          stops: const [0.0, 0.55, 1.0],
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
