import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/ajustes_partida.dart';
import '../game/enlaces.dart';
import '../game/sala.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_app.dart';
import '../widgets/tapete.dart';
import 'game_screen.dart';

/// Crear una sala privada o unirse a la de un amigo.
///
/// No hay servidor detrás: la carrera va dentro del código. Quien lo abra
/// verá exactamente la misma, con el mismo ganador, desde su propio móvil.
class SalaScreen extends StatefulWidget {
  const SalaScreen({super.key});

  @override
  State<SalaScreen> createState() => _SalaScreenState();
}

class _SalaScreenState extends State<SalaScreen> {
  final _codigo = TextEditingController();

  var _pasos = LongitudPista.porDefecto;
  Sala? _creada;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _crear() {
    setState(() => _creada = Sala.nueva(pasos: _pasos));
  }

  void _unirse() {
    final sala = Sala.desdeCodigo(_codigo.text);
    if (sala == null) {
      setState(() => _error = 'Ese código no vale. Son '
          '${Sala.largoCodigo} caracteres, como el que te hayan pasado.');
      return;
    }
    setState(() => _error = null);
    _entrar(sala);
  }

  void _entrar(Sala sala) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          modalidad: ModalidadPartida.sala,
          sala: sala,
        ),
      ),
    );
  }

  void _copiar(String texto, String aviso) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(aviso), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Tapete(
        child: SafeArea(
          child: Column(
            children: [
              _cabecera(context),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                      children: [
                        Text(
                          'Todos los que abran el mismo código verán '
                          'exactamente la misma carrera, cada uno desde su '
                          'móvil. No hace falta registrarse.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.oroClaro.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _bloqueCrear(),
                        const SizedBox(height: 22),
                        _bloqueUnirse(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bloqueCrear() {
    final creada = _creada;

    return _Bloque(
      titulo: 'Crear una sala',
      icono: Icons.add_circle_outline_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Largo de la pista',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.oroClaro.withValues(alpha: 0.85),
                ),
              ),
            ),
            Text(
              _pasos == 1 ? '1 paso' : '$_pasos pasos',
              style: const TextStyle(
                fontFamily: AppTheme.familiaTitulo,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.oroClaro,
              ),
            ),
          ],
        ),
        Slider(
          value: _pasos.toDouble(),
          min: LongitudPista.minimo.toDouble(),
          max: LongitudPista.maximo.toDouble(),
          divisions: LongitudPista.maximo - LongitudPista.minimo,
          label: '$_pasos',
          activeColor: AppColors.oro,
          // Cambiar la pista cambia la carrera: el código anterior ya no
          // vale, así que se retira en vez de dejarlo enseñado.
          onChanged: (valor) => setState(() {
            _pasos = valor.round();
            _creada = null;
          }),
        ),
        const SizedBox(height: 4),
        if (creada == null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _crear,
              child: const Text('Crear sala'),
            ),
          )
        else
          _CodigoCreado(
            sala: creada,
            onCopiarCodigo: () => _copiar(creada.codigo, 'Código copiado'),
            onCopiarEnlace: () => _copiar(
              creada.enlaceDesde(Enlaces.deLaWeb).toString(),
              'Enlace copiado',
            ),
            onEntrar: () => _entrar(creada),
          ),
      ],
    );
  }

  Widget _bloqueUnirse() {
    return _Bloque(
      titulo: 'Unirse a una sala',
      icono: Icons.login_rounded,
      children: [
        TextField(
          controller: _codigo,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _unirse(),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          style: const TextStyle(
            fontFamily: AppTheme.familiaTitulo,
            fontSize: 22,
            letterSpacing: 6,
            fontWeight: FontWeight.bold,
            color: AppColors.oroClaro,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'CÓDIGO',
            hintStyle: TextStyle(
              fontFamily: AppTheme.familiaTitulo,
              fontSize: 22,
              letterSpacing: 6,
              color: AppColors.oroClaro.withValues(alpha: 0.3),
            ),
            errorText: _error,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.22),
            enabledBorder: _borde(AppColors.oro.withValues(alpha: 0.45)),
            focusedBorder: _borde(AppColors.oro),
            border: _borde(AppColors.oro.withValues(alpha: 0.45)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _unirse,
            child: const Text('Unirse'),
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );

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
              'Sala con amigos',
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

/// El código recién creado, listo para pasárselo a alguien.
class _CodigoCreado extends StatelessWidget {
  final Sala sala;
  final VoidCallback onCopiarCodigo;
  final VoidCallback onCopiarEnlace;
  final VoidCallback onEntrar;

  const _CodigoCreado({
    required this.sala,
    required this.onCopiarCodigo,
    required this.onCopiarEnlace,
    required this.onEntrar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.oro, width: 1.6),
          ),
          child: Text(
            sala.codigo,
            textAlign: TextAlign.center,
            style: AppTheme.tituloDisplay.copyWith(
              fontSize: 34,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCopiarCodigo,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Código'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCopiarEnlace,
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Enlace'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onEntrar,
          child: const Text('Entrar a la sala'),
        ),
      ],
    );
  }
}

class _Bloque extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  const _Bloque({
    required this.titulo,
    required this.icono,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.oro.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icono, color: AppColors.oroClaro, size: 20),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: AppTheme.tituloDisplay.copyWith(fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
