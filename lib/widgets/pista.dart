import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/logica_juego.dart';
import '../models/carta.dart';
import '../theme/app_theme.dart';
import 'carta_espanola.dart';
import 'paint/palos.dart';

/// El tablero de la carrera: la hilera de cartas de paso y los cuatro
/// carriles con su caballo.
class PistaWidget extends StatelessWidget {
  final LogicaJuego logica;
  final Duration duracionAnimacion;

  /// Palo que acaba de avanzar, para darle un destello.
  final Palo? destacado;

  /// Reserva una columna a la derecha de la meta con el puesto en el que
  /// va entrando cada caballo. Solo tiene sentido cuando la carrera va a
  /// seguir después del primero: si no, sobraría un hueco para un único
  /// número que aparece justo cuando ya se ha acabado todo.
  final bool mostrarPuestos;

  const PistaWidget({
    super.key,
    required this.logica,
    required this.duracionAnimacion,
    this.destacado,
    this.mostrarPuestos = false,
  });

  static const double _anchoPuerta = 46;
  static const double _anchoMeta = 20;
  static const double _anchoPuesto = 34;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final alto = restricciones.maxHeight;
        final celdas = logica.casillas;
        final anchoPuestos = mostrarPuestos ? _anchoPuesto : 0.0;
        final anchoCelda =
            ((ancho - _anchoPuerta - _anchoMeta - anchoPuestos) / celdas)
                .clamp(18.0, 140.0);

        // Puede haber menos de 4 caballos (el 1 contra 1 solo trae 2): se
        // reparten los carriles según los que compitan de verdad, siempre en
        // el orden canónico de los palos.
        final corredores =
            Palo.values.where(logica.caballos.containsKey).toList();

        // La hilera de cartas de paso se lleva algo menos de un tercio del
        // alto; el resto se reparte entre los carriles.
        final altoTrampas = (alto * 0.27).clamp(44.0, 104.0);
        final disponibleCarriles = alto - altoTrampas - 6;
        final n = corredores.length;
        final altoCarril = (disponibleCarriles / n).clamp(28.0, 92.0);

        // Con menos de 4 caballos (el 1 contra 1 trae solo 2) sobra alto:
        // en vez de dejarlo todo apelmazado arriba, una parte se convierte
        // en un hueco entre carriles —no mucho— y el resto centra el bloque.
        final sobrante = math.max(0.0, disponibleCarriles - n * altoCarril);
        final separacion =
            n > 1 ? math.min(sobrante / (n - 1), 16.0) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: altoTrampas,
              child: _HileraPasos(
                logica: logica,
                anchoPuerta: _anchoPuerta,
                anchoCelda: anchoCelda,
                alto: altoTrampas,
                anchoPuestos: anchoPuestos > 0 ? _anchoMeta + anchoPuestos : 0,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < corredores.length; i++) ...[
                    if (i > 0) SizedBox(height: separacion),
                    SizedBox(
                      height: altoCarril,
                      child: _Carril(
                        palo: corredores[i],
                        posicion: logica.caballos[corredores[i]]!.posicion,
                        celdas: celdas,
                        anchoPuerta: _anchoPuerta,
                        anchoMeta: _anchoMeta,
                        anchoCelda: anchoCelda,
                        anchoPuesto: anchoPuestos,
                        alto: altoCarril,
                        duracion: duracionAnimacion,
                        destacado: destacado == corredores[i],
                        puesto: _puestoDe(corredores[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// En qué puesto entró este caballo, contando desde 1, o `null` si aún
  /// no ha cruzado la meta.
  int? _puestoDe(Palo palo) {
    final puesto = logica.clasificacion.indexOf(palo);
    return puesto < 0 ? null : puesto + 1;
  }
}

/// Las cartas boca abajo que marcan cada paso. Al descubrirse se giran y
/// quedan atenuadas.
class _HileraPasos extends StatelessWidget {
  final LogicaJuego logica;
  final double anchoPuerta;
  final double anchoCelda;
  final double alto;

  /// Ancho del hueco que queda a la derecha para los puestos, 0 si no se
  /// están mostrando.
  final double anchoPuestos;

  const _HileraPasos({
    required this.logica,
    required this.anchoPuerta,
    required this.anchoCelda,
    required this.alto,
    required this.anchoPuestos,
  });

  @override
  Widget build(BuildContext context) {
    // La carta cabe por alto o por ancho, lo que resulte más restrictivo.
    // Nada de clamp: en pantallas estrechas el tope inferior superaría al
    // superior y reventaría.
    final anchoCarta = math.min(alto * kProporcionCarta, anchoCelda * 0.82);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: anchoPuerta,
          child: const _RotuloVertical(texto: 'PASOS'),
        ),
        for (var i = 0; i < logica.casillas; i++)
          SizedBox(
            width: anchoCelda,
            child: Center(
              child: i < logica.pasos
                  ? _CartaPaso(
                      carta: logica.cartaLevantada(i)
                          ? logica.cartasPista[i]
                          : null,
                      ancho: anchoCarta,
                    )
                  : _BanderinMeta(alto: anchoCarta * 0.9),
            ),
          ),
        if (anchoPuestos > 0)
          SizedBox(
            width: anchoPuestos,
            child: const _RotuloVertical(texto: 'PUESTO'),
          ),
      ],
    );
  }
}

class _CartaPaso extends StatelessWidget {
  /// La carta ya descubierta, o `null` mientras sigue boca abajo.
  final Carta? carta;
  final double ancho;

  const _CartaPaso({required this.carta, required this.ancho});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animacion) => ScaleTransition(
        scale: animacion,
        child: FadeTransition(opacity: animacion, child: child),
      ),
      child: carta == null
          ? DorsoCarta(key: const ValueKey('dorso'), ancho: ancho)
          : CartaEspanola(
              key: ValueKey(carta),
              carta: carta!,
              ancho: ancho,
              apagada: true,
            ),
    );
  }
}

class _BanderinMeta extends StatelessWidget {
  final double alto;

  const _BanderinMeta({required this.alto});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_rounded, color: AppColors.oro, size: alto * 0.42),
        const SizedBox(height: 2),
        const Text(
          'META',
          style: TextStyle(
            fontFamily: AppTheme.familiaTitulo,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: AppColors.oroClaro,
          ),
        ),
      ],
    );
  }
}

class _RotuloVertical extends StatelessWidget {
  final String texto;

  const _RotuloVertical({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: AppTheme.familiaTitulo,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
          color: AppColors.oroClaro.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

/// Un carril: cajón de salida, casillas, meta y el caballo que las recorre.
class _Carril extends StatelessWidget {
  final Palo palo;
  final int posicion;
  final int celdas;
  final double anchoPuerta;
  final double anchoMeta;
  final double anchoCelda;
  final double anchoPuesto;
  final double alto;
  final Duration duracion;
  final bool destacado;

  /// Puesto de llegada, contando desde 1, o `null` si sigue en carrera.
  final int? puesto;

  const _Carril({
    required this.palo,
    required this.posicion,
    required this.celdas,
    required this.anchoPuerta,
    required this.anchoMeta,
    required this.anchoCelda,
    required this.anchoPuesto,
    required this.alto,
    required this.duracion,
    required this.destacado,
    required this.puesto,
  });

  /// El centro horizontal que le toca a la ficha según su posición: en el
  /// cajón de salida, centrada ahí (para no tapar el emblema del palo); en
  /// marcha, en el hueco central de la casilla que ocupa —no en la línea
  /// que separa una casilla de la siguiente, que es donde quedaba antes.
  ///
  /// Antes de la salida (posición 0) se apoya justo a la entrada de la
  /// pista, tocando el cajón pero sin invadirlo nunca: si se centrase
  /// dentro del cajón taparía por completo el emblema, que también está
  /// centrado ahí.
  double _centroFicha(double anchoFicha) {
    if (posicion <= 0) return anchoPuerta + anchoFicha / 2;
    final indiceCasilla = (posicion - 1).clamp(0, celdas - 1);
    return anchoPuerta + indiceCasilla * anchoCelda + anchoCelda / 2;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.dePalo(palo);
    final anchoFicha = ((alto - 8) * kProporcionCarta).clamp(16.0, 64.0);
    final izquierda = _centroFicha(anchoFicha) - anchoFicha / 2;
    final anchoTotal = anchoPuerta + celdas * anchoCelda + anchoMeta;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _puerta(color),
              for (var i = 0; i < celdas; i++) _casilla(i),
              _meta(),
              if (anchoPuesto > 0) _distintivoPuesto(),
            ],
          ),
          AnimatedPositioned(
            duration: duracion,
            curve: Curves.easeOutCubic,
            left: izquierda.clamp(1.0, anchoTotal - anchoFicha - 1),
            top: 3,
            child: _Ficha(
              palo: palo,
              ancho: anchoFicha,
              destacado: destacado,
            ),
          ),
        ],
      ),
    );
  }

  Widget _puerta(Color color) {
    return Container(
      width: anchoPuerta,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.32),
        border: Border.all(color: color, width: 1.2),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
      ),
      alignment: Alignment.center,
      child: EmblemaPalo(palo: palo, tamano: (alto * 0.5).clamp(14.0, 30.0)),
    );
  }

  Widget _casilla(int indice) {
    return Container(
      width: anchoCelda,
      decoration: BoxDecoration(
        color: indice.isEven
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.08),
        border: Border(
          right: BorderSide(
            color: AppColors.oro.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _meta() {
    return SizedBox(
      width: anchoMeta,
      child: CustomPaint(painter: const _CuadrosMeta()),
    );
  }

  /// La chapa con el puesto, que entra con un rebote en cuanto el caballo
  /// cruza. Mientras corre, el hueco se queda reservado y vacío para que
  /// los carriles no cambien de ancho al ir llegando unos y otros.
  Widget _distintivoPuesto() {
    final ganador = puesto == 1;

    return SizedBox(
      width: anchoPuesto,
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutBack,
          scale: puesto == null ? 0 : 1,
          // Sin puesto no se monta la chapa: encogerla bastar\u00eda para no
          // verla, pero su n\u00famero seguir\u00eda ah\u00ed para quien lea la pantalla
          // en voz alta o rastree la interfaz.
          child: puesto == null
              ? const SizedBox.shrink()
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ganador
                        ? AppColors.oro
                        : Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: ganador
                          ? AppColors.oroClaro
                          : AppColors.oro.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    '$puesto\u00ba',
                    style: TextStyle(
                      fontFamily: AppTheme.familiaTitulo,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color:
                          ganador ? AppColors.tapeteOscuro : AppColors.oroClaro,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// El caballo de cada palo, que es literalmente la carta del 11.
class _Ficha extends StatelessWidget {
  final Palo palo;
  final double ancho;
  final bool destacado;

  const _Ficha({
    required this.palo,
    required this.ancho,
    required this.destacado,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: destacado ? 1.09 : 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ancho * 0.075),
          boxShadow: [
            BoxShadow(
              color: destacado
                  ? AppColors.oroClaro.withValues(alpha: 0.75)
                  : Colors.black.withValues(alpha: 0.55),
              blurRadius: destacado ? 12 : 5,
              spreadRadius: destacado ? 1 : 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CartaEspanola(
          carta: Carta(palo, Valores.caballo),
          ancho: ancho,
        ),
      ),
    );
  }
}

class _CuadrosMeta extends CustomPainter {
  const _CuadrosMeta();

  @override
  void paint(Canvas canvas, Size size) {
    const columnas = 2;
    final filas = (size.height / (size.width / columnas)).round().clamp(2, 12);
    final ancho = size.width / columnas;
    final alto = size.height / filas;

    for (var f = 0; f < filas; f++) {
      for (var c = 0; c < columnas; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * ancho, f * alto, ancho, alto),
          Paint()
            ..color = (f + c).isEven
                ? const Color(0xFFF2F2F2)
                : const Color(0xFF1A1A1A),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CuadrosMeta oldDelegate) => false;
}
