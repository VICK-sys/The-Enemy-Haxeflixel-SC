# THE ENEMY

Top-down action game built with HaxeFlixel. Fight waves of enemies with a mouse-aimed arsenal, in waves that keep getting bigger and harder for as long as you last, with a boss returning every few waves.

The main menu has PLAY, OPTIONS (master volume, fullscreen, FPS counter, reset best wave), and QUIT, navigated with W/S and ENTER or the mouse. A controls popup with animated demos appears the first time you play; flip pages with A/D and press ENTER to start.

## Online co-op (desktop)

Two players. From the main menu choose ONLINE. One player picks HOST GAME (this listens on TCP port 7777 - forward that port on your router and share your public IP), the other picks JOIN GAME and types the host's IP. If port 7777 is busy the host falls back to the next free port and shows it; in that case the friend joins with `IP:port`. The host presses ENTER once the friend is connected. Time stop is disabled online, and death respawns you after a few seconds instead of ending the run.

## Controls

- WASD - move
- Mouse - aim, left click for the primary attack, right click for the secondary
- Hammer - swing / throw. Revolver - shoot / fan the hammer, which rips through every remaining round in one continuous burst. Eight rounds, fired as fast as you can click; running dry reloads on its own, or press R to top up early. Crossbow - charged shot (hold to charge, release to fire; a full charge pierces) / arrow rain when its meter is full. Hook - quick jab / grab
- Melee attacks (the hammer swing and the hook jab) deflect enemy bullets back at whoever fired them
- Q - super (needs a full AP meter): the hammer orbits blades you launch with left click; the crossbow does Arrow Storm (an arena-wide downpour); the hook extends two auto-grabbing arms that snatch and hurl enemies. The revolver has none yet
- SPACE - dash (2 second cooldown)
- W - jump in side view (press again in the air for a double jump)
- E - time stop (30 second cooldown): the world winds down to a complete stop for 10 seconds while you keep moving and attacking at full speed
- ESC - pause
- ENTER - skip the intro
- R - reload the revolver early; restart after death

## Debug keys

- minus / plus - volume down / up
- 9 / 7 / 8 - spawn Enemy / Woodster / LikWid
- F4 - revive, 5 - die
- 6 - collision debug overlay

## Building

Requires [Haxe](https://haxe.org) with the `flixel` haxelib installed. The Windows target also uses `hxdiscord_rpc` for Discord Rich Presence.

```
haxelib run lime build windows
haxelib run lime build html5
```

## Discord Rich Presence

Each player chooses their own weapon from the online menu before the run begins, or with TAB once hosting or connected.

The Windows build can show your current wave, boss fight, equipped weapon, kill count, and run time on Discord. To enable it, create an application at [discord.com/developers/applications](https://discord.com/developers/applications), copy its Application ID into `assets/data/discord.json`, and optionally upload Rich Presence art assets named `icon`, `hammer`, `revolver`, `crossbow`, and `hook`. Leaving the ID empty keeps presence off.

Code and data reference: [DOCS.md](DOCS.md)
