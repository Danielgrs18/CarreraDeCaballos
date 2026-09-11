import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/ajustes_partida.dart';
import '../game/campeonato.dart';
import '../game/enlaces.dart';
import '../game/sala.dart';
import '../models/carta.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_app.dart';
import '../widgets/selector_palo.dart';
import '../widgets/tapete.dart';
import 'game_screen.dart';

/// Crear una sala privada o unirse a la de un amigo.
///
/// No hay servidor detrás: la partida entera va dentro del código. Quien lo
/// abra verá exactamente la misma, con el mismo ganador, desde su móvil.
class SalaScreen extends StatefulWidget {
  const SalaScreen({super.key});

  @override
  State<SalaScreen> createState() => _SalaScreenState();
}

class _SalaScreenState extends State<SalaScreen> {
  final _codigo = TextEditingController();

  var _modalidad = ModalidadPartida.rapida;
  var _pasos = LongitudPista.porDefecto;
  var _rondas = NumeroRondas.porDefecto;
  var _palo1 = Palo.oros;
  var _palo2 = Palo.copas;

  Sala? _creada;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  /// Cualquier cambio en la mesa cambia la partida, así que el código que
  /// hubiera enseñado deja de valer y se retira.
  void _cambiar(VoidCallback ajuste) {
    setState(() {
      ajuste();
      _creada = null;
    });
  }

  void _crear() {
    setState(() {
      _creada = Sala.nueva(
        modalidad: _modalidad,
        pasos: _pasos,
        rondas: _rondas,
        palos: [_palo1, _palo2],
      );
    });
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
        builder: (_) => GameScreen(modalidad: sala.modalidad, sala: sala),
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
                          'Elige a qué jugáis, comparte el código y todos '
                          'veréis exactamente la misma partida, cada uno '
                          'desde su móvil. No hace falta registrarse.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.oroClaro.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 22),
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

  // --- Crear ---------------------------------------------------------------

  Widget _bloqueCrear() {
    final creada = _creada;

    return _Bloque(
      titulo: 'Crear una sala',
      icono: Icons.add_circle_outline_rounded,
      children: [
        const _Rotulo('A qué jugáis'),
        const SizedBox(height: 8),
        _selectorModalidad(),
        ..._ajustesDelModo(),
        const SizedBox(height: 14),
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

  Widget _selectorModalidad() {
    return Column(
      children: [
        for (final modalidad in Sala.modalidades)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _OpcionModo(
              titulo: _nombreDe(modalidad),
              descripcion: _descripcionDe(modalidad),
              elegida: _modalidad == modalidad,
              onTap: () => _cambiar(() => _modalidad = modalidad),
            ),
          ),
      ],
    );
  }

  /// Lo que cada modo deja configurar. La partida rápida no deja nada: es
  /// justo lo que la hace rápida.
  List<Widget> _ajustesDelModo() {
    switch (_modalidad) {
      case ModalidadPartida.rapida:
        return const [];

      case ModalidadPartida.unoContraUno:
        final disponibles = Palo.values.where((p) => p != _palo1).toList();
        return [
          const SizedBox(height: 10),
          const _Rotulo('Los dos caballos'),
          const SizedBox(height: 8),
          SelectorPalo(
            opciones: Palo.values,
            seleccionado: _palo1,
            onCambio: (palo) => _cambiar(() {
              _palo1 = palo;
              if (_palo2 == palo) {
                _palo2 = Palo.values.firstWhere((p) => p != palo);
              }
            }),
          ),
          const SizedBox(height: 8),
          SelectorPalo(
            opciones: disponibles,
            seleccionado: _palo2,
            onCambio: (palo) => _cambiar(() => _palo2 = palo),
          ),
        ];

      case ModalidadPartida.personalizada:
        return [_regleta('Largo de la pista', _pasos, LongitudPista.minimo,
            LongitudPista.maximo, (v) => _cambiar(() => _pasos = v),
            (n) => n == 1 ? '1 paso' : '$n pasos')];

      case ModalidadPartida.campeonato:
        return [
          _regleta('Largo de la pista', _pasos, LongitudPista.minimo,
              LongitudPista.maximo, (v) => _cambiar(() => _pasos = v),
              (n) => n == 1 ? '1 paso' : '$n pasos'),
          _regleta('Rondas', _rondas, NumeroRondas.minimo,
              NumeroRondas.maximo, (v) => _cambiar(() => _rondas = v),
              (n) => n == 1 ? '1 ronda' : '$n rondas'),
        ];
    }
  }

  Widget _regleta(
    String titulo,
    int valor,
    int minimo,
    int maximo,
    ValueChanged<int> onCambio,
    String Function(int) etiqueta,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Rotulo(titulo)),
            Text(
              etiqueta(valor),
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
          value: valor.toDouble(),
          min: minimo.toDouble(),
          max: maximo.toDouble(),
          divisions: maximo - minimo,
          label: '$valor',
          activeColor: AppColors.oro,
          onChanged: (v) => onCambio(v.round()),
        ),
      ],
    );
  }

  static String _nombreDe(ModalidadPartida modalidad) => switch (modalidad) {
        ModalidadPartida.rapida => 'Partida rápida',
        ModalidadPartida.unoContraUno => '1 contra 1',
        ModalidadPartida.personalizada => 'Partida personalizada',
        ModalidadPartida.campeonato => 'Campeonato',
      };

  static String _descripcionDe(ModalidadPartida modalidad) =>
      switch (modalidad) {
        ModalidadPartida.rapida => 'Los cuatro caballos, pista de siempre',
        ModalidadPartida.unoContraUno => 'Solo dos palos, cara a cara',
        ModalidadPartida.personalizada => 'Elegís el largo de la pista',
        ModalidadPartida.campeonato => 'Varias carreras con marcador',
      };

  // --- Unirse --------------------------------------------------------------

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
            letterSpacing: 5,
            fontWeight: FontWeight.bold,
            color: AppColors.oroClaro,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'CÓDIGO',
            hintStyle: TextStyle(
              fontFamily: AppTheme.familiaTitulo,
              fontSize: 22,
              letterSpacing: 5,
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

/// Uno de los modos a los que se puede jugar en sala.
class _OpcionModo extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final bool elegida;
  final VoidCallback onTap;

  const _OpcionModo({
    required this.titulo,
    required this.descripcion,
    required this.elegida,
    required this.onTap,
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
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: elegida
                  ? AppColors.rojoOscuro.withValues(alpha: 0.65)
                  : Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: elegida
                    ? AppColors.oroClaro
                    : AppColors.oro.withValues(alpha: 0.3),
                width: elegida ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  elegida
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: elegida
                      ? AppColors.oroClaro
                      : AppColors.oroClaro.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontFamily: AppTheme.familiaTitulo,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.oroClaro,
                        ),
                      ),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.oroClaro.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              sala.codigo,
              style: AppTheme.tituloDisplay.copyWith(
                fontSize: 32,
                letterSpacing: 6,
              ),
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
