# The map editor

Opened with F7 from the main menu. Draws collision, paints a floor, places props, and hands the result to a playtest.

- [Layout and chrome](#layout-and-chrome)
- [The parts](#the-parts)
- [Walls](#walls)
- [Tiles](#tiles)
- [Props](#props)
- [Undo and the clipboard](#undo-and-the-clipboard)
- [Importing art](#importing-art)
- [Prop hitboxes](#prop-hitboxes)
- [Depth and layering](#depth-and-layering)
- [Occluding weapon effects](#occluding-weapon-effects)
- [Collision and cover](#collision-and-cover)

## Layout and chrome

Laid out like a desktop tile editor. A dark sidebar on the left holds the palette at the top, a sheet button under it, the three modes as clickable rows - each with an eye toggle that hides that layer in the editor view - and undo/clear at the bottom. A top bar carries the slot and a mode-sensitive chip on the left - brush size in walls, solid in tiles, the prop in hand in props - and controls/save/play on the right.

Everything the chrome does remains a keyboard shortcut too; the chips and rows call the same functions the keys do. The bottom strip shows only the hints for the current mode; the full key list lives behind the Controls button, which opens a panel that swallows input until it is closed.

The map opens fitted to the space beside the sidebar. The wheel zooms about the cursor - the tile under the pointer stays under it - holding space and dragging grabs the view, which is the usual gesture and leaves the left button free to paint, with a middle-drag or the arrows doing the same, and 0 returns to the opening view. Painting is suppressed while space is held, so grabbing the view never leaves a stray tile behind.

The HUD sits on its own camera so it does not shrink with the world. Mouse position is read fresh from the camera rather than through the per-frame cached value, which would otherwise lag a frame behind every zoom and put paint in the wrong cell.

P cycles the three modes. Five slots on the number keys; switching autosaves. ENTER saves and plays the map; ESC saves and returns to the menu.

## The parts

Each subsystem owns its own sprites while the state owns the display order.

- `EditorState` - the coordinator. It constructs the parts (document and cameras first, panels, then tools - the palettes must exist before anything can reference them), adds their sprites in draw order, dispatches update to the active mode, and maps the keys onto their operations. It holds no editing logic of its own.
- `EditorMap` - the map being edited: collision, painted floor, props, spawn and tileset, its CSV serialisation and slot load/save, plus the rules that go with that data - the outer ring staying solid, undo history, clearing the floor when the tileset's cell size changes, and `setWall` reporting whether a cell actually changed so strokes skip redundant redraws.
- `EditorView` - the world camera: cursor-anchored zoom, panning, and the fresh mouse-to-world read.
- `WallTool`, `TileTool`, `PropTool` - the three modes. Each holds its layer, its cursor ghost, and its input handling. `TileTool` reaches walls only through `WallTool.setCell`, which keeps the V-solid feature on a single write path.
- `TilePalette`, `PropPalette` - both on a shared `PalettePanel` base owning the panel sprites and hit-testing.
- `EditorChrome` - the clickable frame: sidebar, top bar, chips, mode rows and eye toggles. It exposes one callback per control so the state wires them straight onto the same functions the keys call. A click landing on any chrome region is also what blocks the tools from painting under it.
- `EditorHud` - the one-line hint strip, the controls panel and the flash message.
- `LibraryPanel`, `PreviewPane` - art import and hitbox editing. See [Importing art](#importing-art).

## Walls

Left button paints, right erases, holding SHIFT drags a filled box. B cycles the brush through 1x1/2x2/3x3, X drops the player spawn at the cursor, Z undoes, C clears the interior, L copies the stock stage in as a starting point.

The painted grid is the source of truth - the tilemap is only its picture, patched per cell while a stroke is live and rebuilt cleanly when it ends so the autotile edges stay exact. Fast drags are line-walked so strokes have no gaps, and the outer ring is locked solid so the arena is always closed.

## Tiles

A palette sits in the sidebar, framed on the sheet's used area with grid lines drawn over it. Drag across it to pick a rectangular patch - a plain click is just a 1x1 patch - `[` `]` step one cell at a time, the wheel zooms the panel, and a right- or middle-drag inside it slides the sheet around.

Painting stamps the whole patch with its top-left on the cursor, keeping the cells in the arrangement they had on the sheet, so a floor pattern several tiles across goes down in one stroke instead of one cell at a time. Erasing clears the same footprint, and the cursor ghost is the patch itself, cut out of the sheet. F switches sheets. `V` toggles whether laying tiles also makes the ground under them solid, which is how wall tiles are drawn and made collidable in one pass.

The panel shows a window cut out of the sheet at the current zoom and pan rather than a scaled copy of the whole thing, which keeps what is drawn exactly the panel's size and the click maths a plain division.

## Props

Props come from different sheets at different sizes, so the panel is composed differently from the tile one: rather than a window into a single image it is a contact sheet - every prop scaled to fit one cell of a grid, built once and then scrolled with the wheel. Click a thumbnail to select, or step with `[` `]`, which scrolls the highlight back into view when it leaves the panel.

Prop mode has two states rather than one. With a prop in hand the cursor carries a ghost, left click stamps copies with its feet on the cursor, F flips it and right click deletes the topmost prop under the cursor. Putting it down - Q, the top bar chip, or clicking the palette entry that is already selected - empties the hands, and then left click picks whichever placed prop is under the cursor, dragging moves it, F flips just that one and Delete removes it.

Dropping a prop is the only way to reach something already on the map, so the hint strip and the chip both change wording with the state. The palette's selection highlight tracks the hand rather than the last click - with nothing held there is no selected prop to show, so the highlight goes out and the panel stops claiming a choice that is not in effect.

A drag pushes an undo snapshot the first time it actually moves something, not when it is merely clicked, so selecting props to look at them does not bury the undo history.

## Undo and the clipboard

Undo is one stack of whole-document snapshots - walls, tiles and props together - pushed once per stroke rather than per cell, so Ctrl+Z steps back through every kind of edit in the order it was made.

In tile mode Ctrl-drag marks a rectangle on the map, Ctrl+C lifts those tiles into a clipboard that becomes the brush, and Ctrl+V stamps it at the cursor. The copied block is pasted exactly, blank cells included, so it overwrites rather than blends.

## Importing art

`util.Library` is the import path for art that was never part of the build. It scans `library/tilesets`, `library/props` and `library/walls` next to the executable, loads each PNG off disk and registers it in the bitmap cache under the key `Paths.image` would have produced, so the rest of the game reaches a dropped-in file exactly as it reaches a baked one.

What has been turned into a tileset or prop is recorded in `library/library.json`, and those registries append their entries to the ones parsed from `assets/data`; a version counter tells them when to rebuild the merged list. Entries whose image has since been deleted are dropped on load rather than left to fail later. Importing needs a filesystem, so on HTML5 the panel says so and lists nothing.

`LibraryPanel` is the front end and `PreviewPane` is its right-hand surface, split out because a drag state machine and tab bookkeeping sharing one class made both harder to follow: the pane owns the scaled preview, the grid overlay, the hitbox rectangle with its handles and the whole draw/move/resize gesture, reporting a finished box through one callback, while the panel keeps the tabs, the file list and the buttons and decides what the pane shows.

A tab per kind, the discovered files on the left, a preview on the right, and the one thing that cannot be guessed from an image asked for directly: tile size, chosen against a grid drawn over the preview.

A wall is not appended as a new look to choose between - with no theme switcher there would be nothing to choose it with - so importing one overrides the wall on the theme every map wears, and the stock wall is kept aside so the button beside it can put things back.

## Prop hitboxes

The library's fourth tab edits prop hitboxes on the same preview. The first drag draws a box, and after that the box is a thing you adjust rather than redraw: dragging inside it moves it, the eight white handles resize from that edge or corner, and only a drag starting outside it begins a new one. Every drag is clamped to the image, so a box cannot describe collision that is not on the sprite.

Boxes are stored per prop name, which is what lets a hitbox be set on a built-in prop without writing to a baked asset. In prop mode H opens that tab directly on whichever prop is in hand or selected on the map, since a hitbox editor reached only through a menu named after importing is a hitbox editor nobody finds.

A building wants a shallow band across its base rather than a box over its whole picture: block only the ground it stands on and a player can walk up to the front, round the side, and be covered by it from behind, whereas a full-sprite box walls off the art and leaves nowhere to pass. BASE BAND sets that shape in one click, measured against the opaque pixels rather than the canvas - a sprite exported with transparent margin would otherwise be stopped short of its own front wall and flip depth below the ground it stands on.

## Depth and layering

The bottom of a prop's hitbox is also the line it sorts on, which is what stops a building from being solid in one place and drawn as though it stood somewhere else. Without a hitbox a prop still sorts by the bottom of its image, so nothing that already existed moved. Prop mode draws each prop's sort line, so the exact point where the player starts passing in front is visible while arranging rather than only discoverable by playing.

Props that should ignore depth entirely have a layer setting alongside the box: ground, which always draws under everything, and overhead, which always draws over it.

The editor sorts its own prop group by the same rule - re-sorting live while a prop is dragged, not just on release - so what is arranged there is what is played. In play the comparison happens every frame against the player's feet, and it is stateless: nothing is toggled when the player crosses the line, so approaching without ever going behind never leaves a prop stuck drawn on the wrong side.

## Occluding weapon effects

Weapon effects are added above the entity layer so they read clearly over characters, which would otherwise let a slash or an arrow paint straight over a building the player is standing behind. Rather than break every effect group into the sorted layer, the part of the sorted layer that sits in front of whatever is hiding the player gets drawn a second time above the effects: the same sprites, no extra art, repopulated each frame.

It has to be that whole tail rather than only the props, because an enemy standing in front of a building belongs above it in both passes - redrawing the building alone would bury a creature that is plainly nearer the camera than the wall it is standing by. Taking the tail of an already-sorted list preserves the order for free. The overlay group is inactive so nothing is updated twice, and it is emptied and refilled rather than remembering anything, so it cannot fall out of step.

Drawing a prop over an effect only helps where the prop's picture actually is, and a weapon swung downward reaches past its bottom edge into open ground - which the projection reads as being in front of the building the player is standing behind. So while the player is buried - behind a prop, horizontally within it, and not above its roof - the held weapon and its melee effects are hidden outright rather than allowed to poke out underneath. The weapon is dimmed through alpha rather than visibility, because visibility is owned by the throw and super systems and is what multiplayer puts on the wire.

All of this - the solid bodies, the second-draw overlay, the buried flag and the player's foot collision - lives in `PropWorld`. PlayState constructs it, adds its two groups in draw order, and applies the buried flag to the held weapon, which stays outside because the weapon belongs to combat, not to props.

## Collision and cover

A prop with a hitbox contributes an invisible immovable body that the player and the enemies collide against; the editor draws those bodies in prop mode so their footprint is visible while placing.

Props are collided against a shallow box at the walker's feet rather than their whole sprite, because the box describes ground a building stands on and the player is ninety pixels taller than the ground they occupy - colliding the full body would stop them a body-height short of a wall they are supposed to be able to reach. Walls keep the whole-body test, since a wall is tall and stopping the sprite against it is what looks right.

`PropBlock` is the same boxes read as cover rather than as obstacles. Every projectile in the game - arrows, slices, the thrown scythe, the hook, super blades, enemy shots - already probed a point ahead of itself against the wall grid to decide when to die, so each of those probes now asks the props the same question and a shot is stopped by a building exactly where it would be stopped by a wall.

Damage is gated by the segment between attacker and target: if a prop sits across that line the hit does not land, which keeps a melee swing from reaching through a storefront and keeps anything on the far side from reaching back. Both directions run through a single funnel - one for what the player deals, one for what the player takes - so contact damage, shots and every weapon inherit the rule without each knowing about it. Enemies also refuse to spawn on a prop's footprint, since arriving inside a building was the one way to end up on the wrong side of it with no way out.

Cover is measured between the two ground points - each fighter's own feet line, the same one their collision and their depth use, rather than the bottom of their sprite or their body centre. A centre sits high enough on a tall sprite to be level with a base band while the feet are plainly in front of it, and the sprite bottom differs from the feet line by a few pixels; since collision parks a fighter exactly against a band's edge, either was enough to put the cover point inside the band and leave two fighters standing together outside a shop unable to touch each other. The boxes are also inset slightly for this test, so standing flush against one is never mistaken for standing in it.

The line itself is named once - `feetY` on the player and on enemies - and collision, depth sorting, cover and shadows all read that property rather than repeating the offset.

---

Back to the [documentation index](../DOCS.md).
