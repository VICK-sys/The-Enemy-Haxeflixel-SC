# Weapon systems (source/systems/weapons/)

## Weapons

The combat coordinator. It owns the weapon for the run, which `equip` sets once and nothing changes mid-run.

It splits the two buttons. Left click runs `primary`, right click runs `secondary`, and both key on the equipped weapon.

It triggers the supers on Q at a full meter. The hammer launches SuperOrbit, the revolver DeadEye, the crossbow ArrowStorm, and the yoyo HookArms. `hasSuper` still gates the key. Dead Eye needs a round in the cylinder. The meter should not go on a super that cannot fire.

It also handles attack input dispatch: super priority, the held-enemy throw intercept, and the aim math. It hides the held weapon while the grab or the yoyo is out. Everything else goes to the systems below.

## WeaponMode

Names the attack that just fired. It drives the held sprite's swing duration, the HUD, and the network wire, where `NetSync` sends `Type.enumIndex`. Reshaping it therefore needs both peers on the same build.

## HitPipeline

The shared hit pipeline. It applies damage with a hit sound, sparks, kill rewards and drop rolls.

`blastRadial` is the shared area hit. It damages every enemy in a circle and flings them outward from the centre. Landing rain arrows use it.

## Rope

Shared cord drawing. It tiles `yoyo_string` segments along a straight line for the grab line and the yoyo's string. For the arms' curved cords it follows a quadratic bezier with an explicit control point. It draws into a caller-owned sprite group.

The curve spaces its segments by distance travelled rather than by curve parameter. It samples the bezier once to measure the real arc, then walks that arc placing a segment every fixed step. Both halves matter. Sizing the count from the straight line between the ends under-counts, because the bow is about a third longer than its chord, and stepping the parameter evenly spreads the segments out where the curve runs fastest. Either one alone opens gaps in a long reach. Spacing from the arc keeps every step shorter than a segment, so the cord stays solid at any length.

## HeldWeapon

The held sprite. `kind` is the equipped weapon and persists. It picks the graphic, origin, hand anchoring, cursor tracking and facing flip.

`attack` is the transient mode passed to `beginSwing`, and lives only for that swing. That is what lets the crossbow return to its aiming pose after an arrow rain, instead of staying raised skyward.

The two weapon shapes flip differently. The game draws melee weapons upright. They swap `flipX` and add 180 to the angle, which keeps the blade leading.

It draws aimed weapons, the revolver and crossbow, pointing right. They rotate straight to the aim angle. They swap `flipY` instead, and without it they hang upside down whenever you aim left.

Both flips use the same margin around 90 degrees. A cursor near straight up or down therefore holds its orientation instead of flickering.

## SwingAttack

The hammer's melee, built from the `swing` config block: long reach, a wide arc, 2 damage and an oversized slash to match the weapon. The yoyo runs `YoyoJab` instead.

Each fire spawns a slash effect and strikes every enemy inside its arc. It also opens a short guard window, during which it deflects enemy shots. The window runs for `GUARD_TIME` rather than only the frame of the click, so a swing catches bullets that arrive mid-animation. A deflected shot swaps to the player bullet sprite rather than taking a tint. A round coming back at its owner therefore reads as yours.

The hammer's block also carries a `cooldown`. Each swing starts it, and both the next swing and the throw wait for it out. Catching a thrown hammer starts the shorter `catchCooldown` from the thrown block, so a catch cannot chain straight into a hit. The reload bar above the player shows the wait, the same way it shows a reload. Dexterity shortens it like every other recovery.

## YoyoJab

The yoyo's primary, held rather than tapped. Press left click and the yoyo is thrown out. Hold it and the yoyo stays out, spinning, chasing the cursor but never further from the hand than `reach`. Aim past that limit and it sits on the edge of the circle in the cursor's direction. Let go and it comes home.

`YoyoFlight` owns the motion. While it is out the yoyo carries real velocity. It steers toward the cursor and brakes as it arrives, so it hovers at the aim point, and the string is a hard limit at `reach`: momentum that would carry it past the edge is cut along the string and kept across it, so overshooting the circle swings the yoyo along the arc the way a cord under tension would carry it. It leaves the hand at full speed along the aim, and a small hover shake keeps it alive at rest. `YoyoJab` wraps that with the damage.

Coming home it runs at flat speed instead. Easing chases a target by closing a share of the gap each frame, which settles into a standing lag once the target is moving, and the hand moves whenever the player does. That lag came out just wider than the distance the catch tests for, so walking away from a returning yoyo left it hovering at the hand, spinning, caught by nothing, with every attack locked out behind it. Flat speed always closes.

Every landed hit bounces the yoyo off the enemy it struck. The recoil owns the motion for a moment before the steering is allowed back, so the knock reads as travel rather than a twitch, and then the return sets up the next hit. Holding it on a target therefore reads as the yoyo hammering it rather than sitting inside it.

The string draws taut from hand to yoyo. An earlier pass simulated it as a loose cord and it read as a kinked chain, because a deployed yoyo keeps its line under tension and a slack cord is the wrong physics for it. The bends the player feels come from the yoyo swinging on the string limit, not from the string itself.

Two floors guard the rest of that. The yoyo will not sit closer to the hand than a minimum while it is out, so aiming at your own feet throws it clear rather than parking it on your chest, and it cannot be caught in the first fraction of a second, so a tap still reads as a throw rather than a flicker.

Damage repeats rather than landing once. Each enemy the yoyo touches is struck, then sits out `hitGap` before it can be struck again, so parking the yoyo on something grinds it down while sweeping across a crowd clips each of them. The push follows the string: out shoves a target away, coming home drags one toward the player. It deflects enemy fire on contact, which makes a parked yoyo a small moving shield.

Holding costs. The throw runs for `holdTime` and then tires out on its own and returns, and a throw that ran itself out pays `restCooldown` rather than the short `cooldown` a released one pays. Letting go early is therefore worth doing. The reload bar above the player shows the wait, the same way it shows a reload.

The held sprite hides for as long as the yoyo is out, since the yoyo is the held weapon. Q recalls it and spends the super. Right click recalls it and throws the grab.

## RevolverAttack

The revolver. Every shot it fires plays `revolver`, whether aimed, fanned or from Dead Eye. The boss keeps `enemies/pistol`, so the two guns no longer sound the same.

The cylinder holds six rounds. The primary fires one fast straight bullet per click. That bullet dies on the first enemy or wall it meets. There is no fire-rate timer, so the cylinder is the only limit.

`fanFire` on the secondary arms a burst rather than firing anything itself. The update loop then looses one round every `fanInterval` until the cylinder is empty. Each round leaves the current aim by up to `fanJitter` degrees. That is what fanning a revolver is: the hammer slapped back over and over.

The rounds therefore leave one at a time. The burst tracks the cursor as it runs, instead of landing together like buckshot. Nothing can fire by hand while it runs, and it is worth more the fuller the cylinder.

Running dry starts a reload, and so does fanning. R reloads early. Three cases refuse it: a full cylinder, a reload already running, or a fan mid-burst. It therefore cannot cut a burst short or stall one reload with another.

`fire` and `fanFire` both re-check their own gates rather than trusting the caller. Nothing can drive the cylinder negative and take the HUD readout with it.

### The ammo readout

The HUD prints `displayRounds` against `capacity`. That is `rounds` at rest. During a reload it is the count chambered so far. The number therefore tallies up as the cylinder fills, rather than snapping from empty to full.

Each climb pops the readout and plays `bulletLoad`, one round at a time. The cylinder snaps shut on the last one. An early reload with three in hand therefore clicks three times, not six. The counter jumps to whatever the tally reached, rather than stepping one at a time. A frame long enough to skip a number therefore costs a click, instead of stacking several at once.

It counts from what was left rather than from zero. Reloading early with three still in hand therefore reads three to six. Every reload costs the same `reloadTime`, whether it chambers one round or six. You can therefore read the wait off the bar alone and never off the count.

`rounds` itself does not move until the reload finishes, so nothing can fire off a half-full display. The blue bar stays with the crossbow's arrow rain, which is a continuous charge with no count to show.

The crossbow borrows the same bar. Every shot puts the bow on `shotCooldown`, and that cooldown drives the bar exactly as a reload does, with its own crank sound. Full charge used to skip the crank, which made the bar appear on some shots and not others, and a reload you cannot predict reads as a broken one. Full charge keeps the pierce as its reward. The crank runs a second, the length of its sound, so the two end together.

### The reload bar

`ReloadBar` puts a second readout in the world, above the player's head. A bracketed track holds a single line that crosses it from left to right over the reload. The screen corner holds the count, and the track holds the time.

It draws from `reloadProgress`, which is the fraction of `reloadTotal` already served.

The travel is measured off the art rather than written down. `traceTrack` reads the widest run of pure white across the middle row of `reload_bar`, which is the channel between the two end caps, and the line sweeps that run. Hard coded numbers had already gone stale once when the bar was redrawn wider, leaving the line stopping short of the right cap. `PlayState` shows it while the held weapon recovers: the revolver's reload, the crossbow's crank, or the hammer's swing cooldown. It follows the player every frame. Because each recovery runs to a flat time, the line always crosses at one speed. It reads as a clock rather than as a count.

It sits after `props.overlay` in the display list, above the wall redraw that buries the player behind a prop. A timer you cannot see is worth nothing, so it stays readable even from behind the scenery.

### Melee weight

Each melee weapon carries its own `knock`, multiplying the push the arc hands to `takeHit`. The hammer sends a struck enemy out at over three times the base, far enough that it has to walk back in; the yoyo moves one barely further than its own stride, and shoves it away going out or drags it back coming home. A struck enemy braces before it goes. `brace` takes the launch off it, shakes its draw offset for the length of the stop, then hands the velocity back on the frame the stop ends. Both count frames rather than seconds, so they cannot drift apart however slow the world is running, and the shake moves the sprite only: the hitbox and the shadow stay where the enemy is. The yoyo braces for nothing, because two frames of shake is not something anyone sees.

A killed enemy is launched too, if whatever killed it braces. `takeHit` still parks a corpse, and the dead branch of `update` still holds it there, but a corpse that finished a brace is left alone so its drag can carry it out. It keeps its death animation and its fade the whole way, because those run on time rather than on where it is. Anything that does not brace kills the way it always did: the yoyo, every gun, every arrow.

### Melee hitstop

A connecting swing freezes the world for a moment, weighted per weapon out of `weapons.json`. The hammer holds for many frames at six percent speed with a real shake; the yoyo holds for two at thirty percent and barely shakes. The numbers live in the data, so the weight of each weapon is a tuning question rather than a code one. The hammer lands like a hammer and the yoyo stays quick.

The hitch fires once per swing, on the first enemy the arc catches, and before the damage is dealt.

A melee hit owns its frame. A swing that kills used to raise two stops at once, its own and the kill's, and whichever wrote last decided the weight. The same swing then bit differently depending on whether it happened to finish something off, which is what spamming made obvious. The kill stop now stands aside when a swing already set one, so a weapon holds exactly its own value whether it killed or not. Ranged kills still raise it, because nothing else did.

Where two stops do meet, they only deepen: frames take the longer and speed the slower.

`Fx.update` is the only thing that restores `timeScale`, and it does not run while a panel is up. Every panel now opens through `PlayState.openPanel`, which clears the hitstop first, so a swing landed on the frame a wave clears cannot leave the shop screen running at six percent speed.

## BowAttack

The bow shot and the arrow rain trigger. It owns ArrowRain.

A shot arrow dies on its first enemy hit or a wall. At full charge it becomes `piercing` and carries a hit list. It then passes through a line of enemies, hitting each once.

Firing anything short of a full charge starts a `shotCooldown` that blocks the next charge, so tapping cannot be click-spammed. A full charge skips that timer. Holding for `fullTime` already paces the weapon, and the cooldown was only ever there to stop the tap.

Arrow rain costs `rainCharge`. That meter runs 0 to 1, empties on use, and refills over `rechargeTime`. The HUD draws it as a blue bar through `Hud.setGauge`, and shows it only while you hold the bow.

The shot charges. Holding the attack button builds charge, and releasing looses the arrow. A tap under `minTime` fires the plain arrow it always did, so nothing is slower than before. Past that point damage steps up to `maxDamage`, and the arrow grows, flies faster and hits harder.

A looping tension sound rises in pitch with the charge. It starts only once the hold passes `minTime`, so tap shots stay silent instead of clipping it. Full charge arrives at `fullTime` with its own sound, and is the only point that awards top damage. Holding longer simply keeps it there. The charge cancels if the player dies, switches weapon, or starts a throw.

## ArrowRain

The bow's secondary. The bow rises above the player's head and points skyward. Firing launches a fanned burst of arrows up from it. A staggered volley then falls onto a scatter of points around the cursor.

Each impact point shows a ground marker during the descent. The falling arrow fades in over the first part of its drop rather than popping into view. That fade keys to distance fallen, so it stays proportional if the drop height or fall speed change. A landing arrow damages enemies in a radius with outward knockback. The rain ignores walls.

Impact points are floor coordinates. The marker, the arrow's descent and the blast all read the same point through `rainAt`.

## HookAttack

The yoyo's secondary, split two ways. The phase machine and the catch-and-throw chain live in `HookAttack`: fly out, latch, reel in, hold, spin, release. It owns the flying sprite and its string. `HookFlight` carries a thrown enemy after the grab has let go. It lives apart because its lifetime outlasts the phase that started it. It keeps running while the yoyo is idle or thrown again.

The grab throws the yoyo itself, trailing its string back to the player. The hand stays empty and all attacks block until it returns. It latches the first enemy it hits, with light damage plus a seize that suspends the AI. It then reels that enemy in and holds it in front of the cursor.

Left click while holding whips the enemy in one quick revolution around the player, then launches it as a projectile. That projectile damages every enemy it passes through. The yoyo returns to the hand at the moment of release, so the enemy flies alone. Hitting a wall damages the thrown enemy. Otherwise the flight ends with a short stun.

On a miss it retracts to the hand, and it stays live on the way back. A returning grab takes the first enemy it touches that nobody already holds, so a shot that missed ahead of a target still catches it on the return. Seized enemies deal no contact damage and skip crowd separation.

A held enemy is a shield. Enemy fire that reaches it stops there and wounds the enemy instead of the player, so you can walk a body into a firing line. Enough shots kill it, and a dead victim drops off the string the same way any other loss does.

The grab cannot latch an enemy flagged not `grabbable`, which means the boss. It deals `snagDamage` instead, then retracts. The return trip snags the same way, so a throw that reaches the boss on the way home still hurts it. One throw lands one snag either way. Without that cap the returning line would bill the boss every frame it overlapped. That is much more than a normal hit, since it is the only thing the grab can do to them. The auto-grabbing arms are the yoyo's super, covered under `HookArms`.

## ThrowAttack

The boomerang throw. It covers the thrown hammer's flight: out leg, wall turnaround, homing return and catch. It also owns the afterimage trail and the spin sound loop. The return steers around walls with its own EnemyNav instance on a fast re-path interval. The player cannot attack while it is airborne.

Only arena walls turn the outbound leg around. Buildings and the rest of the scenery stop every other projectile in the game, but the hammer sails over them, so a throw across a rooftop reaches what is behind it instead of bouncing back off the roof.

## HookArms

The yoyo super. Q with the yoyo equipped and a full super meter drains the meter. It then extends two mechanical grab-arms from the player's back, rendered behind them, for a few seconds.

Each arm works alone. It picks whatever lies nearest the cursor rather than nearest the player, grabs it, reels it up, whips it in an arc and hurls it along the line to the cursor. Every part of that reads off the cursor, including which side the arms rest on and which way the whip sweeps. Those two used to key off which way the body happened to be facing, so the arms swung by the walk rather than by the aim. The arms rest tilted, and their curved ropes trail with inertia. They retract into the body when the super ends. The held yoyo hides, and the player can still move.

The arms also catch bullets, which the ordinary grab cannot do. With no enemy in reach an arm snatches the enemy shot nearest the cursor out of the air, holds it through the same whip, and hurls it back as a friendly round. A held shot harms nobody while it waits.

## ArrowStorm

The crossbow super. Q with the crossbow equipped drains a full super meter. It fires one supercharged arrow straight up from the bow. It is a big glowing arrow with a fading trail.

The storm proper starts once that arrow clears the top of the screen. The bow stays raised skyward while arrows carpet the whole visible arena for a few seconds. Drops spawn across the camera view on a fast cadence, reusing ArrowRain's drop, marker and landing machinery. The player can still move throughout.

## DeadEye

The revolver super. Q whites the screen out, then settles into a sepia wash over a looping heartbeat. It stops the world dead. `superSlow` goes to 0, and the player cannot move. Only the cursor still moves.

Sweeping the cursor over an enemy marks it, one mark per round left in the cylinder. A full cylinder therefore marks six, and a nearly spent one marks one. There is no timer, and it holds until you press fire. Marking nothing and firing cancels without spending anything.

A second press of Q backs out. It answers only while you are still marking, so nothing can stop the volley once it starts. The world, the aim lock and the marks all reset through `cancel`, the same path a dead player takes. The meter does not come back. Without that cost, Q would be a free pause button that freezes the fight and shows you the whole arena.

Releasing unfreezes the world and walks the marks in order at `shotInterval`, one round each, while the sepia fades out. The held revolver locks onto each target as it shoots it. A call to `HeldWeapon.lockAim` snaps the angle instead of easing toward the cursor. The same lock drives the hand offset. The gun therefore never points one way while reaching another.

The rounds home, and each belongs to its mark. Every round remembers its target in `Bullet.seek`. Every frame, `RevolverAttack.steer` re-aims that round, so a mark that walks away is still hit. The hit test asks only about that one enemy, so the round passes through anything in the way.

Without that, two marks in a line went wrong. The front one soaked both rounds, and nothing touched the one behind. Each mark already has a round of its own. A round spent on the wrong enemy is therefore a round lost. A wall still stops them, and a mark that dies before its round lands frees the shot for nothing.

Ordinary revolver fire does not change, and still stops at the first enemy it meets. Only a round with a mark behind it ignores bystanders.

The freeze is solo only. Online the flash, the sepia, the heartbeat, the marking and the volley all still happen. The clock is never touched and the player is never rooted. You paint targets while the fight carries on, and a three second timer releases the shots if you do not.

Freezing would not have worked in either direction. The host owns the enemies, so a host freezing its own world streams still positions. That stops the guest's game with no warning and no end.

A guest freezing its clock stops nothing at all. Enemies still move, because `PuppetMirror` lerps them toward streamed positions on raw elapsed. It never reads `WorldClock`. It would have rooted the guest in place while everything kept coming.

Activation decides `froze` once, and every restore path keys off it.

The freeze is not the super's to own. Every frame, `TimeStop` writes `WorldClock.scale` unconditionally. A second writer would therefore lose before the enemies ever read it. The clock now takes the two sources separately, inside `WorldClock`, and hands out whichever is slower.

A cancel can happen part way through a frame, so `update` re-reads the phase after the marking step and stops there if it went to zero. Without that check, `updateOverlay` ran on behalf of a super that had already ended, and painted the full sepia back over the screen. The next frame then returned at the top, because the phase was zero, and nothing ever cleared it. The wash stayed for the rest of the run. Firing with nothing marked was the way in.

The idle branch now also forces the overlay clear rather than only returning. A phase of zero means no wash, so any path that ends the super without tidying up heals itself on the next frame.

The fade outlives the super. Ending the shots and running the overlay down are separate steps. A call to `letGo` returns the world, the player and the aim. A fourth phase then runs the overlay down on its own. Folded together, the last frame re-applied a fade the state machine had already stopped updating. That pinned a permanent sepia tint over the game.

## SuperOrbit

The hammer super. Q with the hammer equipped and a full super meter drains the meter. It then wraps the player in a pseudo-3D cylinder of weapon copies. It is an elliptical carousel, where blades pass in front of and behind the player and scale with depth.

The player levitates for the duration. That is a visual offset only, and the hitbox and shadow stay grounded. The held weapon vanishes.

Left click launches the blade nearest the aim. Launched blades spin, pierce enemies and die on walls. Everything leaves ghost trails. The player settles back down after the last blade goes, and the held weapon returns to hand.

---

Back to the [documentation index](../DOCS.md).
