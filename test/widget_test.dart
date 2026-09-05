import 'package:carrera_caballos/main.dart';
import 'package:carrera_caballos/screens/game_screen.dart';
import 'package:carrera_caballos/widgets/pista.dart';
import 'package:carrera_caballos/widgets/carta_espanola.dart';
import 'package:carrera_caballos/widgets/cartel_ganador.dart';
import 'package:carrera_caballos/models/carta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el menú ofrece partida rápida y desbloquear más',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    expect(find.text('Partida rápida'), findsOneWidget);
    expect(find.text('Desbloquear más'), findsOneWidget);
    expect(find.text('Baraja española'), findsNothing);
  });

  testWidgets('"Desbloquear más" todavía no lleva a ninguna parte',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Desbloquear más'));
    await tester.pump();

    expect(find.text('Próximamente'), findsOneWidget);
  });

  testWidgets('partida rápida enseña el tablero con el botón de comenzar',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();

    // Tablero tendido: los 4 caballos y las cartas de paso boca abajo.
    expect(find.byType(CartaEspanola), findsWidgets);
    expect(find.byType(DorsoCarta), findsWidgets);

    // Y la salida todavía sin dar: se elige caballo y modo antes de empezar.
    expect(find.text('Elige tu caballo ganador'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('Automático'), findsOneWidget);
  });

  testWidgets('al comenzar en manual se destapa carta tocando el mazo',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    // Con la carrera en marcha el mazo late en bucle, así que no hay estado
    // de reposo al que asentarse: se avanza el reloj a mano.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Comenzar'), findsNothing);
    // Las velocidades solo aparecen en modo automático.
    expect(find.text('Lenta'), findsNothing);

    final cartasAntes = tester.widgetList(find.byType(CartaEspanola)).length;
    await tester.tap(find.bySemanticsLabel('Sacar carta del mazo').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // La carta destapada se suma a las que ya había en la mesa.
    expect(
      tester.widgetList(find.byType(CartaEspanola)).length,
      greaterThan(cartasAntes),
    );
  });

  testWidgets(
      'el modo automático ya se puede elegir en el velo, con sus velocidades',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automático'));
    await tester.pumpAndSettle();

    expect(find.text('Lenta'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Rápida'), findsOneWidget);
  });

  testWidgets(
      'el selector de modo no se duplica: pasa del velo a la barra al empezar',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();

    // Antes de empezar solo está el del velo.
    expect(find.text('Manual'), findsOneWidget);

    await tester.tap(find.text('Comenzar'));
    await tester.pump(const Duration(milliseconds: 400));

    // Al empezar el velo desaparece y el de la barra ocupa su lugar: sigue
    // habiendo solo uno.
    expect(find.text('Elige tu caballo ganador'), findsNothing);
    expect(find.text('Manual'), findsOneWidget);
  });

  testWidgets('en pantalla vertical el tablero se gira en vez de aplastarse',
      (tester) async {
    // Móvil en vertical con la rotación bloqueada: el sistema no gira, así
    // que tiene que girarlo la propia pantalla de juego.
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();

    final girado = tester.widget<RotatedBox>(
      find.descendant(
        of: find.byType(GameScreen),
        matching: find.byType(RotatedBox),
      ).first,
    );
    expect(girado.quarterTurns, 1);

    // Y el tablero recibe un lienzo apaisado pese a la pantalla vertical.
    final pista = tester.getSize(find.byType(PistaWidget));
    expect(pista.width, greaterThan(pista.height));
  });

  testWidgets('en horizontal el tablero no se gira', (tester) async {
    tester.view.physicalSize = const Size(900, 420);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CarreraCaballosApp());
    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();

    final girado = tester.widget<RotatedBox>(
      find.descendant(
        of: find.byType(GameScreen),
        matching: find.byType(RotatedBox),
      ).first,
    );
    expect(girado.quarterTurns, 0);
  });

  testWidgets('el cartel de victoria canta el palo y ofrece finalizar',
      (tester) async {
    var finalizado = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelGanador(
            palo: Palo.espadas,
            onFinalizar: () => finalizado = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ESPADAS'), findsOneWidget);
    expect(find.text('GANA'), findsOneWidget);

    await tester.tap(find.text('Finalizar'));
    expect(finalizado, isTrue);
  });
}
