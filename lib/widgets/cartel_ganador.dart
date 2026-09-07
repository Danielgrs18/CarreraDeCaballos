import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/carta.dart';
import '../theme/app_theme.dart';
import 'cartel_flotante.dart';
import 'paint/palos.dart';

/// Pantalla de victoria: el palo ganador en grande, su emblema y los
/// botones para seguir la carrera, repetirla o cerrar la partida.
class CartelGanador extends StatelessWidget {
  final Palo palo;
  final VoidCallback onFinalizar;

  /// Reinicia la partida sin salir de la mesa.
  final VoidCallback onRevancha;

  /// Sigue la carrera para repartir los demás puestos. Es `null` cuando ya
  /// no queda nadie que pueda avanzar y no hay nada que seguir.
  final VoidCallback? onContinuar;

  /// Nombres de los jugadores que iban a este palo. Solo hay en la partida
  /// personalizada, y puede quedar vacío si el palo que ganó no lo había
  /// elegido nadie.
  final List<String> ganadores;

  const CartelGanador({
    super.key,
    required this.palo,
    required this.onFinalizar,
    required this.onRevancha,
    this.onContinuar,
    this.ganadores = const [],
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.dePalo(palo);
    // Los verdes y azules del palo se pierden sobre el tapete: se aclaran.
    final colorTexto = Color.lerp(color, AppColors.oroClaro, 0.45)!;

    return LayoutBuilder(
      builder: (context, restricciones) {
        final alto = restricciones.maxHeight;
        final ancho = restricciones.maxWidth;
        final emblema = math.min(alto * 0.5, ancho * 0.26).clamp(72.0, 190.0);
        final tipoNombre = math.min(alto * 0.17, ancho * 0.1).clamp(26.0, 62.0);

        return CartelFlotante(
          resplandor: color,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmblemaPalo(palo: palo, tamano: emblema),
              const SizedBox(width: 26),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        palo.nombre.toUpperCase(),
                        maxLines: 1,
                        style: AppTheme.tituloDisplay.copyWith(
                          fontSize: tipoNombre,
                          letterSpacing: tipoNombre * 0.09,
                          color: AppColors.oroClaro,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'GANA',
                        maxLines: 1,
                        style: AppTheme.tituloDisplay.copyWith(
                          fontSize: tipoNombre * 0.72,
                          letterSpacing: tipoNombre * 0.16,
                          color: colorTexto,
                        ),
                      ),
                    ),
                    if (ganadores.isNotEmpty)
                      _Ganadores(
                        nombres: ganadores,
                        color: color,
                        anchoMaximo: ancho * 0.5,
                      ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      // Sin tope, la fila de botones estira el cartel de
                      // lado a lado; con él, el largo "hasta que lleguen
                      // todos" baja a su propia línea.
                      constraints: BoxConstraints(maxWidth: ancho * 0.52),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          if (onContinuar != null)
                            ElevatedButton.icon(
                              onPressed: onContinuar,
                              icon: const Icon(Icons.flag_rounded, size: 18),
                              label: const Text('Seguir hasta que lleguen todos'),
                            ),
                          // Con la carrera aún viva manda el botón de
                          // seguir; si ya no da más de sí, la revancha
                          // pasa a ser la acción principal.
                          if (onContinuar == null)
                            ElevatedButton(
                              onPressed: onRevancha,
                              child: const Text('Revancha'),
                            )
                          else
                            OutlinedButton(
                              onPressed: onRevancha,
                              child: const Text('Revancha'),
                            ),
                          OutlinedButton(
                            onPressed: onFinalizar,
                            child: const Text('Finalizar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Los jugadores que iban al palo ganador, en chapitas del color del palo.
class _Ganadores extends StatelessWidget {
  final List<String> nombres;
  final Color color;
  final double anchoMaximo;

  const _Ganadores({
    required this.nombres,
    required this.color,
    required this.anchoMaximo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: math.max(anchoMaximo, 140)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RotuloCartel(nombres.length == 1 ? 'Ganador' : 'Ganadores'),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final nombre in nombres) ChapaNombre(nombre, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// El nombre de un jugador en una chapita del color de su palo.
class ChapaNombre extends StatelessWidget {
  final String nombre;
  final Color color;
  final double tamano;

  const ChapaNombre(this.nombre, {super.key, required this.color, this.tamano = 13});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Text(
        nombre,
        style: TextStyle(
          fontFamily: AppTheme.familiaTitulo,
          fontSize: tamano,
          fontWeight: FontWeight.bold,
          color: AppColors.oroClaro,
        ),
      ),
    );
  }
}
