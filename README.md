# THE ENEMY

Top-down action game built with HaxeFlixel. Fight waves of enemies with a mouse-aimed arsenal. The waves keep getting bigger and harder for as long as you last, and a boss returns every few waves.

The main menu holds PLAY, OPTIONS and QUIT. Navigate it with W/S and ENTER, or with the mouse. Options covers master volume, fullscreen, the FPS counter and reset best wave. A controls popup with animated demos appears the first time you play. Flip its pages with A/D, then press ENTER to start.

## Online co-op (desktop)

Choose ONLINE on the main menu. One player picks HOST GAME, which listens on TCP port 7777. Forward that port on your router and share your public IP. The other player picks JOIN GAME and types the host's IP.

If port 7777 is busy, the host falls back to the next free port and shows it. The friend then joins with `IP:port`. The host presses ENTER once the friend has joined.

Each player chooses a weapon in the online menu before the run starts. TAB opens that choice again once you host or join.

Time stop is off online. Dead Eye marks without stopping the world. Death respawns you after a few seconds instead of ending the run.

## Controls

Keyboard and mouse, or a controller. The game follows whichever you touched last, and every bind below can be changed from OPTIONS, CONTROLS.

- WASD or the left stick - move
- Mouse or the right stick - aim. Left click or the right trigger is the primary attack, right click or the left trigger the secondary.
- SPACE or A - dash, with a 2 second cooldown
- Q or Y - super, once the meter is full
- R or X - reload the revolver early. It also restarts the run after death.
- ENTER or A - interact and ready up
- ESC or START - pause

## Weapons

You pick one weapon at the start and keep it for the whole run.

- Hammer - swing, or throw.
- Revolver - shoot, or fan the hammer. Fanning rips through every remaining round in one burst. Six rounds, fired as fast as you can click. Running dry reloads on its own, or press R to top up early.
- Crossbow - a charged shot. Hold to charge, release to fire. A full charge pierces and can fire back to back, a tap cannot. Arrow rain is the secondary, once its meter fills.
- Yoyo - hold to keep it out and steer it, or a grab.

Melee attacks deflect enemy bullets back at whoever fired them. That covers the hammer swing.

## Supers

Q fires the super once the meter is full. Each weapon has its own.

- Hammer - orbits blades around you. Left click launches them.
- Revolver - Dead Eye. The world stops while you paint a target for every round left in the cylinder. The fire button then empties the cylinder into them.
- Crossbow - Arrow Storm, an arena-wide downpour.
- Yoyo - two auto-grabbing arms that snatch and hurl enemies.

## Debug keys

- minus / plus - volume down / up
- 9 / 7 / 8 - spawn Enemy / Woodster / LikWid
- F4 - revive, 5 - die
- 6 - collision debug overlay

## Building

Requires [Haxe](https://haxe.org) 4.3 or newer. The library versions are pinned in `Project.xml`: flixel 6.2.0, openfl 9.5.2, lime 8.3.2. Install each with `haxelib install <name> <version>`. The Windows target also uses `hxdiscord_rpc` for Discord Rich Presence.

```
haxelib run lime build windows
haxelib run lime build html5
```

A running copy of the game keeps a lock on `lime.ndll`, and the Windows link
step then fails while copying its output. The error names the file rather than
the cause. Close the game, or end the process, and build again:

```
taskkill /F /IM Enemy.exe
```

"The process Enemy.exe not found" means no stale copy was running. That is the
normal case and it is not an error.

`tools/verify.ps1` builds both targets and runs this step for you:

```
powershell -ExecutionPolicy Bypass -File tools/verify.ps1
```

## Discord Rich Presence

The Windows build can show your wave, boss fight, equipped weapon, kill count and run time on Discord. To switch it on, create an application at [discord.com/developers/applications](https://discord.com/developers/applications). Copy its Application ID into `assets/data/discord.json`. You can also upload Rich Presence art named `icon`, `hammer`, `revolver`, `crossbow` and `hook`. An empty ID keeps presence off.

Code and data reference: [DOCS.md](DOCS.md)
