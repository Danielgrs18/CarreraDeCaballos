import 'package:carrera_caballos/game/ajustes_app.dart';
import 'package:carrera_caballos/game/ajustes_partida.dart';
import 'package:carrera_caballos/game/cosmeticos.dart';
import 'package:carrera_caballos/game/enlaces.dart';
import 'package:carrera_caballos/game/sonido.dart';
import 'package:carrera_caballos/main.dart';
import 'package:carrera_caballos/screens/game_screen.dart';
import 'package:carrera_caballos/widgets/pista.dart';
import 'package:carrera_caballos/widgets/tapete.dart';
import 'package:carrera_caballos/widgets/carta_espanola.dart';
import 'package:carrera_caballos/widgets/cartel_ganador.dart';
import 'package:carrera_caballos/widgets/paint/palos.dart';
import 'package:carrera_caballos/models/carta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cuántos caballos hay corriendo en la pista mostrada ahora mismo.
int _carriles(WidgetTester tester) =>
    tester.widget<PistaWidget>(find.byType(PistaWidget)).logica.caballos.length;

/// De cuántos pasos es la pista que hay tendida ahora mismo.
int _pasos(WidgetTester tester) =>
    tester.widget<PistaWidget>(find.byType(PistaWidget)).logica.pasos;

/// El nombre escrito en el campo del jugador [indice]. Se busca por
/// posición porque el campo lleva el mismo texto de valor que de pista, y
/// buscarlo por texto lo encontraría dos veces.
String _nombreJugador(WidgetTester tester, int indice) =>
    tester.widget<TextField>(find.byType(TextField).at(indice)).controller!.text;

/// Cuántas cartas quedan por robar en la partida que hay en pantalla.
int _cartasEnMazo(WidgetTester tester) => tester
    .widget<PistaWidget>(find.byType(PistaWidget))
    .logica
    .cartasEnMazo;

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    // Sin plugin de audio detrás: se apaga de raíz para que no lluevan
    // MissingPluginException por caminos asíncronos.
    Sonido.desactivado = true;
  });

  // Los ajustes son un único objeto compartido que sobrevive a todos los
  // tests: sin esto, el que toca un interruptor se lo deja puesto al resto.
  setUp(ajustesApp.reiniciar);
  setUp(sonido.reiniciar);

  testWidgets(
      'el menú ofrece partida rápida, modos de juego y personalizar',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    expect(find.text('Partida rápida'), findsOneWidget);
    expect(find.text('Modos de juego'), findsOneWidget);
    expect(find.text('Personalizar'), findsOneWidget);
    expect(find.text('Baraja española'), findsNothing);
    // El antiguo "Desbloquear más" no prometía nada que existiera.
    expect(find.text('Desbloquear más'), findsNothing);
  });

  testWidgets(
      'modos de juego enseña el catálogo, y los tres ya se juegan',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Modos de juego'));
    await tester.pumpAndSettle();

    // De menos a más: la carrera suelta, la configurable y la que encadena
    // varias rondas. El orden se comprueba por dónde cae cada una.
    const orden = ['1 contra 1', 'Partida personalizada', 'Campeonato'];
    final alturas = <double>[];
    for (final modo in orden) {
      expect(find.text(modo), findsOneWidget);
      alturas.add(tester.getTopLeft(find.text(modo)).dy);
    }
    expect(alturas, orderedEquals(<double>[...alturas]..sort()));

    // Ya no queda ninguno pendiente de estrenar.
    expect(find.text('Pronto'), findsNothing);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Partida rápida'), findsOneWidget);
  });

  group('Partida personalizada', () {
    /// Entra al modo desde el catálogo y deja la pantalla en el velo.
    Future<void> abrir(WidgetTester tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.text('Modos de juego'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Partida personalizada'));
      await tester.pumpAndSettle();
    }

    testWidgets('el velo trae el largo de pista y un jugador de salida',
        (tester) async {
      await abrir(tester);

      expect(find.text('LONGITUD DE LA PISTA'), findsOneWidget);
      expect(find.text('JUGADORES'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Un solo jugador de partida, con su nombre por defecto.
      expect(find.byType(TextField), findsOneWidget);
      expect(_nombreJugador(tester, 0), 'Jugador 1');
      expect(find.text('Añadir jugador'), findsOneWidget);

      // Corren los 4 caballos: los jugadores solo se reparten los palos.
      expect(_carriles(tester), 4);
      // Y la pista arranca con el largo por defecto.
      expect(_pasos(tester), LongitudPista.porDefecto);
    });

    testWidgets('el deslizador cambia el largo de la pista al vuelo',
        (tester) async {
      await abrir(tester);

      // Se arrastra el pulsador hasta el extremo izquierdo: el mínimo.
      await tester.drag(find.byType(Slider), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(_pasos(tester), LongitudPista.minimo);

      await tester.drag(find.byType(Slider), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(_pasos(tester), LongitudPista.maximo);
    });

    testWidgets('se pueden añadir y quitar jugadores', (tester) async {
      await abrir(tester);

      // Con un solo jugador no hay nada que quitar.
      expect(find.byTooltip('Quitar jugador'), findsNothing);

      await tester.tap(find.text('Añadir jugador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir jugador'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
      expect(_nombreJugador(tester, 1), 'Jugador 2');
      expect(_nombreJugador(tester, 2), 'Jugador 3');
      expect(find.byTooltip('Quitar jugador'), findsNWidgets(3));

      await tester.tap(find.byTooltip('Quitar jugador').last);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byTooltip('Quitar jugador'), findsNWidgets(2));
    });

    testWidgets('el cartel canta los nombres de quienes iban a ese palo',
        (tester) async {
      await abrir(tester);

      // Dos jugadores, ambos al mismo palo.
      await tester.enterText(find.byType(TextField).at(0), 'Ana');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir jugador'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'Luis');
      await tester.pumpAndSettle();

      // Ana y Luis a oros; el tercero, a copas.
      for (final desplegable in [0, 1]) {
        await tester.tap(find.byType(DropdownButton<Palo>).at(desplegable));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Oros').last);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Comenzar'));
      await tester.pump(const Duration(milliseconds: 400));

      for (var i = 0; i < 400 && find.text('GANA').evaluate().isEmpty; i++) {
        await tester.tap(find.bySemanticsLabel('Sacar carta del mazo').first);
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.text('GANA'), findsOneWidget);
      await tester.pumpAndSettle();

      // Si ganan oros salen los dos nombres; si gana otro palo, ninguno.
      if (find.text('OROS').evaluate().isNotEmpty) {
        expect(find.text('Ana'), findsOneWidget);
        expect(find.text('Luis'), findsOneWidget);
        expect(find.text('GANADORES'), findsOneWidget);
      } else {
        expect(find.text('Ana'), findsNothing);
        expect(find.text('Luis'), findsNothing);
      }
    });
  });

  group('1 contra 1', () {
    testWidgets('el velo deja elegir un palo por jugador, sin repetirse',
        (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());

      await tester.tap(find.text('Modos de juego'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 contra 1'));
      await tester.pumpAndSettle();

      // Por defecto, Oros (jugador 1) contra Copas (jugador 2): 2 carriles.
      expect(find.byType(CartaEspanola), findsWidgets);
      expect(_carriles(tester), 2);
      // Oros solo puede estar en el selector del jugador 1: el del jugador 2
      // nunca ofrece el palo que ya tiene el otro.
      expect(find.text('Oros'), findsOneWidget);
      expect(find.text('Copas'), findsNWidgets(2));
      expect(find.text('Espadas'), findsNWidgets(2));
      expect(find.text('Bastos'), findsNWidgets(2));

      // El selector del jugador 1 se construye antes que el del jugador 2:
      // el primer resultado de cada palo es siempre el suyo.
      await tester.tap(find.text('Espadas').first);
      await tester.pumpAndSettle();
      expect(_carriles(tester), 2);
      // El jugador 1 solo ofrece Espadas a sí mismo (ya lo tiene elegido);
      // el jugador 2 sigue siendo Copas, sin cambios.
      expect(find.text('Espadas'), findsOneWidget);
      expect(find.text('Copas'), findsNWidgets(2));

      // Si el jugador 1 elige el palo del jugador 2, el jugador 2 se mueve
      // a otro distinto (nunca pueden coincidir).
      await tester.tap(find.text('Copas').first);
      await tester.pumpAndSettle();
      expect(_carriles(tester), 2);
      final logica = tester
          .widget<PistaWidget>(find.byType(PistaWidget))
          .logica;
      expect(logica.caballos.keys.toSet(), hasLength(2));
      expect(logica.caballos.containsKey(Palo.copas), isTrue);
      expect(logica.caballos.containsKey(Palo.espadas), isFalse);
    });

    testWidgets('se juega igual que la partida rápida: gana y hay revancha',
        (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());

      await tester.tap(find.text('Modos de juego'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 contra 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comenzar'));
      await tester.pump(const Duration(milliseconds: 400));

      for (var i = 0; i < 200 && find.text('GANA').evaluate().isEmpty; i++) {
        await tester.tap(find.bySemanticsLabel('Sacar carta del mazo').first);
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('GANA'), findsOneWidget);
      // El ganador es uno de los dos elegidos: Oros o Copas.
      final ganaOros = find.text('OROS').evaluate().isNotEmpty;
      final ganaCopas = find.text('COPAS').evaluate().isNotEmpty;
      expect(ganaOros || ganaCopas, isTrue);

      await tester.pumpAndSettle();
      await tester.tap(find.text('Revancha'));
      await tester.pumpAndSettle();

      expect(find.text('GANA'), findsNothing);
      expect(find.text('Elige tu caballo ganador'), findsOneWidget);
      expect(_carriles(tester), 2);
    });
  });

  group('Personalizar', () {
    Future<void> abrir(WidgetTester tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.text('Personalizar'));
      await tester.pumpAndSettle();
    }

    testWidgets('ofrece paños y dorsos, con lo elegido de fábrica',
        (tester) async {
      await abrir(tester);

      expect(find.text('PAÑO DE LA MESA'), findsOneWidget);
      expect(find.text('DORSO DE LA BARAJA'), findsOneWidget);
      for (final pano in PanoTapete.values) {
        expect(find.text(pano.etiqueta), findsOneWidget);
      }
      for (final dorso in DorsoBaraja.values) {
        expect(find.text(dorso.etiqueta), findsOneWidget);
      }

      expect(ajustesApp.pano, PanoTapete.verde);
      expect(ajustesApp.dorso, DorsoBaraja.granate);
    });

    testWidgets('elegir un paño y un dorso los deja puestos', (tester) async {
      await abrir(tester);

      await tester.tap(find.text(PanoTapete.azul.etiqueta));
      await tester.pumpAndSettle();
      expect(ajustesApp.pano, PanoTapete.azul);

      await tester.tap(find.text(DorsoBaraja.ebano.etiqueta));
      await tester.pumpAndSettle();
      expect(ajustesApp.dorso, DorsoBaraja.ebano);

      // Y siguen puestos al volver al menú y entrar otra vez.
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personalizar'));
      await tester.pumpAndSettle();
      expect(ajustesApp.pano, PanoTapete.azul);
      expect(ajustesApp.dorso, DorsoBaraja.ebano);
    });

    testWidgets('el paño elegido tiñe también la mesa de juego',
        (tester) async {
      await abrir(tester);
      await tester.tap(find.text(PanoTapete.burdeos.etiqueta));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Partida rápida'));
      await tester.pumpAndSettle();

      // El degradado del tapete de la mesa es el del paño elegido.
      final fondo = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(Tapete),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final gradiente =
          (fondo.decoration as BoxDecoration).gradient! as RadialGradient;
      expect(gradiente.colors.first, PanoTapete.burdeos.claro);
    });
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

  testWidgets(
      'los caballos en el cajón de salida no tapan el emblema de su palo',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();

    final pista = find.byType(PistaWidget);
    final emblemas =
        find.descendant(of: pista, matching: find.byType(EmblemaPalo));
    final fichas =
        find.descendant(of: pista, matching: find.byType(CartaEspanola));

    expect(emblemas.evaluate().length, 4);
    expect(fichas.evaluate().length, 4);

    // Cada emblema precede a la ficha de su propio carril en el árbol, así
    // que van emparejados por índice: ninguna ficha debe empezar antes de
    // que termine el cajón (emblema) de su carril.
    for (var i = 0; i < 4; i++) {
      final cajon = tester.getRect(emblemas.at(i));
      final caballo = tester.getRect(fichas.at(i));
      expect(caballo.left, greaterThanOrEqualTo(cajon.right - 1));
    }
  });

  testWidgets(
      'salir antes de comenzar no pide confirmación: no hay nada que perder',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Salir de la partida'));
    await tester.pumpAndSettle();

    expect(find.text('¿Salir de la carrera?'), findsNothing);
    expect(find.text('Partida rápida'), findsOneWidget);
  });

  testWidgets(
      'salir en plena carrera pide confirmar, y "seguir jugando" no sale',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pump(const Duration(milliseconds: 400));

    // Con la carrera en marcha el mazo late en bucle (invita a tocarlo en
    // modo manual), así que no hay estado de reposo al que pumpAndSettle
    // pueda asentarse: se avanza el reloj a mano también aquí.
    await tester.tap(find.byTooltip('Salir de la partida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('¿Salir de la carrera?'), findsOneWidget);

    await tester.tap(find.text('Seguir jugando'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Sigue en la mesa, con la carrera intacta (ya no está "Comenzar").
    expect(find.text('¿Salir de la carrera?'), findsNothing);
    expect(find.text('Comenzar'), findsNothing);
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('confirmar la salida en plena carrera sí que sale',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Salir de la partida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Salir'));
    // El mazo late en bucle hasta el mismísimo instante en que GameScreen
    // se desmonta del todo (a media transición de cierre, sigue latiendo):
    // pumpAndSettle no puede asentarse mientras tanto. Se avanza el reloj
    // a mano: primero el cierre del diálogo, luego el pop de la propia
    // pantalla de juego (son dos transiciones seguidas, no una).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('Partida rápida'), findsOneWidget);
  });

  testWidgets(
      'el botón de retroceso del sistema también pide confirmar en carrera',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pump(const Duration(milliseconds: 400));

    // Simula el gesto/botón de atrás del sistema, no un toque en la app.
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('¿Salir de la carrera?'), findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);
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

  testWidgets(
      'el cartel de victoria canta el palo y ofrece finalizar o revancha',
      (tester) async {
    var finalizado = false;
    var revancha = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelGanador(
            palo: Palo.espadas,
            onFinalizar: () => finalizado = true,
            onRevancha: () => revancha = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ESPADAS'), findsOneWidget);
    expect(find.text('GANA'), findsOneWidget);

    await tester.tap(find.text('Revancha'));
    expect(revancha, isTrue);
    expect(finalizado, isFalse);

    await tester.tap(find.text('Finalizar'));
    expect(finalizado, isTrue);
  });

  testWidgets('la revancha vuelve a la pantalla de comenzar sin salir de la mesa',
      (tester) async {
    await tester.pumpWidget(const CarreraCaballosApp());

    await tester.tap(find.text('Partida rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pump(const Duration(milliseconds: 400));

    // Se juega hasta que gane alguien: con 6 pasos, muchos turnos bastan.
    for (var i = 0; i < 200 && find.text('GANA').evaluate().isEmpty; i++) {
      await tester.tap(find.bySemanticsLabel('Sacar carta del mazo').first);
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('GANA'), findsOneWidget);
    // Se deja terminar la animación de entrada del cartel antes de tocar
    // sus botones, o el toque puede caer mientras el cartel aún crece.
    await tester.pumpAndSettle();

    await tester.tap(find.text('Revancha'));
    await tester.pumpAndSettle();

    // De vuelta al velo de salida, en la misma pantalla de juego.
    expect(find.text('GANA'), findsNothing);
    expect(find.text('Elige tu caballo ganador'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
  });

  group('Seguir hasta que lleguen todos', () {
    testWidgets('el cartel ofrece seguir, y al hacerlo reparte los puestos',
        (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.text('Partida rápida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comenzar'));
      await tester.pump(const Duration(milliseconds: 400));

      await _destaparHasta(tester, 'GANA');

      // La carrera está decidida, pero aún puede seguir. Hasta pedirlo,
      // la pista no gasta sitio en una columna de puestos.
      expect(find.text('PUESTO'), findsNothing);
      expect(find.text('1º'), findsNothing);

      expect(find.text('Seguir hasta que lleguen todos'), findsOneWidget);
      await tester.tap(find.text('Seguir hasta que lleguen todos'));
      // Nada de pumpAndSettle: al reanudar, el latido del mazo vuelve a
      // animarse sin fin y no habría fotograma en reposo que esperar.
      await tester.pump(const Duration(milliseconds: 400));

      // Se retira el cartel y se vuelve a poder destapar cartas.
      expect(find.text('GANA'), findsNothing);

      // Y la pista estrena la columna de puestos, con el primero ya dado.
      expect(find.text('PUESTO'), findsOneWidget);
      expect(find.text('1º'), findsOneWidget);
      // Los que siguen en carrera aún no tienen puesto que enseñar.
      expect(find.text('2º'), findsNothing);

      await _destaparHasta(tester, 'CLASIFICACIÓN');

      // Los cuatro palos aparecen con su puesto y el primero, cantado.
      for (final palo in Palo.values) {
        expect(find.text(palo.nombre), findsOneWidget);
      }
      // Dos veces cada puesto: la chapa de la pista, que sigue detrás, y
      // la línea del cartel que la tapa.
      expect(find.text('1º'), findsNWidgets(2));
      expect(find.text('Revancha'), findsOneWidget);
      expect(find.text('Finalizar'), findsOneWidget);
      // Ya no hay nada que seguir.
      expect(find.text('Seguir hasta que lleguen todos'), findsNothing);
    });

    testWidgets('sin nadie a quien esperar, el cartel no ofrece seguir',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartelGanador(
              palo: Palo.bastos,
              onFinalizar: () {},
              onRevancha: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BASTOS'), findsOneWidget);
      expect(find.text('Seguir hasta que lleguen todos'), findsNothing);
      expect(find.text('Revancha'), findsOneWidget);
    });

    testWidgets('la clasificación se puede repetir con la revancha',
        (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.text('Partida rápida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comenzar'));
      await tester.pump(const Duration(milliseconds: 400));

      await _destaparHasta(tester, 'GANA');
      await tester.tap(find.text('Seguir hasta que lleguen todos'));
      // Nada de pumpAndSettle: al reanudar, el latido del mazo vuelve a
      // animarse sin fin y no habría fotograma en reposo que esperar.
      await tester.pump(const Duration(milliseconds: 400));
      await _destaparHasta(tester, 'CLASIFICACIÓN');

      await tester.tap(find.text('Revancha'));
      await tester.pumpAndSettle();

      expect(find.text('CLASIFICACIÓN'), findsNothing);
      expect(find.text('Comenzar'), findsOneWidget);
    });
  });

  group('Campeonato', () {
    /// Entra al modo desde el catálogo y deja la pantalla en el velo.
    Future<void> abrir(WidgetTester tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.text('Modos de juego'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Campeonato'));
      await tester.pumpAndSettle();
    }

    /// Deja el velo con el campeonato más corto posible: dos rondas y la
    /// pista mínima, para que la partida quepa en un test.
    Future<void> ajustarCorto(WidgetTester tester) async {
      await tester.drag(find.byType(Slider).at(0), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Slider).at(1), const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('el velo añade las rondas a los ajustes de la personalizada',
        (tester) async {
      await abrir(tester);

      expect(find.text('RONDAS DEL CAMPEONATO'), findsOneWidget);
      expect(find.text('LONGITUD DE LA PISTA'), findsOneWidget);
      expect(find.text('JUGADORES'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));

      await ajustarCorto(tester);
      expect(find.text('2 rondas'), findsOneWidget);
      expect(_pasos(tester), LongitudPista.minimo);
      // Corren los cuatro caballos, como en la personalizada.
      expect(_carriles(tester), 4);
    });

    testWidgets('corre las rondas, puntúa y corona al campeón',
        (tester) async {
      await abrir(tester);
      await ajustarCorto(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Ana');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comenzar'));
      await tester.pump(const Duration(milliseconds: 400));

      // La barra superior canta por qué ronda va.
      expect(find.text('Ronda 1 de 2'), findsOneWidget);

      await _destaparHasta(tester, 'RONDA 1 DE 2');
      expect(find.text('Marcador del campeonato'), findsOneWidget);
      // Los cuatro palos con su marcador, y ni rastro de la revancha.
      expect(find.textContaining(' pts'), findsNWidgets(4));
      expect(find.text('Revancha'), findsNothing);

      await tester.tap(find.text('Siguiente ronda'));
      // La ronda arranca al momento, con el mazo latiendo otra vez: hay
      // que avanzar a mano en vez de esperar a un reposo que no llega.
      await tester.pump(const Duration(milliseconds: 400));

      // Arranca sola: entre rondas no se vuelve a pasar por el velo.
      expect(find.text('Comenzar'), findsNothing);
      expect(find.text('Ronda 2 de 2'), findsOneWidget);

      await _destaparHasta(tester, 'CAMPEONATO');

      // Ana es la única jugadora: gane el palo que gane, el campeonato
      // se lo lleva ella.
      expect(find.text('Gana Ana'), findsOneWidget);
      expect(find.text('Siguiente ronda'), findsNothing);

      await tester.tap(find.text('Otro campeonato'));
      await tester.pumpAndSettle();
      expect(find.text('CAMPEONATO'), findsNothing);
      expect(find.text('Comenzar'), findsOneWidget);
    });
  });

  group('Sonido', () {
    testWidgets('callado hasta que el usuario toca la página',
        (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());

      // Los navegadores no dejan sonar nada sin un gesto previo, así que
      // ni se intenta: se espera.
      expect(sonido.puedeSonar, isFalse);

      await tester.tap(find.text('Partida rápida'));
      await tester.pumpAndSettle();
      expect(sonido.puedeSonar, isTrue);
    });

    testWidgets('silenciar desde el menú calla el sonido', (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();
      expect(sonido.puedeSonar, isTrue);

      await tester.tap(find.text('Silenciar'));
      await tester.pumpAndSettle();
      expect(ajustesApp.silencio, isTrue);
      expect(sonido.puedeSonar, isFalse);

      // Y al quitarlo vuelve a poder sonar, sin salir del menú.
      await tester.tap(find.text('Silenciar'));
      await tester.pumpAndSettle();
      expect(sonido.puedeSonar, isTrue);
    });
  });

  group('Menú de la app', () {
    testWidgets('el botón está en la esquina de las tres pantallas',
        (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      expect(find.byTooltip('Menú'), findsOneWidget);

      await tester.tap(find.text('Modos de juego'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Menú'), findsOneWidget);

      await tester.tap(find.text('1 contra 1'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Menú'), findsOneWidget);
    });

    testWidgets('los interruptores recuerdan lo que se elige',
        (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();

      expect(find.text('Silenciar'), findsOneWidget);
      expect(find.text('Vibración'), findsOneWidget);
      expect(find.text('Pantalla siempre encendida'), findsOneWidget);
      expect(find.text('La música y el barajeo de las cartas'), findsOneWidget);

      expect(ajustesApp.vibracion, isTrue);
      await tester.tap(find.text('Vibración'));
      await tester.pumpAndSettle();
      expect(ajustesApp.vibracion, isFalse);

      expect(ajustesApp.silencio, isFalse);
      await tester.tap(find.text('Silenciar'));
      await tester.pumpAndSettle();
      expect(ajustesApp.silencio, isTrue);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.text('Silenciar'), findsNothing);
      // Y lo elegido sigue puesto al volver a abrirlo.
      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();
      expect(ajustesApp.silencio, isTrue);
    });

    testWidgets('la entrada de apoyo solo sale si hay enlace configurado',
        (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();

      // El código sí es público y siempre está.
      expect(find.text('Código fuente'), findsOneWidget);
      // La de donaciones espera a que se pegue una dirección propia: una
      // de ejemplo mandaría el dinero a otra parte.
      expect(Enlaces.hayDonacion, isFalse);
      expect(find.text('Apoyar el proyecto'), findsNothing);
    });

    testWidgets('desde el menú se llega a las reglas', (tester) async {
      // En horizontal el alto escasea y las reglas son largas: si el
      // diálogo no se desplazara, el desbordamiento tumbaría el test.
      tester.view.physicalSize = const Size(880, 420);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();

      // Con tan poco alto la entrada cae bajo el pliegue del menú: hay
      // que traerla a la vista o el toque se iría al velo de fuera.
      await tester.ensureVisible(find.text('Cómo se juega'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cómo se juega'));
      await tester.pumpAndSettle();

      expect(find.textContaining('el 11 de cada palo'), findsOneWidget);
      expect(find.textContaining('retrocede una casilla'), findsOneWidget);

      await tester.ensureVisible(find.text('Entendido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      // Se vuelve al menú, que sigue abierto detrás.
      expect(find.text('Silenciar'), findsOneWidget);
    });

    testWidgets('abrir el menú para la carrera automática', (tester) async {
      await tester.pumpWidget(const CarreraCaballosApp());
      await tester.tap(find.text('Partida rápida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Automático'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comenzar'));
      await tester.pump(const Duration(seconds: 2));

      final antes = _cartasEnMazo(tester);

      await tester.tap(find.byTooltip('Menú'));
      await tester.pump(const Duration(milliseconds: 400));
      // Con el menú tapando la mesa no deben salir cartas a ciegas.
      await tester.pump(const Duration(seconds: 3));
      expect(_cartasEnMazo(tester), antes);

      await tester.tap(find.text('Cerrar'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));
      expect(_cartasEnMazo(tester), lessThan(antes));
    });
  });
}

/// Destapa cartas a mano hasta que salga el cartel con [rotulo]. Se pulsa
/// el mazo en vez de dejar correr el automático porque su temporizador no
/// para nunca y `pumpAndSettle` no llegaría a devolver el control.
Future<void> _destaparHasta(WidgetTester tester, String rotulo) async {
  final cartel = find.text(rotulo);
  for (var i = 0; i < 600 && cartel.evaluate().isEmpty; i++) {
    await tester.tap(find.bySemanticsLabel('Sacar carta del mazo').first);
    await tester.pump(const Duration(milliseconds: 400));
  }
  // Se deja acabar la animación de entrada antes de tocar sus botones, o
  // el toque cae mientras el cartel todavía está creciendo.
  await tester.pumpAndSettle();
  expect(cartel, findsOneWidget, reason: 'nunca salió el cartel "$rotulo"');
}
