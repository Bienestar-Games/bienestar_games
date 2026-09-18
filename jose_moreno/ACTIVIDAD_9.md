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
| **Estado de barrera** | Indicador diagramático en bordes del mapa. Tres estados: cerrada / entreabierta / abierta (ver sección 10, pregunta 3). | *Por implementar* |
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

## 6. Esquema de Controles

> Rogers insiste en documentar los controles de forma explícita y temprana: un HUD bien diseñado es inútil si el mapeo de inputs no es legible ni consistente. Cada acción del loop necesita un input único y predecible.

| Acción | Teclado (PC) | Mando | Contexto de disponibilidad |
|---|---|---|---|
| Mover | `WASD` | Stick izquierdo | Siempre (excepto `on_inventory_state`) |
| Apuntar | Ratón | Stick derecho | `player_idle_state` / `moving` |
| Disparar | Clic izquierdo | Gatillo derecho (`RT`) | Requiere munición > 0 |
| Recargar | `R` | `X` / `Square` | Bloquea movimiento parcial (*por definir*) |
| Cambiar arma | Rueda de ratón / `1`-`2` | D-pad | Revolver ↔ Sawed-off Shotgun |
| Inventario | `E` | `Y` / `Triangle` | Alterna a `on_inventory_state` |
| Interactuar con barrera | `F` (mantener) | `A` / `Cross` (mantener) | Alterna a `interacting_barrier_state` |
| Confirmar extracción | `F` (mantener, en zona) | `A` / `Cross` (mantener) | Solo en `decision_state`, dentro del panel |
| Pausa | `Esc` | `Start` / `Options` | Siempre |

**Principio de diseño (Rogers):** ninguna acción crítica del loop de riesgo (abrir barrera, extraer) debe compartir input con una acción de combate reflejo (disparar, recargar). Mantener inputs de "decisión deliberada" (mantener presionado) separados de inputs de "reacción" (pulsación única) reduce errores del jugador bajo presión — coherente con el principio de "cada decisión tiene un costo visible" de la sección 1.

**Resuelto (ver sección 10, preguntas 2 y 12):** `interacting_barrier_state` requiere mantener el botón (fricción intencional, evita aperturas accidentales), no es un toggle instantáneo.

---

## 7. Flujo de Pantallas (Screen Flow)

> Rogers recomienda mapear *todas* las pantallas del juego —no solo el HUD in-game— como un diagrama de flujo, incluyendo menús, pausas y pantallas de transición. Esto expone estados faltantes antes de la implementación.

```
[TITLE SCREEN]
      |
      v
[MENÚ PRINCIPAL] ---> [AJUSTES] (audio, controles, accesibilidad)
      |          ---> [META-PROGRESIÓN] (árbol de mejoras, ver sección 10 de preguntas)
      |
      v
[INICIO DE CORRIDA] (carga refugio + estado inicial de barreras)
      |
      v
[HUD DE JUEGO] <------------------------------+
      |  (capas permanente + situacional)      |
      v                                        |
[OLEADA ANUNCIADA] -- preview parcial -->      |
      |                                        |
      v                                        |
[DEFENSA ACTIVA] <--> [INVENTARIO] (E, pausa parcial del ritmo, no del tiempo de juego)
      |                                        |
      v                                        |
[FIN DE OLEADA — decision_state]               |
  → Panel de extracción + preview siguiente    |
      |                                        |
      +--- CONTINUAR -------------------------->+  (vuelve a HUD DE JUEGO)
      |
      +--- EXTRAER --> [extracting_state]
                              |
                    (interrumpible por enemigo cercano — ver pregunta 9)
                              |
                              v
                    [PANTALLA DE RESULTADOS]
                    (loot conservado, mejoras desbloqueadas)
                              |
                              v
                    [MENÚ PRINCIPAL]

[MUERTE SIN EXTRACCIÓN] (desde cualquier punto de DEFENSA ACTIVA / decision_state)
      |
      v
[PANTALLA DE MUERTE] (loot de corrida perdido, mejoras previas conservadas)
      |
      v
[MENÚ PRINCIPAL]

[PAUSA] — accesible desde HUD DE JUEGO, INVENTARIO, FIN DE OLEADA
      |
      v
[MENÚ DE PAUSA] → Reanudar / Ajustes / Salir a Menú Principal
```

**Nota de implementación:** actualmente solo existen los estados de la capa táctica (`player_idle_state`, `moving`, `on_inventory_state`). Los estados `decision_state`, `extracting_state` e `interacting_barrier_state` (sección 2) son los nodos de este flujo que aún no tienen pantalla ni transición implementada. La pantalla de resultados y la pantalla de muerte tampoco están definidas en código — quedan como pendientes adicionales a las preguntas ya listadas.

---

## 8. Onboarding y Tutorial

> Principio de Rogers: *"enseña jugando, no leyendo"* — el tutorial ideal es la primera oleada diseñada específicamente para enseñar una mecánica a través de la necesidad, no un texto explicativo ni un pop-up.

| Mecánica a enseñar | Cómo se enseña jugando (propuesta) | Qué NO hacer |
|---|---|---|
| Combate básico (disparo, recarga) | Oleada 1 con enemigos lentos y escasos, munición generosa en el suelo | Texto explicando controles antes de dar el control al jugador |
| Inventario de 9 slots | Oleada 1-2 genera loot suficiente para casi llenar el inventario, sin forzar descarte aún | Tutorial modal que pausa el juego para explicar el inventario |
| Barrera como riesgo | Oleada 2 o 3: una barrera comprometida cercana, con daño bajo, para que el jugador vea el efecto sin morir por ello | Forzar al jugador a abrir la barrera manualmente en la primera corrida |
| Decisión de extracción | Primera ventana de decisión con panel de extracción simplificado y loot ya visible, sin exigir la decisión (el juego no penaliza continuar en la oleada 1) | Explicar el trade-off completo por texto antes de que el jugador lo sienta una vez |
| Death Border (medidor de riesgo acumulado) | Introducirlo visualmente (sube un poco) en la primera vez que el jugador abre una barrera, sin explicación textual — el icono + el cambio de audio comunican la idea | Mostrar un tooltip explicando "esto es tu riesgo acumulado" |

**Justificación:** el documento ya establece en la sección 5 que la experiencia buscada es *codicia con incertidumbre*, no optimización. Un tutorial verbal ("la barrera aumenta el riesgo un X%") rompe esa promesa desde el primer minuto. El onboarding debe replicar en miniatura la misma filosofía del HUD: mostrar consecuencias, no números.

---

## 9. Accesibilidad

> Rogers dedica atención explícita a que el HUD y los sistemas de feedback no dependan de un único canal sensorial — especialmente relevante aquí porque varias señales clave del documento (secciones 1 y 3) son puramente cromáticas o sonoras.

| Área | Riesgo actual del diseño | Mitigación propuesta |
|---|---|---|
| Daltonismo | Barra de salud verde→amarillo→rojo; borde de pantalla "enrojecido" para barrera comprometida | Añadir un segundo indicador no cromático: parpadeo, forma del icono, o texto numérico opcional en la barra de salud |
| Dependencia de audio | La escalada de la alarma (barrera abierta) y el silencio tenso (ventana de decisión) comunican estado sin equivalente visual explícito | Reforzar con el borde de pantalla pulsante (ya existe) como redundancia visual permanente, no solo cuando el borde está "comprometido o abierto" |
| Legibilidad bajo estrés | El preview de oleada es intencionalmente ambiguo (sección 5) — esto es una decisión de diseño, no un problema de accesibilidad, pero el indicador de riesgo (bajo/medio/alto/extremo) debe tener suficiente contraste y tamaño para leerse en el momento de tensión | Usar iconografía + color + posición fija, nunca solo color |
| Remapeo de controles | Tabla de la sección 6 asume layout fijo | Exponer remapeo completo en `[AJUSTES]` (ver sección 7), incluyendo la opción de mantener vs. alternar para "Interactuar con barrera" |
| Escalado de UI | No mencionado en el documento original | Definir un rango mínimo de escalado de HUD (ej. 80%-150%) para distintas resoluciones y distancias de pantalla |

**Nota:** estas mitigaciones son deliberadamente compatibles con la Opción B del trade-off de la sección 5 (preview parcial) — accesibilidad no implica dar más información al jugador, implica que la información *decidida* llegue de forma fiable a más jugadores.

---

## 10. Decisiones de Diseño (Resueltas)

> Cada decisión se justifica contra los dos pilares ya fijados en el documento: **(a)** el riesgo debe *sentirse*, no calcularse (sección 5), y **(b)** cada decisión tiene un costo visible (sección 1). Donde una opción "objetivamente más completa" contradice esos pilares, se descarta a favor de la ambigüedad controlada.

### Barreras

**1. ¿Cuántas barreras tiene el refugio? ¿Independientes o sistema global?**
**Decisión:** Barreras múltiples e independientes — 3 a 4, una por sector del refugio. No es una sola decisión global.
**Justificación:** El documento ya habla de "¿abrir barrera? ¿cuánto?" (sección 2) y de un indicador de barrera "en bordes del mapa" (plural, sección 1). Una única barrera global reduce la decisión a un binario simple; con varias barreras el jugador reparte el riesgo espacialmente (¿qué sector sacrifico?), lo que multiplica la superficie de la apuesta sin añadir un solo número visible.

**2. ¿Cómo interactúa el jugador con ellas?**
**Decisión:** Tecla de acción al acercarse, manteniendo presionado (`F` / `A`-`Cross`), sin panel de menú. Ver sección 6.
**Justificación:** Mantener la interacción diegética (física, en el mundo) refuerza que abrir una barrera es un acto deliberado dentro del combate, no una decisión administrativa de menú. El "mantener" introduce fricción intencional: exige que el jugador se exponga unos segundos extra para tomar la decisión, lo cual es coherente con el resto del sistema de riesgo.

**3. ¿Puede abrirse parcialmente, o solo cerrada/abierta?**
**Decisión:** Tres estados discretos — **cerrada / entreabierta / abierta** — no un slider continuo.
**Justificación:** Un control continuo (0-100%) invita al jugador a *calcular* un punto óptimo, lo que rompe el pilar (a). Tres estados discretos dan granularidad suficiente para que la decisión no sea binaria, pero mantienen la naturaleza de apuesta: el jugador elige una categoría de riesgo, no un porcentaje exacto.

### Oleadas y escalada

**4. ¿Cómo escalan las oleadas?**
**Decisión:** Multiplicador único de "nivel de amenaza" que combina cantidad y tipo de enemigo, compuesto por dos factores: escalada base por número de oleada + escalada adicional por cada barrera abierta/entreabierta activa.
**Justificación:** Un solo multiplicador configurable es más fácil de balancear en playtesting (sección 4) que curvas independientes de cantidad y tipo, y permite que el indicador de riesgo del preview (sección 5) se derive de un único valor interno sin exponerlo directamente al jugador.

**5. ¿Límite máximo de oleadas o infinito?**
**Decisión:** Infinito — no hay techo de oleadas. La única salida "ganadora" de una corrida es la extracción; la muerte es la única salida forzada.
**Justificación:** Un límite fijo convierte la pregunta de diseño en "¿llego a la oleada N?" en vez de "¿cuánto aguanto?". El formato infinito mantiene la tensión de pérdida (sección 3) como el único techo real de cada corrida.

### Loot

**6. ¿Cuántos niveles de rareza?**
**Decisión:** Cuatro niveles — Común / Poco común / Raro / Épico.
**Justificación:** Es el número mínimo que permite una curva de rareza legible por color (ya mencionada en sección 1, "loot con borde de color por rareza") sin saturar la lectura rápida durante combate. Coincide con el estándar del género (extraction/horde shooters) y facilita el playtest del riesgo de diseño principal (sección 4), que depende de que el jugador distinga loot de "rareza superior" de un vistazo.

**7. ¿Solo armas/equipo, o también consumibles, recursos, moneda?**
**Decisión:** El pool de loot incluye armas/equipo, consumibles (curación) y recursos de mejora (moneda de meta-progresión). No hay una moneda separada fuera del inventario de 9 slots — el recurso de mejora ocupa espacio como cualquier otro ítem.
**Justificación:** Si la moneda de progresión no compite por espacio de inventario, deja de alimentar la "presión de inventario" descrita en la sección 3 ("cada item nuevo desplaza a otro"). Que el recurso de mejora también sea descartable bajo presión es, en sí mismo, parte de la tensión de codicia.

### Extracción

**8. ¿Punto físico o menú entre oleadas?**
**Decisión:** Híbrido. El panel de extracción (información: loot seguro vs. potencial) aparece en `decision_state` entre oleadas, pero **confirmar** la extracción exige que el jugador esté físicamente en la zona de extracción del mapa.
**Justificación:** Esto ya estaba implícito en la sección 6 (`Confirmar extracción — en zona`) y en el flujo de la sección 7 (`decision_state → extracting_state`). El panel da la información necesaria para decidir sin calcular a ciegas (pilar a), pero la ejecución física mantiene el riesgo activo hasta el último segundo — el jugador puede decidir extraer y aun así no llegar a tiempo.

**9. ¿Animación/secuencia interrumpible?**
**Decisión:** Sí. La extracción es un canalizado de 5-8 segundos que se cancela si el jugador recibe daño o un enemigo entra en un radio mínimo de la zona.
**Justificación:** Una extracción instantánea elimina el último momento de tensión de la corrida. Hacerla interrumpible convierte el tramo final en la apuesta más concentrada del loop — coherente con el título del juego y con el Death Border como frontera entre codicia y ruina (sección 3).

### Meta-progresión

**10. ¿Qué mejoras permanentes existen entre corridas?**
**Decisión:** Las tres en conjunto, con esta prioridad de implementación: (1) mejoras de estadísticas base (`MAX_SPEED`, `base_health`) — las más simples de implementar sobre el código existente; (2) desbloqueo de armas nuevas; (3) árbol de habilidades ligero (pasivas menores) como capa final, no núcleo del sistema.
**Justificación:** Empezar por estadísticas base reutiliza sistemas que ya existen en `BaseCharacter` (sección 1), permitiendo validar el loop completo (sección 4) antes de invertir en un árbol de habilidades más costoso de balancear.

### Death Border como UI

**11. ¿Medidor en HUD o ambiental/narrativo?**
**Decisión:** Ambos, pero con el elemento ambiental como capa principal: vignette de pantalla que se intensifica y música que se degrada progresivamente, reforzado por un ícono mínimo no numérico en el HUD (sin cifra exacta).
**Justificación:** Un medidor numérico puro invita a calcular un umbral seguro, violando el pilar (a). Lo ambiental comunica "cuánto hay en juego" de forma sensorial, coherente con el resto de canales de feedback de la sección 1 (audio, flash de pantalla). El ícono en HUD es solo un recordatorio de que el sistema existe, no una herramienta de cálculo.

### Controles y onboarding

**12. ¿Mantener presionado o toggle para interactuar con barrera?**
**Decisión:** Mantener presionado. (Resuelve directamente la pregunta 2.)

**13. ¿Soporte de mando desde el lanzamiento?**
**Decisión:** Sí, paridad de mando desde el lanzamiento. El teclado/ratón se mantiene como input de referencia para el balanceo de precisión de apuntado, pero ambos esquemas se documentan y prueban desde el prototipo mínimo (sección 4).
**Justificación:** El género de horde/extraction shooter tiene una base de jugadores de consola/mando significativa; retrasar el soporte de mando a una fase posterior obligaría a rediseñar la sección 6 más adelante.

**14. ¿La primera corrida es "gratuita"?**
**Decisión:** Sí. La oleada 1 no penaliza al jugador por no extraer (tal como ya se especifica en la sección 8, tabla de onboarding). Desde la oleada 2 en adelante, el juego es completamente punitivo — la muerte pierde el loot de la corrida sin excepción.
**Justificación:** Es la única forma de enseñar el trade-off de extracción sin romper el pilar (a) con un texto explicativo. El costo de esta gratuidad es mínimo porque solo afecta a una oleada por partida nueva.

---

*Documento base — v0.3. Resueltas las 14 preguntas pendientes en la sección 10, con referencias cruzadas actualizadas en las secciones 1 y 6. Documento de UI/Interacción/Riesgo considerado completo en su especificación de alto nivel; quedan pendientes de detalle los valores numéricos exactos de balanceo (curvas de escalada, duración del canalizado de extracción, radio de interrupción), a resolver en el prototipo mínimo de la sección 4.*
