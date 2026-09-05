import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/carta.dart';
import '../theme/app_theme.dart';
import 'carta_espanola.dart';

/// El mazo de robo y la última carta destapada, uno junto al otro.
class MazoWidget extends StatelessWidget {
  final Carta? ultimaCarta;
  final int cartasRestantes;

  /// Número de turno jugado: sirve de clave para reanimar el volteo aunque
  /// vuelva a salir la misma carta.
  final int turno;

  /// En modo manual se toca el mazo para destapar.
  final VoidCallback? onSacar;

  /// Anima el mazo para invitar a tocarlo.
  final bool invitaATocar;

  final double anchoCarta;

  const MazoWidget({
    super.key,
    required this.ultimaCarta,
    required this.cartasRestantes,
    required this.anchoCarta,
    required this.turno,
    this.onSacar,
    this.invitaATocar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ColumnaRotulada(
              rotulo: 'MAZO',
              child: _Mazo(
                ancho: anchoCarta,
                restantes: cartasRestantes,
                onSacar: onSacar,
                invitaATocar: invitaATocar,
              ),
            ),
            const SizedBox(width: 10),
            _ColumnaRotulada(
              rotulo: 'SALE',
              child: _Descarte(
                carta: ultimaCarta,
                ancho: anchoCarta,
                turno: turno,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColumnaRotulada extends StatelessWidget {
  final String rotulo;
  final Widget child;

  const _ColumnaRotulada({required this.rotulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            fontFamily: AppTheme.familiaTitulo,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.6,
            color: AppColors.oroClaro.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _Mazo extends StatelessWidget {
  final double ancho;
  final int restantes;
  final VoidCallback? onSacar;
  final bool invitaATocar;

  const _Mazo({
    required this.ancho,
    required this.restantes,
    required this.onSacar,
    required this.invitaATocar,
  });

  @override
  Widget build(BuildContext context) {
    // Un par de cartas asomando por detrás para que parezca un montón.
    final capas = restantes.clamp(0, 3);

    final monton = SizedBox(
      width: ancho + 6,
      height: altoCarta(ancho) + 6,
      child: Stack(
        children: [
          for (var i = capas; i > 0; i--)
            Positioned(
              left: i * 2.0,
              top: i * 2.0,
              child: Opacity(
                opacity: 0.55,
                child: DorsoCarta(ancho: ancho),
              ),
            ),
          if (restantes > 0)
            DorsoCarta(ancho: ancho)
          else
            _HuecoMazo(ancho: ancho),
        ],
      ),
    );

    return Semantics(
      button: onSacar != null,
      label: 'Sacar carta del mazo',
      child: GestureDetector(
        onTap: onSacar,
        behavior: HitTestBehavior.opaque,
        child: invitaATocar
            ? RepaintBoundary(child: _Latido(child: monton))
            : monton,
      ),
    );
  }
}

/// El mazo vacío justo antes de rebarajar los descartes.
class _HuecoMazo extends StatelessWidget {
  final double ancho;

  const _HuecoMazo({required this.ancho});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: altoCarta(ancho),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ancho * 0.075),
        border: Border.all(
          color: AppColors.oro.withValues(alpha: 0.5),
          width: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.refresh_rounded,
        color: AppColors.oro.withValues(alpha: 0.7),
        size: ancho * 0.4,
      ),
    );
  }
}

/// Late suavemente para señalar que hay que tocar el mazo.
class _Latido extends StatefulWidget {
  final Widget child;

  const _Latido({required this.child});

  @override
  State<_Latido> createState() => _LatidoState();
}

class _LatidoState extends State<_Latido>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.045).animate(
        CurvedAnimation(parent: _control, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// La última carta destapada, que entra girando como si se volteara.
class _Descarte extends StatelessWidget {
  final Carta? carta;
  final double ancho;
  final int turno;

  const _Descarte({
    required this.carta,
    required this.ancho,
    required this.turno,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho + 6,
      height: altoCarta(ancho) + 6,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: const Threshold(0),
        transitionBuilder: (child, animacion) {
          return AnimatedBuilder(
            animation: animacion,
            child: child,
            builder: (context, hijo) {
              final angulo = (1 - animacion.value) * math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(angulo),
                child: Opacity(opacity: animacion.value, child: hijo),
              );
            },
          );
        },
        child: carta == null
            ? _Vacio(ancho: ancho)
            : CartaEspanola(
                key: ValueKey(turno),
                carta: carta!,
                ancho: ancho,
              ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final double ancho;

  const _Vacio({required this.ancho});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: altoCarta(ancho),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ancho * 0.075),
        border: Border.all(
          color: AppColors.oro.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
    );
  }
}
