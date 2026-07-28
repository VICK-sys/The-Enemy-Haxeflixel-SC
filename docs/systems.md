# Systems, entities and utilities

The per-run machinery owned by PlayState, the sprites it drives, and the shared helpers.

## Systems (source/systems/)

PlayState builds each system once and updates it once per frame. The exception is `MenuList`, which the menu states build.

### Arena

Loads the background and collision tilemap, sets world and camera bounds, and generates pillar sprites from the map data. It answers `wallAt(x, y)`, which is always false while side view is active.

It also owns the side-view landscape. The sky gradient and ground slab come from `buildSideAssets()`. A call to `applySideMorph(t)` interpolates the whole landscape between perspectives. The floor art sinks and dims, and the sky curtain descends. The ground slab fades in, and every pillar stretches into its floating platform. The platform rectangles come from `sidePlatforms()`.

Platform targets come out of the same pass as the pillars. Each keeps the pillar's x and takes a width of at least 150 px. Its height maps from how far north the pillar stands. North becomes high.

It owns the boss-intro transition too. `beginBossTransition()` shakes the camera and fades a white overlay in. It then swaps the background for the warping checkerboard grid, which a `WarpShader` distorts. It clears the interior pillars for an open boss arena, removing their sprites and emptying their collision tiles. It then fades the white back out.

That sequence runs from `update(elapsed)`, which also advances the shader. At the fully-white moment `onWhiteout` fires once, cutting the alarm and starting the boss music. After the boss dies, `endBossTransition()` reverses everything. A quick white flash restores the normal background and drops the shader. It rebuilds the pillars through `restoreObstacles`, which reloads the map CSV. It then fires `onNormal` to restore the normal music.

### DecorTiles

The painted floor layer: grid maths, CSV round-tripping, and building the tilemap from a map's tiles. The editor and the game share it. It is purely decorative, and nothing ever collides against it.

### WallSkin

How a run's walls look. It reads from `CustomArena` once at construction: the theme's colour and repeating texture, plus the painted tiles stamped over them. Arena hands it each wall block to fill. Arena therefore keeps to geometry and the boss transition, while the skin owns every pixel decision.

### Decor

Builds a map's decoration sprites from its placements. The editor and the game share it, so a map looks the same in both.

It cuts each prop out of its sheet once and keeps it in flixel's cache under its own persistent key. The cache clears between states, and a plain BitmapData handed to `loadGraphic` would go with it. It also owns the feet-anchored placement both sides use.

### Fx

Hitstop, which drops the time scale for a few frames on kills. Camera shakes, hit spark bursts, and the dash speed-line trail. It also holds `bossBlast`, the boss death explosion. One place builds it, so the host's real death and a client's mirrored one cannot drift apart.

### RenderLayers

The shadow, entity and tag render groups. It sorts the entity layer every frame by feet position, so characters, pillars and decorations overlap correctly. The tag layer sits above that sort, so a name is never hidden by whoever stands behind it.

### PlayerCombat

Player health and the AP meter. Damage intake, invincibility frames and blink. Dash input, death and revive, and the run's kill counter. The HUD bars bind straight to its fields.

It re-asserts death every frame, rather than only on the transition. Several weapon systems clear `blockMovement` when they finish, and one finishing after you die would otherwise hand control back. So while dead it reapplies the block, and restores the death animation if anything overrode it. Separately, `Player` refuses to run its movement routine while `isDead`. That is what actually keeps a corpse from walking and playing an idle.

### EnemyDirector

Wave pacing and the per-enemy tick. It owns the rigs: enemy, shadow and contact hitbox. It walks them each frame for targeting, entry, shadows, contact damage and cleanup. It also answers the circle queries every weapon aims with.

Three collaborators hold what it used to. Where an enemy goes belongs to `EnemySpawner`: edge placement, the stuck watchdog, and the rescue that frees a wedged enemy. All three ask the same thing, which is where clear ground lies.

A spot counts as clear only if the foot box that actually collides with props is clear. The check samples the enemy's full width at its feet, not its body centre. The two disagree. An enemy can go solid because its centre is clear. It then wedges on the prop its feet already sit inside.

The watchdog treats an enemy as stuck when something drives it but it does not move. It does not simply look for an enemy standing still far away. One wedged next to the player is therefore caught too. The rescue then looks for clear ground in rings around where the enemy stands. It falls back to relocating near the player only when nothing close is free.

`EnemyShots` owns the projectile group. It emits what an enemy queued, and kills shots on walls, props or the player. The shake-then-explode sequence lives in `BossDeath`. That has its own lifetime and touches nothing else. `EnemyRig` moved to its own file so the spawner can take one. The director forwards a callback that moved with a collaborator as a property. The network layer wraps them rather than simply setting them.

`applyWaveScale` scales every enemy as it spawns. It turns the wave number into health, speed and damage multipliers from the `scaling` block. The client applies the same thing in `addPuppet`. Each machine charges contact damage locally, and the two would otherwise differ.

A randomly chosen wave, 4 to 8 and rolled once at startup, is the first boss wave. It fires the `onBoss` callback, which starts the intro cinematic. After a short intro delay it spawns a single `"rofel"` enemy instead of the normal count.

When the boss dies the director runs a defeat sequence. The boss shakes in place, then plays an explosion animation with a boom sound. Once the explosion finishes, `onBossDefeated` fires. That reverts the arena and music to normal.

The director is also the single home of enemy hit queries. `firstInCircle` and `eachInCircle` run the nearest-hitbox-point circle test every attack uses. Both see live enemies only, and `firstInCircle` can skip seized ones.

A wave ends only once every enemy is dead. One enemy that could never reach the player would therefore hang the run forever. Two guards prevent that.

Spawned enemies pass through walls while entering. They turn solid only once they are inside the arena and clear of any pillar. They therefore cannot turn solid inside one. Beyond that the watchdog relocates a stuck enemy. As a backstop, a wave running longer than 75 seconds relocates everything still alive. The boss is exempt, since its movement is its own choreography.

### Pickups

The health pickup pool. The player collects one on contact, unless health is full.

### TimeStop

The time-stop ability on E, with a cooldown from player.json. It ramps a world-time factor from 1 to 0 over the slow phase. It holds the world frozen for the stop duration, then ramps back.

It publishes that factor through `WorldClock`. Enemies, enemy shots and pickups read it, and scale or skip their own updates. PlayState multiplies it into the elapsed it passes to the director and arena. Wave timers, boss logic and cinematics therefore freeze too.

The player, weapons and player projectiles run at full speed throughout. Seized enemies stay in player-time, so the hook still works on frozen targets. Frozen enemies are immovable statues that deal no contact damage, and frozen shots hang harmlessly in the air.

Music pitch rides the factor down for the record-slowdown effect, pauses at the full stop, and ramps back on resume. While time runs slow the player leaves a blue afterimage trail, built from frame-accurate ghosts through GhostTrail. A subtle blue overlay tints the screen. The HUD shows READY, the cooldown, or STOPPED through `hudLabel()`. Dying cancels the stop.

### WeaponFlyIn

The handover after the weapon pick. The chosen weapon arcs from its card to the player's hand, spinning and growing from card scale to held scale. The real held sprite hides until it lands.

It draws on the UI camera and re-reads the hand every frame in screen space. The throw therefore still lands correctly while the camera moves. Dying mid-flight drops the weapon rather than handing it to a corpse.

### MenuList

The shared menu widget used by the main menu and options. It is a centred column of text rows with a bobbing weapon selector. It takes W/S and arrow navigation, A/D value adjustment, mouse hover and click, and plays the move and select sounds. Owners supply `onChoose` and an optional `onAdjust`, and can rewrite row labels in place.

### Hud

The UI camera, health and AP bars, wave counter and banner. Both bars sit in the one widget in the bottom left, where the narrow strip above the health bar reads AP. That strip used to be decoration, and AP used to sit in the opposite corner, which put the two numbers you watch most at opposite ends of the screen. The red BOSS APPROACHING banner shares the same text and slides down from the top. It also owns the revolver ammo readout and the crossbow's blue gauge. It holds the time-stop status label and its fading countdown. It also holds the death text with the best wave, and the custom cursor. It owns a `BossHud`, and hands the boss bar and screen flash to it.

The health bar is an `FlxBar` bound by reflection to `status.health`. The AP strip cannot be, because both bars live in one piece of art. `bar_red` draws the whole widget, so an `FlxBar` over the strip would clip against the full widget width and read full at two thirds. The strip therefore takes a plain sprite with a `clipRect` measured against the strip's own span, and `bar_ap_empty` covers the background's red so the strip can read empty. `bar_main_red` is the health fill with the strip cut out of it, without which the health bar repaints the strip red over the top.

### BossHud

The boss-fight HUD pieces: the pulsing red screen flash and the boss health bar. A call to `showBar(boss)` binds a bar to the boss's HP and plays its entrance. The bar expands out from a compressed sliver as it drops in from the top. The name "Rofel" then fades in letter by letter beneath it. The bar hides itself once the boss is gone.

### PerspectiveShift

The perspective totem and the top-down / side-view switch, in `systems/perspective/`. It splits across `Totem`, `MeteorArrival` and `PerspectiveShift` itself. See [perspective.md](perspective.md).

## Entities (source/entities/)

### Player

WASD movement with an acceleration ramp, a dash, and the walk sound loop. It carries two skins: the top-down sparrow atlas, and a side-view grid sheet described by `sideSkin` in player.json.

`applySkin(side)` swaps the graphic and rebuilds the four animations under the same names. Every caller therefore works against either skin, including hurt, death and the ghost trails. The hitbox stays 75x95 in both, so all movement and feet maths stay perspective-independent. Only the draw offset differs.

The skin changes in `setSideMode`, which the shift calls once the morph finishes. The player therefore keeps its top-down look while the stage folds over. It turns 2D on the frame the new world settles.

The field `baseOffsetY` is public here for the supers. They ride the player's draw offset for hover and somersault lift. They must follow a skin change, rather than a value cached at startup.

`shadowCenterX` exists because the side sheet's artwork is not centred in its cells. The walk frames sit right of centre. Mirroring the sprite therefore swings its visual centre by 28 px, while a fixed shadow offset would not move. The player measures each cell's true content centre once as the sheet loads. It then reports where the shadow belongs, mirrored when facing left. That keeps the shadow under the character in every animation, and re-derives itself if the sheet is redrawn.

### HealthPickup

A dropped heart. It restores health on contact and expires after a few seconds.

## Weapon projectiles (source/entities/weapon/)

- `SlashEffect` - the pooled swing visual. It drifts forward briefly and fades out, and carries no hitbox.
- `ThrownWeapon` - the airborne hammer. It spins, stretches on release, throbs in flight, and hits each enemy once per flight leg, out and return.
- `Orbiter` - one orbiter. SuperOrbit positions it while it circles. Once launched it flies straight, pierces with one hit per enemy, and fades at range.
- `Arrow` - the bow's projectile. It flies straight and fast, dies on the first enemy hit or a wall, and expires at range.
- `Bullet` - the revolver's round. It draws from `assets/images/bullets/`, round for a hand shot and long for a Dead Eye one. It draws at the same 4x as the player, so a bullet matches the pixel size of everything else. It dies on its first hit or at the end of its range.
- `HookShot` - the hook's projectile. It flies head-first. Once latched it sticks to the hooked enemy until the throw resolves.
- `RainArrow` - an arrow rain volley member. It is either a fading skyward launch visual, or a falling arrow that lands at its assigned impact point.

## Enemy behaviour (source/entities/enemy/)

### Enemies

The one enemy class. It loads its definition from JSON by kind: `"enemy"`, `"woodster"` or `"likwid"`.

The sprite keeps only what every enemy has, whatever it does. That is stats, damage and death, the seized, stunned and frozen states, and the walk-on entry. It hands the actual thinking to two behaviours it owns, in the same shape as the `AttackBehavior` it already carried.

`EnemyBrain` is the top-down three-state FSM: Wandering, Following and Attacking. It holds the wander timers and the pathing steer. Once the world flips to side view, `EnemySideStep` takes over. It walks and hops along the ground instead.

Split like that, neither one has to test which mode the world is in. The sprite picks one and calls it.

Wave-spawned enemies start off screen in an entering mode. That walks them through the border wall before collision turns on. Grabbed enemies have one release path, `unseize(releaseStun)`. It clears the seize, restores drag, and optionally applies a release stun. It also grants the short throw grace that keeps a just-thrown enemy from hurting the player.

### EnemyNav

The line-of-sight and pathfinding component. A few times per second it checks a body-width corridor toward the target, using two offset rays. When a wall blocks that corridor, it runs A* over the map. It simplifies the result with a body-sized box cast, then steers along the waypoints. Wall contact while chasing forces an immediate re-path.

### Attack behaviours

`AttackBehavior`, `ChargeAttack`, `ShootAttack` and `RofelBoss` are the attack style interface and its implementations. A charge is a windup, a straight lunge and a recovery. A shooter holds position, cycles its shoot animation, and requests a projectile on the loop frame.

`RofelBoss` is the boss brain, ported from the RofelShooter game. It kites the player, keeping a preferred distance band and strafing sideways, bouncing off walls. It cycles through Rofel's five guns: pistol, shotgun, sniper, revolver and laser. Each carries its own bullet sprite, speed, spread, damage and burst pattern. A held gun sprite rotates to aim at the player and swaps per weapon. Enemies with the `"boss"` attack are `selfDriven`, so they skip the normal FSM and run this brain directly.

### Shots

`EnemyShot` is the pooled enemy projectile. It carries its damage, speed, range and optional sprite from the shot request, and sprite bullets rotate to face travel.

`ShotSpec` is one queued shot request: direction, damage, speed, range, sprite, sound, and an optional spawn origin. Behaviours push these onto the enemy's `pendingShots`, and the director drains and fires them. That lets the boss fire multi-bullet volleys with per-shot parameters.

## Data modules (source/data/)

- `DataLoader` - reads and parses a JSON asset. It throws with the path in the message if the file does not exist.
- `EnemyData`, `PlayerData`, `WaveData`, `ArenaData`, `WeaponData` - typedefs and parse-once registries for the files under `assets/data/`.

## Utilities (source/util/)

### Paths

Asset path builders: `image`, `sound`, `music`, `file`, `json`, and `sparrow`, which returns the loaded atlas for a png and xml pair.

### BushDrift

The canopy never sits still. `BushDrift` walks a prop round a tiny square, three pixels out from where the map placed it, at five pixels a second. `treeBush` runs it one way, and `treeBush2` runs the same square backwards. The two layers therefore pull against each other, and the red mass breathes.

It moves `x` and `y`, not the draw offset. A `PropSprite` caches its sort key in `sortY` when the map places it, so a moving prop keeps its place in the depth order. Without that cache, three pixels would flip the two bushes past the trunk and past each other on every lap.

### PetalFall

Petals breaking off the canopy. They drift south east while they fade, one every second or so. Each takes a random speed, a random life and a random start, so no two fall alike. A slow sine on the horizontal makes them flutter rather than slide.

They leave from the underside of the art, not from a guessed rectangle. The class reads `treeBush2` once and records the lowest opaque pixel in each column of its right half. A spawn picks one of those columns and starts there. A rectangle put petals in the transparent space under the sheet, because the art stops well short of the bottom of its canvas.

The reading is in source pixels, and the spawn converts through the sprite's live position and scale. The bush drifts, so the petals leave from where it is at that moment.

They draw in their own group, and that group goes in above the occlusion overlay rather than merely above the entity layer. Standing behind the tree makes the player buried, and `PropWorld` answers that by redrawing the front of the sorted layer over everything under it. A petal group below that overlay therefore vanished behind the walls for exactly as long as the player stood behind the tree.

The pool holds twelve and recycles the dead, so nothing is built while the room runs.

### TreeMan and DialogueBox

The man behind the tree. `TreeMan` runs only in the quiet room. It finds its spot from the `tree` prop rather than from a fixed coordinate, so moving the prop moves the man with it. He sits a little behind the trunk, so you have to walk round the tree to reach him. Nothing on screen says so.

He has no sprite. You never see him, which is the point of him.

`TreeMan.told` counts the talks and picks the next block of lines. It reads `talk.man<n>.1`, then `.2`, and stops when a key comes back unresolved. A block therefore grows or shrinks by editing the language file alone. After the last block he answers nothing more.

The count is a static. Once he has said his piece, he stays gone for the rest of the session.

`DialogueBox` is the box itself: a white border, a black fill, and a silent typewriter. It draws on the HUD camera, so the quiet room's zoom does not touch it. A press finishes the line early rather than skipping it, then the next press turns the page. The player cannot move while it is open.

The exit check pauses while a box is open. Walking out is what ends a visit, and the check should not fire on a player who cannot move.

### Lang

The string table for the game UI. It holds English, Spanish and Japanese, and `Lang.t(key, args)` reads one line. Arguments replace the `{0}` and `{1}` markers in the line. An unknown key falls back to English, then to the key itself. A key therefore never renders as blank.

`Lang.cycle(dir)` steps through `Lang.codes` in either direction, so the option row answers both left and right.

The map editor keeps its English strings, because it is a build tool rather than a player screen.

`Lang.font()` answers the font every UI text must use. English keeps flixel's default face, and every other language takes `DotGothic16-Regular.ttf`.

That default face is the reason for the split. It carries no kana and no kanji, so Japanese cannot render in it at all. It also draws every accented capital as a lowercase glyph, which turns `RÉCORD` into `RéCORD`. It draws the inverted exclamation mark as a plain `i`. The UI is all capitals, so Spanish needs the swap as much as Japanese does.

The name tag over a remote player reads the same font.

The boss name and the game title stay in the default face. Both read as logos rather than as sentences. The boss name also splits into one sprite per letter for its reveal, which needs stable Latin widths.

A language change writes to the save and raises a flag. The main menu reads that flag with `consumeChanged()` and rebuilds itself. In a run, the pause screen relabels itself and the HUD re-applies the font. Nothing rebuilds the whole play state.

### GhostTrail

A pooled afterimage trail. It fades its ghosts every tick. On a fixed cadence it stamps a copy of a source sprite, carrying position, angle, scale and colour. The time-stop player trail instead uses `stampFrame`, which copies an animated sprite's current frame with a forced tint. The thrown hammer, the orbiters, the Arrow Storm launch arrow and the time-stop trail all use it.

### WorldClock

The world time scale, at 1 normal and 0 frozen. World entities that update through the display list read it.

It holds two sources rather than one value. One belongs to `TimeStop`, the other to Dead Eye. The `scale` field reports whichever is slower. A single field could not survive two writers. Assignment happens every frame inside `TimeStop`, which would overwrite anything else before the enemies read it.

### WarpShader

A GLSL fragment shader that distorts a sprite's texture coordinates with time-driven sine waves. The boss-arena grid background uses it, and `advance(elapsed)` steps its time uniform.

### SaveData

The persistent save: best wave reached, the settings, the last joined IP, and the online player name. The settings are master volume, fullscreen, and FPS counter visibility. A call to `applySettings()` pushes them into the engine. It runs at boot and whenever an option changes.

### CustomArena

The map the editor asked the next run to use, as raw CSV plus a spawn point. Null means the stock arena. The main menu clears it.

### MapStore

The editor's five map slots. They are JSON files next to the executable on desktop, and browser save on html5.

### MenuSlash

The menu's confirm animation. The weapon selector winds up to the left of the chosen row and sweeps through it. On contact the row hides, and one sprite per letter replaces it. Those letters tumble away under gravity and fade. The option is therefore cut apart and falls into the void before the game acts on it.

It measures letter widths individually, then scales them to span the row's real width. That keeps the swap smooth at the moment the shards appear. Every menu choice routes through it, and returning from Options restores the shattered row.

### JaggedBand

A sawtooth strip that scrolls sideways forever, used to frame the main menu. The tooth shape comes from Will Boyd's "Hello Houdini: Jagged Edge with Mask" pen. Walk across the width, alternating between a peak and a valley. Then close the polygon along the bottom and fill it.

It does not redraw the strip every frame. It draws it once at two teeth wider than the screen, then simply slides it left, wrapping every tooth width. The motion therefore costs nothing and never shows a join. Setting `top` flips it vertically for the upper edge, and a negative speed scrolls the other way. That is how the menu gets its two mirrored pairs.

### IrisWipe

The state transition. A black overlay carries the game icon punched out of it as a transparent hole. The hole grows to reveal a state on arrival, and shrinks to swallow it on the way out.

It builds the mask once and caches it as a persistent `FlxGraphic`. It draws the icon into a square bitmap and inverts its alpha, so the icon silhouette becomes the hole. It must be persistent. Flixel clears its bitmap cache between states. A plain cached BitmapData therefore dies after the first transition, and every later wipe renders as a bare square.

Four oversized black bars track the mask's edges, so the screen stays covered however small the hole gets. It draws on its own camera added on top, so it covers the HUD as well as the world. When finished, `open` hides itself, so the icon's concave notches never linger over gameplay.

`FlxTween.num` drives the scale. The fully open scale clears the screen comfortably. Anything smaller would pop black into the corners the moment a close began. The title sequence, the menu, the pause menu's quit and the death restart all use it.

### Music

The single owner of music playback. `play(name, volume, loop)` switches tracks only when the requested track differs from the current one. Asking for the playing track instead applies the volume, restores pitch, and resumes it if paused. That is what keeps the stage theme unbroken across the menu, the game, pause-quit and restarts.

### SideView

Global side-view state, following the WorldClock pattern. It holds `active`, `morphing`, `groundY`, the platform rectangles, and the shared helpers the player, enemies and pickups use. Those helpers are gravity, one-way platform landing, `settle` and `placeShadow`. `settle` is the snap-or-fall resolve every side-mode body runs each frame. Physics values load from sideview.json in `reset()`.

Shadows anchor to each entity's existing feet offset, so a grounded character looks identical to top-down. In side view an airborne one drops its shadow onto the surface below, ground or platform. That shadow shrinks and fades with height. PlayState resets it on every run.

### DiscordPresence

Discord Rich Presence, Windows native only, through the `hxdiscord_rpc` haxelib. Every method is a no-op on HTML5. It reads the application ID from `assets/data/discord.json`, and stays silent if that is empty.

PlayState feeds it the raw facts each frame through `playing(wave, bossFight, weapon, kills)`, and it diffs internally. Wave changes, the boss fight, weapon switches, pause and death push immediately. Kill-count changes throttle to one update every couple of seconds.

It shows the current wave or boss fight, plus the equipped weapon and kill count. It shows run elapsed time through the start timestamp, and the best wave on the menu and death screens. Image keys are `icon` for the large slot, and `hammer`, `revolver`, `crossbow` or `hook` for the small per-weapon slot. You upload that art to the Discord application.

### PerfLog

A frame-time logger for native builds. It writes `perflog.txt` next to the executable. Each second gets one aggregate line of average, worst and fps. Spike frames and long gaps get an immediate line. Every line carries the live enemy count, pathfinding calls, projectile count and wave. The projectile count covers enemy shots, bullets, arrows, rain arrows, the thrown hammer and the hook.

---

Back to the [documentation index](../DOCS.md).
