# Systems, entities and utilities

The per-run machinery owned by PlayState, the sprites it drives, and the shared helpers.

## Controls

Every input in the game asks `util/Controls` instead of the keyboard or mouse directly. An action, dash or attack or super or interact, carries one keyboard side bind, a key or a mouse button, and one controller bind, both saved, plus fixed extras that never move: the left stick always moves, the right stick always aims, and Z always confirms.

Aiming is a device question, so `Controls` owns the answer. It watches which device spoke last, real window coordinates for the mouse, so a drifting camera cannot be mistaken for a moving hand, and serves either the mouse's world position or a virtual cursor held a fixed reach from the player in the right stick's direction. Panels opened over the game reset only the keyboard, never the pad: keyboard state is event driven and stays quiet after a reset, but a pad is polled, so resetting it makes a still held button read as a fresh press one frame later, which closed the pause the same instant a controller opened it. The crosshair, every weapon, the camera lean and the co-op aim targets all read that one answer, which is what makes a controller work everywhere without any weapon knowing devices exist.

Fire is pinned whenever a panel over the game closes, and stays pinned until neither attack button is down. Every weapon fires on hold rather than on the press, so the click that picks a weapon or dismisses a menu was still held on the first frame of play and went straight into the gun. Requiring the button to come up first means the click that closed the panel can never be the click that fires.

Fire is also locked outright for a second as a run opens. The weapon flies to the hand over half a second and the held sprite is hidden for the trip, but attacking mid flight shows it again, since the yoyo and the thrown hammer both restore it when they finish. That left the weapon in the hand and in the air at once. The lock covers the flight with room to spare, and it is a timer rather than a pin because a player who releases and clicks again during the animation would otherwise walk straight back into it.

## Fonts

`Lang.font` answers the font for body text and `Lang.display` the one for large names. Japanese keeps `DotGothic16`, which is the only face here carrying kana and kanji. Everything else takes `modernDos`, which covers Latin-1 and so serves English and Spanish alike.

`runescape_uf` is ASCII only, ninety six glyphs with no accents at all, so it is kept to text that cannot be translated. The boss name is the one place that qualifies, being a hardcoded word. Putting it on anything from the language tables would show holes the moment someone played in Spanish. The seven segment `digital-7` still owns the time stop clock, which is a readout rather than writing.

## Systems (source/systems/)

PlayState builds each system once and updates it once per frame. The exception is `MenuList`, which the menu states build.

### Arena

Loads the background and collision tilemap, sets world and camera bounds, and generates pillar sprites from the map data. It answers `wallAt(x, y)`.

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

Player health and the super meter. Damage intake, invincibility frames and blink. The meter is locked while any super is running, so no damage dealt during one, by the super or by the hands beside it, charges the next. Dash input, death and revive, and the run's kill counter. The HUD bars bind straight to its fields.

The dash speaks twice. Launching one plays a random line from `dash/dash1` and `dash/dash2`, and the moment its cooldown runs out `dash/charged` sounds and a puff of steam vents from the player's back, so the dash announces itself as ready rather than leaving the player to count the seconds. The ready cue keys on the cooldown crossing zero rather than on it being zero, so it sounds once per dash instead of every frame afterwards, and it stays quiet for a player who died mid-cooldown.

The puff comes from `Fx.steamAt`. Its art drifts across its own frames, so it is mirrored against the player's facing rather than with it, which sends it away from the back instead of through the body. It draws under the entity layer beside the dash trail, so the player's own body clips its inner edge and it reads as coming from behind them.

It rides the player for the whole of its short life rather than being dropped in the world. Facing here follows the cursor, so it can turn over in a single frame, and a puff left standing where it spawned ends up in front of a player who spun during it. `trackSteam` re-seats it against the current facing every frame, so it stays on the back through any spin, and lets go of it once the animation is done.

The hit sound is one owned `FlxSound` restarted on every hit, not a fresh play each time. Invincibility spaces hits 0.4 seconds apart while the sound runs longer than that, so fresh plays overlapped their own tail and each hit landed on a different amount of the last one. Restarting one instance makes every hit sound the same.

It re-asserts death every frame, rather than only on the transition. Several weapon systems clear `blockMovement` when they finish, and one finishing after you die would otherwise hand control back. So while dead it reapplies the block, and restores the death animation if anything overrode it. Separately, `Player` refuses to run its movement routine while `isDead`. That is what actually keeps a corpse from walking and playing an idle.

### EnemyDirector

Wave pacing and the per-enemy tick. It owns the rigs: enemy, shadow and contact hitbox. It walks them each frame for targeting, entry, shadows, contact damage and cleanup. It also answers the circle queries every weapon aims with.

Three collaborators hold what it used to. Where an enemy goes belongs to `EnemySpawner`: placement along the bottom edge, the stuck watchdog, and the rescue that frees a wedged enemy. Every spawn walks in from below, so the fight has a front rather than a surround, and the shop at the top of the arena stays behind you. All three ask the same thing, which is where clear ground lies.

A spot counts as clear only if the foot box that actually collides with props is clear. The check samples the enemy's full width at its feet, not its body centre. The two disagree. An enemy can go solid because its centre is clear. It then wedges on the prop its feet already sit inside.

Boss waves can bring the Rofel Duo, two Rofels sharing one encounter. The first boss of a run is always a single Rofel, and every boss wave after it rolls the duo at `duoChance` from the wave data. The director spawns the whole pack through one path, so each member gets the same wave scaling, its own death watch and its own loot drop, and the encounter ends when the last one falls. The boss bar pools the pack's health into one fill and names itself off the pack size, so the duo reads as one enemy with two bodies rather than two fights stacked.

A downed player's revive is a ritual rather than a switch: the scattered body parts draw back together over three quarters of a second, hold and flash, and only then does the body return. The avatar packet carries a reviving flag alongside the dead flag, so every other machine runs the same ritual on its own copy of that player's parts and ghost at the same time. Without it the flag would only ever say dead or alive, and a revived friend would pop back in with nothing between. The flag going away before the ritual ends cancels it, which is what happens when a run ends underneath one.

A run's big pauses wait for the players before they end. `ReadyGate` holds the countdown at the run's first wave, after every shop wave and after every boss, and prints a prompt until each player presses ENTER. Ordinary waves flow on the timer, so the gate marks the rests rather than nagging between every fight. It runs solo as well as online: a solo player readies and the wave starts at once, which is what makes the shop a safe place to think rather than a timer you can fumble. Readying also rolls the shop shutter down, so the shop's window is the whole rest rather than one visit. In co-op the shutter waits for the room rather than for one player: readying announces you and nothing else, and the door comes down on the same release that starts the wave, once everyone is in. Closing it on your own ready would shut your friends out of a shop they were still standing in. In co-op the host arms every machine, each player readies for themselves, and the wave starts only once everyone has. A ready player wears a speech bubble over their head, so the room can see who it is still waiting on. A player who is already down readies on their own without a bubble of their own, but the ready still crosses the wire, so everyone else draws one for them. That bubble hangs off the floating ghost rather than the hidden body, which stands where the player fell, and it rides the ghost's bob so it reads as attached. The host releases the hold anyway after 90 seconds, or the moment the last guest drops, so nobody can strand a lobby by walking away.

The gate holds the wave through a flag of its own rather than the shop's, so a shop round and a ready round can both be open without either clearing the other. It also stands down while the shop is in reach, since the shop answers the same key.

Spawned enemies march straight in rather than steering at the player. A spawn sits below the map, and chasing a player who stands off to one side used to walk them sideways along the bottom edge for seconds before they ever entered. While entering they now drive north at full speed with a slight lean toward the target, so they cross the threshold at once and the south edge stays clear.

Four guards feed the rescue. The first treats an enemy as stuck when something drives it but it does not move for 2.5 seconds. The second caps the walk-in: an enemy still entering after 6 seconds relocates instead of circling outside forever. The third catches the quiet failures, where an enemy makes no progress for 8 seconds. The fourth is an invariant rather than a timer: a live enemy that is done entering must be inside the arena, and one found outside it relocates on the spot. That covers anything that leaves through a wall, whatever threw it.

Two rules keep the timers honest. Only a genuine engagement pauses them, meaning the enemy is inside its attack range with a clear line to its target, plus a crowd exemption on the drive check so a mob pressed around a player never teleports. An earlier version paused on raw distance instead, which was almost always true of an enemy chasing you and left the catch-all doing nothing. Progress is also measured between samples two seconds apart rather than against a rolling reference, so an enemy jittering in place cannot keep resetting the clock.

The rescue itself looks for clear ground in rings around where the enemy stands. It falls back to relocating near the player only when nothing close is free.

`EnemyShots` owns the projectile group. It emits what an enemy queued, and kills shots on walls, props or the player. The shake-then-explode sequence lives in `BossDeath`. That has its own lifetime and touches nothing else. `EnemyRig` moved to its own file so the spawner can take one. The director forwards a callback that moved with a collaborator as a property. The network layer wraps them rather than simply setting them.

`applyWaveScale` scales every enemy as it spawns. It turns the wave number into health, speed and damage multipliers from the `scaling` block. The client applies the same thing in `addPuppet`. Each machine charges contact damage locally, and the two would otherwise differ.

A randomly chosen wave, 4 to 8 and rolled once at startup, is the first boss wave. It fires the `onBoss` callback, which starts the intro cinematic. After a short intro delay it spawns a single `"rofel"` enemy instead of the normal count.

When the boss dies the director runs a defeat sequence. The boss shakes in place, then plays an explosion animation with a boom sound. Once the explosion finishes, `onBossDefeated` fires. That reverts the arena and music to normal.

The director is also the single home of enemy hit queries. `firstInCircle` and `eachInCircle` run the nearest-hitbox-point circle test every attack uses. Both see live enemies only, and `firstInCircle` can skip seized ones.

A wave ends only once every enemy is dead. One enemy that could never reach the player would therefore hang the run forever. Two guards prevent that.

Spawned enemies pass through walls and prop footprints while entering. They turn solid only once they are inside the arena and clear of any pillar or prop. They therefore cannot turn solid inside one. Beyond that the watchdogs relocate a stuck enemy. A seized enemy is exempt, so a long grab cannot be mistaken for a wedged enemy and torn out of the holder's hands. As a backstop, a wave running longer than 75 seconds relocates everything still alive. The boss is exempt, since its movement is its own choreography.

### Pickups

The health pickup pool. The player collects one on contact, unless health is full.

### TimeStop

The time-stop ability on E, with a cooldown from player.json. It ramps a world-time factor from 1 to 0 over the slow phase. It holds the world frozen for the stop duration, then ramps back.

It publishes that factor through `WorldClock`. Enemies, enemy shots and pickups read it, and scale or skip their own updates. PlayState multiplies it into the elapsed it passes to the director and arena. Wave timers, boss logic and cinematics therefore freeze too.

The player, weapons and player projectiles run at full speed throughout. Seized enemies stay in player-time, so the grab still works on frozen targets. Frozen enemies are immovable statues that deal no contact damage, and frozen shots hang harmlessly in the air.

Music pitch rides the factor down for the record-slowdown effect, pauses at the full stop, and ramps back on resume. While time runs slow the player leaves a blue afterimage trail, built from frame-accurate ghosts through GhostTrail. A subtle blue overlay tints the screen, sized from the camera's view through the same `Veil` the revolver super's sepia uses, so it holds at any zoom. The HUD shows READY, the cooldown, or STOPPED through `hudLabel()`. Dying cancels the stop.

### WeaponFlyIn

The handover after the weapon pick. The chosen weapon arcs from its card to the player's hand, spinning and growing from card scale to held scale. The real held sprite hides until it lands.

It draws on the UI camera and re-reads the hand every frame in screen space. The throw therefore still lands correctly while the camera moves. Dying mid-flight drops the weapon rather than handing it to a corpse.

### MenuList

The shared menu widget used by the main menu and options. It is a centred column of text rows with a bobbing weapon selector. It takes W/S and arrow navigation, A/D value adjustment, mouse hover and click, and plays the move and select sounds. Owners supply `onChoose` and an optional `onAdjust`, and can rewrite row labels in place.

### Hud

The UI camera, health and super bars, wave counter and banner. Both bars sit in the one widget in the bottom left, where the narrow strip above the health bar reads the super meter. That strip used to be decoration, and the meter used to sit in the opposite corner, which put the two numbers you watch most at opposite ends of the screen. The red BOSS APPROACHING banner shares the same text and slides down from the top. The scrap counter is a picture of scrap next to a number, rather than a word next to a number. It needs no translation. It sits directly over the health widget, sharing its left edge, so everything the player watches is in one column in that corner rather than split across opposite ends of the screen. The icon anchors to that edge and the number runs off its right, so a four figure count grows into open space instead of moving the icon. The icon draws at the same scale as the rest of the UI. It was two thirds of it, which read as a different resolution to everything beside it. Both carry a soft drop shadow, because white on a dark arena floor was the only thing holding them apart from the background.

It also owns the revolver ammo readout and the crossbow's blue gauge, which sits below the health bar. All three bars therefore stack in the one corner, super over health over the gauge. It holds the time-stop status label and its fading countdown. It also holds the death text with the best wave, and the custom cursor. It owns a `BossHud`, and hands the boss bar and screen flash to it.

The health bar is an `FlxBar` bound by reflection to `status.health`. The super strip cannot be, because both bars live in one piece of art. `bar_red` draws the whole widget, so an `FlxBar` over the strip would clip against the full widget width and read full at two thirds. The strip therefore takes a plain sprite with a `clipRect` measured against the strip's own span, and `bar_super_empty` covers the background's red so the strip can read empty. `bar_main_red` is the health fill with the strip cut out of it, without which the health bar repaints the strip red over the top.

The HUD wears the player's colour. Every piece of its art loads through the same hue rotation the character and their weapon use, so the gear frame, both bars and the ammo pips all turn with the player. The rotation only touches saturated pixels, so the white outlines and the grey bolts stay as drawn and only what was red follows the player. The ammo art is held out of the rotation by name: a bullet reads as brass and an arrow as red because that is what they are, not because of who is holding them, and a player picking a green tint should not end up with green brass. Each skinned sprite remembers the art it is wearing, which is what lets a colour change in the options repaint pieces that are swapped at runtime, like the full and spent ammo pips. Repainting reseeds the bar widths, since loading a graphic drops the clip that draws a partial bar. The heal flash stays green whatever colour the player picks, because there it is reporting healing rather than identity.

Both bars slide to their new value rather than snapping to it. The drawn amount chases the real amount by a quarter of the remaining gap each sixtieth of a second, worked out from the frame time so the slide takes the same wall-clock time at any framerate. The first frame after a bar appears snaps, since there is nothing to slide from. The clip only gets rewritten when the whole-pixel width actually changes, so a bar at rest costs nothing. Cues still key on the real value, not the drawn one: the super's chime and glow land the moment it is usable, while the bar is still catching up.

Picking up a battery flashes the health bar green for a second before it settles back to red. A hue-shifted copy of the bar art draws over the red one, sharing its position, scale, offset and clip rect, so the green covers the red exactly rather than sitting proud of it. It fades out over the last third of the second. The flash keys on `heal`, which only the battery pickup calls, and it stays hidden while the HUD is switched off.

The super bar lights up the moment the super becomes usable. It keys on the same `canSuper` the input check uses rather than on the meter merely reading full, so a meter that refilled while the cooldown was still running stays dark until the cooldown ends, and the bar never invites a press that would do nothing. Becoming usable plays a chime once and starts a slow additive pulse on the fill; spending it, dying, or dropping below full puts the light out. The cue keys on the crossing rather than on the state, so holding a full meter stays quiet.

### Scraps

Enemies pay in scrap rather than in exp. A rewardable kill drops one `ScrapPickup` where the enemy fell, and picking it up pays one scrap. A kill you do not walk over is therefore worth nothing.

Stat rows read one higher than the points behind them. A stat nobody has spent on shows 1 rather than 0, since a zero on a character sheet reads as broken. The maths still runs off the raw point count.

Refunds only reach the points spent in the open session. Closing the screen locks the current spread in, so a later visit cannot claw back what an earlier one bought.

One piece is one scrap, and nothing else pays. Clearing a wave used to hand over a hidden bonus that scaled with the wave number, which meant the counter jumped without anything being picked up and one piece on the ground was worth six. Both read as the number lying about the sprite. The level costs were divided down to match, so the pace is unchanged: the same wave still buys about the same number of levels.

Scrap pulls toward the player inside `MAGNET`, faster the closer it gets, so a kill at your feet collects itself and a kill across the room asks you to go and get it. It expires after fourteen seconds and blinks for the last three, which keeps a cleared arena from filling with debris.

A dropped piece wears one of five sprites, picked at random, and carries a small ground shadow that stays at the piece's rest height while the piece bobs above it. The sprite is cosmetic only. Every piece pays the same one scrap, so the counter cannot tell them apart.

Scrap is collected one piece at a time, a fifth of a second apart, and the nearest piece goes first. Without the gap a heap landed on the same frame: one muddy sound made of several copies of itself, and a counter that jumped in a single step. The gap has to be long enough to see. A tenth of a second was still read as picking up three or five at once.

The magnet stops pulling at `HOLD`, a little short of the player, rather than dragging every piece onto the same point. A queue waiting its turn therefore sits spread around the player instead of stacking into what looks like a single piece. `HOLD` is set inside the overlap the collection test needs, so a waiting piece still counts as touching even at the bottom of its bob.

Health drops are batteries now, and carry the same small ground shadow scrap does. The shadow mounts once per pickup, the first time it leaves the pool, on both the local drop path and the mirrored one a guest builds from a host snapshot.

The kill counter and the super gain still fire on the kill itself. Only the exp moved.

A guest never runs `applyHit`, because its hits are claimed and sent to the host to apply. Its scrap therefore drops from `PuppetMirror`, on the same credited kill that pays the kill counter. Scrap stays on the peer that earned it and is never synced, unlike a health pickup, because exp is already counted per player.

### Levelling in co-op

The screen opens for everyone at once, and nobody waits on a menu they cannot see.

The host owns the moment. Its own wave clear broadcasts `lvl`, and every peer opens its own screen off that one message. A peer that cannot afford a level skips the screen and reports done at once, so it costs nothing to be broke.

Closing the screen puts you straight back in the arena. You can walk, shoot and collect scrap in the breather while somebody else is still spending. What holds is the next wave, not the world. `EnemyDirector.holdWave` stops the breather counting down, so the wave resumes from where it paused rather than from the start.

Each peer reports `lvldone` when its screen closes. The host counts one per guest plus itself, then broadcasts `lvlgo` to release. The guests need that message: their own hold flag guards the screen from opening twice, and without a release they would never see the screen again. A sixty second cap releases the hold anyway, so one player who walks away cannot stall the run, and a dropped peer releases it at once.

While a player is still spending, their avatar carries a gold `LEVELING UP` note above their name. It goes up for everyone when the screen opens and comes down per player as each `lvldone` arrives, so the note always matches who you are actually waiting on.

### PlayState and states/play/

`PlayState` builds the run and orders the frame. It owns the subsystem construction, the update sequence, and the wiring that binds one system's event to another's handler. What it no longer owns is the behaviour behind those handlers.

Four pieces live in `states/play/` and are reached by call rather than by reading `PlayState`'s fields:

| Piece | Holds |
|---|---|
| `ShopRound` | which waves open the shop, who has finished spending, and how long the next wave waits |
| `QuietRoom` | the detour roll, the tree room's stripped down rules, and the walk back out |
| `BossShow` | alarm, whiteout, boss music, loot and the return to normal |
| `RunIntro` | weapon pick, the one time tutorial, and the weapon thrown into your hand |

Each takes the collaborators it needs and nothing else, so the wiring in `create` reads as a list of what answers what. `leaveFor` is the one thing they share back: a single guarded exit through the iris, so two pieces cannot both start a state switch.

### Shop

The repair shop stands at the top of the arena for the whole run, greyed out and solid. Its counter blocks movement, so you walk up to it rather than through it.

Clearing a round no longer offers a level. Every tenth round does: the shop lights up, a banner announces it, and the next wave holds while it is open. Walk into range and a prompt appears; the interact key, E by default, opens the screen that spends scrap, which is the same screen the stats allocator always used. Interact is its own bind rather than sharing the ready key, so standing at the shop cannot confuse buying with starting the next wave. The prompt prints whatever the key is bound to, and shows the pad button instead while a pad is in use.

Closing the menu never shuts the shop, spent or not. The shutter stays up until you press ready for the next round, so the shop and the breather share one commitment: readying up is what puts the counter away, and until then you can walk back in as often as you like. The shop still closes itself after a while as a backstop, so an idle player cannot strand a lobby.

The keeper waits below the counter and rises into the window as the shutter goes up, on a four frame idle. She drops back out of sight when the shop shuts, and hides herself at the bottom of the travel so nothing hangs below the building.

The shutter runs a garage door sound while it moves, and fades it out when the shutter lands rather than letting a four second clip keep rolling over a settled door. The shutter itself was slowed to a second and a half so it reads as something heavy rather than a flick.

A shutter covers the counter while the shop is shut and rolls up when it opens. Behind it, a dark interior backdrop fills the opening, pinned to the ground layer so the shutter always slides over it. All three draw behind the building, and the counter opening is the only transparent part of the art, so the opening is the only place any of them can show. Their order is pinned with explicit sort keys rather than left to the feet sort, which would reshuffle the interior mid slide. Sliding the shutter up tucks it behind the sign board, which clips it without any clipping code. It rolls back down when the shop closes. The building itself keeps its full colour whether open or shut, and nothing pulses when it opens. The shutter position and the banner are the whole signal.

Two things end the hold. Shopping ends it when the screen closes, and a forty five second cap ends it if nobody comes, so a player who ignores the shop cannot stall their own run. `dismiss()` exists for the first case: it shuts the shop without releasing the hold, because the screen the player just opened owns the hold from that moment.

The shop blocks. Its hitbox covers the standing structure and stops short of the roof, so the roof overhangs and you can walk behind its lip without walking through the building.

The shop hides and returns with the rest of the decor, so the boss whiteout takes it away and the arena restoring brings it back. It stops answering the interact key while hidden, so it cannot be entered through a boss fight. The prop blockers switch off with the decor too, and `PropBlock` ignores a switched-off blocker, so nothing hidden can stop a body, a shot or a sight line in the boss void.

In co-op the shop round is shared but the shopping is not. The host's tenth wave broadcasts the round, every peer's shutter rolls up, and each player walks to their own shop and spends alone while the others keep playing. A player in the menu wears the LEVELING note. The wave stays held until every peer reports done, by shopping or by letting the shop time out, and the host's sixty second cap backstops the lot.

### BossHud

The boss-fight HUD pieces: the pulsing red screen flash and the boss health bar. A call to `showBar(boss)` binds a bar to the boss's HP and plays its entrance. The bar expands out from a compressed sliver as it drops in from the top. The name "Rofel" then fades in letter by letter beneath it. The bar hides itself once the boss is gone.

## Entities (source/entities/)

### Player

WASD movement with an acceleration ramp, a dash, and the walk sound loop.

`applySkin()` loads the sparrow atlas and builds the four animations. The hitbox stays 75x95, so all movement and feet maths read the same numbers whatever the animation is doing.

The field `baseOffsetY` is public here for the supers. They ride the player's draw offset for hover and somersault lift. They must follow a skin change, rather than a value cached at startup.

`shadowCenterX` exists because the side sheet's artwork is not centred in its cells. The walk frames sit right of centre. Mirroring the sprite therefore swings its visual centre by 28 px, while a fixed shadow offset would not move. The player measures each cell's true content centre once as the sheet loads. It then reports where the shadow belongs, mirrored when facing left. That keeps the shadow under the character in every animation, and re-derives itself if the sheet is redrawn.

### HealthPickup

A dropped heart. It restores health on contact and expires after a few seconds.

## Weapon projectiles (source/entities/weapon/)

- `SlashEffect` - the pooled swing visual. It drifts forward briefly and fades out, and carries no hitbox.
- `ThrownWeapon` - the airborne hammer. It spins, stretches on release, throbs in flight, and hits each enemy once per flight leg, out and return.
- `Arrow` - the bow's projectile. It flies straight and fast, dies on the first enemy hit or a wall, and expires at range.
- `Bullet` - the revolver's round. It draws from `assets/images/bullets/`, the normal round for a hand shot and the shotgun shell for a big one. It draws at the same 4x as the player, so a bullet matches the pixel size of everything else. It dies on its first hit or at the end of its range.
- `HookShot` - the hook's projectile. It flies head-first. Once latched it sticks to the hooked enemy until the throw resolves.
- `RainArrow` - an arrow rain volley member. It is either a fading skyward launch visual, or a falling arrow that lands at its assigned impact point.

## Enemy behaviour (source/entities/enemy/)

### Enemies

The one enemy class. It loads its definition from JSON by kind: `"enemy"`, `"woodster"` or `"likwid"`.

The sprite keeps only what every enemy has, whatever it does. That is stats, damage and death, the seized, stunned and frozen states, and the walk-on entry. It hands the actual thinking to two behaviours it owns, in the same shape as the `AttackBehavior` it already carried.

`EnemyBrain` is the three-state FSM: Wandering, Following and Attacking. It holds the wander timers and the pathing steer.

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

### BackGear

The spinning gear on the player's back, drawn as its own sprite so it can turn freely behind the body. It anchors to the player each frame with a lean that tucks it in while walking or dashing. The anchor rides the visual body, not just the hitbox: the update takes the sprite's spin angle, its lift off the ground and the point it spins about, so during the hammer bounce the gear orbits the somersault and rises with the hop instead of sitting at ground level. `PlayState` updates it after combat so those values are current-frame, and `RemoteAvatar` feeds the same three values off the wire for remote players.

### GhostTrail

A pooled afterimage trail. It fades its ghosts every tick. On a fixed cadence it stamps a copy of a source sprite, carrying position, angle, scale and colour. The time-stop player trail instead uses `stampFrame`, which copies an animated sprite's current frame with a forced tint. The thrown hammer, the orbiters, the Arrow Storm launch arrow and the time-stop trail all use it.

### WorldClock

The world time scale, at 1 normal and 0 frozen. World entities that update through the display list read it.

It holds two sources rather than one value. One belongs to `TimeStop`, the other is free for anything else that needs to slow the world. The `scale` field reports whichever is slower. A single field could not survive two writers. Assignment happens every frame inside `TimeStop`, which would overwrite anything else before the enemies read it.

### WarpShader

A GLSL fragment shader that distorts a sprite's texture coordinates with time-driven sine waves. The boss-arena grid background uses it, and `advance(elapsed)` steps its time uniform.

### SaveData

The persistent save: best wave reached, the settings, the last joined IP, and the online player name. The settings are the master, music and sound effect volumes, display mode, V-Sync, framerate, aspect ratio, screenshake and freeze-frame amounts, HUD visibility, 3D sound, FPS counter visibility, and language. A call to `applySettings()` pushes them into the engine. It runs at boot and whenever an option changes. The master volume sets `FlxG.sound.volume`, and the music and sound volumes set the two default flixel sound groups, so the final level of any sound is its own volume times its group times the master.

### The fire family and Domo

The basic ranks are the fire children. The green one is pure pursuit: its attack range sits below zero so no attack can ever trigger, its aggro range is effectively infinite, and its stop threshold is zero. That last one matters. Every other enemy halts at its stop threshold and idles there, which is the room a charger needs to wind up in, but a creature whose only weapon is its body has to keep walking until it is inside you. Left at the usual 170 it would jog up, stop just out of reach and stand there, looking like a dash that never comes. The turquoise champion keeps the standard charge behaviour but wears its ball form for the dash, through an optional `chargeAnim` on the charge attack that any enemy can use.

Domo is the first boss and fights with `DomoBoss`, chasing whoever the director targets at a little over fire-child speed. Past `farDist` it only picks between summoning and dashing, since the shotgun would be wasted at range. The shotgun is three quick five-shot fans, telegraphed by the SHOTGUN! sign riding the enemy's gun sprite slot, which also carries it over the wire in co-op. The shotgun cannot be shot out of Domo. Any hit normally calls `attack.reset()`, which for a state machine means the whole attack is abandoned, so one bullet used to end the three-burst fan on its first shot. An enemy can now raise `poise`, and while it is up a hit still lands its damage and its flash but skips the interrupt, the reset, the knockback and the stun. Domo raises it for every attack it commits to, so none of the three can be shot out of it once it starts, including the gaps between the dashes in a chain. It only drops the guard while chasing, which is the window to punish. Poise goes up at the moment an attack is entered rather than at the end of the frame that entered it, since a hit landing in between would otherwise still cancel the attack on its opening frame. Death ignores poise, so it can always be killed mid-attack.

The summon queues four basic fire children through `pendingSummons` on the enemy, drained by the director the same way pending shots are, one at each cardinal point around Domo. The dash is three runs that commit to a heading and sail well past the player, covering about a thousand units against the four hundred a fleeing player manages in the same time. The turn rate is deliberately weak: over a whole dash it bends the heading toward the player by less than a third, enough to curve after someone who moved but nowhere near enough to track them down. Domo's chase is slower than the player at every wave it can appear on, so the dash is the only thing that closes distance, and it has to be dodgeable or nothing is. Both `poise` and `ramming` are derived from the phase every frame rather than switched on and off at the edges, because `reset()` carries no reference to the enemy: a hit landing mid-dash would otherwise leave the ram flag raised for good, flinging fire children at the player for the rest of the fight. While Domo is dashing it wears that `ramming` flag, and the director flings any fire child it touches at the player, spinning, with a stun carrying the launch so the brain cannot cancel it.

Boss fights no longer swap into the warped checkerboard realm. The alarm, banner, boss music and camera pull survive on their own timer, and the arena, decor and shop all stay, so the fight happens in the room the run is played in.

### Boss roster

`summonBoss(kind, count)` starts a boss fight on demand: it clears whatever wave is queued, announces the boss so the arena runs its whiteout, and hands the chosen kind to the spawn that follows. It refuses while a boss is already arriving or already alive, and an unknown name falls back to Rofel rather than throwing. Debug builds bind it to 7 for the knight and 8 for Rofel, host side only, since a client spawning its own boss would not exist for anybody else.


Boss waves pick a kind from the `bosses` list in `waves.json` rather than always spawning the same one. A second list, `debugBosses`, is folded into the roster only in debug builds, which is where a boss still being worked on lives until it is ready to ship. The Roaring Knight and Rofel sit there for now, so a shipping build never rolls it, while a debug build rolls it alongside Rofel. Its art and data are bundled either way, since a guest on a shipping build still has to draw a knight a debug host spawned. An unknown name falls back to Rofel, and an absent list keeps the old behaviour, so the roster is safe to edit. A pack spawns one kind for all its members, so a duo is two of the same boss rather than a mixed pair. The boss bar names whichever kind turned up, and adds "Duo" when there is more than one.

The Roaring Knight is the second entry. Its art is cut from a rip of the Deltarune sheet: each frame sits in its own red box there, so the boxes are found as connected red regions, the interior of each is taken without its border, and every pixel is snapped to fully solid or fully clear, since the rip carried a hundred thousand part-transparent pixels that would have fringed at 4x. Frames of one animation are cropped to the union of their own bounds, which keeps the movement inside an animation, then centred on a shared canvas with their feet on the bottom edge, which keeps the animations lined up with each other. Grouping frames by gaps in the grid was not enough, because the sheet separates some animations by label alone: Ball and Ball Transition sit in one unbroken run of equally spaced boxes. The eighteen animations are therefore cut at the x positions of the sheet's own printed labels, which is the only thing that actually marks where one ends. Every prefix carries a trailing underscore, since flixel matches an animation by string prefix and would otherwise let Ball swallow every Ball Transition frame as well.

The knight does not fight like Rofel. `KnightBoss` is a melee state machine: it hovers at a chosen distance with its sword out, winds up, flies at where the player stood when the wind ended, and slashes on arrival or when the dash runs out, then rests. The slash raises its contact damage for the length of that one animation. The restore is written as "any phase that is not the slash puts the damage back", rather than being handed back on the way out, because a reset carries no reference to the enemy and could otherwise leave the boost on for good.

Being hit interrupts whatever it is doing with the static animation. The behaviour re-asserts its own animation every frame, so it would otherwise overwrite that within one frame: the stun is far shorter than the animation. It therefore holds off while a non-looping hurt is still running and takes the sprite back when that finishes.

Rofel fights with the `boss` behaviour, holding a sword where Rofel holds a gun, and firing shards, stars and thrown blades cut from the same sheet.

### CustomArena

The map the editor asked the next run to use, as raw CSV plus a spawn point. Null means the stock arena. The main menu clears it.

### MapStore

The editor's five map slots. They are JSON files next to the executable on desktop, and browser save on html5.

### MenuSlash

The menu's confirm animation. The weapon selector winds up to the left of the chosen row and sweeps through it. On contact the row hides, and one sprite per letter replaces it. Those letters tumble away under gravity and fade. The option is therefore cut apart and falls into the void before the game acts on it.

A list can opt into held-key adjustment through `repeatAdjust`. A held left or right then repeats after a short delay and accelerates to a fast crawl, which suits a row counting in single units. Lists leave it off by default, so a row whose step is expensive still takes one press at a time. The tick sound has its own floor either way, so a fast repeat does not machine gun it.

It measures letter widths individually, then scales them to span the row's real width. That keeps the swap smooth at the moment the shards appear. Every menu choice routes through it, and returning from Options restores the shattered row.

### JaggedBand

A sawtooth strip that scrolls sideways forever, used to frame the main menu. The tooth shape comes from Will Boyd's "Hello Houdini: Jagged Edge with Mask" pen. Walk across the width, alternating between a peak and a valley. Then close the polygon along the bottom and fill it.

It does not redraw the strip every frame. It draws it once at two teeth wider than the screen, then simply slides it left, wrapping every tooth width. The motion therefore costs nothing and never shows a join. Setting `top` flips it vertically for the upper edge, and a negative speed scrolls the other way. That is how the menu gets its two mirrored pairs.

### IrisWipe

The state transition. A black overlay carries the game icon punched out of it as a transparent hole. The hole grows to reveal a state on arrival, and shrinks to swallow it on the way out.

It builds the mask once and caches it as a persistent `FlxGraphic`. It draws the icon into a square bitmap and inverts its alpha, so the icon silhouette becomes the hole. It must be persistent. Flixel clears its bitmap cache between states. A plain cached BitmapData therefore dies after the first transition, and every later wipe renders as a bare square.

Four oversized black bars track the mask's edges, so the screen stays covered however small the hole gets. It draws on its own camera added on top, so it covers the HUD as well as the world. When finished, `open` hides itself, so the icon's concave notches never linger over gameplay.

`FlxTween.num` drives the scale. The fully open scale clears the screen comfortably. Anything smaller would pop black into the corners the moment a close began. The title sequence, the menu, the pause menu's quit and the death restart all use it.

### Sfx

Positional playback for world sounds. `at(name, x, y, volume)` fades a one-shot by its distance from the view centre and pans it by its horizontal offset. `tune(sound, x, y, volume)` does the same each frame for a held sound, which the shop door uses. The 3D sound toggle bypasses both and plays everything flat.

Positional sound files must be mono. On the native target the pan value moves the OpenAL source position, and OpenAL ignores source positions for stereo buffers, so a stereo file plays centred no matter what pan it gets. The distance fade still applies either way, since that is plain volume math.

### SoundTray

A restyled replacement for the flixel volume tray, installed through the engine's sound-tray hook at boot. It shows the master volume as a percent under ten bars, in the game font for the current language, and the mute key shows a muted label instead. The bars and the underline take a colour from the level: green when quiet, amber through the middle, red at the top. The colour eases to its new value over about a third of a second rather than snapping, and a change part way through that travel picks up from the colour on screen. It slides in with a small bounce, the lit bars pop in one after another, each flashing as it lands, and after a second it slides away and fades. Adjusting the volume while it is already on screen leaves the panel where it is and animates only the bar that changed: a new bar grows in, a lost bar dips and dims. The panel takes the width of its widest label, so it never resizes or shifts between steps. The volume steps click with the menu scroll sounds. It centres on the game area through the scale mode rather than the stage width, which keeps it centred under Windows display scaling.

### Music

The single owner of music playback. `play(name, volume, loop)` switches tracks only when the requested track differs from the current one. Asking for the playing track instead applies the volume, restores pitch, and resumes it if paused. That is what keeps the stage theme unbroken across the menu, the game, pause-quit and restarts.

### DiscordPresence

Discord Rich Presence, Windows native only, through the `hxdiscord_rpc` haxelib. Every method is a no-op on HTML5. It reads the application ID from `assets/data/discord.json`, and stays silent if that is empty.

PlayState feeds it the raw facts each frame through `playing(wave, bossFight, weapon, kills)`, and it diffs internally. Wave changes, the boss fight, weapon switches, pause and death push immediately. Kill-count changes throttle to one update every couple of seconds.

It shows the current wave or boss fight, plus the equipped weapon and kill count. It shows run elapsed time through the start timestamp, and the best wave on the menu and death screens. Image keys are `icon` for the large slot, and `hammer`, `revolver`, `crossbow` or `hook` for the small per-weapon slot. You upload that art to the Discord application.

### PerfLog

A frame-time logger for native builds. It writes `perflog.txt` next to the executable. Each second gets one aggregate line of average, worst and fps. Spike frames and long gaps get an immediate line. Every line carries the live enemy count, pathfinding calls, projectile count and wave. The projectile count covers enemy shots, bullets, arrows, rain arrows, the thrown hammer and the yoyo.

---

Back to the [documentation index](../DOCS.md).
