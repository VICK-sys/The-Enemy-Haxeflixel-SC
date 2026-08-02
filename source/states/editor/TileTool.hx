package states.editor;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
import data.TilesetData.TilesetData;
import data.TilesetData.TilesetDataRegistry;
import systems.world.DecorTiles;
import util.Paths;

class TileTool
{
	public var layer(default, null):FlxTilemap;
	public var ghost(default, null):FlxSprite;
	public var marquee(default, null):FlxSprite;
	public var solid(default, null):Bool = false;

	private var doc:EditorMap;
	private var walls:WallTool;
	private var pal:TilePalette;
	private var flash:String->Void;

	private var clip:Array<Int> = null;
	private var clipW:Int = 0;
	private var clipH:Int = 0;
	private var selecting:Bool = false;
	private var hasSel:Bool = false;
	private var anchorC:Int = 0;
	private var anchorR:Int = 0;
	private var headC:Int = 0;
	private var headR:Int = 0;

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

		marquee = new FlxSprite();
		marquee.makeGraphic(1, 1, 0xFF4FC3F7);
		marquee.origin.set(0, 0);
		marquee.alpha = 0.35;
		marquee.visible = false;
	}

	function set():TilesetData
		return doc.tileset();

	public function rebuild():Void
	{
		var t = set();
		if (t == null)
			return;
		layer.loadMapFromCSV(DecorTiles.toCsv(doc.tiles, t), Paths.image(t.image), t.tileW, t.tileH, null, 1, 1, 999999);
		layer.scale.set(DecorTiles.SCALE, DecorTiles.SCALE);
	}

	public function hideCursor():Void
		ghost.visible = false;

	public function clearSelection():Void
	{
		selecting = false;
		hasSel = false;
		marquee.visible = false;
	}

	public function clipLabel():String
		return clipW + "X" + clipH;

	public function refreshGhost():Void
	{
		var cut = clip != null ? pal.renderIndices(clip, clipW, clipH) : pal.patchBitmap();
		if (cut == null)
			return;
		var old = ghost.graphic;
		ghost.loadGraphic(cut);
		if (old != null && old != ghost.graphic)
			FlxG.bitmap.remove(old);
		ghost.alpha = 0.6;
		ghost.scale.set(DecorTiles.SCALE, DecorTiles.SCALE);
		ghost.updateHitbox();
	}

	public function toggleSolid():Void
	{
		solid = !solid;
		flash(solid ? "TILES ALSO MAKE WALLS" : "TILES ARE DECORATION ONLY");
	}

	public function update(blocked:Bool):Void
	{
		var t = set();
		if (t == null)
			return;

		var ctrl = FlxG.keys.pressed.CONTROL;

		if (FlxG.keys.justPressed.F)
			cycleSheet();
		if (FlxG.keys.justPressed.V && !ctrl)
			toggleSolid();

		if (blocked && !pal.contains())
		{
			ghost.visible = false;
			return;
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
				clip = null;
				refreshGhost();
			}
			return;
		}

		var m = EditorView.mouseWorld();
		var c0 = Math.floor(m.x / DecorTiles.cellW(t));
		var r0 = Math.floor(m.y / DecorTiles.cellH(t));

		if (ctrl)
		{
			ghost.visible = false;
			updateSelect(c0, r0, t);
			return;
		}

		selecting = false;
		ghost.visible = true;
		ghost.x = c0 * DecorTiles.cellW(t);
		ghost.y = r0 * DecorTiles.cellH(t);

		if (FlxG.keys.justPressed.LBRACKET || FlxG.keys.justPressed.RBRACKET)
		{
			clip = null;
			pal.step(FlxG.keys.justPressed.LBRACKET ? -1 : 1);
			refreshGhost();
		}

		if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight)
		{
			doc.pushUndo();
			clearSelection();
		}

		if (FlxG.mouse.pressed)
			paint(true);
		else if (FlxG.mouse.pressedRight)
			paint(false);
	}

	function updateSelect(c:Int, r:Int, t:TilesetData):Void
	{
		if (FlxG.mouse.justPressed)
		{
			selecting = true;
			anchorC = c;
			anchorR = r;
		}
		if (!selecting)
			return;

		headC = c;
		headR = r;

		marquee.x = Math.min(anchorC, headC) * DecorTiles.cellW(t);
		marquee.y = Math.min(anchorR, headR) * DecorTiles.cellH(t);
		marquee.scale.set((Math.abs(headC - anchorC) + 1) * DecorTiles.cellW(t), (Math.abs(headR - anchorR) + 1) * DecorTiles.cellH(t));
		marquee.visible = true;

		if (!FlxG.mouse.pressed)
		{
			selecting = false;
			hasSel = true;
		}
	}

	public function copySelection():Bool
	{
		var t = set();
		if (!hasSel || t == null)
			return false;

		var gw = DecorTiles.cols(t);
		var gh = DecorTiles.rows(t);
		var cMin = Std.int(Math.max(0, Math.min(anchorC, headC)));
		var rMin = Std.int(Math.max(0, Math.min(anchorR, headR)));
		var cMax = Std.int(Math.min(gw - 1, Math.max(anchorC, headC)));
		var rMax = Std.int(Math.min(gh - 1, Math.max(anchorR, headR)));
		if (cMax < cMin || rMax < rMin)
			return false;

		clipW = cMax - cMin + 1;
		clipH = rMax - rMin + 1;
		clip = [];
		for (r in rMin...rMax + 1)
			for (c in cMin...cMax + 1)
				clip.push(doc.tiles[r * gw + c]);

		refreshGhost();
		return true;
	}

	public function paste():Bool
	{
		if (clip == null)
			return false;
		doc.pushUndo();
		paint(true);
		return true;
	}

	function paint(on:Bool):Void
	{
		var t = set();
		var m = EditorView.mouseWorld();
		var c0 = Math.floor(m.x / DecorTiles.cellW(t));
		var r0 = Math.floor(m.y / DecorTiles.cellH(t));
		var w = DecorTiles.cols(t);
		var h = DecorTiles.rows(t);
		var stamped = clip != null;
		var pw = stamped ? clipW : pal.selCols;
		var ph = stamped ? clipH : pal.selRows;

		for (dy in 0...ph)
			for (dx in 0...pw)
			{
				var c = c0 + dx;
				var r = r0 + dy;
				if (c < 0 || r < 0 || c >= w || r >= h)
					continue;
				var v = on ? (stamped ? clip[dy * clipW + dx] : pal.indexAt(dx, dy)) : 0;
				if (solid)
					solidUnder(c, r, t, on);
				if (doc.tiles[r * w + c] == v)
					continue;
				doc.tiles[r * w + c] = v;
				layer.setTileIndex(r * w + c, v, true);
				doc.dirty = true;
			}
	}

	function solidUnder(tc:Int, tr:Int, t:TilesetData, on:Bool):Void
	{
		var c0 = Math.floor(tc * DecorTiles.cellW(t) / doc.cell);
		var r0 = Math.floor(tr * DecorTiles.cellH(t) / doc.cell);
		var c1 = Math.ceil((tc + 1) * DecorTiles.cellW(t) / doc.cell) - 1;
		var r1 = Math.ceil((tr + 1) * DecorTiles.cellH(t) / doc.cell) - 1;
		for (r in r0...r1 + 1)
			for (c in c0...c1 + 1)
				walls.setCell(c, r, on);
	}

	public function cycleSheet():Void
	{
		if (TilesetDataRegistry.count() <= 1)
			return;
		doc.useTileset((doc.tilesetIndex + 1) % TilesetDataRegistry.count());
		clip = null;
		clearSelection();
		pal.build(set());
		rebuild();
		refreshGhost();
		flash("TILESET: " + set().name + " (CLEARED)");
	}
}
