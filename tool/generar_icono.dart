// Genera los PNG base del icono de la app (no es un test de verdad: es una
// herramienta puntual que aprovecha `flutter test` para tener acceso al
// motor de render). Se ejecuta a mano cuando hace falta rehacer el icono:
//
//   flutter test tool/generar_icono.dart
//
// Produce en assets/icon/: fondo.png (capa de fondo adaptativa), frente.png
// (capa de primer plano adaptativa, con transparencia) y maestro.png (fondo
// + anillo + herradura, para iOS/web/el icono clásico de Android).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tapeteClaro = Color(0xFF177A4B);
const _tapete = Color(0xFF0E5A38);
const _tapeteOscuro = Color(0xFF063722);
const _oroClaro = Color(0xFFF2DFA8);
const _oro = Color(0xFFD9B25A);
const _oroOscuro = Color(0xFF8A6A22);
const _tinta = Color(0xFF3A2A0E);

const _lienzo = 1024.0;

double _rad(double grados) => grados * math.pi / 180;

/// Una herradura: geometría exacta a partir de dos arcos concéntricos, nada
/// de curvas a mano alzada. Es el emblema ecuestre más reconocible que hay,
/// y se lee perfecto incluso diminuto, que es lo que de verdad importa en
/// un icono. La boca mira hacia arriba; el hierro da la vuelta por abajo.
class _Herradura {
  final Offset centro;
  final double radioFuera;
  final double radioDentro;
  final double anguloA; // extremo izquierdo de la boca
  final double anguloB; // extremo derecho de la boca
  final double barrido; // lo que ocupa el hierro, de B a A por abajo

  _Herradura(Rect area, {double gradosBoca = 66, double grosorRelativo = 0.43})
      : centro = area.center,
        radioFuera = area.width * 0.5,
        radioDentro = area.width * 0.5 * (1 - grosorRelativo),
        anguloA = _rad(270 - gradosBoca / 2),
        anguloB = _rad(270 + gradosBoca / 2),
        barrido = _rad(360 - gradosBoca);

  Offset _punto(double radio, double angulo) =>
      centro + Offset(math.cos(angulo), math.sin(angulo)) * radio;

  // El hierro va de B a A dando la vuelta larga (por el este, sur y oeste);
  // de A a B directo por el norte es la boca, la parte que NO se dibuja.
  Path get silueta {
    final inicio = _punto(radioFuera, anguloB);
    final finDentro = _punto(radioDentro, anguloA);
    return Path()
      ..moveTo(inicio.dx, inicio.dy)
      ..addArc(
        Rect.fromCircle(center: centro, radius: radioFuera),
        anguloB,
        barrido,
      )
      ..lineTo(finDentro.dx, finDentro.dy)
      ..addArc(
        Rect.fromCircle(center: centro, radius: radioDentro),
        anguloA,
        -barrido,
      )
      ..close();
  }

  /// Los agujeros de las clavijas, repartidos por el hierro.
  List<Offset> agujeros({int cuantos = 7}) {
    final radioMedio = (radioFuera + radioDentro) / 2;
    return [
      for (var i = 0; i < cuantos; i++)
        _punto(radioMedio, anguloB + barrido * (i + 0.5) / cuantos),
    ];
  }
}

Paint _rellenoOro(Rect area) => Paint()
  ..shader = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_oroClaro, _oro, _oroOscuro],
    stops: [0.0, 0.55, 1.0],
  ).createShader(area);

void _dibujarFondo(Canvas canvas, Size size) {
  final area = Offset.zero & size;
  canvas.drawRect(
    area,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.15, -0.35),
        radius: 1.15,
        colors: [_tapeteClaro, _tapete, _tapeteOscuro],
        stops: [0.0, 0.55, 1.0],
      ).createShader(area),
  );
}

void _dibujarHerradura(Canvas canvas, Rect area) {
  final herradura = _Herradura(area);
  final silueta = herradura.silueta;

  canvas.drawShadow(
    silueta.shift(Offset(area.width * 0.015, area.width * 0.022)),
    Colors.black,
    area.width * 0.018,
    false,
  );
  canvas.drawPath(silueta, _rellenoOro(area));
  canvas.drawPath(
    silueta,
    Paint()
      ..color = _tinta.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = area.width * 0.016
      ..strokeJoin = StrokeJoin.round,
  );

  // Un brillo suave a lo largo del borde exterior, para que no quede plana.
  canvas.drawPath(
    silueta,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = area.width * 0.05
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.softLight,
  );

  for (final agujero in herradura.agujeros()) {
    canvas.drawCircle(agujero, area.width * 0.026, Paint()..color = _tinta);
  }
}

/// Versión sin agujeros, sin anillo y con un hierro mucho más grueso: a
/// tamaño normal se ve tosca, pero es lo que hace falta para que se
/// reconozca en la pestaña del navegador (favicon.png sale a 16x16 de
/// verdad, y ahí cualquier detalle fino se convierte en una mancha).
void _dibujarHerraduraFavicon(Canvas canvas, Rect area) {
  final herradura = _Herradura(area, grosorRelativo: 0.62);
  final silueta = herradura.silueta;

  canvas.drawPath(silueta, _rellenoOro(area));
  canvas.drawPath(
    silueta,
    Paint()
      ..color = _tinta.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = area.width * 0.05
      ..strokeJoin = StrokeJoin.round,
  );
}

Future<ui.Image> _renderizar(void Function(Canvas) pintar, double lado) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  pintar(canvas);
  final picture = recorder.endRecording();
  final imagen = await picture.toImage(lado.round(), lado.round());
  picture.dispose();
  return imagen;
}

Future<void> _guardarPng(ui.Image imagen, String ruta) async {
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  imagen.dispose();
  final fichero = File(ruta);
  await fichero.parent.create(recursive: true);
  await fichero.writeAsBytes(datos!.buffer.asUint8List());
}

void main() {
  test('genera fondo.png, frente.png y maestro.png', () async {
    // La capa de primer plano adaptativa (Android 8+) recibe todavía un
    // 16% de margen automático de flutter_launcher_icons por encima de
    // este, así que aquí se deja casi a sangre: si se le añadiera otro
    // margen propio, la herradura saldría diminuta en los lanzadores
    // modernos. La versión clásica (maestro.png) no recibe ese margen
    // extra, así que ahí sí hace falta uno generoso.
    final zonaAdaptativa = Rect.fromLTWH(
      _lienzo * 0.06,
      _lienzo * 0.06,
      _lienzo * 0.88,
      _lienzo * 0.88,
    );
    final zonaClasica = Rect.fromLTWH(
      _lienzo * 0.19,
      _lienzo * 0.19,
      _lienzo * 0.62,
      _lienzo * 0.62,
    );

    final fondo = await _renderizar(
      (c) => _dibujarFondo(c, const Size(_lienzo, _lienzo)),
      _lienzo,
    );
    await _guardarPng(fondo, 'assets/icon/fondo.png');

    final frente = await _renderizar(
      (c) => _dibujarHerradura(c, zonaAdaptativa),
      _lienzo,
    );
    await _guardarPng(frente, 'assets/icon/frente.png');

    final maestro = await _renderizar((c) {
      _dibujarFondo(c, const Size(_lienzo, _lienzo));
      final centro = Offset(_lienzo / 2, _lienzo / 2);
      c.drawCircle(
        centro,
        _lienzo * 0.465,
        Paint()
          ..color = _oro
          ..style = PaintingStyle.stroke
          ..strokeWidth = _lienzo * 0.02,
      );
      _dibujarHerradura(c, zonaClasica);
    }, _lienzo);
    await _guardarPng(maestro, 'assets/icon/maestro.png');

    // Fuente aparte para el favicon: la web la reduce a 16x16 de verdad,
    // donde el anillo y los agujeros de la versión normal se emborronan.
    final zonaFavicon = Rect.fromLTWH(
      _lienzo * 0.08,
      _lienzo * 0.08,
      _lienzo * 0.84,
      _lienzo * 0.84,
    );
    final favicon = await _renderizar((c) {
      _dibujarFondo(c, const Size(_lienzo, _lienzo));
      _dibujarHerraduraFavicon(c, zonaFavicon);
    }, _lienzo);
    await _guardarPng(favicon, 'assets/icon/favicon_fuente.png');
  });
}
