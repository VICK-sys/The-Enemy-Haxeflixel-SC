# Tuning

Gameplay numbers live in the JSON files under `assets/data/` (see Data). The remaining code constants are `static inline var`s at the top of the file that owns them.

| File | Constants |
|---|---|
| `systems/weapons/HeldWeapon.hx` | swing time per attack, arc, scale pulse, aim smoothing, facing flip margin, bow hold distance, rain raise height, charge grow/draw-back/tint |
| `systems/weapons/SwingAttack.hx` | melee guard window (how long a swing keeps deflecting shots) |
| `systems/weapons/BowAttack.hx` | draw-loop pitch floor and rise |
| `systems/weapons/ThrowAttack.hx` | spawn distance, catch radius, wall probe, trail density and fade |
| `systems/weapons/HookAttack.hx` | spawn distance, wall probe, retract speed, catch radius, rope handle length |
| `systems/weapons/HookArms.hx` | rest pose geometry and tilt, rope curve fraction, eases, whip arc and radius, extend delay |
| `systems/weapons/ArrowRain.hx` | drop height, launch visual count and speed |
| `systems/weapons/Shockwave.hx` | ring texture base size, crack lifetime |
| `systems/weapons/DeadEye.hx` | X marker size, colour, thickness, scale and pulse. Sepia tone. Input arm delay |
| `systems/weapons/SuperOrbit.hx` | ring radii, carousel speed, depth scaling, hover and landing feel, deploy timings, trail settings |
| `systems/weapons/BounceStrike.hx` | hop apex, somersault spin, hand pivot |
| `systems/weapons/ArrowStorm.hx` | bow raise, launch arrow speed and scale, charge tint, trail settings |
| `entities/weapon/Orbiter.hx` | launch speed, range, spin, hit radius |
| `entities/weapon/ThrownWeapon.hx` | throw speed, spin rate, hit radius (the thrown hammer) |
| `entities/HealthPickup.hx` | heal amount, lifetime |
| `entities/weapon/SlashEffect.hx` | drift speed, effect lifetime |
| `entities/weapon/Arrow.hx` | arrow speed, range, hit radius |
| `entities/weapon/Bullet.hx` | bullet sprite scale and hitbox size |
| `systems/weapons/RevolverAttack.hx` | muzzle offset |
| `entities/enemy/EnemyShot.hx` | shot sprite scale and hitbox size, deflected shot speed boost |
| `states/PlayState.hx` | deflected shot hit radius, damage, knockback |
| `entities/weapon/HookShot.hx` | hook speed, hit radius |
| `entities/enemy/Enemies.hx` | wander and idle durations, hit flash time |
| `entities/enemy/RofelBoss.hx` | gun sprite scale, shot sound (the movement and gun stats live in `rofel.json`) |
| `entities/enemy/EnemyNav.hx` | waypoint radius, body radius default. The repath interval is in `tick()` |
| `systems/EnemyDirector.hx` | off-screen entry margin, boss intro delay, wave stall timeout |
| `systems/enemy/EnemySpawner.hx` | edge spawn margins and spread, stuck watchdog time and drive threshold, local unstick rings, rescue distances |
| `systems/EnemyShots.hx` | shot wall probe |
| `systems/BossDeath.hx` | boss death shake duration and amplitude |
| `systems/Fx.hx` | hitstop length, shake strengths, spark settings, dash line fade |
| `systems/TimeStop.hx` | trail tint, alpha, fade, cadence, and minimum speed. Overlay tint strength. Minimum music pitch |
| `systems/perspective/Totem.hx` | totem draw size, glow padding, hit flash time |
| `systems/perspective/MeteorArrival.hx` | ember cadence, arena edge padding for landing spots |
| `systems/perspective/PerspectiveShift.hx` | totem hit cooldown |
| `states/MainMenuState.hx` | splash text and its angle, throb depth and speed. Quit-collapse flatten, pinch and fade durations, and minimum window size |
| `util/IrisWipe.hx` | open and close durations, mask resolution, fully open scale |
| `util/MenuSlash.hx` | wind-up, cut and follow-through timings, shard linger, shard gravity |
| `util/JaggedBand.hx` | (all shape and speed values are constructor arguments, set in `MainMenuState.addBands`) |
| `util/SideView.hx` | shadow projection reach, shrink, and fade |

---

Back to the [documentation index](../DOCS.md).
