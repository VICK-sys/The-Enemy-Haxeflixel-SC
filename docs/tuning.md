# Tuning

Gameplay numbers live in the JSON files under `assets/data/` (see Data). The remaining code constants are `static inline var`s at the top of the file that owns them.

| File | Constants |
|---|---|
| `systems/weapons/HeldWeapon.hx` | swing time per attack, arc, scale pulse, aim smoothing, facing flip margin, bow hold distance, rain raise height, charge grow/draw-back/tint, reload frame count |
| `systems/weapons/SwingAttack.hx` | melee guard window (how long a swing keeps deflecting shots) |
| `systems/weapons/GigaCharge.hx` | charge and ready volumes, glow ramp/base/wave, shine pulse speed, sparkle beat and timing window, sparkle reach along the hammer |
| `systems/weapons/BowAttack.hx` | draw-loop pitch floor and rise |
| `systems/weapons/ThrowAttack.hx` | spawn distance, catch radius, wall probe, trail density and fade |
| `systems/weapons/HookAttack.hx` | spawn distance, wall probe, retract speed, catch radius, rope handle length |
| `systems/weapons/YoyoSpin.hx` | inner dead band, tip band width, visual spin rate, string shrink fraction |
| `systems/weapons/ArrowRain.hx` | drop height, launch visual count and speed |
| `systems/weapons/HammerBounce.hx` | hop apex, spin, hammer pivot geometry |
| `systems/weapons/ArrowStorm.hx` | bow raise, launch arrow speed and scale, charge tint, trail settings |
| `entities/weapon/ThrownWeapon.hx` | throw speed, spin rate, hit radius (the thrown hammer) |
| `entities/HealthPickup.hx` | heal amount, lifetime |
| `entities/weapon/SlashEffect.hx` | drift speed, effect lifetime |
| `entities/weapon/Arrow.hx` | arrow speed, range, hit radius |
| `entities/weapon/Bullet.hx` | bullet sprite scale and hitbox size |
| `systems/weapons/RevolverAttack.hx` | muzzle offset, twin gun offsets, shade, fire stagger, kick, twin reload scale, reload spin cue points and volumes |
| `entities/enemy/EnemyShot.hx` | shot sprite scale and hitbox size, deflected shot speed boost and trajectory carry |
| `states/PlayState.hx` | deflected shot hit radius, damage, knockback |
| `entities/weapon/HookShot.hx` | hook speed, hit radius |
| `entities/enemy/Enemies.hx` | wander and idle durations, hit flash time |
| `entities/enemy/RofelBoss.hx` | gun sprite scale, shot sound (the movement and gun stats live in `rofel.json`) |
| `entities/enemy/EnemyNav.hx` | waypoint radius, body radius default. The repath interval is in `tick()` |
| `systems/EnemyDirector.hx` | off-screen entry margin, boss intro delay, wave stall timeout |
| `systems/enemy/EnemySpawner.hx` | edge spawn margins and spread, watchdog times, drive and progress thresholds, progress sample interval, local unstick rings, rescue distances |
| `entities/enemy/EnemyBrain.hx` | wander and idle durations, walk-in lean and its slack |
| `systems/EnemyShots.hx` | shot wall probe |
| `systems/BossDeath.hx` | boss death shake duration and amplitude |
| `systems/Fx.hx` | hitstop length, shake strengths, spark settings, dash line fade, dash steam frame rate and scale |
| `systems/PlayerCombat.hx` | voice volume, death throes length and shake, hurt and death line counts, dash and dash-ready volumes, dash steam offset from the back |
| `systems/TimeStop.hx` | trail tint, alpha, fade, cadence, and minimum speed. Overlay tint strength. Minimum music pitch |
| `states/MainMenuState.hx` | splash text and its angle, throb depth and speed. Quit-collapse flatten, pinch and fade durations, and minimum window size |
| `util/IrisWipe.hx` | open and close durations, mask resolution, fully open scale |
| `util/MenuSlash.hx` | wind-up, cut and follow-through timings, shard linger, shard gravity |
| `util/JaggedBand.hx` | (all shape and speed values are constructor arguments, set in `MainMenuState.addBands`) |

---

Back to the [documentation index](../DOCS.md).
