import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// El velo oscuro con el recuadro dorado que se echa encima de la mesa al
/// acabar una carrera. Entra con un fundido y un rebote corto, y se puede
/// desplazar si el contenido no cabe —listas largas de jugadores en
/// pantallas bajas—.
class CartelFlotante extends StatefulWidget {
  final Widget child;

  /// Resplandor alrededor del recuadro, normalmente del color del palo que
  /// ha ganado.
  final Color? resplandor;

  final EdgeInsetsGeometry padding;

  const CartelFlotante({
    super.key,
    required this.child,
    this.resplandor,
    this.padding = const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
  });

  @override
  State<CartelFlotante> createState() => _CartelFlotanteState();
}

class _CartelFlotanteState extends State<CartelFlotante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  late final Animation<double> _entrada = CurvedAnimation(
    parent: _control,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _fundido = CurvedAnimation(
    parent: _control,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resplandor = widget.resplandor ?? AppColors.oro;

    return FadeTransition(
      opacity: _fundido,
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: ScaleTransition(
            scale: _entrada,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: widget.padding,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  radius: 1.1,
                  colors: [AppColors.tapeteClaro, AppColors.tapeteOscuro],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.oro, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: resplandor.withValues(alpha: 0.45),
                    blurRadius: 46,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rótulo pequeño en versalitas doradas, el que encabeza las secciones de
/// los carteles y del velo de salida.
class RotuloCartel extends StatelessWidget {
  final String texto;
  final double tamano;

  /// Los encabezados van en mayúsculas, pero cuando el rótulo lleva dentro
  /// el nombre de un jugador se respeta cómo lo escribió.
  final bool mayusculas;

  const RotuloCartel(
    this.texto, {
    super.key,
    this.tamano = 10,
    this.mayusculas = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      mayusculas ? texto.toUpperCase() : texto,
      style: TextStyle(
        fontFamily: AppTheme.familiaTitulo,
        fontSize: tamano,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: AppColors.oroClaro.withValues(alpha: 0.6),
      ),
    );
  }
}
