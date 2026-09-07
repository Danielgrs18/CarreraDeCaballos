import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/carta.dart';
import '../theme/app_theme.dart';
import 'cartel_flotante.dart';
import 'cartel_ganador.dart';
import 'paint/palos.dart';

/// Una línea de la clasificación: qué palo, quién lo llevaba y —si el modo
/// lleva marcador— cuántos puntos suma.
class PuestoClasificacion {
  final Palo palo;

  /// Jugadores que iban a este palo. Vacío fuera de los modos con nombres.
  final List<String> nombres;

  /// `false` si el caballo no cruzó la meta: se quedó sin cartas vivas y
  /// la carrera se cortó sin él.
  final bool llegado;

  /// Marcador, en los modos que puntúan.
  final int? puntos;

  /// Nota corta a la derecha del palo, del estilo de "+3 en esta ronda".
  final String? detalle;

  const PuestoClasificacion({
    required this.palo,
    this.nombres = const [],
    this.llegado = true,
    this.puntos,
    this.detalle,
  });
}

/// Cartel con el orden de llegada —o el marcador del campeonato— y los
/// botones que toquen en cada momento.
class CartelClasificacion extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<PuestoClasificacion> puestos;
  final List<Widget> acciones;

  const CartelClasificacion({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.puestos,
    required this.acciones,
  });

  @override
  Widget build(BuildContext context) {
    final primero = puestos.isEmpty ? null : puestos.first.palo;

    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final tipoTitulo =
            math.min(restricciones.maxHeight * 0.11, ancho * 0.06)
                .clamp(19.0, 34.0);

        return CartelFlotante(
          resplandor: primero == null ? null : AppColors.dePalo(primero),
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.max(ancho * 0.66, 300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  titulo.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTheme.tituloDisplay.copyWith(
                    fontSize: tipoTitulo,
                    letterSpacing: tipoTitulo * 0.08,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 3),
                  Center(
                    child: RotuloCartel(
                      subtitulo!,
                      tamano: 11.5,
                      mayusculas: false,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 150,
                    height: 1,
                    color: AppColors.oro.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < puestos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _Linea(puesto: puestos[i], orden: i + 1),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: acciones,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Linea extends StatelessWidget {
  final PuestoClasificacion puesto;

  /// Posición en la lista, contando desde 1.
  final int orden;

  const _Linea({required this.puesto, required this.orden});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.dePalo(puesto.palo);
    // El azul de espadas y el marrón de bastos se pierden sobre el tapete:
    // el nombre se aclara, y el color puro se deja para el borde y las
    // chapas, donde sí destaca.
    final colorTexto = Color.lerp(color, AppColors.oroClaro, 0.45)!;
    // El primero va resaltado; quien no llegó, apagado.
    final destacado = orden == 1 && puesto.llegado;
    final opacidad = puesto.llegado ? 1.0 : 0.45;

    return Opacity(
      opacity: opacidad,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: destacado
              ? color.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: destacado
                ? AppColors.oro
                : AppColors.oro.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                // Sin llegar no hay puesto que dar.
                puesto.llegado ? '$ordenº' : '—',
                style: TextStyle(
                  fontFamily: AppTheme.familiaTitulo,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.oroClaro,
                ),
              ),
            ),
            EmblemaPalo(palo: puesto.palo, tamano: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    puesto.palo.nombre,
                    style: TextStyle(
                      fontFamily: AppTheme.familiaTitulo,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                  ),
                  if (puesto.nombres.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          for (final nombre in puesto.nombres)
                            ChapaNombre(nombre, color: color, tamano: 11),
                        ],
                      ),
                    ),
                  if (!puesto.llegado)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Se quedó sin cartas',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.oroClaro.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (puesto.detalle != null) ...[
              const SizedBox(width: 8),
              Text(
                puesto.detalle!,
                style: TextStyle(
                  fontFamily: AppTheme.familiaTitulo,
                  fontSize: 11.5,
                  color: AppColors.oroClaro.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (puesto.puntos != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: Text(
                  '${puesto.puntos} pts',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontFamily: AppTheme.familiaTitulo,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oroClaro,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
