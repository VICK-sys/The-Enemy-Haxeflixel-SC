# THE ENEMY

Top-down action game built with HaxeFlixel. Fight enemies with a mouse-aimed scythe that fires piercing slash waves.

## Controls

- WASD — move
- Mouse — aim, left click to attack
- 1-4 or scroll wheel — switch weapon (scythe / hammer / bow / hook)
- Q — switch the equipped weapon's mode (scythe: swing / air slice / throw; hammer: slam / shockwave; bow: shot / arrow rain)
- Right click — super (scythe only, needs a full AP meter): scythes orbit you, left click launches them
- SPACE — dash (costs 1 AP; kills refill the meter)
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
