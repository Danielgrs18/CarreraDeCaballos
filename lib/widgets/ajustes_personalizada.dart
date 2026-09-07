import 'package:flutter/material.dart';

import '../game/ajustes_partida.dart';
import '../game/campeonato.dart';
import '../models/carta.dart';
import '../models/jugador.dart';
import '../theme/app_theme.dart';
import 'paint/palos.dart';

/// Los ajustes propios de la partida personalizada, tal como se ven en el
/// velo de salida: el largo de la pista y quién juega con cada palo. El
/// campeonato añade encima cuántas rondas se corren.
class AjustesPersonalizada extends StatelessWidget {
  final int pasos;
  final ValueChanged<int> onPasos;
  final List<Jugador> jugadoresIniciales;
  final ValueChanged<List<Jugador>> onJugadores;

  /// Número de carreras del campeonato. En la partida personalizada, que
  /// es de una sola carrera, va a `null` y el mando no aparece.
  final int? rondas;
  final ValueChanged<int>? onRondas;

  const AjustesPersonalizada({
    super.key,
    required this.pasos,
    required this.onPasos,
    required this.jugadoresIniciales,
    required this.onJugadores,
    this.rondas,
    this.onRondas,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 330,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rondas != null && onRondas != null) ...[
            const _Rotulo('Rondas del campeonato'),
            const SizedBox(height: 2),
            _SelectorNumero(
              valor: rondas!,
              minimo: NumeroRondas.minimo,
              maximo: NumeroRondas.maximo,
              onCambio: onRondas!,
              rotulo: (n) => n == 1 ? '1 ronda' : '$n rondas',
            ),
            const SizedBox(height: 10),
          ],
          const _Rotulo('Longitud de la pista'),
          const SizedBox(height: 2),
          _SelectorNumero(
            valor: pasos,
            minimo: LongitudPista.minimo,
            maximo: LongitudPista.maximo,
            onCambio: onPasos,
            rotulo: (n) => n == 1 ? '1 paso' : '$n pasos',
          ),
          const SizedBox(height: 10),
          const _Rotulo('Jugadores'),
          const SizedBox(height: 6),
          EditorJugadores(
            iniciales: jugadoresIniciales,
            onCambio: onJugadores,
          ),
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

/// Una regleta con su cifra al lado, para elegir un número entero corto.
class _SelectorNumero extends StatelessWidget {
  final int valor;
  final int minimo;
  final int maximo;
  final ValueChanged<int> onCambio;
  final String Function(int) rotulo;

  const _SelectorNumero({
    required this.valor,
    required this.minimo,
    required this.maximo,
    required this.onCambio,
    required this.rotulo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: AppColors.oro,
              inactiveTrackColor: AppColors.oro.withValues(alpha: 0.22),
              thumbColor: AppColors.oroClaro,
              overlayColor: AppColors.oro.withValues(alpha: 0.18),
              valueIndicatorColor: AppColors.rojo,
              valueIndicatorTextStyle: const TextStyle(
                color: AppColors.oroClaro,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: valor.toDouble(),
              min: minimo.toDouble(),
              max: maximo.toDouble(),
              divisions: maximo - minimo,
              label: '$valor',
              onChanged: (elegido) => onCambio(elegido.round()),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 66,
          child: Text(
            rotulo(valor),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: AppTheme.familiaTitulo,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.oroClaro,
            ),
          ),
        ),
      ],
    );
  }
}

/// Lista editable de jugadores: nombre y palo de cada uno, con un botón
/// para ir añadiendo más. Se queda con los controladores de texto, así que
/// va por dentro y solo avisa hacia arriba de la lista resultante.
class EditorJugadores extends StatefulWidget {
  final List<Jugador> iniciales;
  final ValueChanged<List<Jugador>> onCambio;

  const EditorJugadores({
    super.key,
    required this.iniciales,
    required this.onCambio,
  });

  @override
  State<EditorJugadores> createState() => _EditorJugadoresState();
}

class _FilaJugador {
  final TextEditingController controlador;
  Palo palo;

  _FilaJugador({required this.controlador, required this.palo});
}

class _EditorJugadoresState extends State<EditorJugadores> {
  late final List<_FilaJugador> _filas = [
    for (final jugador in widget.iniciales)
      _FilaJugador(
        controlador: TextEditingController(text: jugador.nombre),
        palo: jugador.palo,
      ),
  ];

  @override
  void dispose() {
    for (final fila in _filas) {
      fila.controlador.dispose();
    }
    super.dispose();
  }

  /// Si el jugador deja el nombre en blanco, se le llama por su número en
  /// vez de dejar una etiqueta vacía en el cartel de victoria.
  String _nombre(int indice) {
    final escrito = _filas[indice].controlador.text.trim();
    return escrito.isEmpty ? 'Jugador ${indice + 1}' : escrito;
  }

  void _avisar() {
    widget.onCambio([
      for (var i = 0; i < _filas.length; i++)
        Jugador(nombre: _nombre(i), palo: _filas[i].palo),
    ]);
  }

  void _anadir() {
    setState(() {
      _filas.add(
        _FilaJugador(
          controlador: TextEditingController(
            text: 'Jugador ${_filas.length + 1}',
          ),
          // Va rotando de palo para que dos jugadores seguidos no salgan
          // con el mismo por defecto; compartirlo sigue estando permitido.
          palo: Palo.values[_filas.length % Palo.values.length],
        ),
      );
    });
    _avisar();
  }

  void _quitar(int indice) {
    final fila = _filas[indice];
    setState(() => _filas.removeAt(indice));
    // El campo ya no está en el árbol, así que soltar el controlador es
    // seguro solo después de que se haya reconstruido sin él.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => fila.controlador.dispose(),
    );
    _avisar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _filas.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _Fila(
              fila: _filas[i],
              posicion: i,
              sePuedeQuitar: _filas.length > 1,
              onNombre: _avisar,
              onPalo: (palo) {
                setState(() => _filas[i].palo = palo);
                _avisar();
              },
              onQuitar: () => _quitar(i),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _anadir,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Añadir jugador'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.oroClaro,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              textStyle: const TextStyle(
                fontFamily: AppTheme.familiaTitulo,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final _FilaJugador fila;
  final int posicion;
  final bool sePuedeQuitar;
  final VoidCallback onNombre;
  final ValueChanged<Palo> onPalo;
  final VoidCallback onQuitar;

  const _Fila({
    required this.fila,
    required this.posicion,
    required this.sePuedeQuitar,
    required this.onNombre,
    required this.onPalo,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: fila.controlador,
            onChanged: (_) => onNombre(),
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.oroClaro,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              hintText: 'Jugador ${posicion + 1}',
              hintStyle: TextStyle(
                fontSize: 13.5,
                color: AppColors.oroClaro.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.22),
              enabledBorder: _borde(AppColors.oro.withValues(alpha: 0.45)),
              focusedBorder: _borde(AppColors.oro),
              border: _borde(AppColors.oro.withValues(alpha: 0.45)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _DesplegablePalo(palo: fila.palo, onCambio: onPalo),
        SizedBox(
          width: 30,
          child: sePuedeQuitar
              ? IconButton(
                  onPressed: onQuitar,
                  icon: const Icon(Icons.close_rounded, size: 17),
                  color: AppColors.oroClaro.withValues(alpha: 0.6),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Quitar jugador',
                )
              : null,
        ),
      ],
    );
  }

  static OutlineInputBorder _borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );
}

class _DesplegablePalo extends StatelessWidget {
  final Palo palo;
  final ValueChanged<Palo> onCambio;

  const _DesplegablePalo({required this.palo, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.dePalo(palo);

    return Container(
      width: 134,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.3),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Palo>(
          value: palo,
          isDense: true,
          isExpanded: true,
          dropdownColor: AppColors.tapeteOscuro,
          borderRadius: BorderRadius.circular(10),
          iconEnabledColor: AppColors.oroClaro.withValues(alpha: 0.8),
          onChanged: (elegido) {
            if (elegido != null) onCambio(elegido);
          },
          items: [
            for (final opcion in Palo.values)
              DropdownMenuItem(
                value: opcion,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EmblemaPalo(palo: opcion, tamano: 15),
                    const SizedBox(width: 6),
                    // Flexible para que "Espadas" no se salga del ancho
                    // del desplegable por unos pocos píxeles.
                    Flexible(
                      child: Text(
                        opcion.nombre,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.familiaTitulo,
                          fontSize: 13,
                          color: AppColors.dePalo(opcion),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
