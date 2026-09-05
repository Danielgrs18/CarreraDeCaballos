import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/carta.dart';
import '../../theme/app_theme.dart';

/// Dibuja las tres figuras de la baraja española —Sota (10), Caballo (11) y
/// Rey (12)— al modo de las estampas grabadas: silueta de trazo firme, color
/// plano apagado y rayado fino para las sombras.
class DibujoFigura {
  const DibujoFigura._();

  static const _tinta = Color(0xFF241C14);
  static const _piel = Color(0xFFE7CBA4);
  static const _lino = Color(0xFFEDE1C6);
  static const _oro = Color(0xFFC9A227);
  static const _cabello = Color(0xFF4A3521);
  static const _pelaje = Color(0xFF8A5E38);
  static const _pelajeSombra = Color(0xFF5E3D22);
  static const _crin = Color(0xFF33220F);
  static const _cuero = Color(0xFF6B4525);

  /// Pinta la figura de [carta] centrada en [area].
  ///
  /// Las estampas son estrechas y altas (ocupan en torno al 70% del ancho de
  /// su caja), así que se ajustan al alto disponible en vez de al ancho: si
  /// no, quedarían diminutas y flotando en medio de la carta.
  static void dibujar(Canvas canvas, Rect area, Carta carta) {
    const esbeltez = 0.72;
    final lado = math.min(area.height, area.width / esbeltez);
    if (lado <= 0 || !carta.esFigura) return;

    final ropa = AppColors.dePalo(carta.palo);

    canvas.save();
    canvas.translate(
      area.left + (area.width - lado) / 2,
      area.top + (area.height - lado) / 2,
    );
    canvas.scale(lado);

    switch (carta.valor) {
      case Valores.sota:
        _sota(canvas, ropa);
      case Valores.caballo:
        _caballo(canvas, ropa);
      case Valores.rey:
        _rey(canvas, ropa);
    }

    canvas.restore();
  }

  // --- Utilidades de trazo ------------------------------------------------

  static Paint _relleno(Color color) => Paint()..color = color;

  static Paint _perfil([double grosor = 0.011]) => Paint()
    ..color = _tinta
    ..style = PaintingStyle.stroke
    ..strokeWidth = grosor
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// Rellena y perfila una forma de una sola vez.
  static void _pieza(Canvas canvas, Path forma, Color color,
      [double grosor = 0.011]) {
    canvas
      ..drawPath(forma, _relleno(color))
      ..drawPath(forma, _perfil(grosor));
  }

  /// Miembro alargado (pierna, brazo, pata): un trazo grueso de tinta con
  /// otro de color encima, que es como se consigue un contorno limpio sin
  /// tener que cerrar el contorno a mano.
  static void _miembro(Canvas canvas, Path trazo, Color color, double grosor) {
    canvas
      ..drawPath(
        trazo,
        Paint()
          ..color = _tinta
          ..style = PaintingStyle.stroke
          ..strokeWidth = grosor + 0.018
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        trazo,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = grosor
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
  }

  /// Rayado de grabado dentro de una forma: es lo que despega el dibujo del
  /// aspecto de pegatina plana.
  static void _rayado(
    Canvas canvas,
    Path forma, {
    double angulo = 1.0,
    double paso = 0.032,
    double opacidad = 0.28,
    double grosor = 0.007,
  }) {
    canvas
      ..save()
      ..clipPath(forma);

    final lapiz = Paint()
      ..color = _tinta.withValues(alpha: opacidad)
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;

    final caja = forma.getBounds();
    final alcance = caja.width + caja.height;
    final direccion = Offset(math.cos(angulo), math.sin(angulo));
    final normal = Offset(-direccion.dy, direccion.dx);

    for (var t = -alcance / 2; t <= alcance / 2; t += paso) {
      final origen = caja.center + normal * t;
      canvas.drawLine(
        origen - direccion * alcance,
        origen + direccion * alcance,
        lapiz,
      );
    }

    canvas.restore();
  }

  /// Cabeza de perfil mirando a la izquierda: frente, nariz y mentón de una
  /// sola línea, sin ojos redondos de muñeco.
  static void _cabezaPerfil(
    Canvas canvas,
    Offset centro,
    double radio, {
    Color pelo = _cabello,
    bool barba = false,
  }) {
    final r = radio;
    final craneo = Path()
      ..moveTo(centro.dx + r * 0.15, centro.dy - r)
      ..cubicTo(
        centro.dx - r * 0.75, centro.dy - r * 0.95,
        centro.dx - r * 1.05, centro.dy - r * 0.1,
        centro.dx - r * 0.82, centro.dy + r * 0.28,
      )
      ..cubicTo(
        centro.dx - r * 0.98, centro.dy + r * 0.45,
        centro.dx - r * 0.72, centro.dy + r * 0.52,
        centro.dx - r * 0.5, centro.dy + r * 0.6,
      )
      ..cubicTo(
        centro.dx - r * 0.25, centro.dy + r * 1.02,
        centro.dx + r * 0.62, centro.dy + r * 0.95,
        centro.dx + r * 0.78, centro.dy + r * 0.35,
      )
      ..cubicTo(
        centro.dx + r * 0.95, centro.dy - r * 0.3,
        centro.dx + r * 0.7, centro.dy - r * 0.95,
        centro.dx + r * 0.15, centro.dy - r,
      )
      ..close();
    _pieza(canvas, craneo, _piel, 0.009);

    // Ceja y ojo: dos trazos cortos, nada de puntos.
    canvas
      ..drawLine(
        centro + Offset(-r * 0.55, -r * 0.22),
        centro + Offset(-r * 0.15, -r * 0.3),
        _perfil(0.009),
      )
      ..drawLine(
        centro + Offset(-r * 0.48, -r * 0.02),
        centro + Offset(-r * 0.2, -r * 0.05),
        _perfil(0.008),
      );

    if (barba) {
      final pelambre = Path()
        ..moveTo(centro.dx - r * 0.62, centro.dy + r * 0.3)
        ..cubicTo(
          centro.dx - r * 0.5, centro.dy + r * 1.5,
          centro.dx + r * 0.7, centro.dy + r * 1.6,
          centro.dx + r * 0.85, centro.dy + r * 0.35,
        )
        ..cubicTo(
          centro.dx + r * 0.8, centro.dy + r * 0.9,
          centro.dx - r * 0.3, centro.dy + r * 0.95,
          centro.dx - r * 0.62, centro.dy + r * 0.3,
        )
        ..close();
      _pieza(canvas, pelambre, _lino, 0.009);
      _rayado(canvas, pelambre, angulo: 1.35, paso: 0.016, opacidad: 0.22);
    }

    // Melena por detrás de la oreja.
    final melena = Path()
      ..moveTo(centro.dx + r * 0.2, centro.dy - r * 0.98)
      ..cubicTo(
        centro.dx + r * 0.95, centro.dy - r * 0.85,
        centro.dx + r * 1.1, centro.dy + r * 0.2,
        centro.dx + r * 0.78, centro.dy + r * 0.7,
      )
      ..cubicTo(
        centro.dx + r * 0.6, centro.dy + r * 0.2,
        centro.dx + r * 0.6, centro.dy - r * 0.5,
        centro.dx + r * 0.2, centro.dy - r * 0.98,
      )
      ..close();
    _pieza(canvas, melena, pelo, 0.009);
  }

  // --- SOTA: paje de pie, jubón acuchillado y gorra con pluma -------------
  static void _sota(Canvas canvas, Color ropa) {
    final ropaSombra = Color.lerp(ropa, Colors.black, 0.3)!;

    // Piernas con calzas y zapatos.
    for (final pierna in const [
      [0.445, 0.6, 0.418, 0.78, 0.404, 0.9],
      [0.556, 0.6, 0.578, 0.78, 0.592, 0.9],
    ]) {
      final trazo = Path()
        ..moveTo(pierna[0], pierna[1])
        ..cubicTo(pierna[2], pierna[3] - 0.06, pierna[2], pierna[3],
            pierna[4], pierna[5]);
      _miembro(canvas, trazo, _lino, 0.042);
    }
    for (final zapato in const [Offset(0.398, 0.925), Offset(0.598, 0.925)]) {
      final z = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: zapato, width: 0.115, height: 0.055),
          const Radius.circular(0.022),
        ));
      _pieza(canvas, z, _cuero, 0.01);
    }

    // Calzón acuchillado (los gajos verticales del traje de época).
    final calzon = Path()
      ..moveTo(0.372, 0.485)
      ..cubicTo(0.338, 0.56, 0.35, 0.63, 0.402, 0.645)
      ..cubicTo(0.47, 0.665, 0.53, 0.665, 0.598, 0.645)
      ..cubicTo(0.65, 0.63, 0.662, 0.56, 0.628, 0.485)
      ..close();
    _pieza(canvas, calzon, ropa);
    for (final x in const [0.43, 0.5, 0.57]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 0.5)
          ..cubicTo(x - 0.012, 0.56, x - 0.008, 0.61, x, 0.648),
        _perfil(0.008),
      );
    }

    // Jubón.
    final jubon = Path()
      ..moveTo(0.402, 0.318)
      ..cubicTo(0.372, 0.4, 0.368, 0.46, 0.376, 0.5)
      ..cubicTo(0.45, 0.525, 0.55, 0.525, 0.624, 0.5)
      ..cubicTo(0.632, 0.46, 0.628, 0.4, 0.598, 0.318)
      ..close();
    _pieza(canvas, jubon, ropa);
    _rayado(canvas, jubon, angulo: 1.15, paso: 0.026, opacidad: 0.2);

    // Banda cruzada y cinturón.
    final banda = Path()
      ..moveTo(0.404, 0.335)
      ..lineTo(0.462, 0.325)
      ..lineTo(0.62, 0.478)
      ..lineTo(0.596, 0.508)
      ..close();
    _pieza(canvas, banda, _oro, 0.009);
    final cinto = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(0.375, 0.492, 0.625, 0.53),
        const Radius.circular(0.014),
      ));
    _pieza(canvas, cinto, _cuero, 0.01);

    // Mangas abullonadas.
    for (final espejo in const [false, true]) {
      final s = espejo ? -1.0 : 1.0;
      final o = espejo ? 1.0 : 0.0;
      double x(double v) => o + s * v;

      final hombro = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(x(0.372), 0.352),
          width: 0.135,
          height: 0.115,
        ));
      _pieza(canvas, hombro, ropa, 0.01);

      final antebrazo = Path()
        ..moveTo(x(0.352), 0.385)
        ..cubicTo(x(0.318), 0.44, x(0.322), 0.475, x(0.342), 0.505);
      _miembro(canvas, antebrazo, ropaSombra, 0.05);

      final mano = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(x(0.35), 0.522),
          width: 0.058,
          height: 0.052,
        ));
      _pieza(canvas, mano, _piel, 0.009);
    }

    // Gorguera.
    final gorguera = Path()
      ..addOval(Rect.fromCenter(
        center: const Offset(0.5, 0.312),
        width: 0.235,
        height: 0.078,
      ));
    _pieza(canvas, gorguera, _lino, 0.01);
    for (var i = 0; i < 9; i++) {
      final a = math.pi * (0.08 + 0.105 * i);
      canvas.drawLine(
        Offset(0.5 - math.cos(a) * 0.05, 0.312 + math.sin(a) * 0.016),
        Offset(0.5 - math.cos(a) * 0.116, 0.312 + math.sin(a) * 0.038),
        _perfil(0.007),
      );
    }

    _cabezaPerfil(canvas, const Offset(0.5, 0.215), 0.088);

    // Gorra ladeada con pluma.
    final gorra = Path()
      ..moveTo(0.388, 0.152)
      ..cubicTo(0.4, 0.058, 0.61, 0.042, 0.63, 0.132)
      ..cubicTo(0.638, 0.168, 0.558, 0.184, 0.47, 0.18)
      ..close();
    _pieza(canvas, gorra, ropa, 0.01);
    _rayado(canvas, gorra, angulo: 0.6, paso: 0.022, opacidad: 0.22);
    canvas.drawPath(
      Path()
        ..moveTo(0.616, 0.106)
        ..cubicTo(0.72, 0.07, 0.79, 0.036, 0.822, 0.006),
      Paint()
        ..color = _oro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.024
        ..strokeCap = StrokeCap.round,
    );
  }

  // --- CABALLO: jinete al paso, de perfil hacia la izquierda --------------
  static void _caballo(Canvas canvas, Color ropa) {
    final ropaSombra = Color.lerp(ropa, Colors.black, 0.32)!;

    // Patas del lado lejano, más apagadas para dar profundidad.
    for (final tramo in const [
      [0.436, 0.545, 0.452, 0.7, 0.428, 0.845],
      [0.742, 0.53, 0.786, 0.68, 0.774, 0.84],
    ]) {
      final trazo = Path()
        ..moveTo(tramo[0], tramo[1])
        ..cubicTo(tramo[2], tramo[3] - 0.06, tramo[2], tramo[3], tramo[4],
            tramo[5]);
      _miembro(canvas, trazo, _pelajeSombra, 0.042);
    }

    // Cola.
    final cola = Path()
      ..moveTo(0.822, 0.392)
      ..cubicTo(0.928, 0.44, 0.948, 0.64, 0.878, 0.79)
      ..cubicTo(0.874, 0.62, 0.844, 0.5, 0.788, 0.462)
      ..close();
    _pieza(canvas, cola, _crin, 0.01);
    _rayado(canvas, cola, angulo: 1.3, paso: 0.02, opacidad: 0.3);

    // Silueta continua: cabeza, cuello, pecho, vientre y grupa de un trazo.
    final cuerpo = Path()
      ..moveTo(0.306, 0.118)
      ..cubicTo(0.252, 0.14, 0.174, 0.18, 0.128, 0.212)
      ..cubicTo(0.1, 0.232, 0.09, 0.254, 0.1, 0.272)
      ..cubicTo(0.114, 0.292, 0.144, 0.29, 0.166, 0.278)
      ..cubicTo(0.208, 0.302, 0.252, 0.32, 0.294, 0.334)
      ..cubicTo(0.332, 0.376, 0.358, 0.424, 0.374, 0.466)
      ..cubicTo(0.388, 0.502, 0.394, 0.532, 0.4, 0.558)
      ..cubicTo(0.434, 0.614, 0.522, 0.634, 0.612, 0.622)
      ..cubicTo(0.682, 0.614, 0.744, 0.592, 0.794, 0.55)
      ..cubicTo(0.842, 0.506, 0.858, 0.448, 0.83, 0.408)
      ..cubicTo(0.802, 0.37, 0.742, 0.352, 0.674, 0.356)
      ..cubicTo(0.598, 0.36, 0.522, 0.372, 0.472, 0.372)
      ..cubicTo(0.44, 0.372, 0.414, 0.352, 0.4, 0.318)
      ..cubicTo(0.37, 0.232, 0.336, 0.156, 0.306, 0.118)
      ..close();
    _pieza(canvas, cuerpo, _pelaje, 0.013);
    _rayado(canvas, cuerpo, angulo: 1.2, paso: 0.03, opacidad: 0.16);

    // Orejas.
    for (final oreja in const [
      [0.296, 0.118, 0.276, 0.048, 0.336, 0.096],
      [0.336, 0.108, 0.336, 0.04, 0.382, 0.104],
    ]) {
      final o = Path()
        ..moveTo(oreja[0], oreja[1])
        ..quadraticBezierTo(oreja[2], oreja[3], oreja[4], oreja[5])
        ..close();
      _pieza(canvas, o, _pelaje, 0.009);
    }

    // Ollar, boca y ojo: trazos, no manchas.
    canvas
      ..drawLine(const Offset(0.113, 0.262), const Offset(0.142, 0.268),
          _perfil(0.009))
      ..drawPath(
        Path()
          ..moveTo(0.126, 0.232)
          ..quadraticBezierTo(0.14, 0.24, 0.136, 0.25),
        _perfil(0.009),
      );
    final ojo = Path()
      ..addOval(Rect.fromCenter(
        center: const Offset(0.229, 0.184),
        width: 0.042,
        height: 0.03,
      ));
    _pieza(canvas, ojo, _tinta, 0.008);

    // Crin en mechones.
    final crin = Path()
      ..moveTo(0.312, 0.114)
      ..lineTo(0.372, 0.152)
      ..lineTo(0.322, 0.184)
      ..lineTo(0.4, 0.238)
      ..lineTo(0.346, 0.268)
      ..lineTo(0.428, 0.324)
      ..lineTo(0.396, 0.352)
      ..cubicTo(0.372, 0.264, 0.342, 0.176, 0.306, 0.118)
      ..close();
    _pieza(canvas, crin, _crin, 0.01);

    // Gualdrapa con el color del palo.
    final gualdrapa = Path()
      ..moveTo(0.486, 0.372)
      ..lineTo(0.7, 0.358)
      ..cubicTo(0.716, 0.44, 0.71, 0.51, 0.686, 0.566)
      ..cubicTo(0.61, 0.594, 0.53, 0.594, 0.474, 0.572)
      ..close();
    _pieza(canvas, gualdrapa, ropa, 0.011);
    _rayado(canvas, gualdrapa, angulo: 1.25, paso: 0.028, opacidad: 0.2);
    canvas.drawPath(
      Path()
        ..moveTo(0.49, 0.548)
        ..cubicTo(0.56, 0.572, 0.63, 0.572, 0.688, 0.546),
      Paint()
        ..color = _oro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.016,
    );

    // Patas del lado cercano, por delante de la gualdrapa.
    for (final tramo in const [
      [0.478, 0.565, 0.512, 0.71, 0.5, 0.862],
      [0.79, 0.552, 0.836, 0.7, 0.828, 0.862],
    ]) {
      final trazo = Path()
        ..moveTo(tramo[0], tramo[1])
        ..cubicTo(tramo[2], tramo[3] - 0.06, tramo[2], tramo[3], tramo[4],
            tramo[5]);
      _miembro(canvas, trazo, _pelaje, 0.046);
    }
    for (final casco in const [
      Offset(0.428, 0.878),
      Offset(0.774, 0.872),
      Offset(0.5, 0.892),
      Offset(0.828, 0.892),
    ]) {
      final c = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: casco, width: 0.062, height: 0.042),
          const Radius.circular(0.012),
        ));
      _pieza(canvas, c, _crin, 0.009);
    }

    // --- Jinete ---
    // Pierna con bota, por delante de la gualdrapa.
    final pierna = Path()
      ..moveTo(0.598, 0.372)
      ..cubicTo(0.578, 0.45, 0.552, 0.5, 0.526, 0.542);
    _miembro(canvas, pierna, ropaSombra, 0.062);
    final bota = Path()
      ..moveTo(0.542, 0.5)
      ..cubicTo(0.512, 0.552, 0.492, 0.586, 0.474, 0.606)
      ..lineTo(0.53, 0.63)
      ..cubicTo(0.556, 0.59, 0.578, 0.548, 0.596, 0.518)
      ..close();
    _pieza(canvas, bota, _cuero, 0.01);

    // Capa al viento por detrás.
    final capa = Path()
      ..moveTo(0.63, 0.212)
      ..cubicTo(0.74, 0.238, 0.812, 0.31, 0.83, 0.404)
      ..cubicTo(0.79, 0.36, 0.73, 0.336, 0.676, 0.342)
      ..cubicTo(0.664, 0.29, 0.65, 0.244, 0.63, 0.212)
      ..close();
    _pieza(canvas, capa, ropaSombra, 0.011);
    _rayado(canvas, capa, angulo: 0.8, paso: 0.026, opacidad: 0.25);

    // Torso.
    final torso = Path()
      ..moveTo(0.556, 0.196)
      ..cubicTo(0.616, 0.176, 0.66, 0.194, 0.668, 0.226)
      ..cubicTo(0.68, 0.288, 0.664, 0.342, 0.64, 0.386)
      ..cubicTo(0.6, 0.398, 0.564, 0.392, 0.544, 0.372)
      ..cubicTo(0.534, 0.318, 0.54, 0.25, 0.556, 0.196)
      ..close();
    _pieza(canvas, torso, ropa, 0.012);
    _rayado(canvas, torso, angulo: 1.2, paso: 0.026, opacidad: 0.2);

    // Brazo hacia las riendas.
    final brazo = Path()
      ..moveTo(0.592, 0.244)
      ..cubicTo(0.55, 0.278, 0.5, 0.31, 0.462, 0.328);
    _miembro(canvas, brazo, ropa, 0.048);
    final mano = Path()
      ..addOval(Rect.fromCenter(
        center: const Offset(0.452, 0.332),
        width: 0.055,
        height: 0.05,
      ));
    _pieza(canvas, mano, _piel, 0.009);

    // Riendas hasta la boca.
    canvas.drawPath(
      Path()
        ..moveTo(0.44, 0.336)
        ..cubicTo(0.35, 0.32, 0.25, 0.286, 0.168, 0.264),
      _perfil(0.011),
    );

    _cabezaPerfil(canvas, const Offset(0.616, 0.156), 0.062);

    // Sombrero de ala ancha con pluma.
    final sombrero = Path()
      ..moveTo(0.516, 0.128)
      ..cubicTo(0.55, 0.052, 0.686, 0.048, 0.706, 0.116)
      ..cubicTo(0.72, 0.148, 0.62, 0.166, 0.516, 0.128)
      ..close();
    _pieza(canvas, sombrero, ropaSombra, 0.01);
    canvas.drawPath(
      Path()
        ..moveTo(0.69, 0.09)
        ..cubicTo(0.77, 0.052, 0.822, 0.028, 0.86, 0.014),
      Paint()
        ..color = _oro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.02
        ..strokeCap = StrokeCap.round,
    );
  }

  // --- REY: coronado, con manto de armiño y cetro -------------------------
  static void _rey(Canvas canvas, Color ropa) {
    final ropaSombra = Color.lerp(ropa, Colors.black, 0.3)!;

    // Cetro por detrás.
    _miembro(
      canvas,
      Path()
        ..moveTo(0.822, 0.9)
        ..lineTo(0.752, 0.28),
      _oro,
      0.026,
    );
    final remate = Path()
      ..addOval(Rect.fromCircle(center: const Offset(0.748, 0.248), radius: 0.05));
    _pieza(canvas, remate, _oro, 0.011);
    final cruz = Path()
      ..moveTo(0.748, 0.176)
      ..lineTo(0.748, 0.216)
      ..moveTo(0.724, 0.196)
      ..lineTo(0.772, 0.196);
    canvas.drawPath(
      cruz,
      Paint()
        ..color = _oro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.018
        ..strokeCap = StrokeCap.round,
    );

    // Manto acampanado.
    final manto = Path()
      ..moveTo(0.352, 0.35)
      ..cubicTo(0.27, 0.5, 0.212, 0.72, 0.176, 0.94)
      ..cubicTo(0.38, 0.972, 0.62, 0.972, 0.824, 0.94)
      ..cubicTo(0.788, 0.72, 0.73, 0.5, 0.648, 0.35)
      ..close();
    _pieza(canvas, manto, ropa, 0.013);
    _rayado(canvas, manto, angulo: 1.45, paso: 0.034, opacidad: 0.18);

    // Orla dorada del bajo.
    canvas.drawPath(
      Path()
        ..moveTo(0.184, 0.898)
        ..cubicTo(0.38, 0.932, 0.62, 0.932, 0.816, 0.898),
      Paint()
        ..color = _oro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.026,
    );

    // Franja central bordada con motivos.
    final franja = Path()
      ..moveTo(0.446, 0.42)
      ..lineTo(0.554, 0.42)
      ..cubicTo(0.578, 0.62, 0.59, 0.8, 0.596, 0.952)
      ..lineTo(0.404, 0.952)
      ..cubicTo(0.41, 0.8, 0.422, 0.62, 0.446, 0.42)
      ..close();
    _pieza(canvas, franja, _lino, 0.011);
    for (final y in const [0.52, 0.64, 0.76, 0.88]) {
      final rombo = Path()
        ..moveTo(0.5, y - 0.032)
        ..lineTo(0.536, y)
        ..lineTo(0.5, y + 0.032)
        ..lineTo(0.464, y)
        ..close();
      _pieza(canvas, rombo, _oro, 0.008);
    }

    // Mangas.
    for (final espejo in const [false, true]) {
      final s = espejo ? -1.0 : 1.0;
      final o = espejo ? 1.0 : 0.0;
      double x(double v) => o + s * v;

      final manga = Path()
        ..moveTo(x(0.366), 0.386)
        ..cubicTo(x(0.29), 0.46, x(0.262), 0.56, x(0.276), 0.64)
        ..cubicTo(x(0.33), 0.652, x(0.372), 0.63, x(0.392), 0.592)
        ..cubicTo(x(0.386), 0.51, x(0.386), 0.44, x(0.402), 0.4)
        ..close();
      _pieza(canvas, manga, ropaSombra, 0.011);
      _rayado(canvas, manga, angulo: 1.3, paso: 0.024, opacidad: 0.22);

      final mano = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(x(0.3), 0.664),
          width: 0.062,
          height: 0.055,
        ));
      _pieza(canvas, mano, _piel, 0.009);
    }

    // Cuello de armiño.
    final armino = Path()
      ..moveTo(0.322, 0.404)
      ..cubicTo(0.386, 0.336, 0.614, 0.336, 0.678, 0.404)
      ..cubicTo(0.61, 0.454, 0.39, 0.454, 0.322, 0.404)
      ..close();
    _pieza(canvas, armino, _lino, 0.011);
    for (final x in const [0.394, 0.462, 0.538, 0.606]) {
      final cola = Path()
        ..moveTo(x, 0.386)
        ..lineTo(x + 0.014, 0.412)
        ..lineTo(x - 0.014, 0.412)
        ..close();
      _pieza(canvas, cola, _tinta, 0.006);
    }

    _cabezaPerfil(canvas, const Offset(0.5, 0.26), 0.096, barba: true);

    // Corona.
    final corona = Path()
      ..moveTo(0.372, 0.196)
      ..lineTo(0.398, 0.086)
      ..lineTo(0.448, 0.16)
      ..lineTo(0.5, 0.058)
      ..lineTo(0.552, 0.16)
      ..lineTo(0.602, 0.086)
      ..lineTo(0.628, 0.196)
      ..close();
    _pieza(canvas, corona, _oro, 0.011);
    final aro = Path()
      ..addRRect(RRect.fromLTRBR(
          0.362, 0.186, 0.638, 0.238, const Radius.circular(0.018)));
    _pieza(canvas, aro, _oro, 0.011);
    _rayado(canvas, aro, angulo: 1.5, paso: 0.02, opacidad: 0.2);
    for (final gema in const [
      Offset(0.398, 0.086),
      Offset(0.5, 0.058),
      Offset(0.602, 0.086),
    ]) {
      final g = Path()..addOval(Rect.fromCircle(center: gema, radius: 0.026));
      _pieza(canvas, g, ropa, 0.008);
    }
    for (final perla in const [0.416, 0.5, 0.584]) {
      canvas.drawCircle(
          Offset(perla, 0.212), 0.014, _relleno(_lino));
      canvas.drawCircle(Offset(perla, 0.212), 0.014, _perfil(0.007));
    }
  }
}
