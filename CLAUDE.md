# CLAUDE.md

Guía para trabajar en este repositorio. Responder al equipo en español.

## Idioma

**Todo lo que se produzca para el juego va en inglés**:
- Código: identificadores, nombres de archivos y carpetas, nodos, señales, acciones del InputMap.
- Comentarios y documentación del código (`##` docstrings).
- Mensajes de commit, ramas, títulos y descripciones de PR.
- Documentación nueva en `docs/`.
- Textos de UI del juego.

Excepciones, que se quedan en español: el GDD (`gdd/`), las carpetas personales de actividades y este `CLAUDE.md`.

## Proyecto

**Death Border**: un horde-extraction shooter top-down 2D hecho en **Godot 4** (GDScript). El diseño está en [`gdd/v1.md`](gdd/v1.md) y es la fuente de verdad. El backlog está en GitHub Projects / Issues (`[B01]`…`[B42]`), y cada issue cita la sección del GDD de la que sale.

Antes de implementar algo, revisa:
- **§8 MVP**: qué entra en el prototipo (1 barrera, solo 2 estados, 3 rarezas, 2 enemigos, extracción de 5 s).
- **§9 Fuera del MVP**: qué **no** se implementa todavía (barrera entreabierta, varias barreras, rareza Épica, meta-progresión, consumibles activos, audio del Death Border, menús completos).
- **§15 Decisiones resueltas**: no las vuelvas a discutir en el código.

Pilares que debe respetar cualquier sistema:
1. El riesgo se **siente**, no se calcula. Nunca muestres números exactos de amenaza, riesgo ni Death Border.
2. Cada decisión tiene un **costo visible**.
3. Las acciones deliberadas (abrir la barrera, extraer) se hacen **manteniendo** un botón y nunca comparten input con las de combate.

## Estructura del repositorio

```
bienestar_games/
├── CLAUDE.md
├── README.md                 # presentación del equipo
├── gdd/                      # documento de diseño (v1.md = vigente)
├── game/                     # ← proyecto Godot 4 (project.godot vive aquí)
├── docs/                     # sprint reviews, retrospectivas, burndown, playtests
│   └── playtests/            # registros de la tabla de validación §8 (B13, B28, B39)
├── builds/                   # exportaciones locales (ignorado por git)
├── jose_moreno/  Juan_Pablo/  Perez_Collas/  Heriberto Cruz/
│                             # actividades individuales del curso: NO tocar
```

El proyecto Godot vive en `game/` para no mezclarse con las carpetas personales. Abrir siempre `game/project.godot`. Todas las rutas `res://` de abajo son relativas a `game/`.

> El proyecto se empieza **desde cero**. Las clases que el GDD marca como "ya implementadas" (`BaseCharacter`, `Weapon`, `Magazine`, `InventoryController`, `EnemySpawnZone`, estados del jugador) vienen de otro proyecto y aquí hay que construirlas. Para mover archivos usa siempre el editor de Godot (FileSystem → arrastrar), así se actualizan las referencias y los UIDs.

## Estructura del proyecto Godot (`game/`)

Organización **por funcionalidad**: cada escena va junto a su script (`foo.tscn` + `foo.gd` en la misma carpeta). En `scripts/` solo va código compartido que no pertenece a una escena concreta.

```
game/
├── project.godot
├── assets/                          # archivos importados en bruto (png, wav, ttf…). Sin lógica.
│   ├── sprites/{player,enemies,weapons,bullets,loot}/
│   ├── environment/{tiles,tilesheets,props,textures}/
│   ├── effects/
│   ├── ui/{icons,elements,buttons,art}/
│   ├── audio/{sfx,music}/
│   ├── fonts/
│   └── kenney/                      # packs de Kenney tal cual se descargan + licencia (B02)
│
├── resources/                       # .tres reutilizables / datos editables desde el inspector
│   ├── config/
│   │   └── balance_config.tres      # B20: cantidades, velocidades, daño, bonos (@export)
│   ├── items/                       # B21: un ItemData .tres por ítem (con rareza)
│   ├── loot_tables/                 # B31: tablas ponderadas por amenaza
│   ├── tilesets/                    # TileSet del refugio (graybox, B03)
│   ├── navigation_polygons/
│   ├── shaders/                     # vignette del Death Border (B35), flash de daño (B37)
│   ├── materials/
│   └── fonts/
│
├── scenes/
│   ├── main/                        # main.tscn: escena raíz que instancia mapa + HUD + managers (B38)
│   ├── maps/
│   │   └── shelter/                 # shelter.tscn (refugio): TileMap, colisiones, NavigationRegion2D (B03)
│   ├── entities/
│   │   ├── base_character.gd        # class_name BaseCharacter (base_health, daño, muerte)
│   │   ├── player/                  # Kade: player.tscn/.gd, sprite frames
│   │   └── enemies/
│   │       ├── enemy.gd/.tscn       # base del enemigo melee
│   │       ├── melee_basic/         # B07: lento
│   │       └── melee_fast/          # B19: más velocidad y daño, desde la oleada 3
│   ├── weapons/
│   │   ├── weapon.gd                # class_name Weapon
│   │   ├── revolver/
│   │   ├── sawed_off_shotgun/
│   │   ├── magazine/
│   │   └── bullets/
│   ├── world/                       # objetos interactivos del mapa
│   │   ├── barrier/                 # B04, B15, B16: barrera + punto de spawn propio (B18)
│   │   ├── extraction_zone/         # B32: zona física de extracción
│   │   ├── enemy_spawn_zone/        # EnemySpawnZone
│   │   └── loot_pickup/             # B09: ítem en el suelo con borde por rareza
│   ├── inventory/                   # InventoryController + InventorySlot (9 slots)
│   └── ui/
│       ├── hud/                     # B10, B11, B26: salud, munición, arma, oleada, barrera
│       ├── death_border/            # B35: vignette + icono no numérico
│       ├── decision_panel/          # B25, B34: panel de extracción + preview de oleada
│       ├── extraction_progress/     # B33: barra del canalizado
│       ├── pause_menu/              # B27
│       ├── death_screen/            # B12
│       └── results_screen/          # B36
│
├── scripts/                         # código compartido, sin escena propia
│   ├── autoload/                    # singletons registrados en Project Settings → Autoload
│   │   ├── game_loop_manager.gd     # B22: oleada → decision_state → siguiente oleada
│   │   ├── wave_manager.gd          # B08, B17: spawn por oleada y detección de fin
│   │   ├── threat_manager.gd        # B29, B30: multiplicador de amenaza → bajo/medio/alto/extremo
│   │   └── events.gd                # bus de señales globales (run_ended, wave_started, barrier_opened…)
│   ├── components/                  # nodos reutilizables: hit_box.gd, hurt_box.gd, interior_zone.gd
│   ├── data/                        # clases Resource: item_data.gd, balance_config.gd, loot_table.gd
│   └── states/
│       ├── state.gd
│       ├── state_machine.gd
│       ├── player/                  # idle, moving, on_inventory, decision (B23),
│       │                            # extracting (B32), interacting_barrier (B15)
│       ├── enemy/                   # idle, moving, chasing, searching, attacking, attack_recovery
│       └── weapon/                  # idle, shooting, reloading
│
└── tests/                           # escenas de prueba aisladas (sandbox de un sistema)
```

### Dónde va cada cosa

| Si vas a crear…                          | Va en                                   |
| ---------------------------------------- | --------------------------------------- |
| Una escena con su script                 | `scenes/<área>/<nombre>/`               |
| Un estado nuevo de la máquina de estados | `scripts/states/{player,enemy,weapon}/` |
| Un sistema global (una sola instancia)   | `scripts/autoload/` + registrarlo       |
| Un nodo reutilizable sin escena          | `scripts/components/`                   |
| Una clase `Resource` (definición)        | `scripts/data/`                         |
| Una instancia `.tres` de esa clase       | `resources/<tipo>/`                     |
| Un valor de balance (números)            | `resources/config/balance_config.tres`. **Nunca** hardcodeado en el script. |
| Un png/wav/ttf                           | `assets/<tipo>/`                        |

## Convenciones

### Nombres
- **Archivos y carpetas**: `snake_case` (`melee_fast.tscn`, `game_loop_manager.gd`). Sin mayúsculas, espacios ni acentos.
- **`class_name`**: `PascalCase` (`BaseCharacter`, `ItemData`, `WaveManager`).
- **Nodos en escena**: `PascalCase` (`HitBox`, `NavigationAgent2D`, `HealthBar`).
- **Señales**: en pasado y `snake_case` (`died`, `wave_ended`, `barrier_opened`, `extraction_cancelled`).
- **Estados**: `<entidad>_<estado>_state.gd` (`player_decision_state.gd`, `enemy_chasing_state.gd`).
- **Constantes**: `UPPER_SNAKE_CASE`. **Variables y funciones privadas**: con prefijo `_`.

### Escenas
- Una escena = una responsabilidad. Instancia las escenas, no copies nodos.
- La comunicación hacia arriba se hace con **señales**, y la comunicación entre sistemas lejanos con el bus `Events`. Nada de `get_node("../../..")`.
- Las escenas de UI no tienen lógica de juego: leen el estado mediante señales.
- La escena principal (`run/main_scene`) es `scenes/main/main.tscn`.

### Input
Todas las acciones se definen en el **InputMap**, nunca con teclas directas en el código. Los nombres siguen la §11 del GDD: `move_*`, `aim_*`, `shoot`, `reload`, `weapon_next`, `weapon_1`, `weapon_2`, `inventory`, `interact` (mantener), `pause`. Cada acción debe tener su equivalente de mando (B24).

### Ramas y commits
- `main`: solo versiones estables y entregas (etiquetas `v0.1-prototipo`…).
- `dev`: integración. Todos los PR apuntan aquí.
- Ramas de trabajo: `feature/B<nn>-short-description` (p. ej. `feature/B15-barrier-interaction`), `fix/B<nn>-...`, `docs/...`.
- Commits **convencionales** (Conventional Commits) con el formato `type: description (#issue)`, en inglés:
  - `feat`: funcionalidad nueva · `fix`: corrección de bug · `refactor`: cambio de código sin cambio de comportamiento
  - `docs`: documentación · `chore`: configuración, estructura, assets · `test`: escenas de prueba
  - Ejemplo: `feat: hold F to open barrier (#15)`.
- Para evitar conflictos en `.tscn`, no editen la misma escena en dos ramas a la vez. Coordinen en la issue quién toca `main.tscn` y `shelter.tscn`.

### Git y Godot
- `.gitignore` dentro de `game/`: `.godot/`, `*.translation`, `export_credentials.cfg`; en la raíz: `builds/`.
- Sí se versionan los `.import` y los `.uid`.
- Las carpetas vacías llevan un `.gitkeep` hasta que tengan contenido.

## Notas técnicas
- Renderer: el objetivo es PC (§1). Hay que confirmar `Forward+` o `Compatibility` antes de exportar (B41).
- Los valores numéricos de balance aún no están definidos (ver cierre del GDD). Empiecen con los del MVP §8 en `balance_config.tres` y ajústenlos tras el playtest (B40).
