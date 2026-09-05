# Carrera de Caballos

Juego de la carrera de caballos con baraja española, hecho en Flutter y
pensado para Android.

## Cómo se juega

- Se apartan los **4 caballos** (el 11 de cada palo): son los corredores.
- De las 36 cartas restantes se tienden **6 boca abajo** formando la pista;
  el resto es el mazo de robo.
- Cada carta que sale hace **avanzar un paso** al caballo de su palo.
- En cuanto los cuatro caballos dejan atrás un paso, se **levanta su carta**
  y el caballo de ese palo **retrocede una casilla**.
- Gana el primero en cruzar la meta, un paso más allá de la última carta.

## Pantallas

| Pantalla | Contenido |
|---|---|
| Menú | `Partida rápida` y `Desbloquear más` (aún sin función). |
| Mesa | En horizontal: barra de modo (`Manual` / `Automático` con tres velocidades), mazo y carta destapada, hilera de cartas de paso y los 4 carriles. |
| Victoria | El palo ganador en grande con su emblema y el botón `Finalizar`. |

## Estructura

```
lib/
  models/      Carta, Palo, Baraja y Caballo
  game/        Reglas de la carrera y ajustes de la partida
  theme/       Paleta (tapete verde, botones rojo oscuro) y tema
  widgets/     Tapete, carta española, mazo, pista, controles y cartel
    paint/     Trazo vectorial de los 4 palos y de las 3 figuras
  screens/     Menú y mesa de juego
```

Las cartas no son imágenes: se dibujan con `CustomPainter`, así que escalan
sin pixelarse y no pesan nada. El marco lleva las **pintas** tradicionales
(interrupciones del filete: oros 0, copas 1, espadas 2, bastos 3).

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
