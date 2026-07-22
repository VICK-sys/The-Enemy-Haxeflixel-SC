# Documentation

Code and data reference for THE ENEMY. Controls and build commands are in [README.md](README.md).

## Project layout

```
assets/
  data/enemies/*.json    enemy definitions
  data/waves.json        wave table
  data/player.json       player stats
  data/arena.json        arena definition
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
- `PauseSubState` — opened with ESC. Freezes the game and pauses all audio, dims the screen, closes on ESC. Volume keys work while open.

## Systems (source/systems/)

Each system is constructed once by PlayState and updated once per frame.

- `Arena` — loads the background and collision tilemap, sets world and camera bounds, generates pillar sprites from the map data, and answers `wallAt(x, y)`.
- `Fx` — hitstop (time scale drops for a few frames on kills), camera shakes, and hit spark bursts.
- `RenderLayers` — the shadow and entity render groups. The entity layer is sorted every frame by feet position so characters and pillars overlap correctly.
- `PlayerCombat` — player health, the AP meter, damage intake, invincibility frames and blink, dash input, death and revive. The HUD bars bind directly to its fields.
- `EnemyDirector` — spawns waves from the wave table, owns the per-enemy rigs (enemy, shadow, contact hitbox), runs enemy collision and cleanup, and updates enemy shots.
- `ScytheCombat` — scythe position and swing, facing flip, the Q mode toggle (swing or throw), attack input, the slash projectile pool, and the shared hit pipeline (hit sound, sparks, kill rewards, drops). Delegates the throw to ThrowAttack.
- `ThrowAttack` — the boomerang throw: thrown scythe flight (out leg, wall turnaround, homing return, catch), its afterimage trail, and the spin sound loop. The player cannot attack while the scythe is airborne.
- `Pickups` — the health pickup pool. Collected on player contact unless health is full.
- `Hud` — the UI camera, health and AP bars, wave counter and banner, death text with the best wave, and the custom cursor.

## Entities (source/entities/)

- `Player` — WASD movement with an acceleration ramp, dash, and the walk sound loop.
- `Enemies` — the one enemy class. Loads its definition from JSON by kind (`"enemy"`, `"woodster"`, `"likwid"`) and runs a three-state FSM: Wandering, Following, Attacking. Wave-spawned enemies start off screen in an entering mode that walks them through the border wall before collision turns on.
- `EnemyNav` — line-of-sight and pathfinding component. It rays the tilemap toward the target a few times per second; when the line is blocked it runs A* over the map and steers along the waypoints.
- `AttackBehavior`, `ChargeAttack`, `ShootAttack` — the attack style interface and its two implementations. A charge is a windup, a straight lunge, and a recovery. A shooter holds position, cycles its shoot animation, and requests a projectile on the loop frame.
- `SlashProjectile` — the player's pooled slash wave. It pierces enemies (one hit per enemy per wave) and dies on walls.
- `EnemyShot` — pooled enemy projectile. Carries its damage, speed, and range from the shooter.
- `ThrownScythe` — the airborne scythe. Spins, stretches on release, throbs in flight, and hits each enemy once per flight leg (out and return).
- `HealthPickup` — dropped heart. Restores health on contact, expires after a few seconds.
- `EnemyData`, `PlayerData` — JSON typedefs and parse-once registries for their data files.

## Utilities (source/util/)

- `Paths` — asset path builders: `image`, `sound`, `music`, `file`, `json`, and `sparrow` (returns the loaded atlas for a png/xml pair).
- `DataLoader` — reads and parses a JSON asset; throws with the path in the message if the file is missing.
- `SaveData` — persistent save (best wave reached).

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
| `shotDamage`, `shotSpeed`, `shotRange` | Float | shooters only (`shotSpeed`/`shotRange` optional); projectile damage, speed, and range |
| `dropChance` | Float | chance from 0 to 1 of dropping a health pickup on death |
| `knockback`, `knockbackDrag`, `stunTime` | Float | optional; knockback taken when hit, its decay, and stun duration |
| `wanderSpeed` | Float | optional; walking speed while wandering |
| `chargeWindup`, `chargeSpeed`, `chargeTime`, `chargeRecover` | Float | optional, chargers only; charge attack overrides |
| `shootWindup`, `shootStep`, `shootGap`, `shootDisengage` | Float | optional, shooters only; shoot cycle overrides |
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

### Player — assets/data/player.json

| Field | Meaning |
|---|---|
| `moveSpeed` | top movement speed |
| `rampStart`, `rampRate`, `rampReset` | run-up: starting speed, gain per second, and the value it resets to after standing still |
| `drag` | slowdown when no key is held |
| `dashSpeed`, `dashTime`, `dashCost`, `dashIframes` | dash speed, duration, AP cost, and invincibility window |
| `healthMax`, `apMax` | meter maximums |
| `apPerKill` | AP refunded per kill |
| `iframeTime`, `hurtLockTime` | invincibility and movement-lock time after taking a hit |
| `knockback` | knockback taken when hit |

### Arena — assets/data/arena.json

| Field | Meaning |
|---|---|
| `background` | stage image name under `assets/images/` |
| `map`, `tiles` | collision CSV and tileset file names under `assets/` |
| `spawnX`, `spawnY` | player start position |

The map CSV holds `0` (open) and `1` (solid) tiles, 16 px each, loaded with flixel auto-tiling. The outer ring is the arena wall. Solid interior tiles become pillars: they block movement and projectiles, break line of sight, and Arena draws block sprites over them. Arena geometry is edited in the CSV only.

## Tuning

Gameplay numbers live in the JSON files under `assets/data/` (see Data). The remaining code constants are `static inline var`s at the top of the file that owns them.

| File | Constants |
|---|---|
| `systems/ScytheCombat.hx` | swing time, arc, scale pulse, aim smoothing, slash spawn distance, facing flip margin |
| `systems/ThrowAttack.hx` | throw distance, return speed, catch radius, wall probe, trail density and fade |
| `entities/ThrownScythe.hx` | throw speed, spin rate, hit radius |
| `entities/SlashProjectile.hx` | slash speed, range, fade time, hit radius |
| `entities/Enemies.hx` | wander and idle durations, hit flash time |
| `entities/EnemyNav.hx` | waypoint radius; the repath interval is in `tick()` |
| `entities/HealthPickup.hx` | heal amount, lifetime |
| `systems/EnemyDirector.hx` | off-screen entry margin, edge spawn margins, shot wall probe |
| `systems/Fx.hx` | hitstop length, shake strengths, spark settings |

## Builds

Windows native and HTML5 share the same source and assets. Commands are in [README.md](README.md).
