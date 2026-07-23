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
  entities/enemy/        enemy class, navigation, attack styles, projectile
  data/                  JSON typedefs and loaders (mirrors assets/data/)
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
- `EnemyDirector` — spawns waves from the wave table, owns the per-enemy rigs (enemy, shadow, contact hitbox), runs enemy collision and cleanup, and updates enemy shots. Also the single home of enemy hit queries: `firstInCircle` and `eachInCircle` do the nearest-hitbox-point circle test every attack uses (live enemies only; `firstInCircle` can skip seized ones).
- `Weapons` — the combat coordinator. Weapon selection (1-4 or scroll wheel: scythe, hammer, bow, hook), the Q mode cycle within the equipped weapon (each weapon remembers its last mode), attack input dispatch (super priority, the held-enemy throw intercept, aim math), and held-weapon visibility while the hook is out. Everything else is delegated to the systems below.
- `WeaponMode` — the mode enum shared by the weapon systems.
- `HitPipeline` — the shared hit pipeline: damage with hit sound, sparks, kill rewards, and drop rolls, plus a zero-damage stun hit with a caller-supplied duration.
- `HeldWeapon` — the held sprite: per-weapon graphic and origin, hand anchoring, cursor tracking and facing flip, the swing sweep and bow recoil animations, the bow's held-out pose, and the arrow rain skyward pose.
- `SwingAttack` — the scythe swing: slash visual pool and the melee strike (an arc in front of the player).
- `SliceAttack` — the slice projectile pool: firing, wall death, and pierce hits.
- `HammerAttack` — the hammer slam (a damage circle at the aim point, 2 damage and heavy knockback) and the shockwave trigger; owns Shockwave.
- `BowAttack` — the bow shot (a fast arrow that dies on its first enemy hit or a wall) and the arrow rain trigger; owns ArrowRain.
- `Shockwave` — the shockwave mode: the hammer slams the ground at the aim point, spawning a temporary cracked-ground decal and an expanding ring that stuns every enemy it passes (a staggered no-damage stagger hit plus a long stun). The wave ignores walls.
- `ArrowRain` — the arrow rain mode: the bow is held above the player's head pointing skyward; firing launches a fanned burst of arrows up from it, then a staggered volley falls onto a scatter of points around the cursor. Each impact point shows a ground marker during the descent; a landing arrow damages enemies in a radius with outward knockback. The rain ignores walls.
- `HookAttack` — the hook grab: the held hook itself is thrown (the hand stays empty and all attacks are blocked until it returns), trailing a rope line back to the player. It latches the first enemy hit (light damage plus a seize that suspends its AI), reels it to the player, and holds it in front of the cursor. Left click while holding whips the enemy in one quick revolution around the player, then launches it as a projectile that damages every enemy it passes through; the hook returns to the hand at the moment of release, so the enemy flies alone. Hitting a wall damages the thrown enemy, otherwise it is released with a short stun at the end of the flight. On a miss the hook retracts to the hand. Seized enemies deal no contact damage and skip crowd separation.
- `ThrowAttack` — the boomerang throw: thrown scythe flight (out leg, wall turnaround, homing return, catch), its afterimage trail, and the spin sound loop. The return steers around walls using its own EnemyNav instance on a fast re-path interval. The player cannot attack while the scythe is airborne.
- `SuperScythes` — the super: right click with the scythe equipped and a full AP meter drains it and wraps the player in a pseudo-3D cylinder of scythes — an elliptical carousel where blades pass in front of and behind the player, scaling with depth. The player levitates for the duration (visual offset only; the hitbox and shadow stay grounded) and the held scythe vanishes. Left click launches the blade nearest the aim; launched blades spin, pierce enemies, and die on walls. Everything leaves ghost trails. When the last blade is fired the player settles back down and the scythe returns, with the previous weapon mode intact.
- `Pickups` — the health pickup pool. Collected on player contact unless health is full.
- `Hud` — the UI camera, health and AP bars, wave counter and banner, the mode indicator (label plus icon, animated on switch), death text with the best wave, and the custom cursor.

## Entities (source/entities/)

- `Player` — WASD movement with an acceleration ramp, dash, and the walk sound loop.
- `SlashEffect` — the pooled swing visual. It drifts forward briefly and fades out; it carries no hitbox.
- `SliceProjectile` — the slice mode's traveling wave. Pierces enemies (one hit per enemy per wave) and dies on walls.
- `ThrownScythe` — the airborne scythe. Spins, stretches on release, throbs in flight, and hits each enemy once per flight leg (out and return).
- `SuperBlade` — one orbiting super scythe. Positioned by SuperScythes while orbiting; once launched it flies straight, pierces (one hit per enemy), and fades at range.
- `Arrow` — the bow mode's projectile. Flies straight and fast, dies on the first enemy hit or a wall, expires at range.
- `HookShot` — the hook mode's projectile. Flies head-first; once latched it sticks to the hooked enemy until the throw resolves.
- `RainArrow` — an arrow rain volley member. Either a fading skyward launch visual or a falling arrow that lands at its assigned impact point.
- `HealthPickup` — dropped heart. Restores health on contact, expires after a few seconds.

Enemy behavior lives in `source/entities/enemy/`:

- `Enemies` — the one enemy class. Loads its definition from JSON by kind (`"enemy"`, `"woodster"`, `"likwid"`) and runs a three-state FSM: Wandering, Following, Attacking. Wave-spawned enemies start off screen in an entering mode that walks them through the border wall before collision turns on.
- `EnemyNav` — line-of-sight and pathfinding component. A few times per second it checks a body-width corridor toward the target (two offset rays); when blocked it runs A* over the map, simplified with a body-sized box cast, and steers along the waypoints. Wall contact while chasing forces an immediate re-path.
- `AttackBehavior`, `ChargeAttack`, `ShootAttack` — the attack style interface and its two implementations. A charge is a windup, a straight lunge, and a recovery. A shooter holds position, cycles its shoot animation, and requests a projectile on the loop frame.
- `EnemyShot` — pooled enemy projectile. Carries its damage, speed, and range from the shooter.

## Data modules (source/data/)

- `DataLoader` — reads and parses a JSON asset; throws with the path in the message if the file is missing.
- `EnemyData`, `PlayerData`, `WaveData`, `ArenaData` — typedefs and parse-once registries for the files under `assets/data/`.

## Utilities (source/util/)

- `Paths` — asset path builders: `image`, `sound`, `music`, `file`, `json`, and `sparrow` (returns the loaded atlas for a png/xml pair).
- `SaveData` — persistent save (best wave reached).
- `PerfLog` — frame-time logger for native builds. Writes `perflog.txt` next to the executable: one aggregate line per second (average, worst, fps) plus immediate lines for spike frames and long gaps, each tagged with the live enemy count, pathfinding calls, projectile count (slices, enemy shots, arrows, rain arrows, thrown scythe, hook), and wave.

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
| `systems/HeldWeapon.hx` | swing times per mode, arc, scale pulse, aim smoothing, facing flip margin, bow hold distance, rain raise height |
| `systems/SwingAttack.hx` | melee range and arc, slash spawn distance |
| `systems/SliceAttack.hx` | slice spawn distance |
| `systems/HammerAttack.hx` | reach, radius, damage, push, shockwave stun length |
| `systems/ThrowAttack.hx` | throw distance, return speed, catch radius, wall probe, trail density and fade |
| `systems/HookAttack.hx` | flight range, pull speed and timeout, grab and hold distances, spin windup time, throw speed, duration, and hit radius, release stun, retract speed |
| `systems/ArrowRain.hx` | volley size, drop delay and stagger, spread, drop height, fall speed, hit radius, launch visual count and speed |
| `systems/Shockwave.hx` | wave radius and expansion time, crack lifetime |
| `systems/SuperScythes.hx` | blade count, ring radii, carousel speed, depth scaling, fire gate, trail settings |
| `entities/SuperBlade.hx` | launch speed, range, spin, hit radius |
| `entities/ThrownScythe.hx` | throw speed, spin rate, hit radius |
| `entities/HealthPickup.hx` | heal amount, lifetime |
| `entities/SlashEffect.hx` | drift speed, effect lifetime |
| `entities/SliceProjectile.hx` | slice speed, range, fade time, hit radius |
| `entities/Arrow.hx` | arrow speed, range, hit radius |
| `entities/HookShot.hx` | hook speed, hit radius |
| `entities/enemy/Enemies.hx` | wander and idle durations, hit flash time |
| `entities/enemy/EnemyNav.hx` | waypoint radius, body radius default; the repath interval is in `tick()` |
| `systems/EnemyDirector.hx` | off-screen entry margin, edge spawn margins, shot wall probe |
| `systems/Fx.hx` | hitstop length, shake strengths, spark settings |

## Builds

Windows native and HTML5 share the same source and assets. Commands are in [README.md](README.md).
