import 'dart:math';

import 'package:carrera_caballos/game/ajustes_partida.dart';
import 'package:carrera_caballos/game/campeonato.dart';
import 'package:carrera_caballos/game/logica_juego.dart';
import 'package:carrera_caballos/game/sala.dart';
import 'package:carrera_caballos/models/carta.dart';
import 'package:flutter_test/flutter_test.dart';

/// La crónica completa de una carrera: si dos coinciden, los dos jugadores
/// han visto exactamente lo mismo.
String _cronica(Sala sala, {int ronda = 0}) {
  final juego = LogicaJuego(
    pasos: sala.pasos,
    palos: sala.palosEnCarrera,
    random: sala.generador(ronda: ronda),
  );
  final turnos = <String>[];
  var t = 0;
  while (!juego.agotada && t++ < 5000) {
    final r = juego.jugarTurno();
    turnos.add('${r.carta}|${r.avanza}|${r.llegada}|${r.mazoReciclado}');
  }
  return '${juego.clasificacion}::${turnos.join(';')}';
}

/// Una sala de cada modo, con todos sus extras puestos.
List<Sala> _unaDeCada(Random aleatorio) => [
      Sala.nueva(random: aleatorio),
      Sala.nueva(
        modalidad: ModalidadPartida.unoContraUno,
        palos: const [Palo.espadas, Palo.copas],
        random: aleatorio,
      ),
      Sala.nueva(
        modalidad: ModalidadPartida.personalizada,
        pasos: 9,
        random: aleatorio,
      ),
      Sala.nueva(
        modalidad: ModalidadPartida.campeonato,
        pasos: 4,
        rondas: 5,
        random: aleatorio,
      ),
    ];

void main() {
  group('Código de sala', () {
    test('el código son ocho caracteres y vuelve a la misma sala', () {
      final aleatorio = Random(1);
      for (var i = 0; i < 50; i++) {
        for (final sala in _unaDeCada(aleatorio)) {
          expect(sala.codigo, hasLength(Sala.largoCodigo));
          expect(sala.codigo, matches(RegExp(r'^[0-9A-Z]+$')));
          expect(Sala.desdeCodigo(sala.codigo), sala, reason: sala.codigo);
        }
      }
    });

    test('el modo viaja dentro del código', () {
      final aleatorio = Random(2);
      for (final modalidad in Sala.modalidades) {
        final sala = Sala.nueva(modalidad: modalidad, random: aleatorio);
        expect(Sala.desdeCodigo(sala.codigo)!.modalidad, modalidad);
      }
    });

    test('el 1 contra 1 conserva sus dos palos, y en su orden', () {
      final aleatorio = Random(3);
      for (final a in Palo.values) {
        for (final b in Palo.values) {
          if (a == b) continue;
          final sala = Sala.nueva(
            modalidad: ModalidadPartida.unoContraUno,
            palos: [a, b],
            random: aleatorio,
          );
          expect(Sala.desdeCodigo(sala.codigo)!.palos, [a, b]);
        }
      }
    });

    test('el campeonato conserva sus rondas', () {
      final aleatorio = Random(4);
      for (var rondas = NumeroRondas.minimo;
          rondas <= NumeroRondas.maximo;
          rondas++) {
        final sala = Sala.nueva(
          modalidad: ModalidadPartida.campeonato,
          rondas: rondas,
          random: aleatorio,
        );
        expect(Sala.desdeCodigo(sala.codigo)!.rondas, rondas);
      }
    });

    test('la pista se conserva entera', () {
      for (var pasos = LongitudPista.minimo;
          pasos <= LongitudPista.maximo;
          pasos++) {
        final sala = Sala.nueva(
          modalidad: ModalidadPartida.personalizada,
          pasos: pasos,
          random: Random(pasos),
        );
        expect(Sala.desdeCodigo(sala.codigo)!.pasos, pasos);
      }
    });

    test('no usa letras que se confunden al dictarlas', () {
      final aleatorio = Random(7);
      for (var i = 0; i < 100; i++) {
        for (final sala in _unaDeCada(aleatorio)) {
          for (final confusa in ['I', 'L', 'O', 'U']) {
            expect(sala.codigo.contains(confusa), isFalse,
                reason: sala.codigo);
          }
        }
      }
    });

    test('perdona cómo lo copie la gente', () {
      final sala = Sala.nueva(
        modalidad: ModalidadPartida.personalizada,
        pasos: 8,
        random: Random(3),
      );
      final codigo = sala.codigo;

      for (final variante in [
        codigo.toLowerCase(),
        '  $codigo  ',
        codigo.split('').join('-'),
        '${codigo.substring(0, 4)} ${codigo.substring(4)}',
        codigo.replaceAll('0', 'O'),
        codigo.replaceAll('1', 'I'),
        codigo.replaceAll('1', 'l'),
      ]) {
        expect(Sala.desdeCodigo(variante), sala, reason: variante);
      }
    });

    test('un código inventado no cuela', () {
      for (final malo in [
        '',
        'ABC',
        'ABCDEFGHJ',
        '@@@@@@@@',
        '00000000', // pista de 0 pasos
        '0Z000000', // pista de 31 pasos
        'Z6000000', // modo que no existe
        '06100000', // partida rápida con un extra que no le toca
        '36100000', // campeonato de 1 ronda: por debajo del mínimo
        '36Z00000', // campeonato de 31 rondas: por encima del máximo
      ]) {
        expect(Sala.desdeCodigo(malo), isNull, reason: '"$malo"');
      }
    });
  });

  group('Misma sala, misma partida', () {
    test('dos dispositivos con el mismo código ven lo mismo', () {
      final aleatorio = Random(11);
      for (var i = 0; i < 10; i++) {
        for (final anfitrion in _unaDeCada(aleatorio)) {
          // El amigo solo recibe el código, no el objeto.
          final invitado = Sala.desdeCodigo(anfitrion.codigo)!;
          expect(_cronica(invitado), _cronica(anfitrion));
        }
      }
    });

    test('en el 1 contra 1 solo corren los dos palos de la sala', () {
      final sala = Sala.nueva(
        modalidad: ModalidadPartida.unoContraUno,
        palos: const [Palo.bastos, Palo.oros],
        random: Random(8),
      );
      final invitado = Sala.desdeCodigo(sala.codigo)!;

      expect(invitado.palosEnCarrera, [Palo.bastos, Palo.oros]);
      final juego = LogicaJuego(
        pasos: invitado.pasos,
        palos: invitado.palosEnCarrera,
        random: invitado.generador(),
      );
      expect(juego.caballos.keys.toSet(), {Palo.bastos, Palo.oros});
    });

    test('cada ronda del campeonato es distinta, pero igual para todos', () {
      final sala = Sala.nueva(
        modalidad: ModalidadPartida.campeonato,
        rondas: 4,
        random: Random(21),
      );
      final invitado = Sala.desdeCodigo(sala.codigo)!;

      final cronicas = <String>{};
      for (var ronda = 0; ronda < sala.rondas; ronda++) {
        // Al anfitrión y al invitado les sale la misma ronda...
        expect(_cronica(invitado, ronda: ronda), _cronica(sala, ronda: ronda));
        cronicas.add(_cronica(sala, ronda: ronda));
      }
      // ...y las cuatro rondas son carreras distintas entre sí.
      expect(cronicas, hasLength(sala.rondas));
    });

    test('salas distintas dan carreras distintas', () {
      final aleatorio = Random(5);
      final vistas = <String>{};
      for (var i = 0; i < 40; i++) {
        vistas.add(_cronica(Sala.nueva(random: aleatorio)));
      }
      expect(vistas.length, greaterThan(35));
    });
  });

  group('Enlace', () {
    test('cuelga el código de la dirección de la web', () {
      final sala = Sala.nueva(
        modalidad: ModalidadPartida.personalizada,
        pasos: 7,
        random: Random(2),
      );
      final enlace = sala.enlaceDesde(
        Uri.parse('https://danielgrs18.github.io/CarreraDeCaballos/'),
      );

      expect(enlace.queryParameters['sala'], sala.codigo);
      expect(enlace.path, '/CarreraDeCaballos/');
      expect(Sala.desdeCodigo(enlace.queryParameters['sala']!), sala);
    });

    test('sustituye la sala anterior en vez de encadenarlas', () {
      final primera = Sala.nueva(random: Random(1));
      final segunda = Sala.nueva(random: Random(2));
      final base = Uri.parse('https://ejemplo.test/juego/');

      final enlace = segunda.enlaceDesde(primera.enlaceDesde(base));

      expect(enlace.queryParameters['sala'], segunda.codigo);
      expect(enlace.queryParametersAll['sala'], hasLength(1));
    });
  });
}
