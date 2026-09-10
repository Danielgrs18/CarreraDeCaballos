import 'package:flutter/material.dart';

import 'game/ajustes_app.dart';
import 'game/sonido.dart';
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
      // El navegador no deja sonar nada hasta que el usuario toca la
      // página. Se escucha el primer toque, venga de donde venga, para
      // arrancar entonces la música que tocara.
      builder: (context, hijo) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => sonido.desbloquear(),
        child: hijo ?? const SizedBox.shrink(),
      ),
      home: const HomeScreen(),
    );
  }
}
