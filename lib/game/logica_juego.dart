import 'dart:math';

import '../models/baraja.dart';
import '../models/caballo.dart';
import '../models/carta.dart';

/// Una carta de paso que se acaba de levantar.
class Revelacion {
  /// Número de paso (1..pasos) en el que estaba la carta.
  final int paso;
  final Carta carta;

  const Revelacion({required this.paso, required this.carta});

  /// Palo que retrocede por culpa de esta carta.
  Palo get palo => carta.palo;
}

/// Lo que ha ocurrido al destapar una carta, para que la interfaz sepa
/// qué animar y qué mensaje enseñar.
class ResultadoTurno {
  final Carta carta;

  /// Palo que ha avanzado con esta carta.
  final Palo avanza;

  /// Cartas de paso levantadas en este turno (normalmente 0 o 1).
  final List<Revelacion> revelaciones;

  /// El mazo se había agotado y se ha vuelto a formar con los descartes.
  final bool mazoReciclado;

  /// Palo ganador, si la carrera ha terminado en este turno.
  final Palo? ganador;

  const ResultadoTurno({
    required this.carta,
    required this.avanza,
    this.revelaciones = const [],
    this.mazoReciclado = false,
    this.ganador,
  });
}

/// Reglas de la carrera de caballos con baraja española.
///
/// Preparación:
///  - Se sacan los 4 caballos (el 11 de cada palo): son los corredores.
///  - De las 36 cartas restantes, ya barajadas, se ponen [pasos] boca abajo
///    formando la pista. El resto es el mazo de robo.
///
/// Turno:
///  - Se destapa una carta y avanza el caballo de ese palo.
///  - En cuanto los 4 caballos han dejado atrás un paso, su carta se levanta
///    y el caballo de ese palo retrocede una casilla.
///  - Gana el primero que cruza la meta, que está un paso más allá de la
///    última carta de la pista.
class LogicaJuego {
  /// Cartas boca abajo que forman la pista.
  final int pasos;

  final Map<Palo, Caballo> caballos;

  /// Las cartas de la pista, de la primera a la última. Se levantan siempre
  /// en orden, así que [pasosLevantados] basta para saber cuáles se ven.
  final List<Carta> cartasPista;

  final Random _random;

  List<Carta> _mazo;
  List<Carta> _descartes;
  int _pasosLevantados = 0;

  LogicaJuego._({
    required this.pasos,
    required this.caballos,
    required this.cartasPista,
    required List<Carta> mazo,
    required Random random,
  })  : _mazo = mazo,
        _descartes = [],
        _random = random;

  /// Con los 4 palos por defecto corren los 4 caballos (Partida rápida);
  /// pasando menos —siempre 2 o más— se juegan carreras reducidas, como el
  /// 1 contra 1.
  factory LogicaJuego({
    int pasos = 6,
    List<Palo> palos = Palo.values,
    Random? random,
  }) {
    assert(pasos >= 1 && pasos <= 20, 'La pista debe tener entre 1 y 20 pasos');
    assert(palos.length >= 2, 'Hacen falta al menos 2 caballos para competir');
    assert(palos.toSet().length == palos.length, 'Los palos no pueden repetirse');
    final rnd = random ?? Random();

    final mazo = Baraja.completa(palos: palos);

    // 1. Los caballos salen de la baraja y se ponen en la línea de salida.
    mazo.removeWhere((c) => c.esCaballo);
    final corredores = {
      for (final palo in palos) palo: Caballo(palo),
    };

    // 2. Se baraja el resto y se tiende la pista boca abajo.
    Baraja.barajar(mazo, rnd);
    final pista = mazo.take(pasos).toList();
    mazo.removeRange(0, pasos);

    // 3. Lo que queda es el mazo de robo.
    return LogicaJuego._(
      pasos: pasos,
      caballos: corredores,
      cartasPista: pista,
      mazo: mazo,
      random: rnd,
    );
  }

  /// Posición que hay que alcanzar para ganar: un paso más allá de la pista.
  int get meta => pasos + 1;

  /// Casillas dibujables de la pista (la última no lleva carta de paso).
  int get casillas => pasos + 1;

  int get cartasEnMazo => _mazo.length;
  int get cartasDescartadas => _descartes.length;

  /// Cuántas cartas de la pista están ya boca arriba.
  int get pasosLevantados => _pasosLevantados;

  /// Si la carta del paso [indice] (0..pasos-1) ya se ha descubierto.
  bool cartaLevantada(int indice) => indice < _pasosLevantados;

  /// Última carta destapada del mazo, o `null` si aún no se ha jugado.
  Carta? get ultimaCarta => _descartes.isEmpty ? null : _descartes.last;

  Palo? get ganador {
    for (final c in caballos.values) {
      if (c.haLlegado(meta)) return c.palo;
    }
    return null;
  }

  bool get terminada => ganador != null;

  /// El paso más avanzado que han dejado atrás los 4 caballos.
  int get pasoComunSuperado =>
      caballos.values.map((c) => c.posicion).reduce(min);

  /// Destapa la siguiente carta y aplica sus efectos.
  ResultadoTurno jugarTurno() {
    assert(!terminada, 'La carrera ya ha terminado');

    var reciclado = false;
    if (_mazo.isEmpty) {
      _reciclarDescartes();
      reciclado = true;
    }

    final carta = _mazo.removeLast();
    _descartes.add(carta);

    caballos[carta.palo]!.avanzar();

    // Cruzar la meta termina la carrera al instante: no se levantan más cartas.
    final ganadorTurno = ganador;
    if (ganadorTurno != null) {
      return ResultadoTurno(
        carta: carta,
        avanza: carta.palo,
        mazoReciclado: reciclado,
        ganador: ganadorTurno,
      );
    }

    return ResultadoTurno(
      carta: carta,
      avanza: carta.palo,
      revelaciones: _levantarPasosSuperados(),
      mazoReciclado: reciclado,
    );
  }

  /// Levanta todas las cartas de paso que los 4 caballos hayan dejado atrás.
  /// Cada una hace retroceder a su palo, lo que puede impedir que se levante
  /// la siguiente.
  List<Revelacion> _levantarPasosSuperados() {
    final reveladas = <Revelacion>[];

    while (_pasosLevantados < pasos &&
        pasoComunSuperado >= _pasosLevantados + 1) {
      final carta = cartasPista[_pasosLevantados];
      _pasosLevantados++;
      caballos[carta.palo]!.retroceder();
      reveladas.add(Revelacion(paso: _pasosLevantados, carta: carta));
    }

    return reveladas;
  }

  /// El mazo se ha agotado: los descartes se rebarajan y vuelven a la mesa.
  void _reciclarDescartes() {
    assert(_descartes.isNotEmpty, 'No quedan cartas que reciclar');
    _mazo = List.of(_descartes);
    Baraja.barajar(_mazo, _random);
    _descartes = [];
  }
}
