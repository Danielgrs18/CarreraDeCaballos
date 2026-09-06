# Carrera de Caballos

Juego de la carrera de caballos con baraja española, hecho en Flutter.
Pensado para Android, y también publicado como web en GitHub Pages.

## Cómo se juega

- Se apartan los caballos (el 11 de cada palo) que vayan a competir —los
  4 en Partida rápida, 2 en el modo 1 contra 1— y son los corredores.
- Con las cartas restantes se tienden **6 boca abajo** formando la pista;
  el resto es el mazo de robo.
- Cada carta que sale hace **avanzar un paso** al caballo de su palo.
- En cuanto todos los caballos en carrera dejan atrás un paso, se
  **levanta su carta** y el caballo de ese palo **retrocede una casilla**.
- Gana el primero en cruzar la meta, un paso más allá de la última carta.

## Pantallas

| Pantalla | Contenido |
|---|---|
| Menú | `Partida rápida`, `Modos de juego` y `Desbloquear más` (aún sin función). |
| Modos de juego | Catálogo: `1 contra 1` (jugable), `Torneo personalizado` y `Partida personalizada` (ambos, próximamente). |
| Mesa | En horizontal: barra de modo (`Manual` / `Automático` con tres velocidades), mazo y carta destapada, hilera de cartas de paso y los carriles de los caballos en carrera. En el 1 contra 1, el velo de salida deja elegir el palo de cada jugador antes de empezar. |
| Victoria | El palo ganador en grande con su emblema, y los botones `Revancha` (pista nueva, sin salir de la mesa) y `Finalizar`. |

Salir de una carrera en marcha —con la flecha de la barra o con el back
del sistema— pide confirmación antes de perder el progreso.

## Estructura

```
lib/
  models/      Carta, Palo, Baraja y Caballo
  game/        Reglas de la carrera (LogicaJuego) y ajustes de la partida
  theme/       Paleta (tapete verde, botones rojo oscuro) y tema
  widgets/     Tapete, carta española, mazo, pista, controles, selector de
               palo y cartel de victoria
    paint/     Trazo vectorial de los 4 palos y de las 3 figuras
  screens/     Menú, catálogo de modos y mesa de juego
```

`LogicaJuego` no sabe nada de "1 contra 1": simplemente acepta qué palos
compiten (2 o más). La mesa, la pista, el cartel de victoria y la
revancha son el mismo código para cualquier número de caballos.

Las cartas no son imágenes: se dibujan con `CustomPainter`, así que
escalan sin pixelarse y no pesan nada. El marco lleva las **pintas**
tradicionales (interrupciones del filete: oros 0, copas 1, espadas 2,
bastos 3). El icono de la app (una herradura) se genera igual, con
`tool/generar_icono.dart`.

## Desarrollo

```bash
flutter pub get
flutter test            # lógica de juego e interfaz
flutter analyze
flutter run
```

Para revisar el diseño a ojo se pueden regenerar las capturas de
`test/capturas/`:

```bash
flutter test --run-skipped test/capturas_golden_test.dart --update-goldens
```

## Publicación

- **Android**: `flutter build apk --release` (firma con las claves de
  debug hasta que se configure un keystore propio en
  `android/app/build.gradle.kts`).
- **Web**: cada push a `main` compila y publica automáticamente en
  GitHub Pages (`.github/workflows/deploy-web.yml`).
