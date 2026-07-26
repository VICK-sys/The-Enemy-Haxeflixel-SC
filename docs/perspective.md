# The perspective shift

The totem that crashes into the arena, and the top-down / side-view switch it triggers. Timing and tuning come from [sideview.json](data-files.md).

## The three classes

`systems/perspective/` splits the feature three ways:

- `Totem` - the sprite, glow, shadow, faces, hit flash, and hit test.
- `MeteorArrival` - the crash sequence and its particles.
- `PerspectiveShift` - the morph phase machine, entity movers, probe gating, and boss lock.

## The arrival

The totem is not in the arena at the start of a run. It crashes down like a meteor on a randomly rolled wave (`totemWaveMin` / `totemWaveRange`).

The arrival picks a clear spot 300-430 px from the player so the crash happens on screen, pulses a red warning decal on the ground for about a second, drops the totem from far above trailing embers, and lands with a boom, camera shake, a dust ring, and a shockwave that damages nearby enemies. Gameplay continues throughout - it is an event, not a cutscene.

If the roll lands on a locked wave (a boss fight) the arrival waits for the next wave.

Custom maps never get one. A map drawn in the editor has no side-view landscape mapping behind it, so the totem is switched off outright for any run started from a slot - the arrival never rolls and the totem cannot be struck. That is a separate flag from the boss lock, which is cleared once the arena returns to normal.

## Triggering the switch

Until it lands the totem is invisible and inert. Afterwards it listens to every attack hit-test through the director's `onProbe` hook, so any weapon that touches it triggers the switch.

The impact shockwave runs through that same hit query, so the landing starts the totem's hit cooldown before firing the blast - otherwise the meteor would trigger itself and flip the world the instant it touched down.

Totem hits are ignored while a super is running or scythe blades still orbit, since those systems drive the player and their own sprites.

The totem wears one of two faces, `stage/totem_top` in top-down and `stage/totem_side` in side view, swapped as each morph begins so it shows the mode it is taking you to; the glow is the same art blended additively behind it. Its crash site becomes the position it returns to when reverting from side view.

## The morph

The morph freezes combat - enemy updates pause, shots clear, contact damage off, inputs held - plays its direction's swap sound (`platswap_side` going to 2D, `platswap_top` coming back), drives the landscape through `applySideMorph`, and glides the player, enemies, and totem to their remapped positions over about a second and a half. Entities farther north end up higher, then fall.

Because combat is frozen mid-morph, the shift keeps the held weapon anchored to the player itself (`Weapons.anchorHeld()`, position only) so it travels with them, and retracts a deployed hook before the move so no rope is left stretched across the arena. Retracting first also clears the grapple's movement block, which would otherwise be restored when the morph ends.

## Side view

When the morph completes `SideView.active` turns on and the game plays as a platformer:

- A/D run, W jumps (one air jump), dash stays horizontal.
- All mouse-aimed weapons work unchanged.
- Waves walk in on foot from the left and right edges at ground level rather than dropping from above. In top-down they still arrive from all four edges.
- Enemies chase along the ground and hop after a raised player.
- Shooters keep shooting. The attack behaviors are written for the top-down plane and set a full 2D velocity, so side view preserves the enemy's vertical velocity across the behavior call - gravity stays with the world, horizontal movement stays with the behavior.
- Hearts fall, and time stop freezes everything mid-air.

## Reverting, and the boss

Hitting the totem again morphs back with the inverse mapping.

A boss wave force-reverts at double speed and locks the totem until the arena is normal again. The totem also vanishes for the fight exactly as the pillars do - `clearTotem()` on the whiteout that strips them, `restoreTotem()` on the reverse flash that rebuilds them.

Since the director fires the wave callback before the boss callback, an arrival rolled onto the boss wave would start and only then be locked, so the boss also cancels an in-flight arrival; the meteor simply crashes down on a later wave instead.

---

Back to the [documentation index](../DOCS.md).
