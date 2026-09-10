import 'dart:math';

import 'ajustes_partida.dart';

/// Una sala privada: una carrera concreta que varios amigos pueden ver a la
/// vez desde sus móviles.
///
/// No hace falta servidor. La carrera está determinada por completo por la
/// semilla y el largo de la pista, así que basta con que todos tengan esos
/// dos números para que vean exactamente la misma carrera, carta por carta
/// y con el mismo ganador. El código de sala no es más que esos dos números
/// escritos de forma que se puedan dictar por teléfono.
class Sala {
  final int pasos;
  final int semilla;

  const Sala({required this.pasos, required this.semilla});

  /// Alfabeto de Crockford: base 32 sin la I, la L, la O ni la U. Las tres
  /// primeras se confunden al leerlas con el 1 y el 0, y la U se quita para
  /// no formar palabrotas sin querer.
  static const _digitos = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Cinco dígitos dan 33 millones de salas: de sobra, y se dictan sin
  /// cansarse.
  static const _largoSemilla = 5;
  static const _limiteSemilla = 32 * 32 * 32 * 32 * 32;

  /// El largo del código completo: un dígito de pista más la semilla.
  static const largoCodigo = 1 + _largoSemilla;

  /// Una sala nueva, con la pista pedida y una carrera al azar.
  factory Sala.nueva({int pasos = LongitudPista.porDefecto, Random? random}) {
    assert(
      pasos >= LongitudPista.minimo && pasos <= LongitudPista.maximo,
      'La pista se sale de lo que admite el código de sala',
    );
    return Sala(
      pasos: pasos,
      semilla: (random ?? Random()).nextInt(_limiteSemilla),
    );
  }

  /// El código para compartir, de seis caracteres.
  String get codigo =>
      _aBase32(pasos, 1) + _aBase32(semilla, _largoSemilla);

  /// Lee un código tecleado o pegado. Devuelve `null` si no es válido, que
  /// es lo que hay que enseñarle al usuario en vez de una carrera cualquiera.
  ///
  /// Se perdona todo lo que se perdona sin ambigüedad: minúsculas, espacios,
  /// guiones, y la I o la L por 1 y la O por 0, que es como la gente copia
  /// los códigos a mano.
  static Sala? desdeCodigo(String texto) {
    final limpio = texto
        .toUpperCase()
        .replaceAll(RegExp('[^0-9A-Z]'), '')
        .replaceAll(RegExp('[IL]'), '1')
        .replaceAll('O', '0');
    if (limpio.length != largoCodigo) return null;

    final pasos = _deBase32(limpio.substring(0, 1));
    final semilla = _deBase32(limpio.substring(1));
    if (pasos == null || semilla == null) return null;
    if (pasos < LongitudPista.minimo || pasos > LongitudPista.maximo) {
      return null;
    }
    return Sala(pasos: pasos, semilla: semilla);
  }

  /// La dirección que abre esta sala directamente.
  Uri enlaceDesde(Uri base) => base.replace(queryParameters: {'sala': codigo});

  /// El generador de la carrera. Dos dispositivos con el mismo código
  /// sacan las cartas en el mismo orden.
  Random get generador => Random(semilla);

  static String _aBase32(int valor, int largo) {
    final crudo = valor.toRadixString(32).padLeft(largo, '0');
    return [
      for (final c in crudo.split('')) _digitos[int.parse(c, radix: 32)],
    ].join();
  }

  static int? _deBase32(String texto) {
    var valor = 0;
    for (final c in texto.split('')) {
      final indice = _digitos.indexOf(c);
      if (indice < 0) return null;
      valor = valor * 32 + indice;
    }
    return valor;
  }

  @override
  bool operator ==(Object other) =>
      other is Sala && other.pasos == pasos && other.semilla == semilla;

  @override
  int get hashCode => Object.hash(pasos, semilla);

  @override
  String toString() => 'Sala($codigo)';
}
