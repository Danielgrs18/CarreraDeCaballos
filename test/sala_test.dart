import 'dart:math';

import 'package:carrera_caballos/game/ajustes_partida.dart';
import 'package:carrera_caballos/game/logica_juego.dart';
import 'package:carrera_caballos/game/sala.dart';
import 'package:flutter_test/flutter_test.dart';

/// La crónica completa de una carrera: si dos coinciden, los dos jugadores
/// han visto exactamente lo mismo.
String _cronica(Sala sala) {
  final juego = LogicaJuego(pasos: sala.pasos, random: sala.generador);
  final turnos = <String>[];
  var t = 0;
  while (!juego.agotada && t++ < 5000) {
    final r = juego.jugarTurno();
    turnos.add('${r.carta}|${r.avanza}|${r.llegada}|${r.mazoReciclado}');
  }
  return '${juego.clasificacion}::${turnos.join(';')}';
}

void main() {
  group('Código de sala', () {
    test('el código son seis caracteres y vuelve a la misma sala', () {
      final aleatorio = Random(1);
      for (var i = 0; i < 200; i++) {
        final sala = Sala.nueva(
          pasos: LongitudPista.minimo +
              aleatorio.nextInt(
                LongitudPista.maximo - LongitudPista.minimo + 1,
              ),
          random: aleatorio,
        );

        expect(sala.codigo, hasLength(Sala.largoCodigo));
        expect(sala.codigo, matches(RegExp(r'^[0-9A-Z]+$')));
        expect(Sala.desdeCodigo(sala.codigo), sala);
      }
    });

    test('no usa letras que se confunden al dictarlas', () {
      final aleatorio = Random(7);
      for (var i = 0; i < 300; i++) {
        final codigo = Sala.nueva(random: aleatorio).codigo;
        for (final confusa in ['I', 'L', 'O', 'U']) {
          expect(codigo.contains(confusa), isFalse, reason: codigo);
        }
      }
    });

    test('perdona cómo lo copie la gente', () {
      final sala = Sala.nueva(pasos: 8, random: Random(3));
      final codigo = sala.codigo;

      for (final variante in [
        codigo.toLowerCase(),
        '  $codigo  ',
        codigo.split('').join('-'),
        '${codigo.substring(0, 3)} ${codigo.substring(3)}',
      ]) {
        expect(Sala.desdeCodigo(variante), sala, reason: variante);
      }
    });

    test('la I y la L valen por 1, y la O por 0', () {
      final sala = Sala(pasos: 6, semilla: 1);
      // El código de esta sala acaba en ceros y un uno.
      expect(Sala.desdeCodigo(sala.codigo), sala);
      expect(
        Sala.desdeCodigo(sala.codigo.replaceAll('0', 'O')),
        sala,
      );
      expect(
        Sala.desdeCodigo(sala.codigo.replaceAll('1', 'I')),
        sala,
      );
      expect(
        Sala.desdeCodigo(sala.codigo.replaceAll('1', 'l')),
        sala,
      );
    });

    test('un código inventado no cuela', () {
      for (final malo in [
        '',
        'ABC',
        'ABCDEFGH',
        '@@@@@@',
        '000000', // pista de 0 pasos: fuera de lo admitido
        '100000', // pista de 1 paso: también
        'Z00000', // pista de 31 pasos: pasa del máximo
      ]) {
        expect(Sala.desdeCodigo(malo), isNull, reason: '"$malo"');
      }
    });

    test('la pista se conserva entera en el código', () {
      for (var pasos = LongitudPista.minimo;
          pasos <= LongitudPista.maximo;
          pasos++) {
        final sala = Sala.nueva(pasos: pasos, random: Random(pasos));
        expect(Sala.desdeCodigo(sala.codigo)!.pasos, pasos);
      }
    });
  });

  group('Misma sala, misma carrera', () {
    test('dos dispositivos con el mismo código ven lo mismo', () {
      final aleatorio = Random(11);
      for (var i = 0; i < 25; i++) {
        final anfitrion = Sala.nueva(random: aleatorio);
        // El amigo solo recibe el código, no el objeto.
        final invitado = Sala.desdeCodigo(anfitrion.codigo)!;

        expect(_cronica(invitado), _cronica(anfitrion));
      }
    });

    test('salas distintas dan carreras distintas', () {
      final aleatorio = Random(5);
      final vistas = <String>{};
      for (var i = 0; i < 40; i++) {
        vistas.add(_cronica(Sala.nueva(pasos: 6, random: aleatorio)));
      }
      // Alguna coincidencia suelta cabe, pero no que se repitan todas.
      expect(vistas.length, greaterThan(35));
    });

    test('volver a jugar la misma sala repite la carrera', () {
      final sala = Sala.nueva(random: Random(99));
      expect(_cronica(sala), _cronica(sala));
    });
  });

  group('Enlace', () {
    test('cuelga el código de la dirección de la web', () {
      final sala = Sala.nueva(pasos: 7, random: Random(2));
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
