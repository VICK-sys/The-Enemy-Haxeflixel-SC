# Data

## Enemy definitions - assets/data/enemies/&lt;kind&gt;.json

| Field | Type | Meaning |
|---|---|---|
| `sprite` | String | Sparrow atlas name under `assets/images/` (png and xml pair) |
| `width`, `height` | Float | hitbox size in px |
| `offsetX`, `offsetY` | Float | sprite draw offset relative to the hitbox |
| `animations` | Array | `{name, prefix, fps, loop}`. `name` is what the code plays (`idle`, `walk`, `hurt`, `death`, and `sstart`/`sloop`/`send` for shooters). `prefix` is the atlas frame prefix |
| `hp` | Int | hits to kill |
| `speed` | Float | movement speed while chasing |
| `aggroRange` | Float | chasing starts inside this distance and ends outside it. Wave spawns override it, so they never stop chasing |
| `stopThreshold` | Float | a chaser with line of sight stops approaching inside this distance |
| `attackRange` | Float | the attack starts inside this distance, and needs line of sight |
| `attack` | String | `"charge"`, `"shoot"`, or `"boss"` |
| `boss` | Object | boss attack only: `moveSpeed`, `prefMin`/`prefMax` (kiting distance band), `strafeWeight`, `gunDist` (gun hold distance), and `guns`, an array of gun configs (`image`, `bullet`, `speed`, `count`, `spread`, `damage`, `burst`, `burstInterval`, `cooldown`, `range`, `muzzle`) |
| `contactDamage` | Float | damage dealt to the player on contact |
| `shotDamage`, `shotSpeed`, `shotRange` | Float | shooters only, and `shotSpeed`/`shotRange` are optional. Projectile damage, speed, and travel range. Every gun in the game currently sets travel effectively infinite, so bullets die on walls and cover rather than mid-air |
| `shotSprite`, `shotSound` | String | optional. Image and sound for the projectile. Defaults are the green pellet and `enemies/shoot` |
| `dropChance` | Float | chance from 0 to 1 of dropping a health pickup on death |
| `knockback`, `knockbackDrag`, `stunTime` | Float | optional. Knockback taken when hit, its decay, and stun duration |
| `wanderSpeed` | Float | optional. Walking speed while wandering |
| `chargeWindup`, `chargeSpeed`, `chargeTime`, `chargeRecover` | Float | optional, chargers only. Charge attack overrides |
| `shootWindup`, `shootStep`, `shootGap`, `shootDisengage` | Float | optional, shooters only. Shoot cycle overrides |
| `shadowOffX`, `shadowOffXFlip`, `shadowOffY`, `shadowScaleX` | Float | shadow placement and width |
| `hitOffX`, `hitOffXFlip`, `hitOffY` | Float | where the 40x40 contact hitbox sits |

To add an enemy type, do three things. Put an atlas under `assets/images/enemies/`, and add a JSON file here. Then reference its file name, without the extension, from the wave table or a spawn call.

## Wave table - assets/data/waves.json

| Field | Meaning |
|---|---|
| `firstDelay` | seconds before wave 1 |
| `breather` | seconds between waves, before `scaling` shortens it |
| `baseCount`, `countPerWave` | enemy count = baseCount + wave x countPerWave, and it never stops climbing |
| `spawnBatch`, `spawnEvery` | a wave arrives in pulses of `spawnBatch` enemies, `spawnEvery` seconds apart, instead of all at once. A batch of 0 restores the single burst |
| `bossWaveMin`, `bossWaveRange` | the first boss wave is `bossWaveMin + random(0..bossWaveRange)`, rolled once per run |
| `bossRepeat` | waves between bosses after the first. 0 means the boss happens once and never again |
| `duoChance` | chance a boss wave after the run's first brings the Rofel Duo, two Rofels in one encounter, instead of one |
| `waves` | array of `{types}` spawn pools. The first entry is wave 1, and the last entry repeats for every later wave. Repeat a type inside a pool to weight it |
| `scaling` | how a wave hardens with its number, applied to every enemy as it spawns |

### scaling - assets/data/waves.json

Each multiplier is `1 + (wave - 1) x perWave`, with no ceiling. It applies to the values the enemy just read from its own JSON. Wave 1 always multiplies by 1, so the enemy files stay the source of truth for how something starts.

| Field | Meaning |
|---|---|
| `hpPerWave` | health multiplier |
| `speedPerWave` | movement multiplier. Enemies pass the player's 450 speed around wave 30 and keep going. Late runs therefore outrun you rather than let you kite |
| `damagePerWave` | contact and shot damage multiplier |
| `bossHpPerWave`, `bossSpeedPerWave`, `bossDamagePerWave` | the boss's own ramp, same shape, steeper on health and damage and gentler on speed. Each return visit is meaningfully harder, while the charge stays dodgeable |
| `breatherPerWave`, `breatherMin` | seconds taken off the gap between waves each wave, down to a floor |

Enemy count is not part of this. It grows on its own from `baseCount` and `countPerWave`.

Count is the expensive kind of difficulty. Every live enemy pathfinds against the per-frame budget in `EnemyNav`, and crowd separation compares every pair. The multipliers cost nothing by comparison.

## Player - assets/data/player.json

| Field | Meaning |
|---|---|
| `moveSpeed` | top movement speed |
| `rampStart`, `rampRate`, `rampReset` | run-up: starting speed, gain per second, and the value it resets to after standing still |
| `drag` | slowdown while you hold no key |
| `dashSpeed`, `dashTime`, `dashCooldown`, `dashIframes` | dash speed, duration, cooldown, and invincibility window |
| `healthMax`, `superMax` | meter maximums |
| `superPerKill` | super meter refunded per kill |
| `iframeTime`, `hurtLockTime` | invincibility and movement-lock time after a hit lands |
| `knockback` | knockback taken when hit |
| `timestopSlow`, `timestopHold`, `timestopRecover`, `timestopCooldown` | time stop: seconds to wind down to the full stop, seconds held frozen, seconds to ramp back, and the cooldown |

## Weapons - assets/data/weapons.json

Combat balance for every weapon system, one object per system. Field names match the system's tuning names.

| Section | Covers |
|---|---|
| `swing` | melee range and arc, slash spawn distance. The hammer's block adds `cooldown`, the wait after each swing |
| `dropLowHealthBonus` (player.json) | how much the health pack drop chance grows as you lose health. Zero keeps the flat rate, and the full bonus applies at zero health |
| `yoyo` | yoyo reach, travel speed, how long it can stay out, hit radius and the gap between repeat hits, damage, hitstop, knock, the recovery for a released throw and the longer one for a throw that tired out |
| `knock` | multiplies the push a connecting melee blow hands the enemy, so the hammer can throw one and the yoyo cannot |
| `hitBrace` | how far the struck enemy shakes, in pixels, while the hitstop holds. Zero means it takes the hit and goes straight away |
| `hitstop`, `hitstopScale`, `hitShake` | how hard a connecting melee blow bites: frames held, the speed held at, and the shake. Set per weapon, so the hammer can land heavier than the yoyo |
| `revolver` | cylinder size and damage. Reload time, which is flat and does not follow the number of rounds missing. Fan interval and jitter. Bullet speed, range, hit radius and knockback |
| `thrown` | throw distance, return speed, and the `catchCooldown` a catch starts |
| `bowCharge` | charged shot. A press below `minTime` is a plain tap shot. `fullTime` is the time to full charge, and `maxDamage` is the damage there. The `speedBonus`/`sizeBonus`/`knockBonus` multipliers scale across the charge range |
| `arrowRain` | volley size, drop delay and stagger, spread, fall speed, hit radius |
| `hook` | grab flight range. Pull speed and timeout. Grab and hold distances. Spin windup. Throw speed, duration and hit radius. Release stun, and the damage for enemies you cannot grab |
| `deadEye` | white flash length, sepia strength, fade-out length, cursor radius that paints a mark, delay between shots, damage per round |
| `superOrbit` | blade count, fire gate |
| `arrowStorm` | storm duration, spawn cadence, drops per tick |
| `hookArms` | reach and reach speed, grab radius, reel speed, grab distance, throw force, damage, cooldown, whip time, super duration |

Presentation constants stay in the owning source files. That covers trail settings, rope geometry, rest poses, ring radii, and the like. See Tuning.

## Discord - assets/data/discord.json

| Field | Meaning |
|---|---|
| `clientId` | Discord application ID for Rich Presence. Empty string disables presence. Create an application at discord.com/developers/applications, copy its Application ID here, and optionally upload Rich Presence art assets named `icon`, `hammer`, `revolver`, `crossbow`, `hook`. |

## Arena - assets/data/arena.json

| Field | Meaning |
|---|---|
| `cols`, `rows`, `tileSize` | arena size in cells, and the cell size. This is the single source everything derives from. Arena's tilemap, the editor's grid, and the painted floor layer all read it, rather than repeat 160/90/16 |
| `background` | stage image name under `assets/images/` |
| `map`, `tiles` | collision CSV and tileset file names under `assets/` |
| `spawnX`, `spawnY` | player start position |

The map CSV holds `0` (open) and `1` (solid) tiles, 16 px each. Flixel auto-tiling loads it. The outer ring is the arena wall.

Solid interior tiles become pillars. They block movement and projectiles, and they break line of sight. Arena draws block sprites over them. You edit the stock arena in this CSV, and player maps come from the in-game editor instead.

Editor maps ride the same format. `MapStore` keeps five slots. On desktop they are plain JSON files (`sx`, `sy`, `csv`) in a `maps/` folder next to the executable. That folder anchors to the executable's own path, not the working directory, so shortcuts cannot scatter them. Copy a file to share it. On html5 the slots live in the browser save.

Playing one sets `CustomArena`, a static the Arena constructor checks. When set, the raw CSV and spawn replace the stock ones, and the tilemap loader accepts them directly. Everything downstream works unchanged, because it all reads the tilemap generically. That covers pillars, pathfinding and boss obstacle clearing.

The main menu clears `CustomArena` on entry, so a normal PLAY is always the stock arena. Online runs start only from the menu, so custom maps cannot desync a co-op session.

`CustomArena` also records which slot a map came from. The quiet room is not a user slot. It ships as a built-in map, `assets/data/maps/treeRoom.json`, and `MapStore.builtin("treeRoom")` loads it on both targets. `Detour` marks it with the reserved slot -2, and that slot value is what makes a run quiet. A quiet run has no waves and hands you no weapon.

A false `EnemyDirector.spawning` stops wave pacing and the boss intro. The per-enemy tick still runs, so anything already placed still behaves. A true `Weapons.disabled` drops every attack input and hides the held sprite. The weapon card and the tutorial both stay shut.

The quiet room also takes its own music. `track()` answers `stage/Man_music` there. Everywhere else it answers the run's stage track, drawn at random from a pool when the run starts and held for the rest of it. Both stage music calls read it, so the track holds across a detour and on the path back from a boss rather than changing under the player. The main menu keeps `stage/gloomDoomWoods`, which is why that one is not in the gameplay pool.

The slot number carries this rather than a field in the map file. A field would not survive the next save, because the editor writes the map from its own document. The reserved slot keeps that rule intact: the editor never writes slot -2, and the built-in file never changes, so the marker cannot be lost.

## Paintable tilesets - assets/data/tilesets.json

An array of `tilesets`, the sheets the editor can paint floor art from. This is the layer to reach for when you want to *place* tiles from an art pack.

| Field | Meaning |
|---|---|
| `name` | shown in the editor, and what maps store |
| `image` | sheet under `assets/images/` |
| `tileW`, `tileH` | cell size the sheet is cut into |

The collision tileset must be flixel's 16-tile auto-tiling strip. This one is any image cut into a uniform grid. Most art packs therefore work if you name their cell size and nothing else. To add one, write a JSON entry and supply the image:

```json
{ "name": "CAVE", "image": "tilesets/cave", "tileW": 32, "tileH": 32 }
```

The image's own dimensions tell you nothing useful about cell size. A 768 px sheet divides evenly by 16, 24, 32, 48 and 64 alike. Only the art knows where its cells fall, so you write `tileW` and `tileH` by hand.

The editor draws grid lines over the palette, so a wrong guess shows immediately. Zoom in to check that the lines land on the seams.

The sheet does tell you one thing: its used area. Art packs often park a small strip of tiles in the corner of a big empty canvas. The palette therefore scans the image for its non-transparent bounds. It snaps them outward to whole cells, and frames that region instead of the whole file. Tile indices still count across the full sheet, so the crop only changes what you look at.

Each map holds the painted grid as its own CSV. Its cell size comes from the sheet, not from the 16 px collision grid. A 32 px sheet therefore paints on 32 px cells.

`0` is empty, and `1..N` are the sheet's cells in reading order. The layer loads with `startingIndex` 1, because flixel resolves a tile's frame as `index - startingIndex`. That keeps `0` free to mean nothing.

A switch to a different sheet clears the painted layer. The cell size changes, and therefore the grid changes with it.

Re-importing a sheet under its own name does the same thing, because that overwrites the cell size in place. The grid is a flat array read at one stride. Read the same array at a different stride and every row drifts. That shears a clean shape into diagonal bands. `EditorMap` therefore records the grid it built the array for, and drops the floor whenever the tileset moves away from it. The editor says so rather than losing the paint in silence.

Each saved map also records `tileW`. Open a map after its tileset moved to another cell size, and the floor drops on load for the same reason. A map saved before this field existed has no `tileW`, and the editor trusts it.

The floor layer goes in before the render layers, so it draws under everything that moves. It hides with the rest of the decoration during the boss fight.

Painted tiles also make up the walls. Three passes fill a wall block, and each pass covers only what the last one left blank. First comes the theme's flat colour, then its repeating texture, then any tiles painted over that spot. The painted layer therefore wins.

One map can carry brick walls in one corner and cobble in another. A single theme texture cannot express that.

The two grids need not share a cell size, and a 24 px sheet over 16 px collision is normal. The code therefore clips each overlapping tile to the block, rather than assume they align. Walls stay merged block sprites in the entity layer, so they still depth-sort.

Collision stays separate, and lives only in the arena's hidden tilemap. Pathfinding and projectiles read that map.

Painting a tile does not make it solid. The exception is the editor's `V` toggle. With it on, every collision cell a tile covers turns solid as you lay it. One stroke therefore draws a wall and makes it solid.

## Props - assets/data/props.json

An array of `props`, the decorations the editor can stamp into a map.

| Field | Meaning |
|---|---|
| `name` | shown in the editor, and what maps store. A reorder of this file therefore cannot break saved maps |
| `sheet` | image under `assets/images/` |
| `rect` | optional `[x, y, w, h]` that cuts one prop out of a shared sheet. Empty means the whole image is the prop |
| `scale` | draw scale, since the art is pixel-sized |

`rect` is what lets you use an art pack as it comes. List each prop as a region of the same sheet, rather than slice it into files.

Each map holds its placements as `{n, x, y, f}`. That is the prop name, the point its **feet** stand on, and its flip flag.

The feet anchor is deliberate. That same point is the depth-sort key. A prop further down the screen therefore draws in front. Props go into the entity layer, which sorts by feet. You walk behind a house, and in front of one below you. The boss fight strips the arena to a bare void, so it hides them, then restores them afterwards.

A prop is solid only if it has a hitbox. Shipped props carry their box in props.json. The file `library/library.json` overrides those boxes for a machine, and holds them for imported art and the layer overrides, keyed by prop name. A built-in prop can therefore gain one without a write to a baked asset. See [the editor doc](editor.md#collision-and-cover) for how a box works as collision and as cover. A prop with no hitbox is purely visual, and nothing collides against it.

Painted walls under or around a prop still work, and they put the collision in the tilemap instead.

## Languages - assets/data/lang/&lt;code&gt;.json

One flat object per language, from key to line. `en.json` is the source text, and `es.json` and `ja.json` sit beside it. All three must hold the same keys. They must also hold the same `{0}` and `{1}` markers per key, because the code passes the arguments by position.

Every line has to fit its box. Spanish runs longer than English, and the weapon card blurb has only 224 px. That one line therefore carries a hand-placed break.

Japanese has no spaces, so the text field cannot wrap it at all. Write the breaks into those lines by hand. Keep a line under about 34 full-width characters for the online help panel.

To add a language, copy `en.json`, translate the values, and add the code to `Lang.codes`. Check that the face in `Lang.font()` covers the script.

## Levelling - assets/data/levels.json

Souls style stat allocation, for the length of one run. Scrap and waves pay exp, and the repair shop spends it. The shop opens every tenth round, so the screen appears far less often than it once did and each visit carries more scrap.

Spending tells the HUD directly through `onSpent`. The game does not tick under a substate in single player, so the counter in the corner would otherwise hold its old value for the whole visit while the screen beside it counted down, which reads as scrap that never gets spent.

Nothing carries. A run starts at zero exp and zero points every time, from the menu and from a restart. `Levels` therefore holds no save at all, which is why the stats cannot drift out of step with a save written by an older build. What a run earns, that run spends.

A round is a wave, not a run. `EnemyDirector` calls `onWaveCleared` when the last enemy of a wave dies and the breather starts. The screen opens only when you can afford a level, so a round you cannot spend on never interrupts you. Nothing happens on death.

Points can be taken back. A refund returns what the level being dropped costs now, not what that point cost when it was bought, because it is a level that is being undone rather than a purchase. Any point can go back, including one bought on an earlier visit, so a build is never locked in by a shop closing.

The screen fades in and out rather than cutting. Everything on it goes through one `ui` helper, so the fade drives a single list and nothing can be left behind at full alpha. Leaving is a request rather than a close: the screen fades first and closes itself at the end, so `closeCallback` still fires exactly once and the shop's wave hold releases at the right moment.

The screen shows what a point buys before you spend it. The left panel holds the level, the exp and the cost of the next one, then the four stats. The right panel holds what those stats drive, each as the value now and the value after. Only a row the highlighted stat would move lights up.

| Field | Meaning |
|---|---|
| `scrapValue` | scrap paid for one piece picked up. It is one, and the costs are scaled to match, so the counter only ever moves by what you walked over |
| `hitbox` | `[x, y, w, h]` in art pixels, the band a prop blocks. A prop without one is walked straight through, which is what trees want and what buildings do not |
| `baseCost`, `costStep` | each stat prices itself: its next point costs `baseCost + costStep x points already in it`. Feeding one stat makes that stat dearer and leaves the others at their own price, so a specialist pays a premium and a spread stays cheap |
| `vigorPerPoint` | health added per point |
| `enduranceDashPerPoint`, `enduranceSuperPerPoint` | fraction off the dash cooldown, and fraction on to super meter gained per kill. The cooldown cut compounds, each point trimming a fraction of what remains, so the timer thins forever without ever reaching zero |
| `strengthPerPoint` | damage added per point. It is fractional, a quarter per point, and hits carry the fraction all the way to enemy health, so every point moves the number instead of every second one |
| `dexterityPerPoint` | fraction off swing, fire and reload time, compounding the same way |

Level is one plus every point spent, so the cost climbs whichever stat you feed.

The numbers are small because the game is. Health starts at 2 and a touch costs a quarter, weapons deal 1 to 3, and a basic enemy holds 3. A point of vigor is a fifth of a heart, and five points of strength is one more damage.

One of those shapes was chosen against the game rather than against the genre. Endurance raises meter gained per kill rather than the meter ceiling, because a larger ceiling means more kills for the same super, which reads as a reward and plays as a punishment.

## Editor tuning - assets/data/editor.json

Four groups hold the numbers. The `view` group covers start, min and max zoom, zoom step, and pan speed. The `palette` group covers panel width and height, padding, prop cell size, and max zoom. The `brush` group covers max size and undo depth. A `flashTime` value sits beside them.

The editor reads these into named accessors. Call sites therefore still read as constants, while the numbers stay data.

## RUN - assets/data/run.json

A hidden number, rolled once per run, in the manner of the one Undertale keeps. It gates rare content that must not appear on demand. Nothing reads it yet, so this is the framework only.

```json
{
	"min": 1,
	"max": 100,
	"events": []
}
```

`min` and `max` bound the roll. `events` names the windows that rare content sits in. Each one is `{ "name", "min", "max" }`, with an optional `"note"` for what it must trigger. The whole table of secrets therefore sits in one place, rather than scattered through the code as magic numbers.

`util.Run` is the runtime. `Run.value` reads the current roll. It takes the value from the save, and rolls one the first time if there is none. A call to `Run.reroll()` takes a fresh number and stores it. Use it wherever a run must get its own.

`Run.allows("name")` is the question gameplay asks. It is true only when the current value falls inside that event's window. An undefined name answers false, so a typo hides content rather than shows it.

`Run.allows` is the whole runtime surface. Anything else, like pinning a value for a test, goes through the save value directly.

The value persists in the save, beside the best wave and the settings. It survives a restart until something rerolls it.

`treeRoom` is the first event to read it. On a save that rolled 66, one boss wave turns into a visit to the quiet room. `Detour` holds that logic.

Three things must hold. The value sits in the window, a 1 in 66 roll comes up, and the run is solo. The room itself ships with the game, so no map file can be missing. It fires at most once. The menu and the restart both clear the mark.

The visit saves the run before it swaps arenas: wave, boss wave, health, super meter, kills and weapon. Walking back out ends it, and `resumeAfter` puts the director where it was.

The way out is the way in. `PlayState` records the feet line you arrived on, and watches for a return to it. You spawn on that line, so the check arms only after you climb 240 px away from it. Without the arming step you would leave on the frame you arrived. Nothing else ends the visit, so the room holds you for as long as you want it.

That boss wave is spent. The run picks up on the wave after it, and the next boss arrives on its usual schedule.

## Themes - assets/data/themes.json

An array of `themes`. The first entry is the look every map wears. There is no in-editor switcher, so the rest stay inert unless code selects them.

Know one thing before you add art: **the game never draws the collision tileset**. The `Arena` class hides the tilemap, and renders walls as merged block sprites. A swap of `tiles` in arena.json therefore changes collision shapes, not appearance. A theme is what changes how a map looks.

| Field | Meaning |
|---|---|
| `name` | shown in the editor |
| `background` | stage image under `assets/images/` |
| `wall` | optional image tiled across the wall blocks. Empty means a flat colour |
| `wallRect` | optional `[x, y, w, h]` region of that image to tile. Empty means the whole file |
| `wallColor` | wall colour as `RRGGBB`, also the fill behind a wall texture |

`wallColor` is RGB only on purpose. A full ARGB literal like `0xFF1C1010` is larger than a signed 32-bit int. A parse of it clamps to `0x7FFFFFFF`, and every wall comes out translucent white. The code ORs the alpha on instead.

The colour is the base coat under a wall block, and a painted tile covers it. An unpainted cell over a wall therefore shows this colour raw. The first theme holds black for that reason. Erase a tile over a wall and the hole reads as void, rather than as a patch of a different colour.

Only player maps read the theme. `WallSkin` gives up early unless `CustomArena` is active, so the stock arena keeps the `0xFF1C1010` default that the class itself holds.

`wallRect` is what makes an art-pack sheet work directly. Point it at the one patch you want repeated, rather than slice the sheet into a new file. To add a theme, write a JSON entry and supply the images. No code changes:

```json
{
  "name": "SANDSTONE",
  "background": "stages/desert",
  "wall": "tilesets/desert_sheet",
  "wallRect": [0, 96, 48, 48],
  "wallColor": "C86432"
}
```

The first theme applies to editor maps only. The stock arena keeps its arena.json look.

Back to the [documentation index](../DOCS.md).
