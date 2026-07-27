# The map editor

F7 opens it from the main menu. It draws collision, paints a floor, places props, and hands the result to a playtest.

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

The layout follows a desktop tile editor. A dark sidebar on the left holds the palette at the top, and a sheet button under it. Below that sit the three modes as clickable rows. Each row carries an eye toggle, which hides that layer in the editor view. Undo and clear sit at the bottom.

A top bar carries the slot and a mode-sensitive chip on the left. The chip shows brush size in walls, solid in tiles, and the prop in hand in props. Controls, save and play sit on the right.

Every chrome action is a keyboard shortcut too. The chips and rows call the same functions the keys call.

The bottom strip shows only the hints for the current mode. The full key list sits behind the Controls button. That button opens a panel, which swallows input until you close it.

The map opens fitted to the space beside the sidebar. The wheel zooms about the cursor, so the tile under the pointer stays under it. Hold space and drag to grab the view. That is the usual gesture, and it leaves the left button free to paint. A middle-drag or the arrow keys do the same, and 0 returns to the opening view.

The editor stops painting while you hold space. Grabbing the view therefore never leaves a stray tile behind.

The HUD sits on its own camera, so it does not shrink with the world. The editor reads the mouse position fresh from the camera. It does not use the per-frame cached value. That value lags one frame behind every zoom, and puts paint in the wrong cell.

P cycles the three modes. The number keys hold five slots, and a switch autosaves. ENTER saves and plays the map. ESC saves and returns to the menu.

## The parts

Each subsystem owns its own sprites, while the state owns the display order.

- `EditorState` - the coordinator. It builds the parts in order: document and cameras first, then panels, then tools. The palettes must exist before anything can reference them. It adds their sprites in draw order, dispatches update to the active mode, and maps the keys onto their operations. It holds no editing logic of its own.
- `EditorMap` - the map you edit. It holds collision, painted floor, props, spawn and tileset, plus the CSV serialisation and the slot load and save. It also holds the rules that go with that data. The outer ring stays solid, the undo history lives here, and the floor clears when the tileset's cell size changes. Its `setWall` reports whether a cell actually changed, so strokes skip redundant redraws.
- `EditorView` - the world camera: cursor-anchored zoom, panning, and the fresh mouse-to-world read.
- `WallTool`, `TileTool`, `PropTool` - the three modes. Each holds its layer, its cursor ghost, and its input handling. Only `TileTool` reaches walls, and only through `WallTool.setCell`. That keeps the V-solid feature on a single write path.
- `TilePalette`, `PropPalette` - both sit on a shared `PalettePanel` base. That base owns the panel sprites and the hit-testing.
- `EditorChrome` - the clickable frame: sidebar, top bar, chips, mode rows and eye toggles. It exposes one callback per control, so the state wires them straight onto the same functions the keys call. A click on any chrome region also blocks the tools from painting under it.
- `EditorHud` - the one-line hint strip, the controls panel and the flash message.
- `LibraryPanel`, `PreviewPane` - art import and hitbox editing. See [Importing art](#importing-art).

## Walls

The left button paints, and the right button erases. Hold SHIFT and drag for a filled box. B cycles the brush through 1x1, 2x2 and 3x3. X drops the player spawn at the cursor. Z undoes, and C clears the interior. L copies the stock stage in as a starting point.

The painted grid is the source of truth. The tilemap is only its picture. The editor patches it per cell while a stroke is live, then rebuilds it cleanly when the stroke ends. The autotile edges therefore stay exact.

The editor line-walks fast drags, so strokes have no gaps. The outer ring stays locked solid, so the arena is always closed.

## Tiles

A palette sits in the sidebar. It frames the sheet's used area, with grid lines drawn over it. Drag across it to pick a rectangular patch. A plain click gives a 1x1 patch. The `[` and `]` keys step one cell at a time. The wheel zooms the panel, and a right-drag or middle-drag inside it slides the sheet around.

Painting stamps the whole patch, with its top-left on the cursor. The cells keep the arrangement they had on the sheet. A floor pattern several tiles across therefore goes down in one stroke.

Erasing clears the same footprint. The cursor ghost is the patch itself, cut out of the sheet. F switches sheets. `V` toggles whether tiles also make the ground under them solid. That is how you draw wall tiles and make them collidable in one pass.

The panel shows a window cut out of the sheet at the current zoom and pan. It does not show a scaled copy of the whole sheet. What it draws is therefore exactly the panel's size, and the click maths is a plain division.

## Props

Props come from different sheets at different sizes. The panel is therefore not a window into a single image. It is a contact sheet, with every prop scaled to fit one cell of a grid. The editor builds it once, and the wheel scrolls it.

Click a thumbnail to select a prop. The `[` and `]` keys step instead, and scroll the highlight back into view when it leaves the panel.

Prop mode has two states rather than one. With a prop in hand, the cursor carries a ghost. Left click stamps copies with the feet on the cursor. F flips the prop, and right click deletes the topmost prop under the cursor.

Three actions put the prop down: Q, the top bar chip, or a click on the palette entry that is already selected. That empties the hands. Left click then picks whichever placed prop is under the cursor. A drag moves it, F flips only that one, and Delete removes it.

You can reach something already on the map only after you put the prop down. The hint strip and the chip therefore both change wording with the state.

The palette's selection highlight tracks the hand, not the last click. With nothing held there is no selected prop to show. The highlight goes out, and the panel stops claiming a choice that is not in effect.

A drag pushes an undo snapshot the first time it moves something. A plain click pushes nothing. Selecting props to look at them therefore does not bury the undo history.

## Undo and the clipboard

Undo is one stack of whole-document snapshots, which hold walls, tiles and props together. The editor pushes one per stroke, not one per cell. Ctrl+Z therefore steps back through every kind of edit in the order you made it.

In tile mode, Ctrl-drag marks a rectangle on the map. Ctrl+C lifts those tiles into a clipboard, which becomes the brush. Ctrl+V stamps it at the cursor. The paste is exact, and includes blank cells. It therefore overwrites rather than blends.

## Importing art

`util.Library` is the import path for art that was never part of the build. It scans `library/tilesets`, `library/props` and `library/walls` next to the executable. It loads each PNG off disk, and registers it in the bitmap cache. The key is the one `Paths.image` would have produced. The rest of the game therefore reaches a dropped-in file exactly as it reaches a baked one.

`library/library.json` records what you turned into a tileset or a prop. Those registries append their entries to the ones parsed from `assets/data`. A version counter tells them when to rebuild the merged list.

Load drops an entry whose image no longer exists, rather than let it fail later. Import needs a filesystem. On HTML5 the panel says so, and lists nothing.

`LibraryPanel` is the front end, and `PreviewPane` is its right-hand surface. They are separate because a drag state machine and tab bookkeeping in one class made both harder to follow.

The pane owns the scaled preview, the grid overlay, and the hitbox rectangle with its handles. It owns the whole draw, move and resize gesture, and reports a finished box through one callback. The panel keeps the tabs, the file list and the buttons, and decides what the pane shows.

There is one tab per kind. The discovered files sit on the left, and a preview sits on the right. You cannot guess one thing from an image, so the panel asks for it directly. That is the tile size, which you choose against a grid drawn over the preview.

A wall does not arrive as a new look to choose between. There is no theme switcher, so nothing could choose it. An import therefore overrides the wall on the theme every map wears. The editor keeps the stock wall aside, so the button beside it can put things back.

## Prop hitboxes

The library's fourth tab edits prop hitboxes on the same preview. The first drag draws a box. After that you adjust the box rather than redraw it. A drag inside it moves it. The eight white handles resize it from that edge or corner. Only a drag that starts outside it makes a new box.

The editor clamps every drag to the image. A box therefore cannot describe collision that is not on the sprite.

The editor stores boxes per prop name. You can therefore set a hitbox on a built-in prop without a write to a baked asset. In prop mode, H opens that tab directly on the prop in hand or selected on the map. A menu named after importing is the wrong place to look for a hitbox editor.

A building needs a shallow band across its base, not a box over its whole picture. Block only the ground it stands on. A player can then walk up to the front, round the side, and stand covered by it from behind. A full-sprite box walls off the art, and leaves nowhere to pass.

BASE BAND sets that shape in one click. It measures against the opaque pixels, not the canvas. A sprite exported with a transparent margin would otherwise stop short of its own front wall. It would also flip depth below the ground it stands on.

## Depth and layering

The bottom of a prop's hitbox is also the line it sorts on. A building therefore cannot be solid in one place and drawn as though it stood somewhere else. Without a hitbox a prop still sorts by the bottom of its image, so nothing that already existed moved.

Prop mode draws each prop's sort line. You can therefore see where the player starts to pass in front while you arrange, rather than only in play.

A prop that must ignore depth has a layer setting beside the box. Ground always draws under everything, and overhead always draws over it.

The editor sorts its own prop group by the same rule. It re-sorts live during a drag, not only on release. What you arrange there is therefore what you play.

In play the comparison runs every frame against the player's feet, and it holds no state. Nothing toggles when the player crosses the line. An approach that never goes behind therefore cannot leave a prop drawn on the wrong side.

## Occluding weapon effects

Weapon effects sit above the entity layer, so they read clearly over characters. That alone would let a slash or an arrow paint straight over a building the player stands behind.

The fix does not break every effect group into the sorted layer. Part of the sorted layer draws a second time above the effects instead. That part is whatever sits in front of the thing that hides the player. It uses the same sprites and no extra art, and it refills each frame.

It must be that whole tail, not only the props. An enemy in front of a building belongs above it in both passes. A redraw of the building alone would bury a creature that is nearer the camera than the wall beside it. The tail of an already-sorted list keeps the order for free.

The overlay group is inactive, so nothing updates twice. It empties and refills rather than remembering anything, so it cannot fall out of step.

A prop drawn over an effect helps only where the prop's picture is. A downward swing reaches past its bottom edge into open ground. The projection reads that ground as in front of the building.

The game therefore hides the held weapon and its melee effects outright while the player counts as buried. That state means behind a prop, horizontally within it, and not above its roof. The weapon dims through alpha, not visibility. The throw and super systems own visibility, and multiplayer puts it on the wire.

`PropWorld` holds all of this: the solid bodies, the second-draw overlay, the buried flag and the player's foot collision. PlayState builds it, and adds its two groups in draw order. It applies the buried flag to the held weapon. The weapon stays outside `PropWorld`, because it belongs to combat, not to props.

## Collision and cover

A prop with a hitbox contributes an invisible immovable body. The player and the enemies collide against it. The editor draws those bodies in prop mode, so you can see the footprint while you place.

Props collide against a shallow box at the walker's feet, not against the whole sprite. The box describes ground a building stands on. The player is ninety pixels taller than the ground they occupy. A full-body test would stop them a body-height short of a wall they must be able to reach.

Walls keep the whole-body test. A wall is tall, and a sprite stopped against it looks right.

`PropBlock` reads the same boxes as cover rather than as obstacles. Every projectile in the game already probed a point ahead of itself. It tested that point against the wall grid to decide when to die. That covers arrows, the thrown hammer, the hook, orbiters and enemy shots. Each of those probes now asks the props the same question. A building therefore stops a shot exactly where a wall would stop it.

The segment between attacker and target gates damage. If a prop sits across that line, the hit does not land. A melee swing therefore cannot reach through a storefront, and nothing on the far side can reach back.

Both directions run through a single funnel. One handles what the player deals, and one handles what the player takes. Contact damage, shots and every weapon inherit the rule, and none of them knows about it.

Enemies also refuse to spawn on a prop's footprint. An enemy that arrives inside a building lands on the wrong side of it, with no way out.

Cover measures between the two ground points. Each fighter uses its own feet line, the same one its collision and its depth use. It does not use the bottom of the sprite or the body centre.

On a tall sprite, the centre sits high enough to be level with a base band. The feet are plainly in front of it. The sprite bottom differs from the feet line by a few pixels. Collision parks a fighter exactly against a band's edge. Either point was therefore enough to fall inside the band. Two fighters could stand together outside a shop and not touch each other.

The boxes are also inset slightly for this test. A fighter flush against one therefore never counts as inside it.

The line has one name, `feetY`, on the player and on enemies. Collision, depth sorting, cover and shadows all read that property, rather than repeat the offset.

---

Back to the [documentation index](../DOCS.md).
