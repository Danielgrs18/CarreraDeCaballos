import 'package:flutter/material.dart';

import '../models/carta.dart';
import '../theme/app_theme.dart';
import 'paint/palos.dart';

/// Elige un palo entre [opciones], con el color y el emblema de cada uno
/// para que se distingan de un vistazo. Se usa para asignar los caballos en
/// el modo 1 contra 1.
class SelectorPalo extends StatelessWidget {
  final List<Palo> opciones;
  final Palo seleccionado;
  final ValueChanged<Palo> onCambio;

  const SelectorPalo({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final palo in opciones)
          _ChipPalo(
            palo: palo,
            activo: palo == seleccionado,
            onTap: () => onCambio(palo),
          ),
      ],
    );
  }
}

class _ChipPalo extends StatelessWidget {
  final Palo palo;
  final bool activo;
  final VoidCallback onTap;

  const _ChipPalo({
    required this.palo,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.dePalo(palo);

    return Semantics(
      button: true,
      selected: activo,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: activo ? color.withValues(alpha: 0.85) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color, width: activo ? 1.6 : 1.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmblemaPalo(palo: palo, tamano: 16),
              const SizedBox(width: 6),
              Text(
                palo.nombre,
                style: TextStyle(
                  fontFamily: AppTheme.familiaTitulo,
                  fontSize: 13.5,
                  fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                  color: activo ? AppColors.oroClaro : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
