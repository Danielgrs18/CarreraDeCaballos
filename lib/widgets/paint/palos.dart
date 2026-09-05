import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/carta.dart';

/// Dibuja los cuatro palos de la baraja española (oro acuñado, copa con tapa,
/// espada recta y basto nudoso) en un espacio normalizado 0..1, de modo que el
/// mismo trazo sirve para la pinta diminuta de una carta y para el emblema
/// gigante del ganador.
class DibujoPalo {
  const DibujoPalo._();

  static const _oroClaro = Color(0xFFF6E3A8);
  static const _oroMedio = Color(0xFFDDB04A);
  static const _oroHondo = Color(0xFFA9781A);
  static const _oroTrazo = Color(0xFF6E4E12);

  static const _aceroClaro = Color(0xFFDCE6ED);
  static const _aceroMedio = Color(0xFF9AAFBE);
  static const _aceroHondo = Color(0xFF5C7488);
  static const _aceroTrazo = Color(0xFF2F4356);

  static const _maderaClara = Color(0xFFCFA063);
  static const _maderaMedia = Color(0xFFA57038);
  static const _maderaHonda = Color(0xFF77501F);
  static const _maderaTrazo = Color(0xFF422814);

  static const _unidad = Rect.fromLTWH(0, 0, 1, 1);

  /// Fracción del cuadrado unidad que ocupa de verdad cada dibujo. La moneda
  /// es redonda y lo llena casi entero; el garrote es estrecho y alto. Sin
  /// esto, un basto encajado en un cuadrado se queda diminuto.
  static const _huella = <Palo, Size>{
    Palo.oros: Size(0.94, 0.94),
    Palo.copas: Size(0.90, 0.93),
    Palo.espadas: Size(0.75, 0.98),
    Palo.bastos: Size(0.60, 0.90),
  };

  /// Pinta [palo] centrado en [area], al mayor tamaño que quepa.
  static void dibujar(Canvas canvas, Rect area, Palo palo) {
    if (area.width <= 0 || area.height <= 0) return;

    final huella = _huella[palo]!;
    final lado = math.min(area.width / huella.width, area.height / huella.height);
    if (lado <= 0) return;

    canvas.save();
    canvas.translate(
      area.center.dx - lado / 2,
      area.center.dy - lado / 2,
    );
    canvas.scale(lado);

    switch (palo) {
      case Palo.oros:
        _oros(canvas);
      case Palo.copas:
        _copas(canvas);
      case Palo.espadas:
        _espadas(canvas);
      case Palo.bastos:
        _bastos(canvas);
    }

    canvas.restore();
  }

  static Paint _relleno(Shader shader) => Paint()..shader = shader;

  static Paint _trazo(Color color, double grosor) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = grosor
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  static Shader _oroShader() => const RadialGradient(
        center: Alignment(-0.35, -0.4),
        radius: 0.85,
        colors: [_oroClaro, _oroMedio, _oroHondo],
        stops: [0.0, 0.55, 1.0],
      ).createShader(_unidad);

  // --- OROS: moneda acuñada con roseta -----------------------------------
  static void _oros(Canvas canvas) {
    const centro = Offset(0.5, 0.5);
    const radio = 0.46;

    canvas.drawCircle(centro, radio, _relleno(_oroShader()));
    canvas.drawCircle(centro, radio, _trazo(_oroTrazo, 0.028));
    canvas.drawCircle(centro, radio * 0.78, _trazo(_oroTrazo, 0.02));

    // Cordoncillo del canto.
    final punto = Paint()..color = _oroTrazo.withValues(alpha: 0.75);
    for (var i = 0; i < 20; i++) {
      final a = i * math.pi / 10;
      canvas.drawCircle(
        centro + Offset(math.cos(a), math.sin(a)) * (radio * 0.89),
        0.016,
        punto,
      );
    }

    // Roseta central de ocho pétalos.
    final roseta = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      Offset polar(double r, double da) =>
          centro + Offset(math.cos(a + da), math.sin(a + da)) * r;
      final dentro = polar(0.05, 0);
      final fuera = polar(0.3, 0);
      final ladoA = polar(0.17, 0.34);
      final ladoB = polar(0.17, -0.34);
      roseta
        ..moveTo(dentro.dx, dentro.dy)
        ..quadraticBezierTo(ladoA.dx, ladoA.dy, fuera.dx, fuera.dy)
        ..quadraticBezierTo(ladoB.dx, ladoB.dy, dentro.dx, dentro.dy)
        ..close();
    }
    canvas.drawPath(roseta, Paint()..color = _oroTrazo.withValues(alpha: 0.55));

    canvas.drawCircle(centro, 0.085, Paint()..color = _oroClaro);
    canvas.drawCircle(centro, 0.085, _trazo(_oroTrazo, 0.018));
  }

  // --- COPAS: cáliz con tapa y asas --------------------------------------
  static void _copas(Canvas canvas) {
    final oro = _relleno(_oroShader());
    final contorno = _trazo(_oroTrazo, 0.02);

    final asaIzq = Path()
      ..moveTo(0.2, 0.37)
      ..cubicTo(0.05, 0.4, 0.05, 0.56, 0.23, 0.56);
    final asaDer = Path()
      ..moveTo(0.8, 0.37)
      ..cubicTo(0.95, 0.4, 0.95, 0.56, 0.77, 0.56);
    final asaPaint = _trazo(_oroMedio, 0.05);
    canvas
      ..drawPath(asaIzq, asaPaint)
      ..drawPath(asaDer, asaPaint)
      ..drawPath(asaIzq, _trazo(_oroTrazo, 0.014))
      ..drawPath(asaDer, _trazo(_oroTrazo, 0.014));

    final pie = Path()
      ..moveTo(0.26, 0.93)
      ..cubicTo(0.33, 0.87, 0.43, 0.82, 0.5, 0.82)
      ..cubicTo(0.57, 0.82, 0.67, 0.87, 0.74, 0.93)
      ..close();
    canvas
      ..drawPath(pie, oro)
      ..drawPath(pie, contorno);

    final base = RRect.fromLTRBR(
        0.24, 0.925, 0.76, 0.975, const Radius.circular(0.025));
    canvas
      ..drawRRect(base, oro)
      ..drawRRect(base, contorno);

    final vastago = RRect.fromLTRBR(
        0.455, 0.63, 0.545, 0.84, const Radius.circular(0.02));
    canvas
      ..drawRRect(vastago, oro)
      ..drawRRect(vastago, contorno)
      ..drawCircle(const Offset(0.5, 0.71), 0.072, oro)
      ..drawCircle(const Offset(0.5, 0.71), 0.072, contorno);

    final cuenco = Path()
      ..moveTo(0.19, 0.34)
      ..lineTo(0.81, 0.34)
      ..cubicTo(0.81, 0.5, 0.7, 0.65, 0.5, 0.65)
      ..cubicTo(0.3, 0.65, 0.19, 0.5, 0.19, 0.34)
      ..close();
    canvas
      ..drawPath(cuenco, oro)
      ..drawPath(cuenco, contorno)
      ..drawPath(
        Path()
          ..moveTo(0.28, 0.38)
          ..cubicTo(0.28, 0.5, 0.33, 0.57, 0.41, 0.59),
        _trazo(Colors.white.withValues(alpha: 0.5), 0.035),
      );

    final borde = RRect.fromLTRBR(
        0.155, 0.295, 0.845, 0.36, const Radius.circular(0.032));
    canvas
      ..drawRRect(borde, oro)
      ..drawRRect(borde, contorno);

    final tapa = Path()
      ..moveTo(0.225, 0.295)
      ..cubicTo(0.26, 0.13, 0.74, 0.13, 0.775, 0.295)
      ..close();
    canvas
      ..drawPath(tapa, oro)
      ..drawPath(tapa, contorno)
      ..drawLine(const Offset(0.5, 0.12), const Offset(0.5, 0.18),
          _trazo(_oroTrazo, 0.022))
      ..drawCircle(const Offset(0.5, 0.085), 0.055, oro)
      ..drawCircle(const Offset(0.5, 0.085), 0.055, contorno);
  }

  // --- ESPADAS: espada recta de guarnición dorada ------------------------
  static void _espadas(Canvas canvas) {
    final acero = _relleno(const LinearGradient(
      colors: [_aceroClaro, _aceroMedio, _aceroHondo],
      stops: [0.0, 0.45, 1.0],
    ).createShader(_unidad));
    final oro = _relleno(_oroShader());

    final hoja = Path()
      ..moveTo(0.5, 0.025)
      ..lineTo(0.585, 0.17)
      ..lineTo(0.575, 0.585)
      ..lineTo(0.425, 0.585)
      ..lineTo(0.415, 0.17)
      ..close();
    canvas
      ..drawPath(hoja, acero)
      ..drawPath(hoja, _trazo(_aceroTrazo, 0.018))
      ..drawLine(
        const Offset(0.5, 0.09),
        const Offset(0.5, 0.56),
        _trazo(Colors.white.withValues(alpha: 0.65), 0.024),
      );

    final guarnicion = Path()
      ..moveTo(0.13, 0.645)
      ..quadraticBezierTo(0.5, 0.555, 0.87, 0.645)
      ..lineTo(0.87, 0.715)
      ..quadraticBezierTo(0.5, 0.625, 0.13, 0.715)
      ..close();
    canvas
      ..drawPath(guarnicion, oro)
      ..drawPath(guarnicion, _trazo(_oroTrazo, 0.018));

    final puno = RRect.fromLTRBR(
        0.435, 0.69, 0.565, 0.885, const Radius.circular(0.03));
    canvas
      ..drawRRect(puno, Paint()..color = const Color(0xFF6B3F22))
      ..drawRRect(puno, _trazo(_maderaTrazo, 0.018));
    for (final y in const [0.735, 0.79, 0.845]) {
      canvas.drawLine(
        Offset(0.44, y),
        Offset(0.56, y),
        _trazo(_maderaTrazo.withValues(alpha: 0.8), 0.016),
      );
    }

    canvas
      ..drawCircle(const Offset(0.5, 0.915), 0.072, oro)
      ..drawCircle(const Offset(0.5, 0.915), 0.072, _trazo(_oroTrazo, 0.018));
  }

  // --- BASTOS: garrote nudoso --------------------------------------------
  static void _bastos(Canvas canvas) {
    final madera = _relleno(const LinearGradient(
      colors: [_maderaClara, _maderaMedia, _maderaHonda],
      stops: [0.0, 0.55, 1.0],
    ).createShader(_unidad));
    final contorno = _trazo(_maderaTrazo, 0.02);

    // Muñones de rama podada: cortos y romos, con la cara del corte a la
    // vista. Si se alargan, el garrote acaba pareciendo una hoja.
    final munones = [
      (Path()
        ..moveTo(0.395, 0.315)
        ..cubicTo(0.335, 0.288, 0.292, 0.282, 0.262, 0.292)
        ..cubicTo(0.29, 0.336, 0.338, 0.356, 0.392, 0.358)
        ..close()),
      (Path()
        ..moveTo(0.612, 0.475)
        ..cubicTo(0.672, 0.45, 0.716, 0.446, 0.746, 0.458)
        ..cubicTo(0.718, 0.502, 0.668, 0.518, 0.615, 0.516)
        ..close()),
      (Path()
        ..moveTo(0.438, 0.66)
        ..cubicTo(0.388, 0.646, 0.35, 0.648, 0.325, 0.662)
        ..cubicTo(0.352, 0.698, 0.392, 0.71, 0.438, 0.702)
        ..close()),
    ];
    for (final m in munones) {
      canvas
        ..drawPath(m, madera)
        ..drawPath(m, contorno);
    }

    // El garrote: mango fino abajo, maza gruesa arriba.
    final cuerpo = Path()
      ..moveTo(0.468, 0.965)
      ..cubicTo(0.446, 0.79, 0.416, 0.61, 0.4, 0.45)
      ..cubicTo(0.386, 0.3, 0.418, 0.13, 0.5, 0.115)
      ..cubicTo(0.582, 0.13, 0.614, 0.3, 0.6, 0.45)
      ..cubicTo(0.584, 0.61, 0.554, 0.79, 0.532, 0.965)
      ..quadraticBezierTo(0.5, 0.995, 0.468, 0.965)
      ..close();
    canvas
      ..drawPath(cuerpo, madera)
      ..drawPath(cuerpo, contorno)
      ..save();
    canvas.clipPath(cuerpo);

    // Vetas de la madera.
    final veta = _trazo(_maderaTrazo.withValues(alpha: 0.4), 0.013);
    for (final v in const [
      [0.472, 0.9, 0.45, 0.66, 0.44, 0.42, 0.462, 0.2],
      [0.53, 0.88, 0.552, 0.64, 0.558, 0.4, 0.538, 0.19],
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(v[0], v[1])
          ..cubicTo(v[2], v[3], v[4], v[5], v[6], v[7]),
        veta,
      );
    }

    // Nudos con su anillo, que es lo que identifica al basto de un vistazo.
    for (final nudo in const [
      [0.452, 0.585, 0.042],
      [0.556, 0.375, 0.038],
      [0.478, 0.21, 0.032],
    ]) {
      final centro = Offset(nudo[0], nudo[1]);
      canvas
        ..drawCircle(centro, nudo[2], Paint()..color = _maderaHonda)
        ..drawCircle(centro, nudo[2], _trazo(_maderaTrazo, 0.012))
        ..drawCircle(centro, nudo[2] * 0.45, _trazo(_maderaTrazo, 0.01));
    }
    canvas.restore();
  }
}

/// Muestra el emblema de un palo a tamaño libre.
class EmblemaPalo extends StatelessWidget {
  final Palo palo;
  final double tamano;

  const EmblemaPalo({super.key, required this.palo, this.tamano = 32});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(tamano),
      painter: _EmblemaPainter(palo),
      isComplex: true,
    );
  }
}

class _EmblemaPainter extends CustomPainter {
  final Palo palo;
  const _EmblemaPainter(this.palo);

  @override
  void paint(Canvas canvas, Size size) {
    DibujoPalo.dibujar(canvas, Offset.zero & size, palo);
  }

  @override
  bool shouldRepaint(_EmblemaPainter oldDelegate) => oldDelegate.palo != palo;
}
