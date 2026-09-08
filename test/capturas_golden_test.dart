// Genera capturas para revisar el diseño a ojo.
//   flutter test test/capturas_golden_test.dart --update-goldens
@Tags(['capturas'])
library;

import 'dart:io';
import 'dart:math';

import 'package:carrera_caballos/main.dart';
import 'package:carrera_caballos/game/logica_juego.dart';
import 'package:carrera_caballos/models/carta.dart';
import 'package:carrera_caballos/theme/app_theme.dart';
import 'package:carrera_caballos/widgets/carta_espanola.dart';
import 'package:carrera_caballos/widgets/cartel_clasificacion.dart';
import 'package:carrera_caballos/widgets/cartel_ganador.dart';
import 'package:carrera_caballos/widgets/pista.dart';
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

  testWidgets('1 contra 1: velo con selectores', (tester) async {
    await _lienzo(tester, const Size(880, 420));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modos de juego'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 contra 1'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/uno_vs_uno_velo.png'),
    );
  });

  testWidgets('1 contra 1: mesa con solo 2 carriles', (tester) async {
    await _lienzo(tester, const Size(880, 420));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modos de juego'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 contra 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pump(const Duration(milliseconds: 300));

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.bySemanticsLabel('Sacar carta del mazo').first);
      await tester.pump(const Duration(milliseconds: 500));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/uno_vs_uno_mesa.png'),
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
            child: CartelGanador(
              palo: Palo.bastos,
              onFinalizar: () {},
              onRevancha: () {},
              onContinuar: () {},
            ),
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

  testWidgets('personalizada: velo con ajustes', (tester) async {
    await _lienzo(tester, const Size(880, 460));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modos de juego'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partida personalizada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir jugador'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/personalizada_velo.png'),
    );
  });

  testWidgets('cartel de victoria con jugadores', (tester) async {
    await _lienzo(tester, const Size(880, 420));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Scaffold(
          body: Tapete(
            child: CartelGanador(
              palo: Palo.espadas,
              onFinalizar: () {},
              onRevancha: () {},
              ganadores: const ['Ana', 'Luis', 'Marta'],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/ganador_jugadores.png'),
    );
  });

  testWidgets('clasificación al llegar todos', (tester) async {
    await _lienzo(tester, const Size(880, 460));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Scaffold(
          body: Tapete(
            child: CartelClasificacion(
              titulo: 'Clasificación',
              subtitulo: 'Gana Espadas',
              puestos: const [
                PuestoClasificacion(palo: Palo.espadas, nombres: ['Ana']),
                PuestoClasificacion(palo: Palo.oros, nombres: ['Luis']),
                PuestoClasificacion(palo: Palo.copas),
                PuestoClasificacion(
                  palo: Palo.bastos,
                  nombres: ['Marta'],
                  llegado: false,
                ),
              ],
              acciones: [
                ElevatedButton(onPressed: () {}, child: const Text('Revancha')),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/clasificacion.png'),
    );
  });

  testWidgets('campeonato: velo con rondas', (tester) async {
    await _lienzo(tester, const Size(880, 500));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modos de juego'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campeonato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir jugador'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/campeonato_velo.png'),
    );
  });

  testWidgets('campeonato: marcador entre rondas', (tester) async {
    await _lienzo(tester, const Size(880, 460));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Scaffold(
          body: Tapete(
            child: CartelClasificacion(
              titulo: 'Ronda 2 de 4',
              subtitulo: 'Marcador del campeonato',
              puestos: const [
                PuestoClasificacion(
                  palo: Palo.oros,
                  nombres: ['Ana', 'Luis'],
                  puntos: 7,
                  detalle: '+4',
                ),
                PuestoClasificacion(palo: Palo.copas, puntos: 5, detalle: '+2'),
                PuestoClasificacion(
                  palo: Palo.espadas,
                  nombres: ['Marta'],
                  puntos: 4,
                  detalle: '+3',
                ),
                PuestoClasificacion(
                  palo: Palo.bastos,
                  puntos: 4,
                  detalle: 'no llegó',
                ),
              ],
              acciones: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Siguiente ronda'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/campeonato_ronda.png'),
    );
  });

  testWidgets('pista con la columna de puestos', (tester) async {
    await _lienzo(tester, const Size(760, 300));

    // Se juega hasta que hayan entrado dos: así se ven las chapas del 1º
    // y el 2º, y otros dos caballos todavía corriendo.
    final juego = LogicaJuego(pasos: 6, random: Random(4));
    var turnos = 0;
    while (juego.clasificacion.length < 2 && !juego.agotada && turnos++ < 500) {
      juego.jugarTurno();
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Scaffold(
          body: Tapete(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: PistaWidget(
                logica: juego,
                duracionAnimacion: const Duration(milliseconds: 300),
                mostrarPuestos: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Tapete),
      matchesGoldenFile('capturas/pista_puestos.png'),
    );
  });

  testWidgets('menú de la app', (tester) async {
    await _lienzo(tester, const Size(420, 860));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menú'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/menu_ajustes.png'),
    );
  });

  testWidgets('menú sobre la mesa, en horizontal', (tester) async {
    await _lienzo(tester, const Size(880, 420));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menú'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/menu_mesa.png'),
    );
  });

  testWidgets('reglas del juego', (tester) async {
    await _lienzo(tester, const Size(420, 860));

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cómo se juega'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/reglas.png'),
    );
  });
}
