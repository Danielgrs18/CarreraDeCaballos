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
- La carrera puede seguir después, para repartir los demás puestos, hasta
  que no quede nadie con cartas vivas con las que avanzar.

## Pantallas

| Pantalla | Contenido |
|---|---|
| Menú | `Partida rápida`, `Modos de juego` y `Desbloquear más` (aún sin función). |
| Modos de juego | Catálogo: `1 contra 1`, `Campeonato` y `Partida personalizada`. |
| Mesa | En horizontal: barra de modo (`Manual` / `Automático` con tres velocidades), mazo y carta destapada, hilera de cartas de paso y los carriles de los caballos en carrera. |
| Victoria | El palo ganador en grande con su emblema, y los botones `Seguir hasta que lleguen todos`, `Revancha` (pista nueva, sin salir de la mesa) y `Finalizar`. |
| Clasificación | El orden de llegada completo, con los rezagados al final. En el campeonato lleva además el marcador y el paso a la siguiente ronda. |

En el velo de salida se configura cada modalidad: en el `1 contra 1`, el
palo de cada uno de los dos jugadores; en la `Partida personalizada`, el
largo de la pista (de 2 a 12 pasos) y una lista de jugadores con nombre y
palo —pueden repetir palo, y corren los 4 caballos igual—. Al terminar
una personalizada, el cartel canta también los nombres de quienes iban al
palo ganador.

## Seguir hasta que lleguen todos

Cantado el ganador, la carrera no tiene por qué acabarse ahí: el cartel
de victoria ofrece seguirla para repartir el resto de puestos. Puede
quedar algún caballo sin llegar nunca —si las 9 cartas de su palo se
tendieron en la pista, no le queda ninguna con la que avanzar—, así que
la carrera se corta en cuanto los que faltan ya no pueden moverse, y esos
salen al final de la clasificación como rezagados.

## Campeonato

Se configura como la partida personalizada, más el número de rondas (de 2
a 10). Cada ronda es una carrera que se corre entera, y reparte tantos
puntos al primero como caballos haya —4, 3, 2 y 1 con la baraja
completa—; quien no llega no puntúa. Entre rondas se enseña el marcador y
se pasa a la siguiente sin volver a configurar nada. Gana el campeonato
quien más puntos sume, y si hay empate arriba se cantan todos.

Salir de una carrera en marcha —con la flecha de la barra o con el back
del sistema— pide confirmación antes de perder el progreso.

## Estructura

```
lib/
  models/      Carta, Palo, Baraja, Caballo y Jugador
  game/        Reglas de la carrera (LogicaJuego), marcador del campeonato
               y ajustes de la partida
  theme/       Paleta (tapete verde, botones rojo oscuro) y tema
  widgets/     Tapete, carta española, mazo, pista, controles, selector de
               palo y los carteles de victoria y clasificación
    paint/     Trazo vectorial de los 4 palos y de las 3 figuras
  screens/     Menú, catálogo de modos y mesa de juego
```

`LogicaJuego` no sabe nada de las modalidades: solo acepta qué palos
compiten (2 o más) y de cuántos pasos es la pista, y lleva la
clasificación de la carrera hasta donde dé de sí. `Campeonato` tampoco
sabe correr: solo recoge esa clasificación al final de cada ronda y suma.
La mesa, el cartel de victoria y la revancha son el mismo código en las
cuatro modalidades. Los jugadores con
nombre son puro adorno de la personalizada: no tocan las reglas, solo se
reparten los palos para saber a quién felicitar al final.

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
