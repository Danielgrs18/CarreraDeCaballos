import 'package:flutter/material.dart';

import '../models/carta.dart';

/// Paleta de la app: tapete verde de casino y botonería en rojo oscuro.
class AppColors {
  const AppColors._();

  // Tapete
  static const tapete = Color(0xFF0E5A38);
  static const tapeteClaro = Color(0xFF177A4B);
  static const tapeteOscuro = Color(0xFF063722);
  static const tapeteBorde = Color(0xFF0A4229);

  // Botones
  static const rojo = Color(0xFF8A1420);
  static const rojoClaro = Color(0xFFA8202E);
  static const rojoOscuro = Color(0xFF5E0C15);
  static const rojoBorde = Color(0xFFC2565F);

  // Oro y marfil
  static const oro = Color(0xFFD9B25A);
  static const oroClaro = Color(0xFFF2DFA8);
  static const oroOscuro = Color(0xFF8A6A22);

  // Cartas: cartulina envejecida y tinta de imprenta, no blanco y negro puros.
  static const marfil = Color(0xFFF2E7CD);
  static const marfilSombra = Color(0xFFDCCAA3);
  static const marfilMancha = Color(0xFFC9B489);
  static const tinta = Color(0xFF241C14);

  // Color identificativo de cada palo (carriles, marcadores...), en tonos
  // apagados de estampa antigua en vez de colores planos saturados.
  static const paloOros = Color(0xFFB4861A);
  static const paloCopas = Color(0xFF8E2B2B);
  static const paloEspadas = Color(0xFF2E5170);
  static const paloBastos = Color(0xFF4A6B2E);

  static Color dePalo(Palo palo) => switch (palo) {
        Palo.oros => paloOros,
        Palo.copas => paloCopas,
        Palo.espadas => paloEspadas,
        Palo.bastos => paloBastos,
      };
}

class AppTheme {
  const AppTheme._();

  /// Tipografía con serifa para títulos y textos de carta: encaja con el
  /// aire clásico de la baraja española y no depende de fuentes de red.
  static const familiaTitulo = 'serif';

  static ThemeData get tema {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.tapete,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.rojo,
        onPrimary: AppColors.oroClaro,
        secondary: AppColors.oro,
        onSecondary: AppColors.tinta,
        surface: AppColors.tapeteOscuro,
        onSurface: AppColors.oroClaro,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.oroClaro,
        displayColor: AppColors.oroClaro,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: botonRojo),
      outlinedButtonTheme: OutlinedButtonThemeData(style: botonContorno),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.oroClaro),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.rojoOscuro,
        contentTextStyle: TextStyle(color: AppColors.oroClaro),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Botón principal: rojo oscuro con filete dorado.
  static ButtonStyle get botonRojo => ElevatedButton.styleFrom(
        backgroundColor: AppColors.rojo,
        foregroundColor: AppColors.oroClaro,
        disabledBackgroundColor: AppColors.rojoOscuro,
        disabledForegroundColor: AppColors.oroClaro.withValues(alpha: 0.35),
        elevation: 6,
        shadowColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.oro, width: 1.4),
        ),
        textStyle: const TextStyle(
          fontFamily: familiaTitulo,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      );

  /// Botón secundario: mismo trazo, sin relleno.
  static ButtonStyle get botonContorno => OutlinedButton.styleFrom(
        foregroundColor: AppColors.oroClaro,
        backgroundColor: AppColors.rojoOscuro.withValues(alpha: 0.55),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.oro, width: 1.4),
        ),
        textStyle: const TextStyle(
          fontFamily: familiaTitulo,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      );

  static const tituloDisplay = TextStyle(
    fontFamily: familiaTitulo,
    fontWeight: FontWeight.bold,
    color: AppColors.oroClaro,
    letterSpacing: 1.2,
    shadows: [
      Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
    ],
  );
}
