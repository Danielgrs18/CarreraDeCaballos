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

  /// Palo que ha avanzado con esta carta, o `null` si su caballo ya había
  /// cruzado la meta y la carta no ha hecho nada.
  final Palo? avanza;

  /// Palo que acaba de cruzar la meta en este turno, en el puesto que sea.
  final Palo? llegada;

  /// Cartas de paso levantadas en este turno (normalmente 0 o 1).
  final List<Revelacion> revelaciones;

  /// El mazo se había agotado y se ha vuelto a formar con los descartes.
  final bool mazoReciclado;

  /// Palo ganador, solo en el turno en que se decide el primer puesto.
  final Palo? ganador;

  /// Ya no queda nadie que pueda seguir avanzando.
  final bool agotada;

  const ResultadoTurno({
    required this.carta,
    this.avanza,
    this.llegada,
    this.revelaciones = const [],
    this.mazoReciclado = false,
    this.ganador,
    this.agotada = false,
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
  final List<Palo> _clasificacion = [];

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

  /// Orden de llegada a meta, del primero al último. La carrera puede
  /// seguir después de que entre el primero: los demás van entrando aquí
  /// según cruzan.
  List<Palo> get clasificacion => List.unmodifiable(_clasificacion);

  bool haLlegado(Palo palo) => caballos[palo]!.haLlegado(meta);

  /// El primero en cruzar la meta.
  Palo? get ganador => _clasificacion.isEmpty ? null : _clasificacion.first;

  /// Ya hay ganador. La carrera puede seguir para repartir los demás
  /// puestos, pero el primero está decidido.
  bool get terminada => ganador != null;

  /// Un caballo solo puede seguir avanzando si le queda alguna de sus 9
  /// cartas viva. Las que se tienden en la pista no vuelven al mazo ni
  /// siquiera al levantarse, así que si las 9 de un palo acaban ahí, ese
  /// caballo se queda clavado para siempre y no llegará nunca.
  bool puedeAvanzar(Palo palo) =>
      _mazo.any((c) => c.palo == palo) ||
      _descartes.any((c) => c.palo == palo);

  /// Los que aún no han llegado y todavía podrían.
  List<Palo> get enCarrera => [
        for (final palo in caballos.keys)
          if (!haLlegado(palo) && puedeAvanzar(palo)) palo,
      ];

  /// Los que no llegaron ni podrán, por quedarse sin cartas.
  List<Palo> get descolgados => [
        for (final palo in caballos.keys)
          if (!haLlegado(palo) && !puedeAvanzar(palo)) palo,
      ];

  /// La carrera no da más de sí: o han llegado todos, o a los que faltan
  /// no les queda ninguna carta con la que avanzar.
  bool get agotada => enCarrera.isEmpty;

  /// El paso más avanzado que han dejado atrás todos los caballos.
  int get pasoComunSuperado =>
      caballos.values.map((c) => c.posicion).reduce(min);

  /// Destapa la siguiente carta y aplica sus efectos.
  ResultadoTurno jugarTurno() {
    assert(!agotada, 'La carrera ya no da más de sí');

    var reciclado = false;
    if (_mazo.isEmpty) {
      _reciclarDescartes();
      reciclado = true;
    }

    final carta = _mazo.removeLast();
    _descartes.add(carta);

    // Al que ya ha cruzado la meta su carta no le hace nada: se queda ahí.
    Palo? avanza;
    Palo? llegada;
    if (!haLlegado(carta.palo)) {
      avanza = carta.palo;
      caballos[carta.palo]!.avanzar();
      if (haLlegado(carta.palo)) {
        _clasificacion.add(carta.palo);
        llegada = carta.palo;
      }
    }

    return ResultadoTurno(
      carta: carta,
      avanza: avanza,
      llegada: llegada,
      ganador: _clasificacion.length == 1 ? llegada : null,
      revelaciones: _levantarPasosSuperados(),
      mazoReciclado: reciclado,
      agotada: agotada,
    );
  }

  /// Levanta todas las cartas de paso que hayan dejado atrás todos los
  /// caballos. Cada una hace retroceder a su palo, lo que puede impedir
  /// que se levante la siguiente.
  List<Revelacion> _levantarPasosSuperados() {
    final reveladas = <Revelacion>[];

    while (_pasosLevantados < pasos &&
        pasoComunSuperado >= _pasosLevantados + 1) {
      final carta = cartasPista[_pasosLevantados];
      _pasosLevantados++;
      // A quien ya ha cruzado la meta no se le hace retroceder: su carrera
      // terminó y su puesto está dado.
      if (!haLlegado(carta.palo)) {
        caballos[carta.palo]!.retroceder();
      }
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
