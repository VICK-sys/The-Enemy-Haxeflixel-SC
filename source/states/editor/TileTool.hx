package states.editor;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
import data.TilesetData.TilesetData;
import data.TilesetData.TilesetDataRegistry;
import systems.DecorTiles;
import util.Paths;

class TileTool
{
	public var layer(default, null):FlxTilemap;
	public var ghost(default, null):FlxSprite;
	public var solid(default, null):Bool = false;

	private var doc:EditorMap;
	private var walls:WallTool;
	private var pal:TilePalette;
	private var flash:String->Void;

	public function new(doc:EditorMap, walls:WallTool, pal:TilePalette, flash:String->Void)
	{
		this.doc = doc;
		this.walls = walls;
		this.pal = pal;
		this.flash = flash;

		layer = new FlxTilemap();

		ghost = new FlxSprite();
		ghost.alpha = 0.6;
		ghost.visible = false;
	}

	function set():TilesetData
		return doc.tileset();

	public function rebuild():Void
	{
		var t = set();
		if (t == null)
			return;
		layer.loadMapFromCSV(DecorTiles.toCsv(doc.tiles, t), Paths.image(t.image), t.tileW, t.tileH, null, 1, 1, 999999);
	}

	public function hideCursor():Void
		ghost.visible = false;

	public function refreshGhost():Void
	{
		var cut = pal.patchBitmap();
		if (cut == null)
			return;
		var old = ghost.graphic;
		ghost.loadGraphic(cut);
		if (old != null && old != ghost.graphic)
			FlxG.bitmap.remove(old);
		ghost.alpha = 0.6;
	}

	public function statusText():String
	{
		var t = set();
		return "TILES: " + (t == null ? "NONE" : t.name) + "  #" + pal.index()
			+ (pal.selCols > 1 || pal.selRows > 1 ? "  PATCH " + pal.selCols + "x" + pal.selRows : "");
	}

	public function update():Void
	{
		var t = set();
		if (t == null)
			return;

		if (FlxG.keys.justPressed.F)
			cycleSheet();
		if (FlxG.keys.justPressed.V)
		{
			solid = !solid;
			flash(solid ? "TILES ALSO MAKE WALLS" : "TILES ARE DECORATION ONLY");
		}

		if (pal.contains())
		{
			ghost.visible = false;
			if (FlxG.mouse.wheel != 0)
				pal.zoom(FlxG.mouse.wheel);
			else if (FlxG.mouse.pressedRight || FlxG.mouse.pressedMiddle)
				pal.drag();
			else if (FlxG.mouse.pressed)
			{
				pal.pick(FlxG.mouse.justPressed);
				refreshGhost();
			}
			return;
		}

		var m = EditorView.mouseWorld();
		ghost.visible = true;
		ghost.x = Math.floor(m.x / t.tileW) * t.tileW;
		ghost.y = Math.floor(m.y / t.tileH) * t.tileH;

		if (FlxG.keys.justPressed.LBRACKET || FlxG.keys.justPressed.RBRACKET)
		{
			pal.step(FlxG.keys.justPressed.LBRACKET ? -1 : 1);
			refreshGhost();
		}

		if (FlxG.mouse.pressed)
			paint(true);
		else if (FlxG.mouse.pressedRight)
			paint(false);
	}

	function paint(on:Bool):Void
	{
		var t = set();
		var m = EditorView.mouseWorld();
		var c0 = Math.floor(m.x / t.tileW);
		var r0 = Math.floor(m.y / t.tileH);
		var w = DecorTiles.cols(t);
		var h = DecorTiles.rows(t);
		var per = pal.perRow();

		for (dy in 0...pal.selRows)
			for (dx in 0...pal.selCols)
			{
				var c = c0 + dx;
				var r = r0 + dy;
				if (c < 0 || r < 0 || c >= w || r >= h)
					continue;
				var v = on ? pal.indexAt(dx, dy) : 0;
				if (solid)
					solidUnder(c, r, t, on);
				if (doc.tiles[r * w + c] == v)
					continue;
				doc.tiles[r * w + c] = v;
				layer.setTileByIndex(r * w + c, v, true);
				doc.dirty = true;
			}
	}

	function solidUnder(tc:Int, tr:Int, t:TilesetData, on:Bool):Void
	{
		var c0 = Math.floor(tc * t.tileW / doc.cell);
		var r0 = Math.floor(tr * t.tileH / doc.cell);
		var c1 = Math.ceil((tc + 1) * t.tileW / doc.cell) - 1;
		var r1 = Math.ceil((tr + 1) * t.tileH / doc.cell) - 1;
		for (r in r0...r1 + 1)
			for (c in c0...c1 + 1)
				walls.setCell(c, r, on);
	}

	function cycleSheet():Void
	{
		if (TilesetDataRegistry.count() <= 1)
			return;
		doc.useTileset((doc.tilesetIndex + 1) % TilesetDataRegistry.count());
		pal.build(set());
		rebuild();
		refreshGhost();
		flash("TILESET: " + set().name + " (CLEARED)");
	}
}
