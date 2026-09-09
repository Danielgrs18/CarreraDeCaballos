import 'package:flutter/material.dart';

import '../game/ajustes_app.dart';
import '../game/cosmeticos.dart';
import '../models/carta.dart';
import '../theme/app_theme.dart';
import '../widgets/carta_espanola.dart';
import '../widgets/menu_app.dart';
import '../widgets/tapete.dart';

/// Aspecto de la mesa: el paño y el dorso de la baraja. Lo que se toca se
/// ve al momento, porque el propio fondo de esta pantalla es el tapete.
class PersonalizarScreen extends StatelessWidget {
  const PersonalizarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Tapete(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: ajustesApp,
            builder: (context, _) => Column(
              children: [
                _cabecera(context),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        children: [
                          const _Muestra(),
                          const SizedBox(height: 22),
                          const _Rotulo('Paño de la mesa'),
                          const SizedBox(height: 10),
                          _panos(),
                          const SizedBox(height: 24),
                          const _Rotulo('Dorso de la baraja'),
                          const SizedBox(height: 10),
                          _dorsos(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panos() {
    return _Fila(
      children: [
        for (final pano in PanoTapete.values)
          _Opcion(
            etiqueta: pano.etiqueta,
            elegida: ajustesApp.pano == pano,
            onTap: () => ajustesApp.pano = pano,
            muestra: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [pano.claro, pano.oscuro],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dorsos() {
    return _Fila(
      children: [
        for (final dorso in DorsoBaraja.values)
          _Opcion(
            etiqueta: dorso.etiqueta,
            elegida: ajustesApp.dorso == dorso,
            onTap: () => ajustesApp.dorso = dorso,
            // Sin ajustar al ancho de la casilla: el dorso manda su
            // proporción de carta y se centra dentro.
            muestra: Center(child: DorsoCarta(ancho: 40, dorso: dorso)),
          ),
      ],
    );
  }

  Widget _cabecera(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.oroClaro,
            tooltip: 'Volver',
          ),
          Expanded(
            child: Text(
              'Personalizar',
              textAlign: TextAlign.center,
              style: AppTheme.tituloDisplay.copyWith(fontSize: 22),
            ),
          ),
          const BotonMenuApp(),
        ],
      ),
    );
  }
}

/// Una mano de ejemplo sobre el paño, para ver cómo queda todo junto.
class _Muestra extends StatelessWidget {
  const _Muestra();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.oro.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DorsoCarta(ancho: 66),
          const SizedBox(width: 10),
          for (final carta in const [
            Carta(Palo.oros, Valores.caballo),
            Carta(Palo.espadas, Valores.rey),
          ])
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: CartaEspanola(carta: carta, ancho: 66),
            ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final List<Widget> children;

  const _Fila({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  final String etiqueta;
  final bool elegida;
  final VoidCallback onTap;
  final Widget muestra;

  const _Opcion({
    required this.etiqueta,
    required this.elegida,
    required this.onTap,
    required this.muestra,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: elegida,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Estirada: la muestra del paño es un degradado sin hijo, y
              // centrada se quedaría sin ancho ninguno.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 66,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: elegida
                          ? AppColors.oroClaro
                          : AppColors.oro.withValues(alpha: 0.3),
                      width: elegida ? 2.4 : 1.2,
                    ),
                    boxShadow: elegida
                        ? [
                            BoxShadow(
                              color: AppColors.oro.withValues(alpha: 0.45),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                  child: muestra,
                ),
                const SizedBox(height: 5),
                Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.familiaTitulo,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: elegida
                        ? AppColors.oroClaro
                        : AppColors.oroClaro.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String texto;

  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTheme.familiaTitulo,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: AppColors.oroClaro.withValues(alpha: 0.65),
      ),
    );
  }
}
