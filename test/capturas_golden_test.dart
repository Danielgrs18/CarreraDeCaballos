// Genera capturas para revisar el diseño a ojo.
//   flutter test test/capturas_golden_test.dart --update-goldens
@Tags(['capturas'])
library;

import 'dart:io';

import 'package:carrera_caballos/main.dart';
import 'package:carrera_caballos/models/carta.dart';
import 'package:carrera_caballos/theme/app_theme.dart';
import 'package:carrera_caballos/widgets/carta_espanola.dart';
import 'package:carrera_caballos/widgets/cartel_ganador.dart';
import 'package:carrera_caballos/widgets/tapete.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

Future<void> _lienzo(WidgetTester tester, Size tamano) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(_cargarSerif);

  testWidgets('baraja completa', (tester) async {
    await _lienzo(tester, const Size(1000, 760));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Tapete(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final palo in Palo.values)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final valor in Valores.todos)
                        Padding(
                          padding: const EdgeInsets.all(3),
                          child: CartaEspanola(
                            carta: Carta(palo, valor),
                            ancho: 92,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Tapete),
      matchesGoldenFile('capturas/baraja.png'),
    );
  });

  testWidgets('dorso y detalle', (tester) async {
    await _lienzo(tester, const Size(1240, 400));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Tapete(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final carta in const [
                  Carta(Palo.oros, Valores.sota),
                  Carta(Palo.copas, Valores.caballo),
                  Carta(Palo.espadas, Valores.rey),
                  Carta(Palo.bastos, Valores.as),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CartaEspanola(carta: carta, ancho: 210),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: DorsoCarta(ancho: 210),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Tapete),
      matchesGoldenFile('capturas/dorso.png'),
    );
  });

  testWidgets('menú principal', (tester) async {
    await _lienzo(tester, const Size(420, 860));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/menu.png'),
    );
  });

  testWidgets('modos de juego', (tester) async {
    await _lienzo(tester, const Size(420, 860));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modos de juego'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/modos_juego.png'),
    );
  });

  testWidgets('velo de salida', (tester) async {
    await _lienzo(tester, const Size(880, 420));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automático'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/velo_salida.png'),
    );
  });

  testWidgets('mesa en marcha', (tester) async {
    await _lienzo(tester, const Size(880, 420));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pump(const Duration(milliseconds: 300));

    for (var i = 0; i < 14; i++) {
      await tester.tap(find.bySemanticsLabel('Sacar carta del mazo').first);
      await tester.pump(const Duration(milliseconds: 500));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/mesa.png'),
    );
  });

  testWidgets('mesa en automático', (tester) async {
    await _lienzo(tester, const Size(880, 420));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automático'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));

    // Se deja correr el reloj para que salgan cartas y se levante algún paso.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 750));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/mesa_auto.png'),
    );
  });

  testWidgets('cartel de victoria', (tester) async {
    await _lienzo(tester, const Size(880, 420));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Scaffold(
          body: Tapete(
            child: CartelGanador(palo: Palo.bastos, onFinalizar: () {}, onRevancha: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/ganador.png'),
    );
  });
}
