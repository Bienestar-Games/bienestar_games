# DEATH BORDER — Documento de Diseño: UI, Interacción y Riesgo

> **Nota:** Este documento está en español por solicitud explícita del equipo. El resto del repositorio mantiene inglés como idioma estándar (ver CLAUDE.md).

---

## 1. Concepto de UI / HUD

### Filosofía de información

El HUD refuerza la tensión núcleo del juego: **cada decisión tiene un costo visible**. La información se organiza en tres capas de urgencia:

1. **Permanente** — lo que siempre se necesita (salud, munición, arma activa).
2. **Situacional** — lo que se necesita al tomar decisiones durante la oleada (estado de barrera, enemigos restantes).
3. **Decisional** — lo que contextualiza la codicia entre oleadas (loot acumulado, riesgo estimado, opción de extracción).

### Elementos del HUD

#### Capa permanente (siempre visible)

| Elemento | Descripción | Base en código |
|---|---|---|
| **Barra de salud** | HP de Kade, 100 base. Cambia de color: verde → amarillo (< 50%) → rojo (< 25%). | `base_health` en `BaseCharacter` |
| **Contador de munición** | `[balas_restantes / capacidad]` junto al cursor o esquina inferior derecha. | `Magazine.consume_bullet()`, `is_empty()` |
| **Arma activa** | Icono del arma equipada (Revolver / Sawed-off Shotgun). | Sistema de `Weapon` + `Equippable` |

#### Capa situacional (durante oleada)

| Elemento | Descripción | Base en código |
|---|---|---|
| **Contador de oleada** | Oleada actual + enemigos vivos restantes. | `EnemySpawnZone._total_enemies` |
| **Estado de barrera** | Indicador diagramático en bordes del mapa (cerrada / abierta / comprometida). | *Por implementar* |
| **Indicador del Death Border** | Medidor de riesgo acumulado en la corrida. Sube cada vez que el jugador abre una barrera. Funciona como presión narrativa y recuerda cuánto hay en juego. | *Por implementar* |

#### Capa decisional (entre oleadas)

| Elemento | Descripción | Base en código |
|---|---|---|
| **Preview de siguiente oleada** | Tipo general de amenaza + indicador de riesgo (bajo / medio / alto / extremo). Sin números exactos — el jugador apuesta, no calcula. | *Por implementar* |
| **Panel de extracción** | Muestra loot seguro si extrae ahora vs. loot potencial si continúa, con el indicador de riesgo estimado de la siguiente oleada. | *Por implementar* |
| **Inventario** | 9 slots (tecla `E`), ya implementado. Feedback visual cuando está lleno. | `InventoryController` |

### Canales de feedback

| Canal | Señal | Disparador |
|---|---|---|
| Visual | Flash rojo en pantalla | Recibir daño |
| Visual | Parpadeo de barra de salud | HP < 30% |
| Visual | Borde de pantalla enrojecido / pulsante | Barrera comprometida o abierta |
| Visual | Loot con borde de color por rareza | Item de alta calidad en suelo |
| Visual | Slots de inventario parpadeando en rojo | Inventario lleno al intentar recoger |
| Audio | Alarma de baja intensidad → alta | Barrera abierta; sube con tiempo en riesgo |
| Audio | Silencio relativo + música tensa | Entre oleadas (ventana de decisión) |
| Audio | Sonido de confirmación | Extracción iniciada |

---

## 2. Loop Principal de Interacción

```
[INICIO DE CORRIDA]
        |
        v
[OLEADA ANUNCIADA]
  → Preview: tipo de amenaza + indicador de riesgo estimado
  → Decisión del jugador: ¿abrir barrera? ¿cuánto?
        |
        v
[DEFENSA ACTIVA]
  → Combate (Revolver / Sawed-off Shotgun)
  → Gestión de inventario de 9 slots (E)
  → Recolección de loot con descarte forzado si está lleno
        |
        v
[FIN DE OLEADA — ventana de decisión]
  → A) EXTRAER → conservar loot → fin de corrida → meta-progresión
  → B) CONTINUAR → siguiente oleada (escalada de dificultad)
        |                              |
        v                              v
[EXTRACCIÓN EXITOSA]         [MUERTE SIN EXTRACCIÓN]
  → Loot conservado             → Loot de corrida perdido
  → Mejoras permanentes         → Mejoras permanentes previas
    desbloqueadas                  conservadas
  → Nueva corrida               → Nueva corrida
```

### Estados del jugador en el loop

El sistema de estados existente cubre la capa táctica de combate:

- `player_idle_state` / `moving` → movimiento y combate
- `on_inventory_state` → gestión de loot (tecla `E`)

**Estados por implementar para el loop completo:**

- `decision_state` — pausa entre oleadas, muestra panel de extracción y preview
- `extracting_state` — animación/secuencia de extracción en curso
- `interacting_barrier_state` — interacción con una barrera del refugio

---

## 3. Dinámicas y Regulación por UI

| Dinámica | Cómo la UI la regula |
|---|---|
| **Codicia de loot** | El panel de extracción muestra el valor acumulado vs. el riesgo estimado de continuar. El jugador ve el costo de la codicia antes de comprometerse. |
| **Control de barreras** | El indicador de barrera siempre visible no permite ignorar las consecuencias de haberla abierto. El borde de pantalla pulsante recuerda la exposición activa. |
| **Presión de inventario** | 9 slots con feedback de llenado fuerzan decisiones de descarte. Añaden peso emocional a cada recogida: cada item nuevo desplaza a otro. |
| **Escalada de dificultad** | El preview de oleada muestra la escalada antes de que el jugador se comprometa. La decisión de abrir/cerrar barrera es informada, no puramente reactiva. |
| **Tensión de pérdida** | El indicador del Death Border acumula el riesgo elegido por el jugador. Recuerda cuánto hay en juego en cada oleada extra — la frontera entre codicia y ruina es visible. |

---

## 4. Principal Riesgo de Diseño

### Riesgo: La decisión de barrera pierde peso si el loot no escala de forma legible

**Descripción:**
La mecánica núcleo es que el jugador *elige cuánta amenaza dejar entrar*. Si no puede leer con claridad la diferencia entre "abrir la barrera al 50%" y "abrirla completamente", la decisión se convierte en ruido aleatorio, no en una apuesta calculada. Esto destruye la tensión de riesgo/recompensa y reduce el juego a un horde shooter genérico.

**Por qué es el mayor riesgo actual:**
El sistema de oleadas (`EnemySpawnZone`) hoy es estático — carga enemigos hijos prefijados en el editor. No existe sistema de escalado dinámico, ni clasificación de loot por rareza, ni la barrera como mecánica de código. Son tres sistemas ausentes que deben funcionar en conjunto para que la propuesta de valor del juego sea real.

**Cómo validarlo con un prototipo mínimo:**

1. Implementar una barrera simple (toggle abre/cierra, sin arte final) con dos estados:
   - **Cerrada** → oleada estándar.
   - **Abierta** → +50% enemigos, +1 drop de loot de rareza superior.
2. Añadir un contador visible de "loot de alta rareza conseguido esta corrida".
3. Playtest interno de 5 sesiones con la pregunta: ¿el jugador abre la barrera voluntariamente? ¿En qué oleada? ¿Lo repite?

**Criterios de ajuste:**
- Si el jugador **nunca** abre la barrera → la recompensa no justifica el riesgo: subir la curva de loot.
- Si el jugador **siempre** la abre desde la primera oleada → el riesgo no es percibido como real: subir el daño/velocidad de los enemigos que entran.
- **Objetivo:** el jugador duda en la oleada 3-4 antes de decidir abrir la barrera por primera vez.

---

## 5. Trade-off Explícito

**Información completa vs. tensión de incertidumbre en el preview de oleada**

| | Opción A — Preview completo | Opción B — Preview parcial (recomendada) |
|---|---|---|
| **Qué ve el jugador** | Tipo exacto de enemigos, cantidad, loot garantizado | Tipo general de amenaza + indicador de riesgo (bajo / medio / alto / extremo) |
| **Tipo de decisión** | Calculada, estratégica | Emocional, una apuesta |
| **Experiencia resultante** | Optimización matemática | Codicia con incertidumbre — la tensión de "¿cuánto aguanto?" |
| **Riesgo** | Elimina la adrenalina núcleo | La derrota puede sentirse injusta si el indicador no es fiable |

**Decisión: Opción B — Preview parcial.**

**Justificación:** La experiencia buscada es codicia y tensión, no planificación táctica. Un preview completo convierte cada decisión en un cálculo con respuesta correcta, eliminando la apuesta. El jugador debe *sentir* el riesgo, no computarlo. El indicador de riesgo estimado (bajo / medio / alto / extremo) provee legibilidad mínima para que ninguna derrota se sienta completamente ciega — el jugador siempre supo que el riesgo era "extremo" y eligió igualmente.

---

## Preguntas pendientes para cerrar el documento

Las siguientes respuestas determinarán el diseño de detalle de los sistemas de barrera, loot y extracción:

### Barreras
1. ¿Cuántas barreras tiene el refugio? ¿Son independientes (cada una controla un sector) o es un sistema global (una sola decisión)?
2. ¿Cómo interactúa el jugador con ellas? (tecla de acción al acercarse, panel de UI, toggle desde el HUD)
3. ¿La barrera puede abrirse parcialmente, o solo hay dos estados: cerrada / abierta?

### Oleadas y escalada
4. ¿Las oleadas escalan por cantidad de enemigos, por tipo (más resistentes), por ambos, o hay un multiplicador de "nivel de amenaza" configurable?
5. ¿Existe un límite máximo de oleadas, o es infinito hasta que el jugador extrae o muere?

### Loot
6. ¿Cuántos niveles de rareza planeas? (ej. común / poco común / raro / épico)
7. ¿El loot incluye solo armas y equipo, o también consumibles, recursos de mejora, o moneda entre corridas?

### Extracción
8. ¿La extracción ocurre en un punto físico del mapa (zona marcada) o es un menú que aparece entre oleadas?
9. ¿Hay una animación/secuencia de extracción que el jugador pueda interrumpir si llega un enemigo?

### Meta-progresión
10. ¿Qué tipo de mejoras permanentes existen entre corridas? (árbol de habilidades, estadísticas base como `MAX_SPEED` / `base_health`, desbloqueo de armas nuevas)

### Death Border como UI
11. ¿El indicador del Death Border es un medidor en el HUD, o es ambiental/narrativo (efectos visuales en el mapa, música que se degrada)?

---

*Documento base — v0.1. Pendiente de respuestas en sección de preguntas para completar especificación de detalle.*
