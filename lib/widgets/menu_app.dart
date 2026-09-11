import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../game/ajustes_app.dart';
import '../game/enlaces.dart';
import '../game/sonido.dart';
import '../theme/app_theme.dart';

/// El botón de menú de la esquina superior derecha, el mismo en todas las
/// pantallas. Abre los ajustes generales de la app.
class BotonMenuApp extends StatelessWidget {
  /// Se avisa al abrir y al cerrar, para que la pantalla de juego pueda
  /// parar la carrera mientras el menú tapa la mesa.
  final VoidCallback? onAbrir;
  final VoidCallback? onCerrar;

  const BotonMenuApp({super.key, this.onAbrir, this.onCerrar});

  Future<void> _abrir(BuildContext context) async {
    onAbrir?.call();
    await showDialog<void>(
      context: context,
      builder: (_) => const _DialogoMenu(),
    );
    onCerrar?.call();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _abrir(context),
      icon: const Icon(Icons.more_vert_rounded),
      color: AppColors.oroClaro,
      tooltip: 'Menú',
      visualDensity: VisualDensity.compact,
    );
  }
}

/// El recuadro dorado que comparten el menú y las reglas.
class _Panel extends StatelessWidget {
  final String titulo;
  final Widget contenido;
  final List<Widget> acciones;

  const _Panel({
    required this.titulo,
    required this.contenido,
    required this.acciones,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        decoration: BoxDecoration(
          gradient: ajustesApp.pano.gradientePanel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.oro, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 26, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTheme.tituloDisplay.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 120,
                height: 1,
                color: AppColors.oro.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            // En horizontal el alto es poco: que el contenido se desplace
            // antes que desbordar.
            Flexible(child: SingleChildScrollView(child: contenido)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: acciones),
          ],
        ),
      ),
    );
  }
}

class _DialogoMenu extends StatelessWidget {
  const _DialogoMenu();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ajustesApp,
      builder: (context, _) => _Panel(
        titulo: 'Menú',
        contenido: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sin ficheros de audio no hay nada que callar: antes que
            // enseñar un mando que no manda, no se enseña.
            if (hayAudio)
              _Interruptor(
                titulo: 'Silenciar',
                icono: ajustesApp.silencio
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                nota: 'La música y los efectos del juego',
                valor: ajustesApp.silencio,
                onCambio: (valor) => ajustesApp.silencio = valor,
              ),
            _Interruptor(
              titulo: 'Vibración',
              icono: Icons.vibration_rounded,
              nota: 'Al destapar carta a mano',
              valor: ajustesApp.vibracion,
              onCambio: (valor) => ajustesApp.vibracion = valor,
            ),
            _Interruptor(
              titulo: 'Pantalla siempre encendida',
              icono: Icons.brightness_high_rounded,
              nota: 'Que no se apague en plena carrera',
              valor: ajustesApp.pantallaEncendida,
              onCambio: (valor) => ajustesApp.pantallaEncendida = valor,
            ),
            const SizedBox(height: 6),
            _Entrada(
              titulo: 'Cómo se juega',
              icono: Icons.menu_book_rounded,
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const _DialogoReglas(),
              ),
            ),
            // Solo si hay a dónde ir: más vale no enseñarla que enseñar
            // una entrada de apoyo que no lleva a ninguna parte.
            if (Enlaces.hayDonacion)
              _Entrada(
                titulo: 'Apoyar el proyecto',
                icono: Icons.favorite_rounded,
                onTap: () => _abrirEnlace(Enlaces.donacion),
              ),
            _Entrada(
              titulo: 'Código fuente',
              icono: Icons.code_rounded,
              onTap: () => _abrirEnlace(Enlaces.codigo),
            ),
          ],
        ),
        acciones: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

/// Abre una dirección fuera de la app: en la web, en otra pestaña. Si el
/// sistema no sabe abrirla no pasa nada más: no se tumba el menú por no
/// poder enseñar una página.
Future<void> _abrirEnlace(String direccion) async {
  try {
    await launchUrl(
      Uri.parse(direccion),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    // Sin navegador que la atienda, o dirección mal formada.
  }
}

class _DialogoReglas extends StatelessWidget {
  const _DialogoReglas();

  static const _reglas = [
    'Los cuatro caballos —el 11 de cada palo— salen de la baraja y se '
        'ponen en la línea de salida.',
    'Con las cartas restantes se tienden unas cuantas boca abajo, que son '
        'los pasos de la pista. El resto forma el mazo.',
    'Cada carta que se destapa hace avanzar una casilla al caballo de su '
        'palo.',
    'En cuanto todos los caballos dejan atrás un paso, su carta se levanta '
        'y el caballo de ese palo retrocede una casilla.',
    'Gana el primero en cruzar la meta, un paso más allá de la última '
        'carta de la pista.',
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      titulo: 'Cómo se juega',
      contenido: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _reglas.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}.',
                      style: const TextStyle(
                        fontFamily: AppTheme.familiaTitulo,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.oro,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _reglas[i],
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.oroClaro.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      acciones: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}

class _Interruptor extends StatelessWidget {
  final String titulo;
  final String nota;
  final IconData icono;
  final bool valor;
  final ValueChanged<bool> onCambio;

  const _Interruptor({
    required this.titulo,
    required this.nota,
    required this.icono,
    required this.valor,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: valor,
      onChanged: onCambio,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.tapeteOscuro,
      activeTrackColor: AppColors.oro,
      inactiveThumbColor: AppColors.oroClaro.withValues(alpha: 0.7),
      inactiveTrackColor: Colors.black.withValues(alpha: 0.3),
      secondary: Icon(icono, color: AppColors.oroClaro, size: 22),
      title: Text(
        titulo,
        style: const TextStyle(
          fontFamily: AppTheme.familiaTitulo,
          fontSize: 14.5,
          fontWeight: FontWeight.bold,
          color: AppColors.oroClaro,
        ),
      ),
      subtitle: Text(
        nota,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.oroClaro.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _Entrada extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final VoidCallback onTap;

  const _Entrada({
    required this.titulo,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Icon(icono, color: AppColors.oroClaro, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontFamily: AppTheme.familiaTitulo,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oroClaro,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.oroClaro.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
