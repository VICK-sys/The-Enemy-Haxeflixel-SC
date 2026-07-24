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
  states/tutorial/       the tutorial's animated demo pages
  systems/               core systems owned by PlayState
  systems/weapons/       the weapon systems, coordinated by Weapons
  entities/              player and pickup sprites
  entities/enemy/        enemy class, navigation, attack styles, projectile
  entities/weapon/       weapon projectiles and visuals
  data/                  JSON typedefs and loaders (mirrors assets/data/)
  util/                  utilities
export/                  build output (not committed)
```

## States

- `TitleSequence` - intro logo. ENTER skips. Applies the saved settings on boot, then switches to the main menu when done.
- `MainMenuState` - the main menu: PLAY, OPTIONS, and QUIT (QUIT is desktop-only) over a dark warping-grid background (the boss grid with the `WarpShader`), with the title, the best wave in the corner, and menu music. Navigated with W/S or the arrows plus ENTER, or by mouse hover and click. PLAY fades to black and switches to PlayState; OPTIONS opens `OptionsSubState`; QUIT shuts down Discord presence and exits.
- `OptionsSubState` - the options panel over the menu: master volume (adjust with A/D or the arrows, or click to step), fullscreen toggle, FPS counter toggle, and a reset-best-wave action that asks for a second press within a few seconds to confirm. All settings apply immediately and persist in the save file. ESC or BACK closes it.
- `PlayState` - constructs the systems in `create()`, calls them in order in `update()`, and handles the debug keys. It holds no gameplay logic of its own.
- `PauseSubState` - opened with ESC. Freezes the game and pauses all audio, dims the screen, closes on ESC. Volume keys work while open.
- `TutorialSubState` - the controls popup shown the first time PlayState opens each session. Seven pages (move, attack, weapons, modes, super, abilities, health) flipped with A/D or the arrow keys, each with a looping animated demo built from game sprites. The abilities page demos time stop: four enemies close in around the player until the stop triggers, then they freeze mid-stride while the player keeps running laps around them with the blue afterimage trail, steering clear of every frozen body, and everything ramps back up on release. The popup fades in on open; ENTER or ESC freezes the demo and fades it back out before starting the game. The wave timer is frozen while it is open. Each page's demo is its own class under `states/tutorial/` (MoveDemo, AttackDemo, WeaponsDemo, ModesDemo, SuperDemo, AbilitiesDemo, HealthDemo), all extending `TutorialDemo` - a group base with the shared sprite/text/player factories, the demo clock, and a per-frame `step()` hook. The substate itself only owns the panel, the page texts, and page flipping; flipping destroys the old demo instance and constructs the next.

## Systems (source/systems/)

Each system is constructed once by PlayState and updated once per frame (except `MenuList`, which the menu states construct).

- `Arena` - loads the background and collision tilemap, sets world and camera bounds, generates pillar sprites from the map data, and answers `wallAt(x, y)`. Also owns the boss-intro transition: `beginBossTransition()` shakes the camera and fades a white overlay in, then swaps the background to the warping checkerboard grid (a `WarpShader` distorts it), clears the interior pillars (removes their sprites and empties their collision tiles for an open boss arena), and fades the white back out. `update(elapsed)` drives that sequence and advances the shader; `onWhiteout` fires once at the fully-white moment (used to cut the alarm and start the boss music). `endBossTransition()` reverses it after the boss dies - a quick white flash restores the normal background, removes the shader, and rebuilds the pillars (`restoreObstacles` reloads the map CSV), firing `onNormal` to restore the normal music.
- `Fx` - hitstop (time scale drops for a few frames on kills), camera shakes, hit spark bursts, and the dash speed-line trail.
- `RenderLayers` - the shadow and entity render groups. The entity layer is sorted every frame by feet position so characters and pillars overlap correctly.
- `PlayerCombat` - player health, the AP meter, damage intake, invincibility frames and blink, dash input, death and revive, and the run's kill counter. The HUD bars bind directly to its fields.
- `EnemyDirector` - spawns waves from the wave table, owns the per-enemy rigs (enemy, shadow, contact hitbox), runs enemy collision and cleanup, and updates enemy shots. A randomly chosen wave (4-8, rolled once at startup) is the boss wave: it fires the `onBoss` callback (which starts the intro cinematic) and, after a short intro delay, spawns a single `"rofel"` enemy instead of the normal count. When the boss dies the director runs a defeat sequence - the boss shakes in place, then plays an explosion animation with a boom sound - and fires `onBossDefeated` (which reverts the arena and music to normal) once the explosion finishes. Also the single home of enemy hit queries: `firstInCircle` and `eachInCircle` do the nearest-hitbox-point circle test every attack uses (live enemies only; `firstInCircle` can skip seized ones).
- `Pickups` - the health pickup pool. Collected on player contact unless health is full.
- `TimeStop` - the time-stop ability (E, cooldown driven by player.json): ramps a world-time factor from 1 to 0 over the slow phase, holds the world frozen for the stop duration, then ramps back. The factor is published through `WorldClock.scale` (read by enemies, enemy shots, and pickups, which scale or skip their own updates) and PlayState multiplies it into the elapsed passed to the director and arena, so wave timers, boss logic, and cinematics freeze too. The player, weapons, and player projectiles run at full speed throughout; seized enemies stay in player-time so the hook still works on frozen targets. Frozen enemies are immovable statues that deal no contact damage, and frozen shots hang harmlessly in the air. Music pitch rides the factor down (the record-slowdown effect), pauses at the full stop, and ramps back on resume. While time is slowed the player leaves a blue afterimage trail (frame-accurate ghosts via GhostTrail), and a subtle blue overlay tints the screen. The HUD shows READY / cooldown / STOPPED via `hudLabel()`. Dying cancels the stop.
- `MenuList` - the shared menu widget used by the main menu and options: a centered column of text rows with a bobbing scythe selector, W/S and arrow navigation, A/D value adjustment, mouse hover and click, and the move/select sounds. Owners supply `onChoose` and optional `onAdjust` callbacks and can rewrite row labels in place.
- `Hud` - the UI camera, health and AP bars, wave counter and banner (the red BOSS APPROACHING banner shares the same text and slides down from the top), the mode indicator (label plus icon, animated on switch), the time-stop status label and fading countdown timer, death text with the best wave, and the custom cursor. Owns a `BossHud` and delegates the boss bar and screen flash to it.
- `BossHud` - the boss-fight HUD pieces: the pulsing red screen flash and the boss health bar. `showBar(boss)` binds a bar to the boss's HP and plays its entrance: the bar expands out from a compressed sliver as it drops in from the top, then the name "Rofel" fades in letter by letter beneath it. The bar hides itself once the boss is gone.

## Weapon systems (source/systems/weapons/)

- `Weapons` - the combat coordinator. Weapon selection (1-4 or scroll wheel: scythe, hammer, bow, hook), the mode cycle within the equipped weapon (each weapon remembers its last mode), the super trigger (Q at full AP, one per weapon: scythe launches SuperScythes, hammer launches BounceStrike, bow launches ArrowStorm, hook launches HookArms), attack input dispatch (super priority, the held-enemy throw intercept, aim math), and held-weapon visibility while the hook is out or a bounce is running. Everything else is delegated to the systems below.
- `WeaponMode` - the mode enum shared by the weapon systems.
- `HitPipeline` - the shared hit pipeline: damage with hit sound, sparks, kill rewards, and drop rolls; a zero-damage stun hit with a caller-supplied duration; and `blastRadial`, the shared area-of-effect hit (every enemy in a circle is damaged and flung outward from the center) used by the hammer slam, Bounce Strike, and landing rain arrows.
- `Rope` - shared rope drawing: tiles rope segments along a straight line (the hook's rope) or a quadratic bezier with an explicit control point (the arms' curved ropes) into a caller-owned sprite group.
- `HeldWeapon` - the held sprite: per-weapon graphic and origin, hand anchoring, cursor tracking and facing flip, the swing sweep and bow recoil animations, the bow's held-out pose, and the arrow rain skyward pose.
- `SwingAttack` - the scythe swing: slash visual pool and the melee strike (an arc in front of the player).
- `SliceAttack` - the slice projectile pool: firing, wall death, and pierce hits.
- `HammerAttack` - the hammer slam (a damage circle at the aim point, 2 damage and heavy knockback) and the shockwave trigger; owns Shockwave.
- `BowAttack` - the bow shot (a fast arrow that dies on its first enemy hit or a wall) and the arrow rain trigger; owns ArrowRain.
- `Shockwave` - the shockwave mode: the hammer slams the ground at the aim point, spawning a temporary cracked-ground decal and an expanding ring that stuns every enemy it passes (a staggered no-damage stagger hit plus a long stun). The wave ignores walls.
- `ArrowRain` - the arrow rain mode: the bow is held above the player's head pointing skyward; firing launches a fanned burst of arrows up from it, then a staggered volley falls onto a scatter of points around the cursor. Each impact point shows a ground marker during the descent; a landing arrow damages enemies in a radius with outward knockback. The rain ignores walls.
- `HookAttack` - the hook grab: the held hook itself is thrown (the hand stays empty and all attacks are blocked until it returns), trailing a rope line back to the player. It latches the first enemy hit (light damage plus a seize that suspends its AI), reels it to the player, and holds it in front of the cursor. Left click while holding whips the enemy in one quick revolution around the player, then launches it as a projectile that damages every enemy it passes through; the hook returns to the hand at the moment of release, so the enemy flies alone. Hitting a wall damages the thrown enemy, otherwise it is released with a short stun at the end of the flight. On a miss the hook retracts to the hand. Seized enemies deal no contact damage and skip crowd separation. Enemies flagged not `grabbable` (the boss) take damage but cannot be latched - the hook deals its hit and retracts. The spin mode instead whips the hook one full revolution around the player on its rope, starting from the aim angle and hitting each enemy once. The grapple mode fires the hook to where you aim; it only boosts if the hook catches an enemy - hitting a wall or reaching max range with no enemy in reach just retracts the hook. On a catch it rockets the player to that enemy at high speed (tracking it as it moves), shredding and flinging enemies along the path, and the player is invincible for the whole boost. (The auto-grabbing arms are the hook's super - see `HookArms`.)
- `ThrowAttack` - the boomerang throw: thrown scythe flight (out leg, wall turnaround, homing return, catch), its afterimage trail, and the spin sound loop. The return steers around walls using its own EnemyNav instance on a fast re-path interval. The player cannot attack while the scythe is airborne.
- `HookArms` - the hook super: Q with the hook equipped and a full AP meter drains it and extends two mechanical hook-arms from the player's back (rendered behind them) for a few seconds. Each arm independently reaches out to the nearest enemy, grabs it, reels it up, whips it in an arc, and hurls it - automatically and continuously. The arms rest tilted and their curved ropes trail with inertia; when the super ends they retract back into the body. The held hook is hidden and the player can still move.
- `ArrowStorm` - the bow super: Q with the bow equipped and a full AP meter drains it and fires a single supercharged arrow straight up from the bow - a big glowing arrow with a fading trail. Once that arrow clears the top of the screen the storm proper begins: the bow stays raised skyward while arrows carpet the entire visible arena for a few seconds, spawning rain drops across the camera view on a fast cadence (reusing ArrowRain's drop/marker/land machinery). The player can still move throughout.
- `BounceStrike` - the hammer super: Q with the hammer equipped and a full AP meter drains it and plays a three-hit bounce. Each hit is a ground slam (a big AoE that flings caught enemies away with heavy force) that launches the player into the air in a somersault; on landing the next slam fires, three times, then control returns. Movement is locked for the duration and the held hammer is hidden.
- `SuperScythes` - the super: right click with the scythe equipped and a full AP meter drains it and wraps the player in a pseudo-3D cylinder of scythes - an elliptical carousel where blades pass in front of and behind the player, scaling with depth. The player levitates for the duration (visual offset only; the hitbox and shadow stay grounded) and the held scythe vanishes. Left click launches the blade nearest the aim; launched blades spin, pierce enemies, and die on walls. Everything leaves ghost trails. When the last blade is fired the player settles back down and the scythe returns, with the previous weapon mode intact.

## Entities (source/entities/)

- `Player` - WASD movement with an acceleration ramp, dash, and the walk sound loop.
- `HealthPickup` - dropped heart. Restores health on contact, expires after a few seconds.

Weapon projectiles and visuals live in `source/entities/weapon/`:

- `SlashEffect` - the pooled swing visual. It drifts forward briefly and fades out; it carries no hitbox.
- `SliceProjectile` - the slice mode's traveling wave. Pierces enemies (one hit per enemy per wave) and dies on walls.
- `ThrownScythe` - the airborne scythe. Spins, stretches on release, throbs in flight, and hits each enemy once per flight leg (out and return).
- `SuperBlade` - one orbiting super scythe. Positioned by SuperScythes while orbiting; once launched it flies straight, pierces (one hit per enemy), and fades at range.
- `Arrow` - the bow mode's projectile. Flies straight and fast, dies on the first enemy hit or a wall, expires at range.
- `HookShot` - the hook mode's projectile. Flies head-first; once latched it sticks to the hooked enemy until the throw resolves.
- `RainArrow` - an arrow rain volley member. Either a fading skyward launch visual or a falling arrow that lands at its assigned impact point.

Enemy behavior lives in `source/entities/enemy/`:

- `Enemies` - the one enemy class. Loads its definition from JSON by kind (`"enemy"`, `"woodster"`, `"likwid"`) and runs a three-state FSM: Wandering, Following, Attacking. Wave-spawned enemies start off screen in an entering mode that walks them through the border wall before collision turns on. `unseize(releaseStun)` is the one release path for grabbed enemies: it clears the seize, restores drag, optionally applies a release stun, and grants the short throw grace that keeps a just-thrown enemy from hurting the player.
- `EnemyNav` - line-of-sight and pathfinding component. A few times per second it checks a body-width corridor toward the target (two offset rays); when blocked it runs A* over the map, simplified with a body-sized box cast, and steers along the waypoints. Wall contact while chasing forces an immediate re-path.
- `AttackBehavior`, `ChargeAttack`, `ShootAttack`, `RofelBoss` - the attack style interface and its implementations. A charge is a windup, a straight lunge, and a recovery. A shooter holds position, cycles its shoot animation, and requests a projectile on the loop frame. `RofelBoss` is the Rofel boss brain (see below).
- `RofelBoss` - the wave-4 boss behavior, ported from the RofelShooter game. It kites the player (keeping a preferred distance band and strafing sideways, bouncing off walls) and cycles through Rofel's five guns - pistol, shotgun, sniper, revolver, laser - each with its own bullet sprite, speed, spread, damage, and burst pattern. A held gun sprite rotates to aim at the player and swaps per weapon. Enemies with the `"boss"` attack are `selfDriven`: they skip the normal wander/follow/attack FSM and run this brain directly.
- `EnemyShot` - pooled enemy projectile. Carries its damage, speed, range, and optional sprite from the shot request; sprite bullets rotate to face travel.
- `ShotSpec` - one queued shot request (direction, damage, speed, range, sprite, sound, optional spawn origin). Behaviors push these onto the enemy's `pendingShots`; the director drains and fires them. This lets the boss fire multi-bullet volleys with per-shot parameters.

## Data modules (source/data/)

- `DataLoader` - reads and parses a JSON asset; throws with the path in the message if the file is missing.
- `EnemyData`, `PlayerData`, `WaveData`, `ArenaData`, `WeaponData` - typedefs and parse-once registries for the files under `assets/data/`.

## Utilities (source/util/)

- `Paths` - asset path builders: `image`, `sound`, `music`, `file`, `json`, and `sparrow` (returns the loaded atlas for a png/xml pair).
- `GhostTrail` - pooled afterimage trail: fades its ghosts every tick and stamps a copy of a source sprite (position, angle, scale, color) on a fixed cadence. `stampFrame` instead copies an animated sprite's current frame with a forced tint (the time-stop player trail). Used by the thrown scythe, the super scythe blades, the Arrow Storm launch arrow, and the time-stop trail.
- `WorldClock` - a single static `scale` (1 normal, 0 frozen) written by TimeStop and read by world entities that update through the display list.
- `WarpShader` - a GLSL fragment shader that distorts a sprite's texture coordinates with time-driven sine waves. Applied to the boss-arena grid background; `advance(elapsed)` steps its time uniform.
- `SaveData` - persistent save: best wave reached plus the settings (master volume, fullscreen, FPS counter visibility). `applySettings()` pushes the saved settings into the engine and is called at boot and whenever an option changes.
- `Music` - the single owner of music playback. `play(name, volume, loop)` switches tracks only when the requested track differs from the current one; asking for the playing track just applies the volume, restores pitch, and resumes it if paused - which is what keeps the stage theme seamless across the menu, the game, pause-quit, and restarts.
- `DiscordPresence` - Discord Rich Presence (Windows native only, via the `hxdiscord_rpc` haxelib; every method is a no-op on HTML5). Reads the application ID from `assets/data/discord.json` and stays silent if it is empty. PlayState feeds it the raw facts each frame (`playing(wave, bossFight, weapon, kills)`) and it diffs internally: wave changes, the boss fight, weapon switches, pause, and death push immediately, kill-count changes are throttled to one update every couple of seconds. Shows the current wave or boss fight plus the equipped weapon and kill count, run elapsed time via the start timestamp, the best wave on the menu and death screens, and image keys `icon` (large) and `scythe`/`hammer`/`bow`/`hook` (small, per weapon) for art uploaded to the Discord application.
- `PerfLog` - frame-time logger for native builds. Writes `perflog.txt` next to the executable: one aggregate line per second (average, worst, fps) plus immediate lines for spike frames and long gaps, each tagged with the live enemy count, pathfinding calls, projectile count (slices, enemy shots, arrows, rain arrows, thrown scythe, hook), and wave.

## Data

### Enemy definitions - assets/data/enemies/&lt;kind&gt;.json

| Field | Type | Meaning |
|---|---|---|
| `sprite` | String | Sparrow atlas name under `assets/images/` (png and xml pair) |
| `width`, `height` | Float | hitbox size in px |
| `offsetX`, `offsetY` | Float | sprite draw offset relative to the hitbox |
| `animations` | Array | `{name, prefix, fps, loop}` - `name` is what the code plays (`idle`, `walk`, `hurt`, `death`, and `sstart`/`sloop`/`send` for shooters), `prefix` is the atlas frame prefix |
| `hp` | Int | hits to kill |
| `speed` | Float | movement speed while chasing |
| `aggroRange` | Float | chasing starts inside this distance and ends outside it (wave spawns override it so they never stop chasing) |
| `stopThreshold` | Float | a chaser with line of sight stops approaching inside this distance |
| `attackRange` | Float | the attack starts inside this distance, line of sight required |
| `attack` | String | `"charge"`, `"shoot"`, or `"boss"` |
| `boss` | Object | boss attack only: `moveSpeed`, `prefMin`/`prefMax` (kiting distance band), `strafeWeight`, `gunDist` (gun hold distance), and `guns` - an array of gun configs (`image`, `bullet`, `speed`, `count`, `spread`, `damage`, `burst`, `burstInterval`, `cooldown`, `range`, `muzzle`) |
| `contactDamage` | Float | damage dealt to the player on contact |
| `shotDamage`, `shotSpeed`, `shotRange` | Float | shooters only (`shotSpeed`/`shotRange` optional); projectile damage, speed, and range |
| `shotSprite`, `shotSound` | String | optional; image and sound for the projectile (defaults: green pellet, `enemies/shoot`) |
| `dropChance` | Float | chance from 0 to 1 of dropping a health pickup on death |
| `knockback`, `knockbackDrag`, `stunTime` | Float | optional; knockback taken when hit, its decay, and stun duration |
| `wanderSpeed` | Float | optional; walking speed while wandering |
| `chargeWindup`, `chargeSpeed`, `chargeTime`, `chargeRecover` | Float | optional, chargers only; charge attack overrides |
| `shootWindup`, `shootStep`, `shootGap`, `shootDisengage` | Float | optional, shooters only; shoot cycle overrides |
| `shadowOffX`, `shadowOffXFlip`, `shadowOffY`, `shadowScaleX` | Float | shadow placement and width |
| `hitOffX`, `hitOffXFlip`, `hitOffY` | Float | placement of the 40x40 contact hitbox |

To add an enemy type: put an atlas under `assets/images/enemies/`, add a JSON file here, and reference its file name (without extension) from the wave table or a spawn call.

### Wave table - assets/data/waves.json

| Field | Meaning |
|---|---|
| `firstDelay` | seconds before wave 1 |
| `breather` | seconds between waves |
| `baseCount`, `countPerWave` | enemy count = baseCount + wave x countPerWave |
| `maxCount` | count cap |
| `bossWaveMin`, `bossWaveRange` | the boss wave is `bossWaveMin + random(0..bossWaveRange)`, rolled once per run |
| `waves` | array of `{types}` spawn pools; the first entry is wave 1, and the last entry repeats for every later wave. Repeat a type inside a pool to weight it. |

### Player - assets/data/player.json

| Field | Meaning |
|---|---|
| `moveSpeed` | top movement speed |
| `rampStart`, `rampRate`, `rampReset` | run-up: starting speed, gain per second, and the value it resets to after standing still |
| `drag` | slowdown when no key is held |
| `dashSpeed`, `dashTime`, `dashCooldown`, `dashIframes` | dash speed, duration, cooldown, and invincibility window |
| `healthMax`, `apMax` | meter maximums |
| `apPerKill` | AP refunded per kill |
| `iframeTime`, `hurtLockTime` | invincibility and movement-lock time after taking a hit |
| `knockback` | knockback taken when hit |
| `timestopSlow`, `timestopHold`, `timestopRecover`, `timestopCooldown` | time stop: seconds to wind down to the full stop, seconds held frozen, seconds to ramp back, and the cooldown |

### Weapons - assets/data/weapons.json

Combat balance for every weapon system, one object per system; field names match the system's tuning names.

| Section | Covers |
|---|---|
| `swing` | melee range and arc, slash spawn distance |
| `slice` | slice spawn distance |
| `hammer` | reach, radius, damage, push, shockwave stun length |
| `shockwave` | wave radius and expansion time |
| `thrown` | throw distance, return speed |
| `arrowRain` | volley size, drop delay and stagger, spread, fall speed, hit radius |
| `hook` | flight range, pull speed and timeout, grab and hold distances, spin windup, throw speed/duration/hit radius, release stun, whirl time/radius/hit radius, and the grapple set (range, pull speed, sweep radius, fling force, catch distance, timeout) |
| `superScythes` | blade count, fire gate |
| `bounceStrike` | strike count, hop time, radius, damage, force, catapult speed |
| `arrowStorm` | storm duration, spawn cadence, drops per tick |
| `hookArms` | reach and reach speed, grab radius, reel speed, grab distance, throw force, damage, cooldown, whip time, super duration |

Presentation constants (trail settings, rope geometry, rest poses, ring radii, and the like) stay in the owning source files - see Tuning.

### Discord - assets/data/discord.json

| Field | Meaning |
|---|---|
| `clientId` | Discord application ID for Rich Presence. Empty string disables presence. Create an application at discord.com/developers/applications, copy its Application ID here, and optionally upload Rich Presence art assets named `icon`, `scythe`, `hammer`, `bow`, `hook`. |

### Arena - assets/data/arena.json

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
| `systems/weapons/HeldWeapon.hx` | swing times per mode, arc, scale pulse, aim smoothing, facing flip margin, bow hold distance, rain raise height |
| `systems/weapons/ThrowAttack.hx` | spawn distance, catch radius, wall probe, trail density and fade |
| `systems/weapons/HookAttack.hx` | spawn distance, wall probe, retract speed, catch radius, rope handle length |
| `systems/weapons/HookArms.hx` | rest pose geometry and tilt, rope curve fraction, eases, whip arc and radius, extend delay |
| `systems/weapons/ArrowRain.hx` | drop height, launch visual count and speed |
| `systems/weapons/Shockwave.hx` | ring texture base size, crack lifetime |
| `systems/weapons/SuperScythes.hx` | ring radii, carousel speed, depth scaling, hover and landing feel, deploy timings, trail settings |
| `systems/weapons/BounceStrike.hx` | hop apex, somersault spin, hand pivot |
| `systems/weapons/ArrowStorm.hx` | bow raise, launch arrow speed and scale, charge tint, trail settings |
| `entities/weapon/SuperBlade.hx` | launch speed, range, spin, hit radius |
| `entities/weapon/ThrownScythe.hx` | throw speed, spin rate, hit radius |
| `entities/HealthPickup.hx` | heal amount, lifetime |
| `entities/weapon/SlashEffect.hx` | drift speed, effect lifetime |
| `entities/weapon/SliceProjectile.hx` | slice speed, range, fade time, hit radius |
| `entities/weapon/Arrow.hx` | arrow speed, range, hit radius |
| `entities/weapon/HookShot.hx` | hook speed, hit radius |
| `entities/enemy/Enemies.hx` | wander and idle durations, hit flash time |
| `entities/enemy/RofelBoss.hx` | gun sprite scale, shot sound (the movement and gun stats live in `rofel.json`) |
| `entities/enemy/EnemyNav.hx` | waypoint radius, body radius default; the repath interval is in `tick()` |
| `systems/EnemyDirector.hx` | off-screen entry margin, edge spawn margins, shot wall probe |
| `systems/Fx.hx` | hitstop length, shake strengths, spark settings, dash line fade |
| `systems/TimeStop.hx` | trail tint, alpha, fade, cadence, and minimum speed; overlay tint strength; minimum music pitch |

## Builds

Windows native and HTML5 share the same source and assets. Commands are in [README.md](README.md).
