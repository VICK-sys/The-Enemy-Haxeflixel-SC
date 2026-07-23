# THE ENEMY

Top-down action game built with HaxeFlixel. Fight waves of enemies with a mouse-aimed arsenal; a boss appears after wave 3.

A controls popup with animated demos appears the first time you play; flip pages with A/D and press ENTER to start.

## Controls

- WASD — move
- Mouse — aim, left click to attack
- 1-4 or scroll wheel — switch weapon (scythe / hammer / bow / hook)
- Right click — switch the equipped weapon's mode (scythe: swing / air slice / throw; hammer: slam / shockwave; bow: shot / arrow rain; hook: grab / spin / grapple / arms)
- Q — super (needs a full AP meter, one per weapon): scythe orbits blades you launch with left click; hammer does Bounce Strike (somersaulting AoE slams); bow does Arrow Storm (an arena-wide downpour); hook extends two auto-grabbing arms that snatch and hurl enemies
- SPACE — dash (2 second cooldown)
- ESC — pause
- ENTER — skip the intro
- R — restart after death

## Debug keys

- minus / plus — volume down / up
- 9 / 7 / 8 — spawn Enemy / Woodster / LikWid
- F4 — revive, 5 — die
- 6 — collision debug overlay

## Building

Requires [Haxe](https://haxe.org) with the `flixel` haxelib installed.

```
haxelib run lime build windows
haxelib run lime build html5
```

Code and data reference: [DOCS.md](DOCS.md)
