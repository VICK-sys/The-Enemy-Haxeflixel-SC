# The perspective shift

The totem that crashes into the arena, and the top-down / side-view switch it triggers. Timing and tuning come from [sideview.json](data-files.md).

The totem is off everywhere at the moment. `PlayState` sets `shift.disabled = true`, which stops `MeteorArrival.tryBegin` before it picks a landing spot. Nothing falls, and nothing can be hit. The rest of this page still describes what the system does. Clearing that one flag brings all of it back.

## The three classes

`systems/perspective/` splits the feature three ways:

- `Totem` - the sprite, glow, shadow, faces, hit flash and hit test.
- `MeteorArrival` - the crash sequence and its particles.
- `PerspectiveShift` - the morph phase machine, entity movers, probe gating and boss lock.

## The arrival

The totem is not in the arena at the start of a run. It crashes down like a meteor on a randomly rolled wave, from `totemWaveMin` and `totemWaveRange`.

The arrival picks a clear spot 300 to 430 px from the player, so the crash happens on screen. It pulses a red warning decal on the ground for about a second. The totem then drops from far above, trailing embers. It lands with a boom, camera shake, a dust ring, and a shockwave that damages nearby enemies. Gameplay carries on throughout. The arrival is an event, not a cutscene.

If the roll lands on a locked wave, meaning a boss fight, the arrival waits for the next wave.

Custom maps never get one. A map drawn in the editor has no side-view landscape mapping behind it. The totem is therefore off outright for any run started from a slot. The arrival never rolls, and nothing can strike the totem. That flag is separate from the boss lock, which clears once the arena returns to normal.

## Triggering the switch

The totem stays invisible and inert until it lands. Afterwards it listens to every attack hit-test through the director's `onProbe` hook. Any weapon that touches it triggers the switch.

The impact shockwave runs through that same hit query. The landing therefore starts the totem's hit cooldown before it fires the blast. Otherwise the meteor would trigger itself and flip the world the instant it touched down.

The totem ignores hits while a super runs or orbiters still circle. Those systems drive the player and their own sprites.

The totem wears one of two faces: `stage/totem_top` in top-down, and `stage/totem_side` in side view. Each morph swaps the face at its start, so the totem shows the mode it will take you to. The glow is the same art, blended additively behind it. Its crash site becomes the position it returns to when reverting from side view.

## The morph

The morph freezes combat. Enemy updates pause, shots clear, contact damage goes off, and inputs hold. It plays its direction's swap sound, `platswap_side` going to 2D and `platswap_top` coming back. It drives the landscape through `applySideMorph`. It then glides the player, enemies and totem to their remapped positions over about a second and a half. Entities farther north end up higher, then fall.

Combat is frozen mid-morph, so the shift anchors the held weapon to the player itself and it travels with them. That is `Weapons.anchorHeld()`, position only. The shift also retracts a deployed hook before the move, so no rope is left stretched across the arena.

## Side view

`SideView.active` turns on when the morph completes, and the game plays as a platformer:

- A/D run, W jumps with one air jump, and the dash stays horizontal.
- All mouse-aimed weapons work unchanged.
- Waves walk in on foot from the left and right edges at ground level, rather than dropping from above. In top-down they still arrive from all four edges.
- Enemies chase along the ground and hop after a raised player.
- Shooters keep shooting.
- Hearts fall, and time stop freezes everything mid-air.

The attack behaviors target the top-down plane and set a full 2D velocity. Side view therefore preserves the enemy's vertical velocity across the behavior call. Gravity stays with the world, and horizontal movement stays with the behavior.

## Reverting, and the boss

Hitting the totem again morphs back with the inverse mapping.

A boss wave force-reverts at double speed and locks the totem until the arena is normal again. The totem also vanishes for the fight exactly as the pillars do. The whiteout that strips them runs `clearTotem()`. The reverse flash that rebuilds them runs `restoreTotem()`.

The director fires the wave callback before the boss callback. An arrival rolled onto the boss wave would therefore start, and the lock would land only afterwards. So the boss also cancels an in-flight arrival, and the meteor crashes down on a later wave instead.

---

Back to the [documentation index](../DOCS.md).
