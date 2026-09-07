import 'dart:math';

import 'package:carrera_caballos/game/campeonato.dart';
import 'package:carrera_caballos/game/logica_juego.dart';
import 'package:carrera_caballos/models/carta.dart';
import 'package:carrera_caballos/models/jugador.dart';
import 'package:flutter_test/flutter_test.dart';

/// Corre una carrera entera, hasta que no dé más de sí.
LogicaJuego _correr({int pasos = 6, int semilla = 0}) {
  final juego = LogicaJuego(pasos: pasos, random: Random(semilla));
  var turnos = 0;
  while (!juego.agotada && turnos++ < 5000) {
    juego.jugarTurno();
  }
  return juego;
}

const _ana = Jugador(nombre: 'Ana', palo: Palo.oros);
const _bea = Jugador(nombre: 'Bea', palo: Palo.copas);
const _caj = Jugador(nombre: 'Caj', palo: Palo.espadas);

void main() {
  group('Reparto de puntos', () {
    test('el primero se lleva tantos puntos como caballos, y así hacia abajo',
        () {
      final carrera = _correr(semilla: 5);
      final puntos = Campeonato.repartir(carrera);

      expect(carrera.clasificacion, hasLength(4));
      expect(puntos[carrera.clasificacion[0]], 4);
      expect(puntos[carrera.clasificacion[1]], 3);
      expect(puntos[carrera.clasificacion[2]], 2);
      expect(puntos[carrera.clasificacion[3]], 1);
      expect(puntos.values.reduce((a, b) => a + b), 4 + 3 + 2 + 1);
    });

    test('quien no llega a meta no puntúa', () {
      // Se busca una carrera en la que algún caballo se quede clavado.
      LogicaJuego? conDescolgado;
      for (var s = 0; s < 200 && conDescolgado == null; s++) {
        final carrera = _correr(pasos: 20, semilla: s);
        if (carrera.descolgados.isNotEmpty) conDescolgado = carrera;
      }

      expect(conDescolgado, isNotNull,
          reason: 'no se dio el caso en 200 semillas');
      final puntos = Campeonato.repartir(conDescolgado!);
      for (final palo in conDescolgado.descolgados) {
        expect(puntos[palo], 0);
      }
      // Todos los palos aparecen, aunque sea con un cero.
      expect(puntos.keys.toSet(), conDescolgado.caballos.keys.toSet());
    });
  });

  group('Marcador del campeonato', () {
    test('empieza en la ronda 1 y va contando las que se corren', () {
      final campeonato = Campeonato(rondas: 3, jugadores: const [_ana, _bea]);

      expect(campeonato.rondaActual, 1);
      expect(campeonato.rondasCorridas, 0);
      expect(campeonato.terminado, isFalse);

      campeonato.anotar(_correr(semilla: 1));
      expect(campeonato.rondaActual, 2);
      expect(campeonato.terminado, isFalse);

      campeonato.anotar(_correr(semilla: 2));
      campeonato.anotar(_correr(semilla: 3));
      expect(campeonato.rondasCorridas, 3);
      expect(campeonato.terminado, isTrue);
      // Terminado, la ronda actual se queda en la última, no se pasa.
      expect(campeonato.rondaActual, 3);
    });

    test('los puntos se acumulan ronda a ronda', () {
      final campeonato = Campeonato(rondas: 2, jugadores: const [_ana]);

      final primera = _correr(semilla: 8);
      final segunda = _correr(semilla: 9);
      campeonato.anotar(primera);
      campeonato.anotar(segunda);

      final esperado = Campeonato.repartir(primera)[Palo.oros]! +
          Campeonato.repartir(segunda)[Palo.oros]!;
      expect(campeonato.puntosDe(_ana), esperado);
      expect(campeonato.puntosPorPalo[Palo.oros], esperado);
      // El total repartido en dos carreras de 4 caballos.
      expect(
        campeonato.puntosPorPalo.values.reduce((a, b) => a + b),
        2 * (4 + 3 + 2 + 1),
      );
    });

    test('la última ronda solo cuenta la carrera recién corrida', () {
      final campeonato = Campeonato(rondas: 2, jugadores: const [_ana]);
      expect(campeonato.ultimaRonda, isEmpty);

      campeonato.anotar(_correr(semilla: 8));
      final segunda = _correr(semilla: 9);
      campeonato.anotar(segunda);

      expect(campeonato.ultimaRonda, Campeonato.repartir(segunda));
    });

    test('la clasificación ordena a los jugadores de más a menos puntos', () {
      final campeonato =
          Campeonato(rondas: 1, jugadores: const [_ana, _bea, _caj]);
      campeonato.anotar(_correr(semilla: 12));

      final orden = campeonato.clasificacion;
      expect(orden.toSet(), {_ana, _bea, _caj});
      for (var i = 1; i < orden.length; i++) {
        expect(
          campeonato.puntosDe(orden[i - 1]),
          greaterThanOrEqualTo(campeonato.puntosDe(orden[i])),
        );
      }
    });

    test('campeón es quien más suma, y empatados salen todos', () {
      // Dos jugadores con el mismo palo suman siempre lo mismo.
      const dupla = [
        Jugador(nombre: 'Ana', palo: Palo.oros),
        Jugador(nombre: 'Bis', palo: Palo.oros),
      ];
      final campeonato = Campeonato(rondas: 1, jugadores: dupla);
      campeonato.anotar(_correr(semilla: 4));

      expect(campeonato.campeones, dupla);
      expect(campeonato.puntosDe(dupla[0]), campeonato.puntosDe(dupla[1]));
    });

    test('campeón es el del palo que más puntos acumuló en las tres rondas',
        () {
      final campeonato =
          Campeonato(rondas: 3, jugadores: const [_ana, _bea, _caj]);
      for (final semilla in [21, 22, 23]) {
        campeonato.anotar(_correr(semilla: semilla));
      }

      // Puede haber empate arriba; lo que no puede es que quede fuera
      // alguien con tantos puntos como el mejor, ni dentro alguien con menos.
      final mejor = campeonato.puntosDe(campeonato.clasificacion.first);
      for (final jugador in [_ana, _bea, _caj]) {
        expect(
          campeonato.campeones.contains(jugador),
          campeonato.puntosDe(jugador) == mejor,
          reason: '$jugador suma ${campeonato.puntosDe(jugador)} de $mejor',
        );
      }
      // Tres rondas de cuatro caballos reparten 30 puntos en total.
      expect(campeonato.puntosPorPalo.values.reduce((a, b) => a + b), 30);
    });

    test('sin jugadores no hay campeón que valga', () {
      final campeonato = Campeonato(rondas: 1, jugadores: const []);
      campeonato.anotar(_correr(semilla: 1));

      expect(campeonato.campeones, isEmpty);
      expect(campeonato.clasificacion, isEmpty);
      // Los puntos de los palos se reparten igual, aunque no los siga nadie.
      expect(campeonato.puntosPorPalo.values.reduce((a, b) => a + b), 10);
    });

    test('no se puede anotar una ronda de más', () {
      final campeonato = Campeonato(rondas: 1, jugadores: const [_ana]);
      campeonato.anotar(_correr(semilla: 1));

      expect(
        () => campeonato.anotar(_correr(semilla: 2)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
