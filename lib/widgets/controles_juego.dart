import 'package:flutter/material.dart';

import '../game/ajustes_partida.dart';
import '../theme/app_theme.dart';

/// Barra superior de la partida: modo de juego, velocidad del automático y
/// cartas que quedan en el mazo.
class ControlesJuego extends StatelessWidget {
  final ModoJuego modo;
  final Velocidad velocidad;
  final bool habilitado;
  final int cartasEnMazo;
  final ValueChanged<ModoJuego> onModo;
  final ValueChanged<Velocidad> onVelocidad;
  final VoidCallback onSalir;

  /// Antes de dar la salida, el modo se elige en el propio velo de inicio;
  /// aquí solo se repetiría, así que la barra lo esconde hasta que arranca.
  final bool mostrarSelectorModo;

  const ControlesJuego({
    super.key,
    required this.modo,
    required this.velocidad,
    required this.habilitado,
    required this.cartasEnMazo,
    required this.onModo,
    required this.onVelocidad,
    required this.onSalir,
    this.mostrarSelectorModo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.tapeteOscuro.withValues(alpha: 0.55),
        border: const Border(
          bottom: BorderSide(color: AppColors.oro, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onSalir,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.oroClaro,
            tooltip: 'Salir de la partida',
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          if (mostrarSelectorModo)
            Flexible(
              flex: 20,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GrupoPildoras<ModoJuego>(
                      valores: ModoJuego.values,
                      seleccionado: modo,
                      habilitado: habilitado,
                      etiqueta: (m) => m.etiqueta,
                      onCambio: onModo,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: modo == ModoJuego.automatico
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 10),
                                GrupoPildoras<Velocidad>(
                                  valores: Velocidad.values,
                                  seleccionado: velocidad,
                                  habilitado: habilitado,
                                  etiqueta: (v) => v.etiqueta,
                                  onCambio: onVelocidad,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          _ContadorMazo(cartas: cartasEnMazo),
        ],
      ),
    );
  }
}

/// Grupo de botones excluyentes con aire de ficha de casino.
class GrupoPildoras<T> extends StatelessWidget {
  final List<T> valores;
  final T seleccionado;
  final bool habilitado;
  final String Function(T) etiqueta;
  final ValueChanged<T> onCambio;

  const GrupoPildoras({
    super.key,
    required this.valores,
    required this.seleccionado,
    required this.etiqueta,
    required this.onCambio,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.rojoOscuro.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.oro, width: 1.2),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final valor in valores)
            _Pildora(
              texto: etiqueta(valor),
              activa: valor == seleccionado,
              habilitada: habilitado,
              onTap: () => onCambio(valor),
            ),
        ],
      ),
    );
  }
}

class _Pildora extends StatelessWidget {
  final String texto;
  final bool activa;
  final bool habilitada;
  final VoidCallback onTap;

  const _Pildora({
    required this.texto,
    required this.activa,
    required this.habilitada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activa
        ? AppColors.oroClaro
        : AppColors.oroClaro.withValues(alpha: habilitada ? 0.6 : 0.28);

    return Semantics(
      button: true,
      selected: activa,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: habilitada ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            color: activa ? AppColors.rojo : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: activa ? AppColors.oro : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            texto,
            style: TextStyle(
              fontFamily: AppTheme.familiaTitulo,
              fontSize: 13.5,
              fontWeight: activa ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContadorMazo extends StatelessWidget {
  final int cartas;

  const _ContadorMazo({required this.cartas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_rounded, size: 17, color: AppColors.oro),
          const SizedBox(width: 5),
          Text(
            '$cartas',
            style: const TextStyle(
              fontFamily: AppTheme.familiaTitulo,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.oroClaro,
            ),
          ),
        ],
      ),
    );
  }
}
