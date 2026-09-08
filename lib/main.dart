import 'package:flutter/material.dart';

import 'game/ajustes_app.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Sin esperar a que lleguen: la app arranca con los valores de fábrica y
  // se corrige sola en cuanto el disco responde, que es cuestión de un
  // fotograma. Así no se retrasa la primera pantalla.
  ajustesApp.cargar();
  runApp(const CarreraCaballosApp());
}

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
