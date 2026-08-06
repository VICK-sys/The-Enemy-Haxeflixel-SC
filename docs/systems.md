# Systems, entities and utilities

The per-run machinery owned by PlayState, the sprites it drives, and the shared helpers.

## Controls

Every input in the game asks `util/Controls` instead of the keyboard or mouse directly. An action, dash or attack or super or interact, carries one keyboard side bind, a key or a mouse button, and one controller bind, both saved, plus fixed extras that never move: the left stick always moves, the right stick always aims, and Z always confirms.

Aiming is a device question, so `Controls` owns the answer. It watches which device spoke last, real window coordinates for the mouse, so a drifting camera cannot be mistaken for a moving hand, and serves either the mouse's world position or a virtual cursor held a fixed reach from the player in the right stick's direction. Panels opened over the game reset only the keyboard, never the pad: keyboard state is event driven and stays quiet after a reset, but a pad is polled, so resetting it makes a still held button read as a fresh press one frame later, which closed the pause the same instant a controller opened it. The crosshair, every weapon, the camera lean and the co-op aim targets all read that one answer, which is what makes a controller work everywhere without any weapon knowing devices exist.

Gyro aiming stores its claimed cursor position in screen space. Camera movement changes the derived world aim, not the drawn cursor.

Gyro input travels up to 285 screen pixels from its claimed position. This matches 380 world pixels at the normal 0.75 zoom.

Right stick motion moves the claimed position. The hard stick gesture still recenters the gyro cursor toward the stick aim.

Fire is pinned whenever a panel over the game closes, and stays pinned until neither attack button is down. Every weapon fires on hold rather than on the press, so the click that picks a weapon or dismisses a menu was still held on the first frame of play and went straight into the gun. Requiring the button to come up first means the click that closed the panel can never be the click that fires.

## Fonts

`Lang.bodyFont` returns `Unbalanced` at size 48 for English and Spanish body text. Japanese uses `DotGothic16-Regular` at size 24 for every role.

`Lang.titleFont` returns `Kirbys-Adventure` at size 24 for English and Spanish titles.

`Lang.smallFont` returns `5mikropix` at size 24 for English and Spanish small text, chat and peer names. Tutorial instructions use it at size 16.

The three Latin faces each have one base size. Chat scale and tutorial instructions are the exceptions. Both use 8 px size steps.

| Role | Face | Tier |
| --- | --- | --- |
| title | `Lang.titleFont` | 24 |
| menu row | `Lang.bodyFont` | 48 |
| body | `Lang.bodyFont` | 48 |
| small note or hint | `Lang.smallFont` | 24 |
| damage number | `Lang.bodyFont` | 48 |
| chat | `Lang.smallFont` | 24 at scale 1 |
| peer name | `Lang.smallFont` | 24 |
| tutorial instruction | `Lang.smallFont` | 16 |

`digital-7` stays on the time stop clock. The sound tray uses the small face. `runescape_uf` is retired from UI use.

The FPS and memory counter uses the OpenFL `_sans` device font at size 24. Its memory line keeps the dark red alarm above 1 GiB.

The counter follows the scaled game frame and stays at its top-right. Chat remains in the top-left column.

## Systems (source/systems/)

PlayState builds each system once and updates it once per frame. The exception is `MenuList`, which the menu states build.

### Arena

Loads the background and collision tilemap, sets world and camera bounds, and generates pillar sprites from the map data. It answers `wallAt(x, y)`.

Platform targets come out of the same pass as the pillars. Each keeps the pillar's x and takes a width of at least 150 px. Its height maps from how far north the pillar stands. North becomes high.

It owns the boss-intro transition too. `beginBossTransition()` shakes the camera and fades a white overlay in. It then swaps the background for the warping checkerboard grid, which a `WarpShader` distorts. It clears the interior pillars for an open boss arena, removing their sprites and emptying their collision tiles. It then fades the white back out.

That sequence runs from `update(elapsed)`, which also advances the shader. At the fully-white moment `onWhiteout` fires once, cutting the alarm and starting the boss music. After the boss dies, `endBossTransition()` reverses everything. A quick white flash restores the normal background and drops the shader. It rebuilds the pillars through `restoreObstacles`, which reloads the map CSV. It then fires `onNormal` to restore the normal music.

### DecorTiles

The painted floor layer: grid maths, CSV round-tripping, and building the tilemap from a map's tiles. The editor and the game share it. It is purely decorative, and nothing ever collides against it.

Floor art is drawn at `SCALE`, the same four the player, the enemies and every pickup use, so a 24 px tile covers 96 px of floor. It used to draw at its own size, which made the only art in the game at one to one: a fleck you needed eight of to span a character. The scale belongs to the grid as much as the drawing, so `cellW` and `cellH` answer the drawn size and the column count, the cursor, the marquee and the tile to wall mapping all measure in those. A floor painted before this loads on the coarser grid through `parse`, which fills the current grid and takes what fits, so an old map opens with its top corner kept rather than breaking.

### WallSkin

How a run's walls look. It reads from `CustomArena` once at construction: the theme's color and repeating texture, plus the painted tiles stamped over them. Arena hands it each wall block to fill. Arena therefore keeps to geometry and the boss transition, while the skin owns every pixel decision.

### Decor

Builds a map's decoration sprites from its placements. The editor and the game share it, so a map looks the same in both.

It cuts each prop out of its sheet once and keeps it in flixel's cache under its own persistent key. The cache clears between states, and a plain BitmapData handed to `loadGraphic` would go with it. It also owns the feet-anchored placement both sides use.

### Fx

Hitstop drops the time scale for a few frames on kills. `Fx` also owns camera shakes, hit sparks, dash trails and the `bossBlast` death explosion.

`Fx` owns the time scale outright, through `slowFactor`. Hitstop drops below it and returns to it rather than to full speed, so a hit landing during a slow-motion effect still bites and then hands the world back to the slow rather than snapping it back to normal.

### BossFinish

The kill camera. The blow that kills a boss eases the world down to a third speed, zooms the camera to just under twice the fight framing, and leans it most of the way onto the spot the boss died, holds all three, then eases everything back. It runs about three seconds and paces itself in real time, dividing out the time scale it is itself imposing.

`PlayState` hands it the camera by skipping the cursor lean while it is running, so the two never fight over `targetOffset`. Each step snaps camera follow to the eased target. Normal follow smoothing cannot lag behind a distant death. Opening a panel cancels it, which stops a paused menu inheriting the slow motion.

It plays `slowmo` over the top, and owns that sound rather than firing and forgetting it. `FlxG.sound.play` hands back a pooled object, and the pool takes it again the moment it finishes. Holding that handle meant the fade on the way out could land on whatever unrelated sound had since been given the object. It loads its own instance instead, kept out of the pool, and replays it on each kill.

`BossDeath` raises it on the frame it first sees a boss dead. Domo turns red and shakes before breaking into falling shards. The wyrm keeps the shake and explosion. The effects use game time, so they stretch with the slow motion. The host relays the kill-camera moment to clients.

### RenderLayers

The shadow, entity and tag render groups. It sorts the entity layer every frame by feet position, so characters, pillars and decorations overlap correctly. The tag layer sits above that sort, so a name is never hidden by whoever stands behind it.

Fixed bands override the feet rule for states that must not sort by position. Corpses, buried enemies and enemies in the air each hold their own offset. The downed player ghost holds `GHOST_BAND`, which puts it over every prop, so a player who goes down behind the repair shop is still visible.

### PlayerCombat

A hit shoves the player straight away from whatever landed it, along the line between the two bodies. It used to push a fixed 300 on each axis with only the sign taken from the positions, so every hit threw the player on a 45 degree diagonal whatever direction it came from, and a hit from due left moved them sideways as much as back.

How hard is the attacker's to set. `contactPush` on an enemy overrides the player's own `knockback` for contact with that enemy, which is what lets the fire children shove while a stray bullet still only nudges. Enemies without one, and every shot, keep the old figure.

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

Boss waves can bring Domo and the magma wyrm as one encounter. The director unlocks a configured pair after the run defeats every member alone. It prefers undefeated solo bosses, so the current pair appears on the third boss encounter. Each configured pair appears once per run. Each member keeps its full solo scaling and drops its own loot. The director counts boss kinds instead of living bodies, so wyrm splits and cleanup cannot finish the encounter early. Only the final boss kind ends the encounter. One bar pools every member's health and names each distinct boss.

A downed player's revive is a ritual rather than a switch: the scattered body parts draw back together over three quarters of a second, hold and flash, and only then does the body return. The avatar packet carries a reviving flag alongside the dead flag, so every other machine runs the same ritual on its own copy of that player's parts and ghost at the same time. Without it the flag would only ever say dead or alive, and a revived friend would pop back in with nothing between. The flag going away before the ritual ends cancels it, which is what happens when a run ends underneath one.

A run's big pauses wait for the players before they end. `ReadyGate` holds the countdown at the run's first wave, after every shop wave and after every boss, and prints a prompt until each player uses the shown ready key. Solo uses the ready bind. Online keyboard play shows Z when that bind is Enter because Enter opens chat. Controller play keeps the ready button. Ordinary waves flow on the timer, so the gate marks the rests rather than nagging between every fight. It runs solo as well as online: a solo player readies and the wave starts at once, which is what makes the shop a safe place to think rather than a timer you can fumble. Readying also rolls the shop shutter down, so the shop's window is the whole rest rather than one visit. In co-op the shutter waits for the room rather than for one player: readying announces you and nothing else, and the door comes down on the same release that starts the wave, once everyone is in. Closing it on your own ready would shut your friends out of a shop they were still standing in. In co-op the host arms every machine, each player readies for themselves, and the wave starts only once everyone has. A ready player wears a speech bubble over their head, so the room can see who it is still waiting on. A player who is already down readies on their own without a bubble of their own, but the ready still crosses the wire, so everyone else draws one for them. That bubble hangs off the floating ghost rather than the hidden body, which stands where the player fell, and it rides the ghost's bob so it reads as attached. The host releases the hold anyway after 90 seconds, or the moment the last guest drops, so nobody can strand a lobby by walking away.

The gate holds the wave through a flag of its own rather than the shop's, so a shop round and a ready round can both be open without either clearing the other. It also stands down while the shop is in reach, since the shop answers the same key.

### AfkPilot

AFK mode puts a yellow `AFK` label above the player while the pilot controls them. Remote names stay visible below it. Ready bubbles move above the label stack.

An AFK pilot delays ready input while the shop is open. It walks to the shop and uses it when it reaches the counter.

The shop screen buys the affordable stat with the fewest purchased points. Ties follow stat order. It repeats until no stat remains affordable.

The screen then closes the local shop. The pilot can ready for the next wave without waiting for the shop timeout.

Spawned enemies march straight in rather than steering at the player. A spawn sits below the map, and chasing a player who stands off to one side used to walk them sideways along the bottom edge for seconds before they ever entered. While entering they now drive north at full speed with a slight lean toward the target, so they cross the threshold at once and the south edge stays clear.

Four guards feed the rescue. The first treats an enemy as stuck when something drives it but it does not move for 2.5 seconds. The second caps the walk-in: an enemy still entering after 6 seconds relocates instead of circling outside forever. The third catches the quiet failures, where an enemy makes no progress for 8 seconds. The fourth is an invariant rather than a timer: a live enemy that is done entering must be inside the arena, and one found outside it relocates on the spot. That covers anything that leaves through a wall, whatever threw it.

Two rules keep the timers honest. Only a genuine engagement pauses them, meaning the enemy is inside its attack range with a clear line to its target, plus a crowd exemption on the drive check so a mob pressed around a player never teleports. An earlier version paused on raw distance instead, which was almost always true of an enemy chasing you and left the catch-all doing nothing. Progress is also measured between samples two seconds apart rather than against a rolling reference, so an enemy jittering in place cannot keep resetting the clock.

The rescue itself looks for clear ground in rings around where the enemy stands. It falls back to relocating near the player only when nothing close is free.

`EnemyShots` owns the projectile group. It emits queued shots and kills them on walls, props or the player. `BossDeath` owns normal boss defeat timing. `DomoDeathFx` owns Domo's red shake and breakup. The wyrm keeps the shake and explosion. `EnemyRig` lives in its own file so the spawner can use it. The director exposes its callbacks as properties. The network layer wraps those callbacks.

`applyWaveScale` scales every enemy as it spawns. It turns the wave number into health, speed and damage multipliers from the `scaling` block. The client applies the same thing in `addPuppet`. Each machine charges contact damage locally, and the two would otherwise differ.

A randomly chosen wave, 4 to 8 and rolled once at startup, is the first boss wave. It fires the `onBoss` callback, which starts the intro cinematic. After a short intro delay it spawns the boss pack instead of the normal count.

When a boss dies, the director runs its defeat sequence. Domo turns red, shakes and breaks apart. The wyrm shakes and explodes. `onBossDefeated` fires after the final boss effect finishes. That restores normal arena and music state.

The director is also the single home of enemy hit queries. `firstInCircle` and `eachInCircle` run the nearest-hitbox-point circle test every attack uses. Both see live enemies only, and `firstInCircle` can skip seized ones.

A wave ends only once every enemy is dead. One enemy that could never reach the player would therefore hang the run forever. Two guards prevent that.

Spawned enemies pass through walls and prop footprints while entering. They turn solid only once they are inside the arena and clear of any pillar or prop. They therefore cannot turn solid inside one. Beyond that the watchdogs relocate a stuck enemy. A seized enemy is exempt, so a long grab cannot be mistaken for a wedged enemy and torn out of the holder's hands. As a backstop, a wave running longer than 75 seconds relocates everything still alive. The boss is exempt, since its movement is its own choreography.

### Pickups

The health pickup pool. The player collects one on contact, unless health is full.

Contact carries a `GRAB` margin around the kit. The art is the smallest pickup in the game and the player's body box is only 42 by 44, so a plain overlap of the two meant clipping the corner of a small box against a small box, and a run past one often failed to take it. Scraps never had that problem because they magnet in. The margin widens the catch to 72 px from the player's centre, up from 43, without touching the art, the shadow or the drop maths.

The deployed yoyo uses its hit circle as a second collection point. It cannot take a kit at full health.

### TimeStop

The time-stop ability on E, with a cooldown from player.json. It ramps a world-time factor from 1 to 0 over the slow phase. It holds the world frozen for the stop duration, then ramps back.

It publishes that factor through `WorldClock`. Enemies, enemy shots and pickups read it, and scale or skip their own updates. PlayState multiplies it into the elapsed it passes to the director and arena. Wave timers, boss logic and cinematics therefore freeze too.

The player, weapons and player projectiles run at full speed throughout. Seized enemies stay in player-time, so the grab still works on frozen targets. Frozen enemies are immovable statues that deal no contact damage, and frozen shots hang harmlessly in the air.

Music pitch rides the factor down for the record-slowdown effect, pauses at the full stop, and ramps back on resume. While time runs slow the player leaves a blue afterimage trail, built from frame-accurate ghosts through GhostTrail. A subtle blue overlay tints the screen, sized from the camera's view through the same `Veil` the revolver super's sepia uses, so it holds at any zoom. The HUD shows READY, the cooldown, or STOPPED through `hudLabel()`. Dying cancels the stop.

### MenuList

The shared menu widget used by the main menu and options. It is a centred column of text rows with a bobbing weapon selector. It takes W/S and arrow navigation, A/D value adjustment, mouse hover and click, and plays the move and select sounds. Mouse adjustment divides a row between the actual left and right arrow glyphs, so a long label cannot put both arrows on the increase side. Owners supply `onChoose` and an optional `onAdjust`, and can rewrite row labels in place.

### Hud

The UI camera, health and super bars, wave counter and banner. Both bars sit in the one widget in the bottom left, where the narrow strip above the health bar reads the super meter. That strip used to be decoration, and the meter used to sit in the opposite corner, which put the two numbers you watch most at opposite ends of the screen. The red BOSS APPROACHING banner shares the same text and slides down from the top. A red warning icon plays a 5 frame spawn at 14 fps in the screen centre, blinks on a 2 frame loop at 10 fps, and leaves by playing the spawn backwards instead of fading out. Each new wave number flickers between full and dim while the fluorescent-light sound plays, including wave 1. The scrap counter is a picture of scrap next to a number, rather than a word next to a number. It needs no translation. It sits directly over the health widget, sharing its left edge, so everything the player watches is in one column in that corner rather than split across opposite ends of the screen. The icon anchors to that edge and the number runs off its right, so a four figure count grows into open space instead of moving the icon. The icon draws at the same scale as the rest of the UI. It was two thirds of it, which read as a different resolution to everything beside it. Both carry a soft drop shadow, because white on a dark arena floor was the only thing holding them apart from the background.

It also owns the revolver ammo readout and the crossbow's blue gauge, which sits below the health bar. All three bars therefore stack in the one corner, super over health over the gauge. It holds the time-stop status label and its fading countdown. It also holds the death text with the best wave, and the custom cursor. It owns a `BossHud`, and hands boss tracking and the screen flash to it.

Boss encounters replace the label and progress ticks with a full-scale health bar fitted inside the black display window. Its width extends 2 px past uniform scale.

At wave clear, the display hides its label and progress for 0.2 seconds. It then shows the animated GOOD JOB message until the next wave starts. That swap also replaces the boss name and health bar after a boss clears. The host sends the clear event so every player sees the same display.

The display rests against the top-right screen edge. The screen does not clip its top artwork.

Each remote player icon has a small health bar above it. Its fill follows that player's streamed health.

The crossbow arrow points upward 25 pixels below the ammo tube top. Revolver rounds stay centered as a stack.

The ammo bar and health bar use separate PNG files. The HUD loads each complete canvas without cropping. HP and super fills use the health bar's local origin. The super slot extends 2 px to meet its right frame edge. It uses an opaque black backing. Transparent fill gaps reveal black instead of the world.

The health and ammo cluster fades to 75 percent when a boss crosses its screen bounds. Every non-boss enemy leaves it opaque.

The HUD wears the player's color. Every piece of its art loads through the same hue rotation the character and their weapon use, so the gear frame, both bars and the ammo pips all turn with the player. The rotation only touches saturated pixels, so the white outlines and the grey bolts stay as drawn and only what was red follows the player. The ammo art is held out of the rotation by name: a bullet reads as brass and an arrow as red because that is what they are, not because of who is holding them, and a player picking a green tint should not end up with green brass. Each skinned sprite remembers the art it is wearing, which is what lets a color change in the options repaint pieces that are swapped at runtime, like the full and spent ammo pips. Repainting reseeds the bar widths, since loading a graphic drops the clip that draws a partial bar. The heal flash stays green whatever color the player picks, because there it is reporting healing rather than identity.

Both bars slide to their new value rather than snapping to it. The drawn amount chases the real amount by a quarter of the remaining gap each sixtieth of a second, worked out from the frame time so the slide takes the same wall-clock time at any framerate. The first frame after a bar appears snaps, since there is nothing to slide from. The clip only gets rewritten when the whole-pixel width actually changes, so a bar at rest costs nothing. Cues still key on the real value, not the drawn one: the super's chime and glow land the moment it is usable, while the bar is still catching up.

Picking up a repair kit flashes the health bar green for a second before it settles back to red. A hue-shifted copy of the bar art draws over the red one, sharing its position, scale, offset and clip rect, so the green covers the red exactly rather than sitting proud of it. It fades out over the last third of the second. The flash keys on `heal`, which only the health pickup calls, and it stays hidden while the HUD is switched off.

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

Health drops are repair kits, and carry the same small ground shadow scrap does. The shadow mounts once per pickup, the first time it leaves the pool, on both the local drop path and the mirrored one a guest builds from a host snapshot.

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

Three pieces live in `states/play/` and are reached by call rather than by reading `PlayState`'s fields:

| Piece | Holds |
|---|---|
| `ShopRound` | which waves open the shop, who has finished spending, and how long the next wave waits |
| `BossShow` | alarm, whiteout, boss music, loot and the return to normal |
| `RunIntro` | the one-time tutorial shown at the start of the first run |

Each takes the collaborators it needs and nothing else, so the wiring in `create` reads as a list of what answers what.

### Shop

The repair shop stands at the top of the arena for the whole run, greyed out and solid. Its counter blocks movement, so you walk up to it rather than through it.

Clearing a round no longer offers a level. Every tenth round does: the shop lights up, a banner announces it, and the next wave holds while it is open. Walk into range and a prompt appears; the interact key, E by default, opens the screen that spends scrap, which is the same screen the stats allocator always used. Interact is its own bind rather than sharing the ready key, so standing at the shop cannot confuse buying with starting the next wave. The prompt prints whatever the key is bound to, and shows the pad button instead while a pad is in use.

Closing the menu never shuts the shop, spent or not. The shutter stays up until you press ready for the next round, so the shop and the breather share one commitment: readying up is what puts the counter away, and until then you can walk back in as often as you like. The shop still closes itself after a while as a backstop, so an idle player cannot strand a lobby.

The keeper waits below the counter and rises into the window as the shutter goes up, on a four frame idle. She drops back out of sight when the shop shuts, and hides herself at the bottom of the travel so nothing hangs below the building.

The shutter runs a garage door sound while it moves, and fades it out when the shutter lands rather than letting a four second clip keep rolling over a settled door. The shutter itself was slowed to a second and a half so it reads as something heavy rather than a flick.

A shutter covers the counter while the shop is shut and rolls up when it opens. Behind it, a dark interior backdrop fills the opening, pinned to the ground layer so the shutter always slides over it. All three draw behind the building, and the counter opening is the only transparent part of the art, so the opening is the only place any of them can show. Their order is pinned with explicit sort keys rather than left to the feet sort, which would reshuffle the interior mid slide. Sliding the shutter up tucks it behind the sign board, which clips it without any clipping code. It rolls back down when the shop closes. The building itself keeps its full color whether open or shut, and nothing pulses when it opens. The shutter position and the banner are the whole signal.

Two things end the hold. Shopping ends it when the screen closes, and a forty five second cap ends it if nobody comes, so a player who ignores the shop cannot stall their own run. `dismiss()` exists for the first case: it shuts the shop without releasing the hold, because the screen the player just opened owns the hold from that moment.

The shop blocks. Its hitbox covers the standing structure and stops short of the roof, so the roof overhangs and you can walk behind its lip without walking through the building.

The shop hides and returns with the rest of the decor, so the boss whiteout takes it away and the arena restoring brings it back. It stops answering the interact key while hidden, so it cannot be entered through a boss fight. The prop blockers switch off with the decor too, and `PropBlock` ignores a switched-off blocker, so nothing hidden can stop a body, a shot or a sight line in the boss void.

In co-op the shop round is shared but the shopping is not. The host's tenth wave broadcasts the round, every peer's shutter rolls up, and each player walks to their own shop and spends alone while the others keep playing. A player in the menu wears the IN SHOP note. Avatar packets carry that state, so the note clears on every screen after the player exits. The wave stays held until every peer reports done, by shopping or by letting the shop time out, and the host's sixty second cap backstops the lot.

An AFK pilot visits its local shop before it readies. It spreads affordable purchases across the four stats, then closes its local shop.

### BossHud

BossHud keeps the pulsing red warning flash and tracks the current boss pack. The display health bar starts full during the warning and then follows tracked HP after the pack arrives. The name feeds Discord presence. `Hud` draws pooled health.

## Entities (source/entities/)

### Player

WASD movement with an acceleration ramp, a dash, and the walk sound loop.

`applySkin()` loads the sparrow atlas and builds the four animations. The hitbox stays 75x95, so all movement and feet maths read the same numbers whatever the animation is doing.

The field `baseOffsetY` is public here for the supers. They ride the player's draw offset for hover and somersault lift. They must follow a skin change, rather than a value cached at startup.

`shadowCenterX` exists because the side sheet's artwork is not centred in its cells. The walk frames sit right of centre. Mirroring the sprite therefore swings its visual centre by 28 px, while a fixed shadow offset would not move. The player measures each cell's true content centre once as the sheet loads. It then reports where the shadow belongs, mirrored when facing left. That keeps the shadow under the character in every animation, and re-derives itself if the sheet is redrawn.

### HealthPickup

A dropped repair kit. It restores health on contact and expires after a few seconds.

It is drawn from a baked white outline rather than the raw art, and it hovers: the graphic rides a sine on its draw offset while the body stays put, so the hitbox never moves with the bob. Its shadow shrinks and thins as it rises, which is what sells the hover. A white shine pulses over it on a slower sine than the bob, set through the color transform after the expiry blink has written alpha, since writing alpha rebuilds the transform and would drop the shine. Each kit starts its cycle at a random phase so a scattered drop does not pulse in lockstep.

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

It answers two different questions and keeps them apart. `losClear` is the movement corridor, two rays offset by the body radius, and it decides when to path. `fireClear` is one centre ray, and it decides whether a bullet would get through. They disagree in both directions: a pillar thinner than the body passes both shoulder rays while sitting square on the bullet line, and a clipped shoulder blocks the corridor while the shot itself is fine. Every ranged decision reads `fireClear`, movement reads `losClear`.

Both rays also step along their length checking prop solids, since props live outside the tilemap and `map.ray` cannot see them. A tree is cover the same as a pillar.

The tile A* with the box cast and the corridor rays is the navigation model, and it fits a tile map. A navigation mesh would rebuild the same answers from triangles. The gap was never the mesh, it was that self driven bosses skipped the brain, which was the only thing that ticked this component, so they kited and fired with no cover awareness at all. The sprite now ticks pathing for them too.

### Attack behaviours

`AttackBehavior`, `ChargeAttack` and `FlankAttack` are the attack style interface and its implementations. A charge is a windup, a straight lunge and a recovery.

An optional `chargeLift` turns that lunge into a jump, on the same terms the magma wyrm surfaces on. The sprite rides an offset above its own feet while the shadow, the hitbox and the sort key stay on the ground, so the enemy reads as airborne without leaving the floor it is measured against. The height follows a sine arc across the lunge, which lands it back at zero exactly when the lunge ends, and the windup dips the sprite a fraction of that height first so the jump has a squat in front of it. `RenderLayers` already draws anything with lift in the airborne band, so a jumper passes over the crowd it leaps into. A charger with no `chargeLift` is untouched and lunges flat.

The lift is dropped on `reset()` and on death, so nothing can leave a corpse or an interrupted enemy hanging in the air. Guests do not receive it. The wire carries position, facing, health and animation, so a puppet jumper slides flat the same way a puppet wyrm does.

`FlankAttack` is the woodster's behaviour, and the only ranged one outside the bosses. A shooter that holds position walks in with the melee pack and stands where it stopped, so the woodster instead works its way round to the side and fires from there. It picks a post: a bearing 55 to 125 degrees round the target from wherever it stands, at the `standoff` radius. It travels there on an arc, blending a sideways push round the target with a pull toward the standoff radius, so it circles rather than closing. On arrival it plants, plays the start frame, fires two shots off the loop frame, plays the end frame, then picks a fresh post and slides again. It also flips its orbit direction a quarter of the time, so it does not always circle the same way.

Posts are claimed in a shared list, so a second woodster on the same target will not choose a bearing within about 50 degrees of one already taken. It tries four bearings, alternating sides, before settling for a crowded one. Dead and killed claimants are pruned on each claim.

Three things break a post. A target that closes inside `minDist` sends the woodster to a new one, so it backs out rather than standing there to be hit. A hit calls `reset()`, which also sends it to a new post. Losing the corridor to the target, or the target leaving attack range plus `disengage`, hands control back to the brain, which paths in the normal way until the shot is clear again.

A slide ends early if it stalls. The behaviour sets a velocity but a wall decides whether the body moves, and in the corridor the standoff circle does not fit. If half a second passes with neither the bearing nor the radius improving, the woodster plants and fires from where it is. Without that, a woodster pinned on a wall would grind against it for the whole `slideMax` before it took a shot.

Domo only fights what it can hit. While `fireClear` is down the hover hunts instead of holding the band, and the decision roll never picks the shotgun without a line, taking the dash or the summon instead.

### Shots

`EnemyShot` is the pooled enemy projectile. It carries its damage, speed, range and optional sprite from the shot request, and sprite bullets rotate to face travel. It remembers where it was last frame, because the wall check needs the whole segment it travelled: a fast round can cross more than a 24 px wall tile in one frame, so a single probe point ahead of the bullet could land past a pillar it had passed through. The sweep from last position to next samples every step of the way.

`EnemyShots` refuses to spawn a shot whose path from the shooter's centre to its muzzle origin crosses a wall or a prop. A muzzle origin that sits far out from the body used to poke through cover and hit a player standing safely behind it. A gun pressed against a wall now just does not fire.

`ShotSpec` is one queued shot request: direction, damage, speed, range, sprite, sound, and an optional spawn origin. Behaviours push these onto the enemy's `pendingShots`, and the director drains and fires them. That lets the boss fire multi-bullet volleys with per-shot parameters.

## Data modules (source/data/)

- `DataLoader` - reads and parses a JSON asset. It throws with the path in the message if the file does not exist.
- `EnemyData`, `PlayerData`, `WaveData`, `ArenaData`, `WeaponData` - typedefs and parse-once registries for the files under `assets/data/`.

## Utilities (source/util/)

### Paths

Asset path builders: `image`, `sound`, `music`, `file`, `json`, and `sparrow`, which returns the loaded atlas for a png and xml pair.

### Lang

The string table for the game UI. It holds English, Spanish and Japanese, and `Lang.t(key, args)` reads one line. Arguments replace the `{0}` and `{1}` markers in the line. An unknown key falls back to English, then to the key itself. A key therefore never renders as blank.

`Lang.cycle(dir)` steps through `Lang.codes` in either direction, so the option row answers both left and right.

The map editor keeps its English strings, because it is a build tool rather than a player screen.

`Lang.bodyFont`, `Lang.titleFont` and `Lang.smallFont` return role faces with fixed sizes. Body text uses `Unbalanced` 48. Titles use `Kirbys-Adventure` 24. Small text, chat and remote names use `5mikropix` 24. Japanese uses `DotGothic16-Regular` 24 for every role.

The old tier ladder and fitted title sizes are removed. The main menu splash uses the title face when it fits and the small face otherwise. Chat scale is the only variable size. It snaps the small face to 8 px steps.

A language change writes to the save and raises a flag. The main menu reads that flag with `consumeChanged()` and rebuilds itself. In a run, the pause screen relabels itself and the HUD re-applies the font. Nothing rebuilds the whole play state.

### BackGear

The spinning gear on the player's back, drawn as its own sprite so it can turn freely behind the body. It anchors to the player each frame with a lean that tucks it in while walking or dashing. The anchor rides the visual body, not just the hitbox: the update takes the sprite's spin angle, its lift off the ground and the point it spins about, so any move that spins or lifts the body carries the gear with it instead of leaving it at ground level. `PlayState` updates it after combat so those values are current-frame, and `RemoteAvatar` feeds the same three values off the wire for remote players.

### GhostTrail

A pooled afterimage trail. It fades its ghosts every tick. On a fixed cadence it stamps a copy of a source sprite, carrying position, angle, scale and color. The time-stop player trail instead uses `stampFrame`, which copies an animated sprite's current frame with a forced tint. The thrown hammer, the orbiters, the Arrow Storm launch arrow and the time-stop trail all use it.

### WorldClock

The world time scale, at 1 normal and 0 frozen. World entities that update through the display list read it.

It holds two sources rather than one value. One belongs to `TimeStop`, the other is free for anything else that needs to slow the world. The `scale` field reports whichever is slower. A single field could not survive two writers. Assignment happens every frame inside `TimeStop`, which would overwrite anything else before the enemies read it.

### WarpShader

A GLSL fragment shader that distorts a sprite's texture coordinates with time-driven sine waves. The boss-arena grid background uses it, and `advance(elapsed)` steps its time uniform.

### SaveData

The persistent save keeps one overall wave record and one record for each weapon. Reset Best Wave clears all five records. It also keeps settings, the last joined IP, and the online player name. The settings are the master, music and sound effect volumes, display mode, V-Sync, framerate, aspect ratio, screenshake and freeze-frame amounts, HUD visibility, 3D sound, FPS counter visibility, instant quit, and language. A call to `applySettings()` pushes them into the engine. It runs at boot and whenever an option changes. The master volume sets `FlxG.sound.volume`, and the music and sound volumes set the two default flixel sound groups, so the final level of any sound is its own volume times its group times the master.

### The fire family and Domo

The basic ranks are the fire children. Their chase speed follows the six-frame walk art. Every scale stays above zero. Adjacent scales differ by at most 3 times. The fastest scale is 3.5 times the slowest. The six scales average to one, so the basic child averages 300 px per second before wave scaling. Its pulse ranges from 150 to 525 px per second. A basic fire child follows until it makes contact. Its negative attack range prevents a charge.

The turquoise champion notices the player inside 300 px and charges inside 260 px. Its grounded ball lunge covers 266 px. It uses a 0.25 second windup and a 0.15 second recovery. It waits three seconds after recovery. The basic green child keeps its contact push and recoil.

Domo is the first boss and fights with `DomoBoss`. It does not walk into the player. Between attacks it holds a distance band, closing past `prefMax`, backing off inside `prefMin`, and drifting sideways the rest of the time on a strafe that flips on a timer and on wall contact. It moves slower than its own children, so the dash chain is what closes ground rather than the walk. Past `farDist` it only picks between summoning and dashing, since the shotgun would be wasted at range.

The band restores the walk animation once a hurt animation has finished. Nothing else put it back, so a hit taken while chasing used to leave Domo sliding around on its last hurt frame for the rest of the fight. Domo carries its shotgun at all times rather than producing it to fire. It rides the enemy's gun sprite slot, held out from the body toward whoever the director is targeting and turned to that angle, flipped when aiming left so it never hangs upside down. That slot is already replicated, so remote players see it aimed too. The shotgun attack is three quick five-shot fans out of the barrel it was already pointing. It will not fire one from inside `shotMin`, which sits just under the near edge of its band. The fan is five pellets over 52 degrees, so it opens wide at range and only clips a player, but converge it on a 42 px body and all fifteen pellets of the three fans land, which is nearly twice what the player has. A dash that ended on top of someone used to be followed by exactly that, since the roll to attack again did not care how close the dash had left it. Too close now takes the dash or the summon instead, and the dash carries it back out. The fan at the end of each dash answers to the same floor, so a dash that lands on a player leaves the ram damage and nothing else. Every dash also ends in a fan, from `dashShots`, three shots off the first dash, four off the second and five off the last, so a chain that misses still leaves something behind it and the last one hurts most. The dash then hands to a beat of its own, `dashRest`: Domo plants, having just fired, and holds before winding into the next one. It brakes far harder there than anywhere else, since the normal brake takes most of that beat just to shed 1050 px a second and the pause read as a long slide rather than a stop. The beat runs after the last dash too, so the chain ends on the same rhythm before the cooldown takes over, and poise covers it like the rest of the attack. They aim wherever the barrel is pointing at that moment, which is at the player, so the punish for dodging a dash is the spray that follows it. The fan widens with its count off the same `shotSpread`, from 26 degrees to 52. The shotgun cannot be shot out of Domo. Any hit normally calls `attack.reset()`, which for a state machine means the whole attack is abandoned, so one bullet used to end the three-burst fan on its first shot. An enemy can now raise `poise`, and while it is up a hit still lands its damage and its flash but skips the interrupt, the reset, the knockback and the stun. Domo raises it for every attack it commits to, so none of the three can be shot out of it once it starts, including the gaps between the dashes in a chain. It only drops the guard while chasing, which is the window to punish. Poise goes up at the moment an attack is entered rather than at the end of the frame that entered it, since a hit landing in between would otherwise still cancel the attack on its opening frame. Death ignores poise, so it can always be killed mid-attack.

The summon queues four basic fire children through `pendingSummons` on the enemy, drained by the director the same way pending shots are, one at each cardinal point around Domo. It is capped: the director retallies a census of living enemies by kind every frame, and Domo will not choose the summon while more fire children than `summonCap` are already out. The check runs again when the summon lands, so a call that was fair when chosen and crowded by the time it resolves still spawns nothing. The dash is three runs that commit to a heading and sail well past the player, covering about a thousand units against the four hundred a fleeing player manages in the same time. The turn rate is deliberately weak: over a whole dash it bends the heading toward the player by less than a third, enough to curve after someone who moved but nowhere near enough to track them down. Domo's chase is slower than the player at every wave it can appear on, so the dash is the only thing that closes distance, and it has to be dodgeable or nothing is. Both `poise` and `ramming` are derived from the phase every frame rather than switched on and off at the edges, because `reset()` carries no reference to the enemy: a hit landing mid-dash would otherwise leave the ram flag raised for good, flinging fire children at the player for the rest of the fight. While Domo is dashing it wears that `ramming` flag. The director interrupts each enemy attack before applying the fling. A charging child lands immediately and returns to following.

Domo's death uses `DomoDeathFx`. It clones the current body, turns it solid red and shakes it. The clone then splits into 36 falling shards. The original body stays hidden. Host and guest puppets run the same controller, so snapshot removal cannot cut the effect short.

Boss fights no longer swap into the warped checkerboard realm. The alarm, banner, boss music and camera pull survive on their own timer, and the arena, decor and shop all stay, so the fight happens in the room the run is played in.

### Boss roster

`summonBoss(kinds)` starts one boss encounter from an array of kinds. It removes duplicate and unknown kinds, and permits only one wyrm. An empty result falls back to Domo. The summon clears the queued wave and plays the shared boss intro. It refuses while an encounter is arriving or active. CONTROL with 0, 9 or 7 summons the magma wyrm, Domo or the Domo and wyrm pair. These controls run on the host only.


Boss waves pick solo kinds from `bosses` in `waves.json`. They prefer kinds not yet defeated in the current run. Debug builds add the optional `debugBosses` list to that roster. `bossPairs` defines combined encounters. A pair unlocks after every member is defeated in the run and appears once. Forced debug and network summons bypass this unlock.

`spawnBossPack` creates every selected kind before publishing one `onBossPack` callback. Normal bosses use `BossDeath` for their own kill and drop sequence. The wyrm reports one member defeat after its final segment retires. The director decrements one encounter counter for either path. It fires `onBossDefeated` exactly once when that counter reaches zero. The shared bar sums every body in the published pack, including all wyrm segments.

The magma wyrm is a chain rather than a body. It spawns as twenty one linked parts, a head and twenty segments, each a real enemy with its own health and its own small bar above it. The chain moves as one thing: the head hunts whoever the director targets, records the ground it covers, and every segment rides that trail at a fixed spacing, so the body follows the head's path exactly rather than cutting corners.

A wave travels down the chain. Parts on the crest arc into the air and parts in the trough are under the ground, wearing the mound art with no shadow, and a buried part cannot be hurt at all. Each pooled mound samples `Arena.floorColorAt` when placed. Pool reuse always replaces the prior tint. A white flash overrides the tint and restores it when the flash ends. The chain ignores walls and never collides, above ground or below, which lets it dive under the arena edge and surface inside.

Every part uses a 48 x 48 frame. The collision box stays 90 x 90 and remains centered under the larger art.

Surfacing plays the first, third and fifth mound frames. Burrowing plays all five mound frames in reverse. Both passes keep scale and alpha fixed.

Killing a middle part splits the worm. The piece behind the break keeps its head; the piece in front of it promotes its first part to a new head, keeps its own trail, and fights on as a second worm. Each head shoots at its target, but only while it has at least `shotMinParts` segments behind it, so whittling a chain down silences it before it dies. The boss is beaten when every part of every chain is gone, at which point the kill camera, the drops and the defeat handoff fire from the last part to fall.

A chain that drops below two parts collapses at once. A lone head has no body to shoot from and nothing left to sever, so it bursts in a puff and a surface cry rather than skating around the arena as a piece that cannot fight. The cull runs after the split pass. Severing one part can therefore promote a new chain and retire the stub the cut left behind on the same frame.

Every killed or collapsed part plays the seven frame debris burst. The part remains until the last frame finishes.

`WormFlock` owns all of it, chains, trail, wave, bars, splits and promotion, and the segments themselves are `selfDriven` enemies with an empty attack, on rails. The dig sound plays each time a head breaks the surface or goes under.

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

A restyled replacement for the flixel volume tray, installed through the engine's sound-tray hook at boot. It shows the master volume as a percent under ten bars, in the game font for the current language, and the mute key shows a muted label instead. The bars and the underline take a color from the level: green when quiet, amber through the middle, red at the top. The color eases to its new value over about a third of a second rather than snapping, and a change part way through that travel picks up from the color on screen. It slides in with a small bounce, the lit bars pop in one after another, each flashing as it lands, and after a second it slides away and fades. Adjusting the volume while it is already on screen leaves the panel where it is and animates only the bar that changed: a new bar grows in, a lost bar dips and dims. The panel takes the width of its widest label, so it never resizes or shifts between steps. The volume steps click with the menu scroll sounds. It centres on the game area through the scale mode rather than the stage width, which keeps it centred under Windows display scaling.

### Music

The single owner of music playback. `play(name, volume, loop)` switches tracks only when the requested track differs from the current one. Asking for the playing track instead applies the volume, restores pitch, and resumes it if paused.

`rollRunTrack()` chooses `outerDrylands` or `jungleJam` when a run starts. `getRunTrack()` returns that choice for normal play and boss recovery. A lobby gets a lazy choice before the first run starts.

### DiscordPresence

Discord Rich Presence, Windows native only, through the `hxdiscord_rpc` haxelib. Every method is a no-op on HTML5. It reads the application ID from `assets/data/discord.json`, and stays silent if that is empty.

PlayState feeds it the raw facts each frame through `playing(wave, bossFight, weapon, kills)`, and it diffs internally. Wave changes, the boss fight, weapon switches, pause and death push immediately. Kill-count changes throttle to one update every couple of seconds.

It shows the current wave or boss fight, plus the equipped weapon and kill count. It shows run elapsed time through the start timestamp, and the best wave on the menu and death screens. Image keys are `icon` for the large slot, and `hammer`, `revolver`, `crossbow` or `hook` for the small per-weapon slot. You upload that art to the Discord application.

### PerfLog

A frame-time logger for native debug builds. Release builds do not create a log. Debug builds write `perflog.txt` next to the executable. Each second gets one aggregate line of average, worst and fps. Spike frames and long gaps get an immediate line. Every line carries the live enemy count, pathfinding calls, projectile count, wyrm mound count and wave. The projectile count covers enemy shots, bullets, arrows, rain arrows, the thrown hammer and the yoyo.

---

Back to the [documentation index](../DOCS.md).
