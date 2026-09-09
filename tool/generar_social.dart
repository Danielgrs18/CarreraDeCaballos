// Genera web/social.png, la imagen que sale al pegar el enlace en WhatsApp,
// Telegram o redes (la tarjeta de OpenGraph). No es un test: es una
// herramienta puntual que aprovecha `flutter test` para tener el motor de
// render a mano. Se ejecuta cuando cambie la portada:
//
//   flutter test tool/generar_social.dart
//
// Usa los widgets de verdad de la app —el tapete y las cartas vectoriales—
// así que la imagen no se puede desincronizar del juego. La tipografía se
// toma de las fuentes del sistema (Windows), igual que en las capturas.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:carrera_caballos/models/carta.dart';
import 'package:carrera_caballos/theme/app_theme.dart';
import 'package:carrera_caballos/widgets/carta_espanola.dart';
import 'package:carrera_caballos/widgets/tapete.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Medida estándar de las tarjetas de OpenGraph.
const _ancho = 1200.0;
const _alto = 630.0;

Future<void> _cargarSerif() async {
  for (final ruta in [
    r'C:\Windows\Fonts\times.ttf',
    r'C:\Windows\Fonts\georgia.ttf',
  ]) {
    final fichero = File(ruta);
    if (!fichero.existsSync()) continue;
    final bytes = await fichero.readAsBytes();
    final loader = FontLoader('serif')
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
    return;
  }
  throw StateError('No se encontró ninguna fuente con serifa que cargar');
}

void main() {
  setUpAll(_cargarSerif);

  testWidgets('portada para compartir', (tester) async {
    tester.view.physicalSize = const Size(_ancho, _alto);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final lienzo = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.tema,
        // Con Scaffold, no suelto: sin un Material encima, Flutter pinta
        // los textos con el subrayado amarillo de aviso.
        home: RepaintBoundary(
          key: lienzo,
          child: const Scaffold(body: Tapete(child: _Portada())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final limite =
        lienzo.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    // Dentro de runAsync a la fuerza: el reloj falso de los tests no deja
    // que el motor conteste a toImage, y la espera no terminaría nunca.
    await tester.runAsync(() async {
      final imagen = await limite.toImage(pixelRatio: 1.0);
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      final destino = File('web/social.png');
      await destino.writeAsBytes(datos!.buffer.asUint8List());
      // ignore: avoid_print
      print('Escrito ${destino.path} (${_ancho.toInt()}x${_alto.toInt()})');
    });
  });
}

class _Portada extends StatelessWidget {
  const _Portada();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Abanico(),
          const SizedBox(height: 34),
          Text(
            'CARRERA DE CABALLOS',
            textAlign: TextAlign.center,
            style: AppTheme.tituloDisplay.copyWith(
              fontSize: 62,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 260,
            height: 2,
            color: AppColors.oro.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 16),
          Text(
            'El juego de la baraja española, en el navegador',
            style: TextStyle(
              fontFamily: AppTheme.familiaTitulo,
              fontSize: 24,
              letterSpacing: 1.2,
              color: AppColors.oroClaro.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Los cuatro caballos en abanico, como en el menú pero a lo grande.
class _Abanico extends StatelessWidget {
  const _Abanico();

  @override
  Widget build(BuildContext context) {
    const ancho = 150.0;
    final palos = Palo.values;

    return SizedBox(
      width: ancho * 3.4,
      height: altoCarta(ancho) * 1.14,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < palos.length; i++)
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.translationValues(
                (i - (palos.length - 1) / 2) * 82.0,
                0.0,
                0.0,
              )..rotateZ((i - (palos.length - 1) / 2) * 0.19),
              child: Transform.translate(
                offset: Offset(
                  0,
                  -math.cos((i - (palos.length - 1) / 2) * 0.5) * 10,
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
