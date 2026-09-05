import 'dart:math';

import 'package:carrera_caballos/game/logica_juego.dart';
import 'package:carrera_caballos/models/carta.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tope de seguridad para que un fallo no cuelgue la suite.
const _maxTurnos = 5000;

void main() {
  group('Preparación de la partida', () {
    test('los 4 caballos salen de la baraja y esperan en la salida', () {
      final juego = LogicaJuego(random: Random(1));

      expect(juego.caballos.keys.toSet(), Palo.values.toSet());
      expect(juego.caballos.values.every((c) => c.posicion == 0), isTrue);
      expect(
        juego.caballos.values.map((c) => c.carta.valor).toSet(),
        {Valores.caballo},
      );
    });

    test('la pista y el mazo reparten las 36 cartas restantes', () {
      final juego = LogicaJuego(pasos: 6, random: Random(2));

      expect(juego.cartasPista.length, 6);
      expect(juego.cartasEnMazo, 36 - 6);
      expect(juego.cartasPista.any((c) => c.esCaballo), isFalse);
      expect(juego.pasosLevantados, 0);
    });

    test('la meta queda un paso más allá de la última carta', () {
      final juego = LogicaJuego(pasos: 6, random: Random(3));

      expect(juego.meta, 7);
      expect(juego.casillas, 7);
      expect(juego.terminada, isFalse);
      expect(juego.ultimaCarta, isNull);
    });
  });

  group('Desarrollo de la carrera', () {
    test('destapar una carta adelanta al caballo de ese palo', () {
      final juego = LogicaJuego(pasos: 6, random: Random(4));

      final resultado = juego.jugarTurno();

      expect(resultado.avanza, resultado.carta.palo);
      expect(juego.caballos[resultado.carta.palo]!.posicion, 1);
      expect(juego.ultimaCarta, resultado.carta);
    });

    test('una carta de paso solo se levanta cuando la han pasado los cuatro',
        () {
      for (var semilla = 0; semilla < 40; semilla++) {
        final juego = LogicaJuego(pasos: 6, random: Random(semilla));
        var levantadas = 0;

        for (var t = 0; t < _maxTurnos && !juego.terminada; t++) {
          // Al empezar el turno no puede quedar pendiente ninguna carta que
          // los cuatro caballos ya hayan dejado atrás.
          if (juego.pasosLevantados < juego.pasos) {
            expect(
              juego.pasoComunSuperado,
              lessThan(juego.pasosLevantados + 1),
              reason: 'quedó sin levantar el paso ${juego.pasosLevantados + 1}',
            );
          }

          final resultado = juego.jugarTurno();
          levantadas += resultado.revelaciones.length;
        }

        expect(levantadas, juego.pasosLevantados);
      }
    });

    test('las cartas de paso se levantan siempre en orden', () {
      for (var semilla = 0; semilla < 25; semilla++) {
        final juego = LogicaJuego(pasos: 6, random: Random(semilla));
        final levantadas = <Revelacion>[];
        while (!juego.terminada) {
          levantadas.addAll(juego.jugarTurno().revelaciones);
        }

        expect(
          levantadas.map((r) => r.paso),
          List.generate(levantadas.length, (i) => i + 1),
        );
        // Y son exactamente las primeras cartas de la pista, en orden.
        expect(
          levantadas.map((r) => r.carta),
          juego.cartasPista.take(levantadas.length),
        );
      }
    });

    test('ningún caballo retrocede más allá del cajón de salida', () {
      for (var semilla = 0; semilla < 25; semilla++) {
        final juego = LogicaJuego(pasos: 6, random: Random(semilla));
        while (!juego.terminada) {
          juego.jugarTurno();
          for (final caballo in juego.caballos.values) {
            expect(caballo.posicion, inInclusiveRange(0, juego.meta));
          }
        }
      }
    });

    test('cruzar la meta cierra la carrera con un único ganador', () {
      for (var semilla = 0; semilla < 25; semilla++) {
        final juego = LogicaJuego(pasos: 6, random: Random(semilla));

        ResultadoTurno? ultimo;
        var turnos = 0;
        while (!juego.terminada && turnos++ < _maxTurnos) {
          ultimo = juego.jugarTurno();
        }

        expect(juego.terminada, isTrue, reason: 'la carrera no terminó');
        expect(ultimo!.ganador, isNotNull);
        expect(ultimo.ganador, ultimo.carta.palo);
        expect(
          juego.caballos.values.where((c) => c.haLlegado(juego.meta)).length,
          1,
        );
        // El turno que gana no levanta ninguna carta más.
        expect(ultimo.revelaciones, isEmpty);
      }
    });

    test('las 36 cartas se conservan durante toda la partida', () {
      final juego = LogicaJuego(pasos: 6, random: Random(7));

      while (!juego.terminada) {
        juego.jugarTurno();
        expect(juego.cartasEnMazo + juego.cartasDescartadas, 36 - juego.pasos);
        expect(juego.cartasPista.length, juego.pasos);
        expect(juego.pasosLevantados, inInclusiveRange(0, juego.pasos));
      }
    });
  });

  group('Mazo agotado', () {
    test('los descartes se rebarajan y la carrera continúa', () {
      // Con una pista de 20 pasos solo quedan 16 cartas de robo, así que
      // el mazo tiene que reciclarse varias veces antes de que alguien gane.
      final juego = LogicaJuego(pasos: 20, random: Random(11));

      var reciclajes = 0;
      var turnos = 0;
      while (!juego.terminada && turnos++ < _maxTurnos) {
        if (juego.jugarTurno().mazoReciclado) reciclajes++;
      }

      expect(juego.terminada, isTrue);
      expect(reciclajes, greaterThan(0));
      expect(juego.cartasEnMazo + juego.cartasDescartadas, 36 - 20);
    });
  });

  group('Carrera reducida (1 contra 1)', () {
    test('con 2 palos, solo esos dos compiten y llevan la baraja a medias',
        () {
      final juego = LogicaJuego(
        pasos: 6,
        palos: [Palo.oros, Palo.espadas],
        random: Random(3),
      );

      expect(juego.caballos.keys.toSet(), {Palo.oros, Palo.espadas});
      // 2 palos x 10 valores, menos los 2 caballos que ya corren = 18.
      expect(juego.cartasPista.length + juego.cartasEnMazo, 18);
      expect(
        juego.cartasPista.every(
          (c) => c.palo == Palo.oros || c.palo == Palo.espadas,
        ),
        isTrue,
      );
    });

    test('el paso se levanta cuando lo superan los dos, no los cuatro', () {
      for (var semilla = 0; semilla < 25; semilla++) {
        final juego = LogicaJuego(
          pasos: 6,
          palos: [Palo.copas, Palo.bastos],
          random: Random(semilla),
        );

        var turnos = 0;
        while (!juego.terminada && turnos++ < _maxTurnos) {
          final resultado = juego.jugarTurno();
          // Solo pueden avanzar o levantarse cartas de los dos palos en
          // juego: si saliera un oro o una espada no debería pasar nada.
          expect({Palo.copas, Palo.bastos}, contains(resultado.avanza));
        }

        expect(juego.terminada, isTrue);
        expect({Palo.copas, Palo.bastos}, contains(juego.ganador));
      }
    });

    test('hacen falta al menos 2 caballos para competir', () {
      expect(
        () => LogicaJuego(palos: [Palo.oros]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('los palos de la carrera no pueden repetirse', () {
      expect(
        () => LogicaJuego(palos: [Palo.oros, Palo.oros, Palo.copas]),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
