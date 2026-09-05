import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const CarreraCaballosApp());

class CarreraCaballosApp extends StatelessWidget {
  const CarreraCaballosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrera de Caballos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      home: const HomeScreen(),
    );
  }
}
