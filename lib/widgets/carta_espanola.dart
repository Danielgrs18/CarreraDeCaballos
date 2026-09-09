import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/ajustes_app.dart';
import '../game/cosmeticos.dart';
import '../models/carta.dart';
import '../theme/app_theme.dart';
import 'paint/figuras.dart';
import 'paint/palos.dart';

/// Proporción de la baraja española (62 x 95 mm).
const double kProporcionCarta = 62 / 95;

/// Altura que corresponde a una carta de [ancho] píxeles.
double altoCarta(double ancho) => ancho / kProporcionCarta;

/// Una carta española boca arriba, dibujada íntegramente con vectores.
class CartaEspanola extends StatelessWidget {
  final Carta carta;
  final double ancho;

  /// Atenúa la carta (se usa para las cartas de la pista ya levantadas).
  final bool apagada;

  const CartaEspanola({
    super.key,
    required this.carta,
    required this.ancho,
    this.apagada = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: ancho,
        height: altoCarta(ancho),
        child: CustomPaint(
          painter: _CaraPainter(carta: carta, apagada: apagada),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

/// El dorso: rojo oscuro con celosía dorada.
class DorsoCarta extends StatelessWidget {
  final double ancho;

  /// Fuerza un dorso concreto en lugar del que esté elegido. Solo lo usa
  /// la pantalla de Personalizar, para enseñar los que hay donde elegir.
  final DorsoBaraja? dorso;

  const DorsoCarta({super.key, required this.ancho, this.dorso});

  Widget _pintar(DorsoBaraja dorso) {
    return RepaintBoundary(
      child: SizedBox(
        width: ancho,
        height: altoCarta(ancho),
        child: CustomPaint(
          painter: _DorsoPainter(dorso),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final forzado = dorso;
    if (forzado != null) return _pintar(forzado);

    // Como el tapete: escucha por su cuenta, porque hay dorsos montados
    // desde sitios const que no se reconstruirían solos.
    return ListenableBuilder(
      listenable: ajustesApp,
      builder: (context, _) => _pintar(ajustesApp.dorso),
    );
  }
}

// --- Pintores ------------------------------------------------------------

/// Tinta del marco y de los índices, por palo.
Color _tintaPalo(Palo palo) => switch (palo) {
      Palo.oros => const Color(0xFF8A6414),
      Palo.copas => const Color(0xFF8E2222),
      Palo.espadas => const Color(0xFF2F5474),
      Palo.bastos => const Color(0xFF3D6127),
    };

class _CaraPainter extends CustomPainter {
  final Carta carta;
  final bool apagada;

  const _CaraPainter({required this.carta, required this.apagada});

  /// Número de interrupciones del marco: la "pinta" con la que se reconoce
  /// el palo de un vistazo en la baraja española.
  static int _pintas(Palo palo) => switch (palo) {
        Palo.oros => 0,
        Palo.copas => 1,
        Palo.espadas => 2,
        Palo.bastos => 3,
      };

  /// Colocación de las pintas de cada carta numérica, en coordenadas 0..1
  /// del área central de la carta.
  static const Map<int, List<Offset>> _reticula = {
    1: [Offset(0.5, 0.5)],
    2: [Offset(0.5, 0.17), Offset(0.5, 0.83)],
    3: [Offset(0.5, 0.13), Offset(0.5, 0.5), Offset(0.5, 0.87)],
    4: [
      Offset(0.19, 0.15),
      Offset(0.81, 0.15),
      Offset(0.19, 0.85),
      Offset(0.81, 0.85),
    ],
    5: [
      Offset(0.19, 0.15),
      Offset(0.81, 0.15),
      Offset(0.5, 0.5),
      Offset(0.19, 0.85),
      Offset(0.81, 0.85),
    ],
    6: [
      Offset(0.17, 0.12),
      Offset(0.83, 0.12),
      Offset(0.17, 0.5),
      Offset(0.83, 0.5),
      Offset(0.17, 0.88),
      Offset(0.83, 0.88),
    ],
    7: [
      Offset(0.16, 0.11),
      Offset(0.84, 0.11),
      Offset(0.16, 0.5),
      Offset(0.84, 0.5),
      Offset(0.5, 0.5),
      Offset(0.16, 0.89),
      Offset(0.84, 0.89),
    ],
  };

  static const Map<int, double> _tamanoPinta = {
    1: 0.95,
    2: 0.55,
    3: 0.46,
    4: 0.44,
    5: 0.44,
    6: 0.40,
    7: 0.32,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tinta = _tintaPalo(carta.palo);
    final radio = Radius.circular(w * 0.075);
    final cuerpo = RRect.fromRectAndRadius(Offset.zero & size, radio);

    // Cartulina envejecida: base, manchas de humedad y viñeteado.
    final cartulina = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.marfil, AppColors.marfilSombra],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(cuerpo, cartulina);
    _envejecer(canvas, size, cuerpo);

    // Canto exterior.
    canvas.drawRRect(
      cuerpo,
      Paint()
        ..color = AppColors.tinta.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );

    _marcoConPintas(canvas, size, tinta, cartulina);
    _indices(canvas, size, tinta);

    // Cuerpo de la carta: retícula de pintas o estampa de figura.
    if (carta.esFigura) {
      DibujoFigura.dibujar(
        canvas,
        Rect.fromLTRB(w * 0.15, h * 0.135, w * 0.85, h * 0.80),
        carta,
      );
      _nombreFigura(canvas, size, tinta);
    } else {
      _dibujarReticula(canvas, size);
    }

    if (apagada) {
      canvas.drawRRect(
        cuerpo,
        Paint()..color = AppColors.tapeteOscuro.withValues(alpha: 0.5),
      );
    }
  }

  /// Manchas de humedad y viñeteado: es lo que quita a la carta el aspecto
  /// de plástico recién impreso. El sembrado es determinista para que la
  /// misma carta salga siempre igual.
  void _envejecer(Canvas canvas, Size size, RRect cuerpo) {
    canvas
      ..save()
      ..clipRRect(cuerpo);

    var semilla = carta.palo.index * 31 + carta.valor * 7 + 13;
    double siguiente() {
      semilla = (semilla * 1103515245 + 12345) & 0x7FFFFFFF;
      return (semilla % 1000) / 1000;
    }

    for (var i = 0; i < 5; i++) {
      final centro = Offset(
        siguiente() * size.width,
        siguiente() * size.height,
      );
      final radio = size.width * (0.16 + siguiente() * 0.28);
      canvas.drawCircle(
        centro,
        radio,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.marfilMancha.withValues(alpha: 0.16),
              AppColors.marfilMancha.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: centro, radius: radio)),
      );
    }

    // Viñeteado hacia los cantos.
    canvas
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            radius: 0.78,
            colors: [
              AppColors.marfilMancha.withValues(alpha: 0),
              AppColors.marfilMancha.withValues(alpha: 0.28),
            ],
          ).createShader(Offset.zero & size),
      )
      ..restore();
  }

  /// Marco interior con las interrupciones propias del palo: es la seña por
  /// la que se reconoce el palo de un vistazo en la baraja española.
  void _marcoConPintas(
    Canvas canvas,
    Size size,
    Color tinta,
    Paint cartulina,
  ) {
    final w = size.width;
    final h = size.height;
    final inset = w * 0.085;
    final marco = RRect.fromRectAndRadius(
      Rect.fromLTRB(inset, inset, w - inset, h - inset),
      Radius.circular(w * 0.05),
    );

    canvas
      ..drawRRect(
        marco,
        Paint()
          ..color = tinta
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.018,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
              inset + w * 0.03, inset + w * 0.03, w - inset - w * 0.03, h - inset - w * 0.03),
          Radius.circular(w * 0.035),
        ),
        Paint()
          ..color = tinta.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.008,
      );

    final n = _pintas(carta.palo);
    if (n == 0) return;

    // Huecos centrados en los bordes corto superior e inferior.
    final separacion = w * 0.16;
    final ancho = w * 0.12;
    final borrador = cartulina;
    for (var i = 0; i < n; i++) {
      final dx = (i - (n - 1) / 2) * separacion;
      for (final y in [inset, h - inset]) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(w / 2 + dx, y),
            width: ancho,
            height: w * 0.09,
          ),
          borrador,
        );
      }
    }
  }

  /// Número en la esquina superior izquierda y repetido del revés en la
  /// inferior derecha, con una pinta pequeña de apoyo.
  void _indices(Canvas canvas, Size size, Color tinta) {
    final w = size.width;
    final h = size.height;

    final texto = TextPainter(
      text: TextSpan(
        text: carta.indice,
        style: TextStyle(
          fontFamily: AppTheme.familiaTitulo,
          fontSize: w * 0.2,
          height: 1,
          fontWeight: FontWeight.bold,
          color: tinta,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pinta = w * 0.15;

    void bloque(double x, double y, bool invertido) {
      canvas.save();
      canvas.translate(x, y);
      if (invertido) canvas.rotate(math.pi);
      texto.paint(canvas, Offset(-texto.width / 2, -texto.height * 0.62));
      DibujoPalo.dibujar(
        canvas,
        Rect.fromCenter(
          center: Offset(0, texto.height * 0.55 + pinta * 0.5),
          width: pinta,
          height: pinta,
        ),
        carta.palo,
      );
      canvas.restore();
    }

    bloque(w * 0.175, h * 0.085, false);
    bloque(w - w * 0.175, h - h * 0.085, true);
  }

  void _nombreFigura(Canvas canvas, Size size, Color tinta) {
    final nombre = carta.nombreFigura;
    if (nombre == null) return;

    final texto = TextPainter(
      text: TextSpan(
        text: nombre.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTheme.familiaTitulo,
          fontSize: size.width * 0.115,
          height: 1,
          fontWeight: FontWeight.bold,
          letterSpacing: size.width * 0.012,
          color: tinta,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.7);

    texto.paint(
      canvas,
      Offset((size.width - texto.width) / 2, size.height * 0.845),
    );
  }

  void _dibujarReticula(Canvas canvas, Size size) {
    final puntos = _reticula[carta.valor];
    final escala = _tamanoPinta[carta.valor];
    if (puntos == null || escala == null) return;

    final area = Rect.fromLTRB(
      size.width * 0.21,
      size.height * 0.145,
      size.width * 0.79,
      size.height * 0.855,
    );
    // El as lleva una sola pinta y se dibuja a toda plana, como en la baraja
    // de verdad; el resto van en celdas cuadradas para que no se solapen.
    if (carta.esAs) {
      DibujoPalo.dibujar(canvas, area, carta.palo);
      return;
    }

    final lado = area.width * escala;

    for (final p in puntos) {
      DibujoPalo.dibujar(
        canvas,
        Rect.fromCenter(
          center: Offset(
            area.left + p.dx * area.width,
            area.top + p.dy * area.height,
          ),
          width: lado,
          height: lado,
        ),
        carta.palo,
      );
    }
  }

  @override
  bool shouldRepaint(_CaraPainter oldDelegate) =>
      oldDelegate.carta != carta || oldDelegate.apagada != apagada;
}

class _DorsoPainter extends CustomPainter {
  final DorsoBaraja dorso;

  const _DorsoPainter(this.dorso);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cuerpo = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(w * 0.075),
    );

    canvas
      ..drawRRect(
        cuerpo,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [dorso.claro, dorso.medio, dorso.oscuro],
          ).createShader(Offset.zero & size),
      )
      ..drawRRect(
        cuerpo,
        Paint()
          ..color = AppColors.oro
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.035,
      );

    // Celosía de rombos.
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.11, w * 0.11, w - w * 0.11, h - w * 0.11),
      Radius.circular(w * 0.05),
    );
    canvas
      ..save()
      ..clipRRect(panel);

    final hilo = Paint()
      ..color = AppColors.oro.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014;
    final paso = w * 0.17;
    for (var d = -h; d < w + h; d += paso) {
      canvas
        ..drawLine(Offset(d, 0), Offset(d + h, h), hilo)
        ..drawLine(Offset(d, h), Offset(d + h, 0), hilo);
    }
    canvas.restore();

    canvas.drawRRect(
      panel,
      Paint()
        ..color = AppColors.oro.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    // Medallón central.
    final centro = Offset(w / 2, h / 2);
    final r = w * 0.24;
    canvas
      ..drawCircle(centro, r, Paint()..color = dorso.oscuro)
      ..drawCircle(
        centro,
        r,
        Paint()
          ..color = AppColors.oro
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.022,
      )
      ..drawCircle(
        centro,
        r * 0.72,
        Paint()
          ..color = AppColors.oro.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.012,
      );

    // Estrella de ocho puntas.
    final estrella = Path();
    for (var i = 0; i < 16; i++) {
      final radio = i.isEven ? r * 0.58 : r * 0.24;
      final a = i * math.pi / 8 - math.pi / 2;
      final p = centro + Offset(math.cos(a), math.sin(a)) * radio;
      if (i == 0) {
        estrella.moveTo(p.dx, p.dy);
      } else {
        estrella.lineTo(p.dx, p.dy);
      }
    }
    estrella.close();
    canvas.drawPath(estrella, Paint()..color = AppColors.oro);
  }

  @override
  bool shouldRepaint(_DorsoPainter oldDelegate) =>
      oldDelegate.dorso != dorso;
}
