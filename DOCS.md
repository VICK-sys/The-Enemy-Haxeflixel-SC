# Documentation

Code and data reference for THE ENEMY. Controls and build commands are in [README.md](README.md).

## Project layout

```
assets/
  data/enemies/*.json    enemy definitions
  data/waves.json        wave table
  data/player.json       player stats
  data/arena.json        arena definition
  data/sideview.json     side-view physics, platform mapping, morph and meteor tuning
  default_auto.txt       arena collision map (CSV)
  auto_tiles.png         tileset for the collision map (not rendered)
  images/ music/ sounds/ art and audio
source/
  Main.hx                entry point
  net/                   online co-op: transport, sync, puppets
  states/                game states
  states/tutorial/       the tutorial's animated demo pages
  systems/               core systems owned by PlayState
  systems/perspective/   the totem, its meteor arrival, and the view morph
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
- `MainMenuState` - the main menu: PLAY, OPTIONS, and QUIT (QUIT is desktop-only) on a black background framed by two pairs of scrolling `JaggedBand` teeth (a dark, slow, coarse pair behind a bright accent pair, drifting opposite ways for depth), with the title, a yellow splash line angled across the title's lower-right corner that throbs in and out, the best wave in the corner, and menu music. Navigated with W/S or the arrows plus ENTER, or by mouse hover and click. PLAY fades to black and switches to PlayState; OPTIONS opens `OptionsSubState`. QUIT collapses the OS window like a CRT switching off, as a chain of three `FlxTween.num` tweens that drive the window's size and opacity: the frame is dropped so the window can shrink freely, its height squeezes to a horizontal sliver while the width holds, then the width pinches to a dot and the window fades out, and the last tween's completion shuts down Discord presence and exits. Windows will not shrink a window past about 36 px, which is why the last of the vanish is done with opacity rather than size. The collapse is desktop-only; other targets keep the plain fade-to-black exit.
- `OptionsSubState` - the options panel over the menu: master volume (adjust with A/D or the arrows, or click to step), fullscreen toggle, FPS counter toggle, and a reset-best-wave action that asks for a second press within a few seconds to confirm. All settings apply immediately and persist in the save file. ESC or BACK closes it.
- `PlayState` - constructs the systems in `create()`, calls them in order in `update()`, and handles the debug keys. It holds no gameplay logic of its own.
- `PauseSubState` - opened with ESC. Freezes the game and pauses all audio, dims the screen, closes on ESC. Volume keys work while open.
- `OnlineHelpSubState` - the co-op explainer, styled like the controls popup and shown the first time the online lobby opens each session; H reopens it. Three pages flipped with A/D: what co-op is, how to host or join (including the `IP:PORT` form when the host has fallen back to another port), and what behaves differently online. Because the lobby keeps updating while a substate is open - the socket has to stay serviced so a friend can still connect while you are reading - the lobby explicitly hands input ownership to the popup and skips its own key handling, which also stops one ENTER or ESC from being consumed twice.
- `TutorialSubState` - the controls popup shown the first time PlayState opens each session. Seven pages (move, attack, weapons, modes, super, abilities, health) flipped with A/D or the arrow keys, each with a looping animated demo built from game sprites. The abilities page demos time stop: four enemies close in around the player until the stop triggers, then they freeze mid-stride while the player keeps running laps around them with the blue afterimage trail, steering clear of every frozen body, and everything ramps back up on release. The popup fades in on open; ENTER or ESC freezes the demo and fades it back out before starting the game. The wave timer is frozen while it is open. Each page's demo is its own class under `states/tutorial/` (MoveDemo, AttackDemo, WeaponsDemo, ModesDemo, SuperDemo, AbilitiesDemo, HealthDemo), all extending `TutorialDemo` - a group base with the shared sprite/text/player factories, the demo clock, and a per-frame `step()` hook. The substate itself only owns the panel, the page texts, and page flipping; flipping destroys the old demo instance and constructs the next.

## Systems (source/systems/)

Each system is constructed once by PlayState and updated once per frame (except `MenuList`, which the menu states construct).

- `Arena` - loads the background and collision tilemap, sets world and camera bounds, generates pillar sprites from the map data, and answers `wallAt(x, y)` (always false while side view is active). Also owns the side-view landscape: `buildSideAssets()` creates the sky gradient and ground slab, `applySideMorph(t)` interpolates the whole landscape between perspectives (the floor art sinks and dims, the sky curtain descends, the ground slab fades in, and every pillar stretches into its floating platform), and `sidePlatforms()` exposes the platform rectangles. Platform targets are computed alongside the pillars: same x, width at least 150 px, and a height mapped from how far north the pillar stands - north becomes high. Also owns the boss-intro transition: `beginBossTransition()` shakes the camera and fades a white overlay in, then swaps the background to the warping checkerboard grid (a `WarpShader` distorts it), clears the interior pillars (removes their sprites and empties their collision tiles for an open boss arena), and fades the white back out. `update(elapsed)` drives that sequence and advances the shader; `onWhiteout` fires once at the fully-white moment (used to cut the alarm and start the boss music). `endBossTransition()` reverses it after the boss dies - a quick white flash restores the normal background, removes the shader, and rebuilds the pillars (`restoreObstacles` reloads the map CSV), firing `onNormal` to restore the normal music.
- `Fx` - hitstop (time scale drops for a few frames on kills), camera shakes, hit spark bursts, and the dash speed-line trail.
- `RenderLayers` - the shadow and entity render groups. The entity layer is sorted every frame by feet position so characters and pillars overlap correctly.
- `PlayerCombat` - player health, the AP meter, damage intake, invincibility frames and blink, dash input, death and revive, and the run's kill counter. The HUD bars bind directly to its fields. Death is re-asserted every frame rather than only on the transition: several weapon systems clear `blockMovement` when they finish, and one that finishes after you die would otherwise hand control back, so while dead the block is reapplied and the death animation restored if anything overrode it. `Player` independently refuses to run its movement routine while `isDead`, which is what actually keeps a corpse from walking and playing an idle.
- `EnemyDirector` - spawns waves from the wave table, owns the per-enemy rigs (enemy, shadow, contact hitbox), runs enemy collision and cleanup, and updates enemy shots. A randomly chosen wave (4-8, rolled once at startup) is the boss wave: it fires the `onBoss` callback (which starts the intro cinematic) and, after a short intro delay, spawns a single `"rofel"` enemy instead of the normal count. When the boss dies the director runs a defeat sequence - the boss shakes in place, then plays an explosion animation with a boom sound - and fires `onBossDefeated` (which reverts the arena and music to normal) once the explosion finishes. Also the single home of enemy hit queries: `firstInCircle` and `eachInCircle` do the nearest-hitbox-point circle test every attack uses (live enemies only; `firstInCircle` can skip seized ones).

  A wave only ends once every enemy is dead, so one enemy that can never reach the player would hang the run forever. Two guards prevent that. Spawned enemies pass through walls while entering and only become solid once they are inside the arena *and* clear of any pillar, so they cannot turn solid inside one. Beyond that, any enemy that is more than 700 px away and has not moved for five seconds is relocated to a clear spot near the player, and as a backstop a wave running longer than 75 seconds relocates everything still alive. The distance condition is what makes this safe: enemies that legitimately stand still (a woodster shooting, which it only does within about 580 px) are never touched, and a chasing enemy is always moving. The boss is exempt, since its movement is its own choreography.
- `Pickups` - the health pickup pool. Collected on player contact unless health is full.
- `TimeStop` - the time-stop ability (E, cooldown driven by player.json): ramps a world-time factor from 1 to 0 over the slow phase, holds the world frozen for the stop duration, then ramps back. The factor is published through `WorldClock.scale` (read by enemies, enemy shots, and pickups, which scale or skip their own updates) and PlayState multiplies it into the elapsed passed to the director and arena, so wave timers, boss logic, and cinematics freeze too. The player, weapons, and player projectiles run at full speed throughout; seized enemies stay in player-time so the hook still works on frozen targets. Frozen enemies are immovable statues that deal no contact damage, and frozen shots hang harmlessly in the air. Music pitch rides the factor down (the record-slowdown effect), pauses at the full stop, and ramps back on resume. While time is slowed the player leaves a blue afterimage trail (frame-accurate ghosts via GhostTrail), and a subtle blue overlay tints the screen. The HUD shows READY / cooldown / STOPPED via `hudLabel()`. Dying cancels the stop.
- `MenuList` - the shared menu widget used by the main menu and options: a centered column of text rows with a bobbing scythe selector, W/S and arrow navigation, A/D value adjustment, mouse hover and click, and the move/select sounds. Owners supply `onChoose` and optional `onAdjust` callbacks and can rewrite row labels in place.
- `Hud` - the UI camera, health and AP bars, wave counter and banner (the red BOSS APPROACHING banner shares the same text and slides down from the top), the mode indicator (label plus icon, animated on switch), the time-stop status label and fading countdown timer, death text with the best wave, and the custom cursor. Owns a `BossHud` and delegates the boss bar and screen flash to it.
- `BossHud` - the boss-fight HUD pieces: the pulsing red screen flash and the boss health bar. `showBar(boss)` binds a bar to the boss's HP and plays its entrance: the bar expands out from a compressed sliver as it drops in from the top, then the name "Rofel" fades in letter by letter beneath it. The bar hides itself once the boss is gone.
- `PerspectiveShift` (systems/perspective/) - the perspective totem and the top-down / side-view switch, split across three classes: `Totem` (the sprite, glow, shadow, faces, hit flash, and hit test), `MeteorArrival` (the crash sequence and its particles), and `PerspectiveShift` itself (the morph phase machine, entity movers, probe gating, and boss lock). Timing and tuning come from sideview.json. The totem is not in the arena at the start of a run: it crashes down like a meteor on a randomly rolled wave (`totemWaveMin`/`totemWaveRange`). The arrival picks a clear spot 300-430 px from the player so the crash happens on screen, pulses a red warning decal on the ground for about a second, drops the totem from far above trailing embers, and lands with a boom, camera shake, a dust ring, and a shockwave that damages nearby enemies. Gameplay continues throughout - it is an event, not a cutscene. If the roll lands on a locked wave (a boss fight) the arrival waits for the next wave. Until it lands the totem is invisible and inert; afterwards it listens to every attack hit-test through the director's `onProbe` hook, so any weapon that touches it triggers the switch. The impact shockwave runs through that same hit query, so the landing starts the totem's hit cooldown before firing the blast - otherwise the meteor would trigger itself and flip the world the instant it touched down. The totem wears one of two faces, `stage/totem_top` in top-down and `stage/totem_side` in side view, swapped as each morph begins so it shows the mode it is taking you to; the glow is the same art blended additively behind it. Its crash site becomes the position it returns to when reverting from side view. The morph freezes combat (enemy updates pause, shots clear, contact damage off, inputs held), plays its direction's swap sound (`platswap_side` going to 2D, `platswap_top` coming back), drives the landscape through `applySideMorph`, and glides the player, enemies, and totem to their remapped positions over about a second and a half - entities farther north end up higher, then fall. When the morph completes `SideView.active` turns on and the game plays as a platformer: A/D run, W jumps (one air jump), dash stays horizontal, all mouse-aimed weapons work unchanged, waves walk in on foot from the left and right edges at ground level rather than dropping from above (in top-down they still arrive from all four edges), enemies chase along the ground and hop after a raised player, shooters keep shooting (the attack behaviors are written for the top-down plane and set a full 2D velocity, so side view preserves the enemy's vertical velocity across the behavior call - gravity stays with the world, horizontal movement stays with the behavior), hearts fall, and time stop freezes everything mid-air. Hitting the totem again morphs back with the inverse mapping. A boss wave force-reverts at double speed and locks the totem until the arena is normal again. The totem also vanishes for the fight exactly as the pillars do - `clearTotem()` on the whiteout that strips them, `restoreTotem()` on the reverse flash that rebuilds them. Since the director fires the wave callback before the boss callback, an arrival rolled onto the boss wave would start and only then be locked, so the boss also cancels an in-flight arrival; the meteor simply crashes down on a later wave instead. Because combat is frozen mid-morph, the shift keeps the held weapon anchored to the player itself (`Weapons.anchorHeld()`, position only) so it travels with them, and retracts a deployed hook before the move so no rope is left stretched across the arena - retracting first also clears the grapple's movement block, which would otherwise be restored when the morph ends. Totem hits are ignored while a super is running or scythe blades still orbit, since those systems drive the player and their own sprites.

## Multiplayer (source/net/)

Two-player online co-op, desktop only, chosen from ONLINE on the main menu. One player hosts on TCP port 7777 (forwarded on their router) and the friend joins by IP. If 7777 is already in use - Terraria and several other games default to it - the host walks up to the next free port through 7786 and the lobby says which one it landed on, since the friend then has to join with `IP:port` rather than a bare address. The joining side has always accepted that syntax. The model is host-authoritative: the host runs the entire single-player simulation unchanged - waves, enemy AI, pathfinding, boss, drops - and the client never simulates enemies at all.

The client runs its own full weapon stack against *puppets*: real `Enemies` instances flagged `puppet`, which skip their AI and play animations while their positions stream from the host at ~15 Hz with interpolation. Because puppets live in a `PuppetDirector` (an EnemyDirector subclass that replaces spawning and AI with snapshot application but keeps the rigs, shadows, hitboxes, and hit queries), everything the client's weapons need - `firstInCircle`, contact damage, enemy shots hurting the player - works through the exact same code as single player. When a client attack lands, the client plays its own feedback immediately (sparks, sound, hit flash) and sends a damage *claim*; the host applies it authoritatively and the death comes back in the next snapshot, at which point the client is credited the kill for AP if it claimed that enemy recently.

Both players see each other as a `RemoteAvatar` (player sprite, held weapon, shadow) streamed alongside the snapshots. Waves, boss cinematics, enemy shots, and pickups replicate as small events on top of the snapshot stream; pickups are collected locally and confirmed with the host so both sides stay consistent. Death in co-op does not end the run - the player respawns at the spawn point after a few seconds with half health, and R-restart is disabled.

Files: `Net` (non-blocking TCP transport, newline-delimited JSON, host/join/poll/send, marks itself dropped on error and disables `FlxG.autoPause` while online so an alt-tabbed host cannot freeze the session), `NetSync` (all replication logic on both sides), `PuppetDirector`, `RemoteAvatar`, and `states/OnlineState` (the host/join lobby with IP entry; the last IP is remembered in the save). Its menu uses the same `MenuSlash` confirm as the main menu, but because HOST and JOIN both stay on the lobby screen, every path that hands control back to the list - a failed host, a failed connection, cancelling IP entry, or losing the peer - goes through one `releaseMenu()` that restores the shattered row along with re-enabling input. ESC is resolved in a single place and means the narrowest thing available: cancel IP entry if typing, otherwise stop hosting or disconnect if a session is open, and only leave the lobby when idle at the list.

Your friend's weapon visuals are replicated by `RemoteFx`, which spawns decoration only - nothing it creates can damage anything, so it cannot desync the authoritative sim. `Weapons` emits one `onAttack` callback carrying the mode, aim and charge power; it covers every weapon from a single line, with a second call in the bow's charge-release path because charging gives the bow its own input branch that returns before the shared one. The bow modes emit from the hand rather than the body, since that is where their arrows actually leave. The held weapon's own placement is streamed as an offset from the player rather than recomputed on the far side - `anchor()` pushes the bow toward the cursor, lifts it for rain, and switches the sprite origin to centre for both, so re-deriving it invites exactly the drift it used to have. the receiver rebuilds the effect with its own local classes (a slash, a slice, an arrow, a shockwave blast with damage suppressed, a rain volley from a cosmetic `ArrowRain`). The hook, its rope, and the thrown scythe are streamed as state on the avatar packet instead, because they persist and follow the world rather than flying in a straight line. Snapshots only go out every fourth frame, which is far too coarse for a scythe moving 1000 px/s, so the thrown copy is dead-reckoned: the packet carries velocity rather than angle, the sprite integrates that velocity itself at full framerate, and the streamed position acts as a weak correction that pulls out drift. Its spin and ghost trail run locally. The hook uses a plain position lerp instead, with both rope ends interpolated so the rope does not jitter - it cannot dead-reckon because a hook stuck in a victim keeps a stale velocity. Host hits also emit an impact event so the client sees sparks; the client's own hits already draw locally, so only the host's need sending.

The four supers each replicate differently, chosen by what a remote machine can actually reproduce. The blade ring and the arrow storm are replayed from their activation alone: `SuperScythes.decoration()` builds a copy with no player, arena, director or hit pipeline, which strips the damage and the writes to the body, and blade launches arrive as one event each. The storm scatters its drops randomly, but random is random - nobody can tell that the two machines picked different points. Bounce strike is not replayed at all: it genuinely moves the player, so the avatar's own position stream already shows it, and only the shockwave per slam needs sending. The hook arms stream their claws, because they grab enemies, and which enemy is nearest legitimately differs between machines; the grabbed enemy is already host-authoritative, so it gets dragged around correctly on its own. Rope curves are rebuilt locally from the streamed control points, anchored to the interpolated body so they stay attached while it moves.

Up to eight players share a run. The transport is a star: everyone connects to the host, and the host forwards each player's messages on to the rest, so no client needs to know about any other client's address. Every message carries the id of the player it came from, and the host stamps that id itself when it reads a socket - a client cannot claim to be someone else, and a player never sees its own messages echoed back. The host is always id 0 and hands out the rest on connect. Hit claims and pickup grabs are the exception to forwarding; they are the host's business alone, so they stop there.

The net package splits along the seams of that model. `Net` is the transport; `NetSync` is the seam between the local game and the wire - outbound emission, inbound routing, and the shared run rules (respawns, the everyone-down loss, the broadcast restart). Each other player is a `Peer` - their body, their effects and whether they are down - held in a `PeerRoster` that creates one the first time a message arrives from an unfamiliar id. Peers are pooled rather than destroyed, because their visuals are wired into the display list when built; a player leaving hides them and frees the slot for whoever connects next. A guest dropping is survivable for the host and only ends the session for the guest. One subtlety worth knowing: the host never receives its own broadcasts, so when it notices a socket die it queues the departure notice for itself as well, otherwise the departed player would linger on the host's screen and keep counting as alive.

The client's copy of the host's world lives in `PuppetMirror`: puppet enemies and pickups driven by snapshots and interpolated between them, plus the kill-credit window for this player's damage claims. Nothing in it decides anything - it only shows what the host said. `RemoteArms` is the streamed hook-arms channel, kept separate from `RemoteFx` because it is the one effect that is state-lerped every frame rather than replayed from an event. The boss death blast is built by one shared function (`Fx.bossBlast`), so the host's real death and a client's mirrored one cannot drift apart.

Latecomers are told in the host's greeting that a run is already going, and skip the lobby straight into it.

Players set a name in the online menu, kept in the save file, and it floats above their head for everyone else. Names are announced once on entry rather than repeated in every packet, which leaves the question of how someone arriving late learns names that were sent before they connected: everyone re-announces whenever a player joins, so a latecomer is greeted by the whole party. That is also why the host raises a join event for itself - it never receives its own broadcasts, so otherwise it alone would stay silent. Tags live above the depth sort rather than in it, since a name sorted by its own feet would slide behind whoever happened to be standing further up the screen. Only other players get a tag; your own would just sit in the middle of your view.

Enemy targeting is co-op aware. The director keeps a list of living co-op bodies - remote avatar sprites, which are real sprites carrying streamed positions - and each enemy chases whichever living player is nearest, falling through to the survivors as players go down. The same choice drives spawn placement and the stuck-enemy rescue, so a downed host no longer strands the wave around their corpse. Enemies only go idle when every player is down, and that is also the loss condition: a solo death respawns you after a few seconds, while both players being down ends the run and offers a restart that is broadcast so the two machines reset together.

Supers also lift, spin and squash the player's body. Those three ride along in the avatar packet rather than being recomputed, which is what lets the decoration copies stay out of the body entirely.

Three features are deliberately disabled online because they fight the authority model: time stop (it freezes the whole world for one player), the perspective totem (the morph relocates every entity globally), and R-restart (replaced by respawns).

## Weapon systems (source/systems/weapons/)

- `Weapons` - the combat coordinator. Weapon selection (1-4 or scroll wheel: scythe, hammer, bow, hook), the mode cycle within the equipped weapon (each weapon remembers its last mode), the super trigger (Q at full AP, one per weapon: scythe launches SuperScythes, hammer launches BounceStrike, bow launches ArrowStorm, hook launches HookArms), attack input dispatch (super priority, the held-enemy throw intercept, aim math), and held-weapon visibility while the hook is out or a bounce is running. Everything else is delegated to the systems below.
- `WeaponMode` - the mode enum shared by the weapon systems.
- `HitPipeline` - the shared hit pipeline: damage with hit sound, sparks, kill rewards, and drop rolls; a zero-damage stun hit with a caller-supplied duration; and `blastRadial`, the shared area-of-effect hit (every enemy in a circle is damaged and flung outward from the center) used by the hammer slam, Bounce Strike, and landing rain arrows.
- `Rope` - shared rope drawing: tiles rope segments along a straight line (the hook's rope) or a quadratic bezier with an explicit control point (the arms' curved ropes) into a caller-owned sprite group.
- `HeldWeapon` - the held sprite: per-weapon graphic and origin, hand anchoring, cursor tracking and facing flip, the swing sweep and bow recoil animations, the bow's held-out pose, and the arrow rain skyward pose.
- `SwingAttack` - the scythe swing: slash visual pool and the melee strike (an arc in front of the player).
- `SliceAttack` - the slice projectile pool: firing, wall death, and pierce hits.
- `HammerAttack` - the hammer slam (a damage circle at the aim point, 2 damage and heavy knockback) and the shockwave trigger; owns Shockwave.
- `BowAttack` - the bow shot (a fast arrow that dies on its first enemy hit or a wall) and the arrow rain trigger; owns ArrowRain. The shot is charged: holding the attack button builds charge and releasing looses the arrow. A tap under `minTime` fires the plain arrow it always did, so nothing is slower than before; past that, damage steps up to `maxDamage` and the arrow grows, flies faster, and hits harder. While drawing, a looping tension sound rises in pitch with the charge; it only starts once the hold passes `minTime`, so tap shots stay silent instead of clipping it. Full charge is reached at `fullTime`, announced with its own sound, and is the only point that awards top damage - holding longer simply keeps it there. The charge cancels if the player dies, switches weapon or mode, or starts a hook or throw.
- `Shockwave` - the shockwave mode: the hammer slams the ground at the aim point, spawning a temporary cracked-ground decal and an expanding ring that stuns every enemy it passes (a staggered no-damage stagger hit plus a long stun). The wave ignores walls. The ring is an ellipse squashed to 0.7 to read as a circle drawn on the top-down floor; in side view the impact drops to the surface beneath it (platform top or ground, so a slam made in mid-air lands below you) and the ring flattens to 0.18 so it spreads along that surface instead of ballooning through the air. Grounding the centre also fixes the knockback for free, since the push direction is measured from it and now points outward and slightly up. Both the hammer's shockwave and Bounce Strike's slams route through `blast()`, so they share this.
- `ArrowRain` - the arrow rain mode: the bow is held above the player's head pointing skyward; firing launches a fanned burst of arrows up from it, then a staggered volley falls onto a scatter of points around the cursor. Each impact point shows a ground marker during the descent, and the falling arrow fades in over the first part of its drop rather than popping into view (the fade is keyed to distance fallen, so it stays proportional if the drop height or fall speed change); a landing arrow damages enemies in a radius with outward knockback. The rain ignores walls. Impact points are floor coordinates, which in side view would be heights, so `rainAt` snaps each one down onto the surface beneath it (platform top or ground) and the marker, the arrow's descent, and the blast all follow. Arrow Storm passes a point above the arena so its drops land on the first surface from above, which lets platforms shelter what is underneath them.
- `HookAttack` - the hook grab: the held hook itself is thrown (the hand stays empty and all attacks are blocked until it returns), trailing a rope line back to the player. It latches the first enemy hit (light damage plus a seize that suspends its AI), reels it to the player, and holds it in front of the cursor. Left click while holding whips the enemy in one quick revolution around the player, then launches it as a projectile that damages every enemy it passes through; the hook returns to the hand at the moment of release, so the enemy flies alone. Hitting a wall damages the thrown enemy, otherwise it is released with a short stun at the end of the flight. On a miss the hook retracts to the hand. Seized enemies deal no contact damage and skip crowd separation. Enemies flagged not `grabbable` (the boss) take damage but cannot be latched - the hook deals its hit and retracts. The spin mode instead whips the hook one full revolution around the player on its rope, starting from the aim angle and hitting each enemy once. The grapple mode fires the hook to where you aim; it only boosts if the hook catches an enemy - hitting a wall or reaching max range with no enemy in reach just retracts the hook. On a catch it rockets the player to that enemy at high speed (tracking it as it moves), shredding and flinging enemies along the path, and the player is invincible for the whole boost. (The auto-grabbing arms are the hook's super - see `HookArms`.)
- `ThrowAttack` - the boomerang throw: thrown scythe flight (out leg, wall turnaround, homing return, catch), its afterimage trail, and the spin sound loop. The return steers around walls using its own EnemyNav instance on a fast re-path interval. The player cannot attack while the scythe is airborne.
- `HookArms` - the hook super: Q with the hook equipped and a full AP meter drains it and extends two mechanical hook-arms from the player's back (rendered behind them) for a few seconds. Each arm independently reaches out to the nearest enemy, grabs it, reels it up, whips it in an arc, and hurls it - automatically and continuously. The arms rest tilted and their curved ropes trail with inertia; when the super ends they retract back into the body. The held hook is hidden and the player can still move.
- `ArrowStorm` - the bow super: Q with the bow equipped and a full AP meter drains it and fires a single supercharged arrow straight up from the bow - a big glowing arrow with a fading trail. Once that arrow clears the top of the screen the storm proper begins: the bow stays raised skyward while arrows carpet the entire visible arena for a few seconds, spawning rain drops across the camera view on a fast cadence (reusing ArrowRain's drop/marker/land machinery). The player can still move throughout.
- `BounceStrike` - the hammer super: Q with the hammer equipped and a full AP meter drains it and plays a three-hit bounce. Each hit is a ground slam (a big AoE that flings caught enemies away with heavy force) that launches the player into the air in a somersault; on landing the next slam fires, three times, then control returns. Movement is locked for the duration and the held hammer is hidden.
- `SuperScythes` - the super: right click with the scythe equipped and a full AP meter drains it and wraps the player in a pseudo-3D cylinder of scythes - an elliptical carousel where blades pass in front of and behind the player, scaling with depth. The player levitates for the duration (visual offset only; the hitbox and shadow stay grounded) and the held scythe vanishes. Left click launches the blade nearest the aim; launched blades spin, pierce enemies, and die on walls. Everything leaves ghost trails. When the last blade is fired the player settles back down and the scythe returns, with the previous weapon mode intact.

## Entities (source/entities/)

- `Player` - WASD movement with an acceleration ramp, dash, and the walk sound loop. Carries two skins: the top-down sparrow atlas and a side-view grid sheet described by `sideSkin` in player.json. `applySkin(side)` swaps the graphic and rebuilds the four animations under the same names, so every caller (hurt, death, the ghost trails) works against either. The hitbox stays 75x95 in both, so all movement and feet maths are perspective-independent; only the draw offset differs. The skin changes in `setSideMode`, which the shift calls once the morph finishes, so the player keeps its top-down look while the stage is folding over and turns 2D on the frame the new world settles. `baseOffsetY` is published here because the supers ride the player's draw offset for hover and somersault lift, and they must follow a skin change rather than a value cached at startup.

  `shadowCenterX` exists because the side sheet's artwork is not centred in its cells - the walk frames sit right of centre, so mirroring the sprite swings its visual centre by 28 px while a fixed shadow offset would not move. The player measures each cell's true content centre once when the sheet loads and reports where the shadow belongs, mirrored when facing left. That keeps the shadow under the character in every animation and re-derives itself if the sheet is redrawn.
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
- `MenuSlash` - the menu's confirm animation. The scythe selector winds up to the left of the chosen row, sweeps through it, and on contact the row is hidden and replaced by one sprite per letter that tumbles away under gravity and fades - so the option is cut apart and falls into the void before the choice is carried out. Letter widths are measured individually and then scaled to span the row's real width, which keeps the swap seamless at the moment the shards appear. Every menu choice routes through it, and returning from Options restores the shattered row.
- `JaggedBand` - a sawtooth strip that scrolls sideways forever, used to frame the main menu. The tooth shape is the one from Will Boyd's "Hello Houdini: Jagged Edge with Mask" pen: walk across the width alternating between a peak and a valley, then close the polygon along the bottom and fill it. Rather than redraw that path every frame, the strip is drawn once at two teeth wider than the screen and simply slid left, wrapping every tooth width - so the motion costs nothing and never seams. `top` flips it vertically for the upper edge, and a negative speed scrolls the other way, which is how the menu gets its two mirrored pairs.
- `IrisWipe` - the state transition: a black overlay with the game icon punched out of it as a transparent hole, which grows to reveal a state on arrival and shrinks to swallow it on the way out. The mask is built once and cached as a persistent `FlxGraphic` - the icon is drawn into a square bitmap and its alpha inverted, so the icon silhouette becomes the hole. It must be persistent: Flixel clears its bitmap cache between states, so a plain cached BitmapData is disposed after the first transition and every later wipe renders as a bare square. Four oversized black bars track the mask's edges so the screen stays covered no matter how small the hole gets. It draws on its own camera added on top, so it covers the HUD as well as the world, and `open` hides itself when finished so the icon's concave notches never linger over gameplay. Scale is driven by `FlxTween.num`; the fully open scale is set so the hole comfortably clears the screen, since anything smaller would pop black into the corners the moment a close began. Used by the title sequence, the menu, the pause menu's quit, and the death restart.
- `Music` - the single owner of music playback. `play(name, volume, loop)` switches tracks only when the requested track differs from the current one; asking for the playing track just applies the volume, restores pitch, and resumes it if paused - which is what keeps the stage theme seamless across the menu, the game, pause-quit, and restarts.
- `SideView` - global side-view state, following the WorldClock pattern: `active`, `morphing`, `groundY`, the platform rectangles, and the shared helpers used by the player, enemies, and pickups: gravity, one-way platform landing, `settle` (the snap-or-fall resolve every side-mode body runs each frame), and `placeShadow`. Physics values load from sideview.json in `reset()`. Shadows are anchored to each entity's existing feet offset, so a grounded character looks identical to top-down; in side view an airborne one drops its shadow onto the surface below (ground or platform), shrinking and fading with height. Reset by PlayState on every run.
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
| `sideSkin` | the side-view sprite: `sheet` (grid image under `assets/images/`), `frameW`/`frameH` cell size, `offsetX`/`offsetY` draw alignment, `shadowScaleX` (the ground shadow is drawn wider in side view than the top-down default of 4), the `idle`/`walk`/`jump`/`fall`/`hurt`/`death` frame index lists, and a frame rate per animation. `jump` and `fall` exist only in this skin and are chosen by vertical velocity while airborne |

### Weapons - assets/data/weapons.json

Combat balance for every weapon system, one object per system; field names match the system's tuning names.

| Section | Covers |
|---|---|
| `swing` | melee range and arc, slash spawn distance |
| `slice` | slice spawn distance |
| `hammer` | reach, radius, damage, push, shockwave stun length |
| `shockwave` | wave radius and expansion time |
| `thrown` | throw distance, return speed |
| `bowCharge` | charged shot: `minTime` below which a press is a plain tap shot, `fullTime` to reach full charge, `maxDamage` at full, and the `speedBonus`/`sizeBonus`/`knockBonus` multipliers applied across the charge range |
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
| `totemWaveMin`, `totemWaveRange` | the totem crashes down on a wave rolled once at startup from `totemWaveMin` to `totemWaveMin + totemWaveRange` |

The map CSV holds `0` (open) and `1` (solid) tiles, 16 px each, loaded with flixel auto-tiling. The outer ring is the arena wall. Solid interior tiles become pillars: they block movement and projectiles, break line of sight, and Arena draws block sprites over them. Arena geometry is edited in the CSV only.

### Side view - assets/data/sideview.json

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

## Tuning

Gameplay numbers live in the JSON files under `assets/data/` (see Data). The remaining code constants are `static inline var`s at the top of the file that owns them.

| File | Constants |
|---|---|
| `systems/weapons/HeldWeapon.hx` | swing times per mode, arc, scale pulse, aim smoothing, facing flip margin, bow hold distance, rain raise height, charge grow/draw-back/tint |
| `systems/weapons/BowAttack.hx` | draw-loop pitch floor and rise |
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
| `systems/EnemyDirector.hx` | off-screen entry margin, edge spawn margins, shot wall probe, stuck-enemy watchdog thresholds |
| `systems/Fx.hx` | hitstop length, shake strengths, spark settings, dash line fade |
| `systems/TimeStop.hx` | trail tint, alpha, fade, cadence, and minimum speed; overlay tint strength; minimum music pitch |
| `systems/perspective/Totem.hx` | totem draw size, glow padding, hit flash time |
| `systems/perspective/MeteorArrival.hx` | ember cadence, arena edge padding for landing spots |
| `systems/perspective/PerspectiveShift.hx` | totem hit cooldown |
| `states/MainMenuState.hx` | splash text and its angle, throb depth and speed; quit-collapse flatten/pinch/fade durations and minimum window size |
| `util/IrisWipe.hx` | open and close durations, mask resolution, fully open scale |
| `util/MenuSlash.hx` | wind-up, cut and follow-through timings, shard linger, shard gravity |
| `util/JaggedBand.hx` | (all shape and speed values are constructor arguments, set in `MainMenuState.addBands`) |
| `util/SideView.hx` | shadow projection reach, shrink, and fade |

## Builds

Windows native and HTML5 share the same source and assets. Commands are in [README.md](README.md).
