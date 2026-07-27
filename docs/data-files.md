# Data

## Enemy definitions - assets/data/enemies/&lt;kind&gt;.json

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

## Wave table - assets/data/waves.json

| Field | Meaning |
|---|---|
| `firstDelay` | seconds before wave 1 |
| `breather` | seconds between waves, before `scaling` shortens it |
| `baseCount`, `countPerWave` | enemy count = baseCount + wave x countPerWave |
| `maxCount` | count cap |
| `bossWaveMin`, `bossWaveRange` | the first boss wave is `bossWaveMin + random(0..bossWaveRange)`, rolled once per run |
| `bossRepeat` | waves between bosses after the first. 0 means the boss happens once and never again |
| `waves` | array of `{types}` spawn pools; the first entry is wave 1, and the last entry repeats for every later wave. Repeat a type inside a pool to weight it. |
| `scaling` | how a wave hardens with its number, applied to every enemy as it spawns |

### scaling - assets/data/waves.json

Each multiplier is `1 + (wave - 1) x perWave`, held at its `Max`, and applied to the values the enemy just read from its own JSON. Wave 1 always multiplies by 1, so the enemy files stay the source of truth for how something starts.

| Field | Meaning |
|---|---|
| `hpPerWave`, `hpMax` | health multiplier. The main lever, and the ceiling is set high enough that health keeps climbing for as long as anyone plays |
| `speedPerWave`, `speedMax` | movement multiplier. Capped much lower on purpose: past a point extra speed stops being difficulty and starts being undodgeable |
| `damagePerWave`, `damageMax` | contact and shot damage multiplier |
| `breatherPerWave`, `breatherMin` | seconds taken off the gap between waves each wave, down to a floor |

Enemy count is not part of this - it keeps its own `maxCount` cap, because count is what costs frames. Difficulty past that cap comes from the multipliers instead, which cost nothing.

## Player - assets/data/player.json

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
| `sideSkin` | the side-view sprite: `sheet` (grid image under `assets/images/`), `frameW`/`frameH` cell size, `offsetX`/`offsetY` draw alignment, `shadowScaleX` (the ground shadow is drawn wider in side view than the top-down default of 4), the `idle`/`walk`/`jump`/`fall`/`hurt`/`death` frame index lists, and a frame rate per animation. `jump` and `fall` exist only in this skin and are chosen by vertical velocity while airborne |

## Weapons - assets/data/weapons.json

Combat balance for every weapon system, one object per system; field names match the system's tuning names.

| Section | Covers |
|---|---|
| `swing` | melee range and arc, slash spawn distance |
| `jab` | hook jab spawn distance, reach, arc, damage, slash size |
| `revolver` | cylinder size, damage, reload time, fan interval and jitter, bullet speed/range/hit radius/knockback |
| `shockwave` | wave radius, expansion time, and how long it stuns |
| `thrown` | throw distance, return speed |
| `bowCharge` | charged shot: `minTime` below which a press is a plain tap shot, `fullTime` to reach full charge, `maxDamage` at full, and the `speedBonus`/`sizeBonus`/`knockBonus` multipliers applied across the charge range |
| `arrowRain` | volley size, drop delay and stagger, spread, fall speed, hit radius |
| `hook` | flight range, pull speed and timeout, grab and hold distances, spin windup, throw speed/duration/hit radius, release stun, and the damage dealt to enemies that cannot be grabbed |
| `superOrbit` | blade count, fire gate |
| `bounceStrike` | strike count, hop time, radius, damage, force, catapult speed |
| `arrowStorm` | storm duration, spawn cadence, drops per tick |
| `hookArms` | reach and reach speed, grab radius, reel speed, grab distance, throw force, damage, cooldown, whip time, super duration |

Presentation constants (trail settings, rope geometry, rest poses, ring radii, and the like) stay in the owning source files - see Tuning.

## Discord - assets/data/discord.json

| Field | Meaning |
|---|---|
| `clientId` | Discord application ID for Rich Presence. Empty string disables presence. Create an application at discord.com/developers/applications, copy its Application ID here, and optionally upload Rich Presence art assets named `icon`, `hammer`, `revolver`, `crossbow`, `hook`. |

## Arena - assets/data/arena.json

| Field | Meaning |
|---|---|
| `cols`, `rows`, `tileSize` | arena size in cells and the cell size; the single source everything derives from - Arena's tilemap, the editor's grid, and the painted floor layer's dimensions all read it rather than repeating 160/90/16 |
| `background` | stage image name under `assets/images/` |
| `map`, `tiles` | collision CSV and tileset file names under `assets/` |
| `spawnX`, `spawnY` | player start position |
| `totemWaveMin`, `totemWaveRange` | the totem crashes down on a wave rolled once at startup from `totemWaveMin` to `totemWaveMin + totemWaveRange` |

The map CSV holds `0` (open) and `1` (solid) tiles, 16 px each, loaded with flixel auto-tiling. The outer ring is the arena wall. Solid interior tiles become pillars: they block movement and projectiles, break line of sight, and Arena draws block sprites over them. The stock arena is edited in this CSV; player maps come from the in-game editor instead.

Editor maps ride the same format. `MapStore` keeps five slots - on desktop as plain JSON files (`sx`, `sy`, `csv`) in a `maps/` folder next to the executable, anchored to the executable's own path rather than the working directory so shortcuts cannot scatter them, and shareable by copying the file; on html5 they live in the browser save. Playing one sets `CustomArena`, a static the Arena constructor checks: when set, the raw CSV and spawn replace the stock ones, which the tilemap loader accepts directly, and everything downstream - pillars, pathfinding, boss obstacle clearing, the side-view morph - works unchanged because it all reads the tilemap generically. The main menu clears `CustomArena` on entry, so a normal PLAY is always the stock arena, and since online can only be reached through the menu, custom maps cannot desync a co-op session.

## Paintable tilesets - assets/data/tilesets.json

An array of `tilesets`, the sheets the editor can paint floor art from. This is the layer to reach for when you want to *place* tiles from an art pack.

| Field | Meaning |
|---|---|
| `name` | shown in the editor, and what maps store |
| `image` | sheet under `assets/images/` |
| `tileW`, `tileH` | cell size the sheet is cut into |

Unlike the collision tileset, which must be flixel's 16-tile auto-tiling strip, this is any image cut into a uniform grid - so most art packs work by naming their cell size and nothing else. Adding one is a JSON entry plus the image:

```json
{ "name": "CAVE", "image": "tilesets/cave", "tileW": 32, "tileH": 32 }
```

Note what the image's own dimensions can and cannot tell you: nothing useful about cell size, since a 768 px sheet divides evenly by 16, 24, 32, 48 and 64 alike. Only the art knows where its cells fall, so `tileW`/`tileH` stay hand-written - but the editor draws grid lines over the palette so a wrong guess is visible immediately, and you can zoom in to check the lines land on the seams.

What the sheet *can* be read for is its used area. Art packs routinely park a small strip of tiles in the corner of a big empty canvas, so the palette scans the image for its non-transparent bounds, snaps them outward to whole cells, and frames that region instead of the whole file. Tile indices still count across the full sheet, so the crop only changes what you look at.

The painted grid is stored per map as its own CSV, sized from the sheet's cell size rather than the 16 px collision grid, so a 32 px sheet paints on 32 px cells. `0` is empty and `1..N` are the sheet's cells in reading order; the layer loads with `startingIndex` 1 because flixel resolves a tile's frame as `index - startingIndex`, which is what keeps `0` free to mean nothing. Switching a map to a different sheet clears the painted layer, since the cell size - and therefore the grid - changes.

The floor layer is added before the render layers so it draws under everything that moves, and it hides with the rest of the decoration during the boss fight.

Painted tiles are also what walls are made of. A wall block is filled in three passes, each only where the last left nothing: the theme's flat colour, then its repeating texture, then any tiles painted over that spot - so the painted layer wins. That is what lets one map carry brick walls in one corner and cobble in another, which a single theme texture cannot express. The two grids need not share a cell size (a 24 px sheet over 16 px collision is normal), so each overlapping tile is clipped to the block rather than assumed aligned. Walls stay merged block sprites in the entity layer, so they still depth-sort.

Collision itself remains separate and lives only in the arena's hidden tilemap, which is what pathfinding and projectiles read. Painting a tile does not make it solid - unless the editor's `V` toggle is on, which marks every collision cell a tile covers as it is laid, so a wall can be drawn and made solid in one stroke.

## Props - assets/data/props.json

An array of `props`, the decorations the editor can stamp into a map.

| Field | Meaning |
|---|---|
| `name` | shown in the editor, and what maps store - so reordering this file cannot break saved maps |
| `sheet` | image under `assets/images/` |
| `rect` | optional `[x, y, w, h]` cutting one prop out of a shared sheet; empty means the whole image is the prop |
| `scale` | draw scale, since the art is pixel-sized |

`rect` is what lets an art pack be used as-is: list each prop as a region of the same sheet rather than slicing it into files.

Placements are stored per map as `{n, x, y, f}` - prop name, the point its **feet** stand on, and whether it is flipped. Anchoring by the feet is deliberate: that same point is the depth-sort key, so a prop placed further down the screen correctly draws in front. Props go into the entity layer, which sorts by feet, so you walk behind a house and in front of one below you. They are hidden for the boss fight, which strips the arena to a bare void, and restored afterwards.

Decorations are **purely visual** - they never collide. Paint walls under or around a prop when you want it solid, which keeps collision entirely in the tilemap where the pathfinding and projectiles already read it.

## Editor tuning - assets/data/editor.json

Grouped as `view` (start/min/max zoom, zoom step, pan speed), `palette` (panel width and height, padding, prop cell size, max zoom), `brush` (max size, undo depth), and `flashTime`. The editor reads these into named accessors, so call sites still read as constants while the numbers stay data.

## RUN - assets/data/run.json

A hidden number rolled per run, in the manner of the one Undertale keeps, for gating rare content that should not appear on demand. Nothing reads it yet - this is the framework only.

```json
{
	"min": 1,
	"max": 100,
	"events": []
}
```

`min` and `max` bound the roll. `events` names the windows that rare content sits in, each `{ "name", "min", "max" }` with an optional `"note"` for what it is meant to trigger, so the whole table of secrets is readable in one place rather than scattered as magic numbers through the code.

`util.Run` is the runtime. `Run.value` reads the current roll, taking it from the save and rolling one the first time if there is none. `Run.reroll()` takes a fresh number and stores it - call it wherever a run should get its own. `Run.allows("name")` is the question gameplay asks, true only when the current value falls inside that event's window; an undefined name answers false, so a typo hides content rather than exposing it. `Run.inRange(lo, hi)` checks a window inline for something not worth naming, `Run.force(v)` pins a value for testing, and `Run.report()` prints the roll with every event and whether it is live.

The value persists in the save alongside the best wave and the settings, so it survives a restart until something rerolls it.

## Themes - assets/data/themes.json

An array of `themes`. The first entry is the look every map wears - there is no in-editor switcher, so the rest are inert unless something selects them in code. Worth knowing before adding art: **the collision tileset is never drawn**. `Arena` hides the tilemap and renders walls as merged block sprites, so swapping `tiles` in arena.json changes collision shapes, not appearance. What changes how a map looks is a theme.

| Field | Meaning |
|---|---|
| `name` | shown in the editor |
| `background` | stage image under `assets/images/` |
| `wall` | optional image tiled across the wall blocks; empty means a flat colour |
| `wallRect` | optional `[x, y, w, h]` region of that image to tile; empty means the whole file |
| `wallColor` | wall colour as `RRGGBB`, also the fill behind a wall texture |

`wallColor` is RGB only on purpose: a full ARGB literal like `0xFF1C1010` is larger than a signed 32-bit int, so parsing it clamps to `0x7FFFFFFF` and every wall comes out translucent white. The alpha is OR'd on in code.

`wallRect` is what makes an art-pack sheet usable directly - point it at the one patch you want repeated rather than slicing the sheet into a new file. Adding a theme is a JSON entry plus the images; no code changes:

```json
{
  "name": "SANDSTONE",
  "background": "stages/desert",
  "wall": "tilesets/desert_sheet",
  "wallRect": [0, 96, 48, 48],
  "wallColor": "C86432"
}
```

The first theme applies to editor maps only; the stock arena keeps its arena.json look.

## Side view - assets/data/sideview.json

| Field | Meaning |
|---|---|
| `gravity`, `maxFall` | side-view gravity and terminal fall speed |
| `playerJump`, `enemyJump` | jump velocities (the player gets one air jump) |
| `groundOffset` | the ground line sits this far above the arena's bottom edge |
| `platformHigh`, `platformLowGap` | the platform height band: the northmost pillar maps to `platformHigh`, the southmost to `groundY - platformLowGap` |
| `platformHeight`, `platformWidthMult`, `platformWidthMin` | platform slab thickness and width (pillar width times the multiplier, at least the minimum) |
| `enemyHighFeet` | morph mapping: the northmost enemies are lifted to this height, then fall |
| `morphTime`, `revertTime` | seconds for the morph to side view and back |
| `telegraphTime`, `fallTime`, `fallHeight` | meteor arrival: warning decal duration, drop duration, drop start height |
| `impactRadius`, `impactDamage` | the landing shockwave against enemies |
| `landMin`, `landMax` | the meteor lands this far from the player |

---

Back to the [documentation index](../DOCS.md).
