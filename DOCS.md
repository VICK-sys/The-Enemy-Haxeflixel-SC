# Documentation

Code and data reference for THE ENEMY. Controls and build commands are in [README.md](README.md).

## Project layout

```
assets/
  data/enemies/*.json    enemy definitions
  data/waves.json        wave table
  default_auto.txt       arena collision map (CSV)
  auto_tiles.png         tileset for the collision map (not rendered)
  images/ music/ sounds/ art and audio
source/
  Main.hx                entry point
  states/                game states
  systems/               gameplay systems owned by PlayState
  entities/              sprites and components
  util/                  utilities
export/                  build output (not committed)
```

## States

- `TitleSequence` — intro logo. ENTER skips. Switches to PlayState when done.
- `PlayState` — constructs the systems in `create()`, calls them in order in `update()`, and handles the debug keys. It holds no gameplay logic of its own.

## Systems (source/systems/)

Each system is constructed once by PlayState and updated once per frame.

- `Arena` — loads the background and collision tilemap, sets world and camera bounds, generates pillar sprites from the map data, and answers `wallAt(x, y)`.
- `Fx` — hitstop (time scale drops for a few frames on kills), camera shakes, and hit spark bursts.
- `RenderLayers` — the shadow and entity render groups. The entity layer is sorted every frame by feet position so characters and pillars overlap correctly.
- `PlayerCombat` — player health, the AP meter, damage intake, invincibility frames and blink, dash input, death and revive. The HUD bars bind directly to its fields.
- `EnemyDirector` — spawns waves from the wave table, owns the per-enemy rigs (enemy, shadow, contact hitbox), runs enemy collision and cleanup, and updates enemy shots.
- `ScytheCombat` — scythe position and swing, facing flip, attack input, the slash projectile pool, and slash hit detection.
- `Hud` — the UI camera, health and AP bars, wave counter and banner, death text, and the custom cursor.

## Entities (source/entities/)

- `Player` — WASD movement with an acceleration ramp, dash, and the walk sound loop.
- `Enemies` — the one enemy class. Loads its definition from JSON by kind (`"enemy"`, `"woodster"`, `"likwid"`) and runs a three-state FSM: Wandering, Following, Attacking. Wave-spawned enemies start off screen in an entering mode that walks them through the border wall before collision turns on.
- `EnemyNav` — line-of-sight and pathfinding component. It rays the tilemap toward the target a few times per second; when the line is blocked it runs A* over the map and steers along the waypoints.
- `AttackBehavior`, `ChargeAttack`, `ShootAttack` — the attack style interface and its two implementations. A charge is a windup, a straight lunge, and a recovery. A shooter holds position, cycles its shoot animation, and requests a projectile on the loop frame.
- `SlashProjectile` — the player's pooled slash wave. It pierces enemies (one hit per enemy per wave) and dies on walls.
- `EnemyShot` — pooled enemy projectile. Carries its damage value from the shooter.
- `EnemyData` — the enemy JSON typedefs and a parse-once registry. Missing files throw with the path in the message.

## Utilities (source/util/)

- `Paths` — asset path builders: `image`, `sound`, `music`, `file`, `json`, and `sparrow` (returns the loaded atlas for a png/xml pair).

## Data

### Enemy definitions — assets/data/enemies/&lt;kind&gt;.json

| Field | Type | Meaning |
|---|---|---|
| `sprite` | String | Sparrow atlas name under `assets/images/` (png and xml pair) |
| `width`, `height` | Float | hitbox size in px |
| `offsetX`, `offsetY` | Float | sprite draw offset relative to the hitbox |
| `animations` | Array | `{name, prefix, fps, loop}` — `name` is what the code plays (`idle`, `walk`, `hurt`, `death`, and `sstart`/`sloop`/`send` for shooters), `prefix` is the atlas frame prefix |
| `hp` | Int | hits to kill |
| `speed` | Float | movement speed while chasing |
| `aggroRange` | Float | chasing starts inside this distance and ends outside it (wave spawns override it so they never stop chasing) |
| `stopThreshold` | Float | a chaser with line of sight stops approaching inside this distance |
| `attackRange` | Float | the attack starts inside this distance, line of sight required |
| `attack` | String | `"charge"` or `"shoot"` |
| `contactDamage` | Float | damage dealt to the player on contact |
| `shotDamage` | Float | optional, shooters only; damage per projectile |
| `shadowOffX`, `shadowOffXFlip`, `shadowOffY`, `shadowScaleX` | Float | shadow placement and width |
| `hitOffX`, `hitOffXFlip`, `hitOffY` | Float | placement of the 40x40 contact hitbox |

To add an enemy type: put an atlas under `assets/images/enemies/`, add a JSON file here, and reference its file name (without extension) from the wave table or a spawn call.

### Wave table — assets/data/waves.json

| Field | Meaning |
|---|---|
| `firstDelay` | seconds before wave 1 |
| `breather` | seconds between waves |
| `baseCount`, `countPerWave` | enemy count = baseCount + wave x countPerWave |
| `maxCount` | count cap |
| `waves` | array of `{types}` spawn pools; the first entry is wave 1, and the last entry repeats for every later wave. Repeat a type inside a pool to weight it. |

### Arena — assets/default_auto.txt

A CSV of `0` (open) and `1` (solid) tiles, 16 px each, loaded with flixel auto-tiling. The outer ring is the arena wall. Solid interior tiles become pillars: they block movement and projectiles, break line of sight, and Arena draws block sprites over them. The CSV is the only file to edit when changing arena geometry.

## Tuning

Feel constants are `static inline var`s at the top of the file that owns them.

| File | Constants |
|---|---|
| `systems/ScytheCombat.hx` | swing time, arc, scale pulse, aim smoothing, slash spawn distance, facing flip margin |
| `entities/SlashProjectile.hx` | slash speed, range, fade time, hit radius |
| `systems/PlayerCombat.hx` | health and AP maximums, dash cost, kill refund, iframe and hurt-lock times, knockback |
| `entities/ChargeAttack.hx` | charge windup, speed, duration, recovery |
| `entities/ShootAttack.hx` | shot windup, animation step, volley gap, disengage slack |
| `entities/Enemies.hx` | wander and idle durations, knockback taken, stun, flash |
| `entities/EnemyNav.hx` | waypoint radius; the repath interval is in `tick()` |
| `entities/EnemyShot.hx` | shot speed and range |
| `systems/EnemyDirector.hx` | off-screen entry margin |
| `entities/Player.hx` | move speed, run-up ramp, dash speed and duration |

## Builds

Windows native and HTML5 share the same source and assets. Commands are in [README.md](README.md).
