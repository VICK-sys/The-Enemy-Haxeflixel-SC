# Documentation

Code and data reference for THE ENEMY. Controls and build commands are in [README.md](README.md).

Split by concern - start with whichever part you are touching.

| Page | What is in it |
| --- | --- |
| [docs/states.md](docs/states.md) | the screens and how the game moves between them |
| [docs/editor.md](docs/editor.md) | the map editor: chrome, tools, art import, props, depth and cover |
| [docs/systems.md](docs/systems.md) | per-run systems, entities and utilities |
| [docs/weapons.md](docs/weapons.md) | the weapon systems |
| [docs/perspective.md](docs/perspective.md) | the totem and the top-down / side-view switch |
| [docs/multiplayer.md](docs/multiplayer.md) | online co-op: transport, sync, puppets |
| [docs/data-files.md](docs/data-files.md) | every JSON file in `assets/data/` and its fields |
| [docs/tuning.md](docs/tuning.md) | where the numbers live, per file |

## Project layout

```
assets/
  data/enemies/*.json    enemy definitions
  data/waves.json        wave table
  data/player.json       player stats
  data/arena.json        arena definition
  data/sideview.json     side-view physics, platform mapping, morph and meteor tuning
  default_auto.txt       arena collision map (CSV)
  auto_tiles.png         tileset for the collision map (not rendered)
  images/ music/ sounds/ art and audio
source/
  Main.hx                entry point
  net/                   online co-op: transport, sync, puppets
  states/                game states
  states/tutorial/       the tutorial's animated demo pages
  systems/               per-run systems owned by PlayState
  systems/enemy/         the director, its spawner, shots and boss death
  systems/world/         the arena, its props and how they collide
  systems/perspective/   the totem, its meteor arrival, and the view morph
  systems/weapons/       the weapon systems, coordinated by Weapons
  ui/                    the HUD and the menu list widget
  entities/              player and pickup sprites
  entities/enemy/        enemy class, navigation, attack styles, projectile
  entities/weapon/       weapon projectiles and visuals
  data/                  JSON typedefs and loaders (mirrors assets/data/)
  util/                  utilities
export/                  build output (not committed)
```

## Builds

Windows native and HTML5 share the same source and assets. Commands are in [README.md](README.md).
