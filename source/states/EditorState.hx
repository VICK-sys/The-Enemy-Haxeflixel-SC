package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import data.ArenaData.ArenaDataRegistry;
import data.PropData.PropPlace;
import data.PropData.PropDataRegistry;
import data.ThemeData.ThemeDataRegistry;
import data.TilesetData.TilesetData;
import data.TilesetData.TilesetDataRegistry;
import systems.Decor;
import systems.DecorTiles;
import util.CustomArena;
import data.EditorData.EditorDataRegistry;
import states.editor.EditorMap;
import util.MapStore;
import util.Paths;

class EditorState extends FlxState
{
	static inline var MODE_WALLS:Int = 0;
	static inline var MODE_TILES:Int = 1;
	static inline var MODE_PROPS:Int = 2;
	static var MODE_NAMES:Array<String> = ["WALL MODE", "TILE MODE", "PROP MODE"];

	public static var lastSlot:Int = 1;

	private var doc:EditorMap;
	private var cfg = EditorDataRegistry.get();

	var PAL_W(get, never):Float;
	var PAL_H(get, never):Float;
	var PAL_PAD(get, never):Float;
	var PROP_CELL(get, never):Int;
	var ZOOM_MIN(get, never):Float;
	var ZOOM_MAX(get, never):Float;
	var PAN_SPEED(get, never):Float;
	var FLASH_TIME(get, never):Float;

	inline function get_PAL_W():Float return cfg.palette.width;
	inline function get_PAL_H():Float return cfg.palette.height;
	inline function get_PAL_PAD():Float return cfg.palette.padding;
	inline function get_PROP_CELL():Int return cfg.palette.propCell;
	inline function get_ZOOM_MIN():Float return cfg.view.minZoom;
	inline function get_ZOOM_MAX():Float return cfg.view.maxZoom;
	inline function get_PAN_SPEED():Float return cfg.view.panSpeed;
	inline function get_FLASH_TIME():Float return cfg.flashTime;

	private var slot:Int;

	private var map:FlxTilemap;
	private var bg:FlxSprite;
	private var hover:FlxSprite;
	private var rectPreview:FlxSprite;
	private var spawnMark:FlxSprite;
	private var spawnLabel:FlxText;

	private var uiCam:FlxCamera;
	private var slotText:FlxText;
	private var brushText:FlxText;
	private var help:FlxText;
	private var helpBar:FlxSprite;
	private var flashText:FlxText;
	private var flashTimer:Float = 0;

	private var brush:Int = 1;
	private var stroke:Bool = false;
	private var strokePaint:Bool = true;
	private var rectMode:Bool = false;
	private var rectAnchorC:Int = 0;
	private var rectAnchorR:Int = 0;
	private var lastC:Int = -1;
	private var lastR:Int = -1;

	private var tilesPath:String;
	private var leaving:Bool = false;

	private var mode:Int = MODE_WALLS;
	private var isProps(get, never):Bool;

	function get_isProps():Bool
		return mode == MODE_PROPS;

	private var selCol:Int = 0;
	private var selRow:Int = 0;
	private var selCols:Int = 1;
	private var selRows:Int = 1;
	private var dragCol:Int = 0;
	private var dragRow:Int = 0;
	private var tileSolid:Bool = false;
	private var tileLayer:FlxTilemap;
	private var tileGhost:FlxSprite;
	private var palBg:FlxSprite;
	private var palSheet:FlxSprite;
	private var palSel:FlxSprite;
	private var palScale:Float = 1;
	private var palViewX:Float = 0;
	private var palViewY:Float = 0;
	private var palFit:Float = 1;
	private var palCells:Array<Int>;

	private var camZoom:Float;

	private var propIndex:Int = 0;
	private var propFlip:Bool = false;
	private var propGroup:FlxTypedGroup<FlxSprite>;
	private var propSprites:Array<FlxSprite> = [];
	private var ghost:FlxSprite;

	private var propPal:openfl.display.BitmapData;
	private var propPalCols:Int = 1;
	private var propScrollY:Float = 0;

	override public function create():Void
	{
		FlxG.mouse.visible = true;
		FlxG.camera.bgColor = 0xFF120C14;

		var data = ArenaDataRegistry.get();
		tilesPath = Paths.file(data.tiles);

		doc = new EditorMap(cfg.brush.undoDepth);
		slot = lastSlot;
		loadSlot(slot);

		bg = new FlxSprite(0, 0);
		add(bg);

		map = new FlxTilemap();
		add(map);
		rebuildMap();
		applyTheme();

		tileLayer = new FlxTilemap();
		add(tileLayer);
		rebuildTiles();

		propGroup = new FlxTypedGroup<FlxSprite>();
		add(propGroup);
		rebuildProps();

		tileGhost = new FlxSprite();
		tileGhost.alpha = 0.6;
		tileGhost.visible = false;
		add(tileGhost);

		hover = new FlxSprite();
		hover.makeGraphic(doc.cell, doc.cell, 0xFFFFFFFF);
		hover.alpha = 0.3;
		add(hover);

		rectPreview = new FlxSprite();
		rectPreview.makeGraphic(doc.cell, doc.cell, 0xFFFFFFFF);
		rectPreview.origin.set(0, 0);
		rectPreview.alpha = 0.3;
		rectPreview.visible = false;
		add(rectPreview);

		ghost = new FlxSprite();
		ghost.alpha = 0.55;
		ghost.visible = false;
		add(ghost);

		spawnMark = new FlxSprite();
		spawnMark.makeGraphic(22, 22, 0xFF7CFC00);
		spawnMark.angle = 45;
		add(spawnMark);

		spawnLabel = new FlxText(0, 0, 120, "SPAWN");
		spawnLabel.setFormat(null, 20, 0xFF7CFC00, CENTER);
		spawnLabel.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(spawnLabel);
		placeSpawnMark();

		camZoom = cfg.view.startZoom;
		FlxG.camera.zoom = camZoom;
		FlxG.camera.focusOn(FlxPoint.weak(doc.cols * doc.cell / 2, doc.rows * doc.cell / 2));

		uiCam = new FlxCamera();
		uiCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(uiCam, false);

		palBg = new FlxSprite();
		palBg.makeGraphic(1, 1, 0xDD16121C);
		palBg.cameras = [uiCam];
		add(palBg);

		palSheet = new FlxSprite();
		palSheet.antialiasing = false;
		palSheet.cameras = [uiCam];
		add(palSheet);

		palSel = new FlxSprite();
		palSel.makeGraphic(1, 1, 0x66FFFFFF);
		palSel.cameras = [uiCam];
		add(palSel);
		buildPalette();
		showPalette(false);

		slotText = uiText(12, 8, 560, LEFT);
		brushText = uiText(FlxG.width - 452, 8, 440, RIGHT);

		helpBar = new FlxSprite(0, FlxG.height - 52);
		helpBar.makeGraphic(FlxG.width, 52, 0xBB0E0A12);
		helpBar.cameras = [uiCam];
		add(helpBar);

		help = uiText(0, FlxG.height - 46, FlxG.width, CENTER);
		help.size = 15;
		refreshHelp();

		flashText = uiText(0, 60, FlxG.width, CENTER);
		flashText.size = 26;

		refreshHud();
		super.create();
	}

	function uiText(x:Float, y:Float, w:Float, align:FlxTextAlign):FlxText
	{
		var t = new FlxText(x, y, w, "");
		t.setFormat(null, 18, FlxColor.WHITE, align);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		t.cameras = [uiCam];
		add(t);
		return t;
	}

	function loadSlot(n:Int):Void
	{
		slot = n;
		lastSlot = n;
		doc.load(n);
		selCol = 0;
		selRow = 0;
		selCols = 1;
		selRows = 1;
	}

	function rebuildMap():Void
	{
		map.loadMapFromCSV(doc.wallCsv(), tilesPath, doc.cell, doc.cell, AUTO);
		map.color = ThemeDataRegistry.colorOf(ThemeDataRegistry.get(doc.theme));
	}

	function applyTheme():Void
	{
		var t = ThemeDataRegistry.get(doc.theme);
		bg.loadGraphic(Paths.image(t.background));
		bg.setGraphicSize(doc.cols * doc.cell, doc.rows * doc.cell);
		bg.updateHitbox();
		bg.alpha = 0.4;
		map.color = ThemeDataRegistry.colorOf(t);
	}

	function tset():TilesetData
		return TilesetDataRegistry.get(doc.tilesetIndex);

	function rebuildTiles():Void
	{
		var t = tset();
		if (t == null)
			return;
		tileLayer.loadMapFromCSV(DecorTiles.toCsv(doc.tiles, t), Paths.image(t.image), t.tileW, t.tileH, null, 1, 1, 999999);
	}

	function palX():Float
		return FlxG.width - PAL_W - PAL_PAD * 2;

	function palY():Float
		return 96;

	function perRow():Int
	{
		var t = tset();
		var g = FlxG.bitmap.add(Paths.image(t.image));
		var n = g == null ? 1 : Std.int(g.bitmap.width / t.tileW);
		return n < 1 ? 1 : n;
	}

	function tileCount():Int
	{
		var t = tset();
		if (t == null)
			return 0;
		var g = FlxG.bitmap.add(Paths.image(t.image));
		if (g == null)
			return 0;
		return Std.int(g.bitmap.width / t.tileW) * Std.int(g.bitmap.height / t.tileH);
	}

	function buildPalette():Void
	{
		var t = tset();
		if (t == null)
			return;

		palBg.setGraphicSize(Std.int(PAL_W + PAL_PAD * 2), Std.int(PAL_H + PAL_PAD * 2));
		palBg.updateHitbox();
		palBg.x = palX() - PAL_PAD;
		palBg.y = palY() - PAL_PAD;

		palCells = DecorTiles.contentCells(t);
		palFit = Math.min(PAL_W / (palCells[2] * t.tileW), PAL_H / (palCells[3] * t.tileH));
		palScale = palFit;
		palViewX = palCells[0] * t.tileW;
		palViewY = palCells[1] * t.tileH;

		tileGhost.loadGraphic(Paths.image(t.image), true, t.tileW, t.tileH);
		redrawPalette();
	}

	function redrawPalette():Void
	{
		var t = tset();
		var g = FlxG.bitmap.add(Paths.image(t.image));
		if (g == null)
			return;

		var viewW = Std.int(PAL_W / palScale);
		var viewH = Std.int(PAL_H / palScale);
		if (viewW < 1) viewW = 1;
		if (viewH < 1) viewH = 1;

		palViewX = clampF(palViewX, 0, Math.max(0, g.bitmap.width - viewW));
		palViewY = clampF(palViewY, 0, Math.max(0, g.bitmap.height - viewH));

		var view = new openfl.display.BitmapData(viewW, viewH, true, 0xFF120C14);
		view.copyPixels(g.bitmap, new openfl.geom.Rectangle(palViewX, palViewY, viewW, viewH), new openfl.geom.Point(0, 0));

		var gx = Math.ceil(palViewX / t.tileW) * t.tileW;
		while (gx < palViewX + viewW)
		{
			view.fillRect(new openfl.geom.Rectangle(gx - palViewX, 0, 1, viewH), 0x55FFFFFF);
			gx += t.tileW;
		}
		var gy = Math.ceil(palViewY / t.tileH) * t.tileH;
		while (gy < palViewY + viewH)
		{
			view.fillRect(new openfl.geom.Rectangle(0, gy - palViewY, viewW, 1), 0x55FFFFFF);
			gy += t.tileH;
		}

		var old = palSheet.graphic;
		palSheet.loadGraphic(view);
		if (old != null && old != palSheet.graphic)
			FlxG.bitmap.remove(old);

		palSheet.scale.set(palScale, palScale);
		palSheet.updateHitbox();
		palSheet.x = palX();
		palSheet.y = palY();
		refreshPaletteSel();
	}

	static function clampF(v:Float, lo:Float, hi:Float):Float
		return v < lo ? lo : (v > hi ? hi : v);

	function refreshPaletteSel():Void
	{
		var t = tset();
		if (t == null)
			return;
		palSel.setGraphicSize(Std.int(t.tileW * selCols * palScale), Std.int(t.tileH * selRows * palScale));
		palSel.updateHitbox();
		palSel.x = palX() + (selCol * t.tileW - palViewX) * palScale;
		palSel.y = palY() + (selRow * t.tileH - palViewY) * palScale;
		palSel.visible = palBg.visible
			&& palSel.x >= palX() - 1 && palSel.y >= palY() - 1
			&& palSel.x + palSel.width <= palX() + PAL_W + 1
			&& palSel.y + palSel.height <= palY() + PAL_H + 1;
		refreshTileGhost();
	}

	function pickIndex():Int
		return selRow * perRow() + selCol + 1;

	function refreshTileGhost():Void
	{
		var t = tset();
		var g = FlxG.bitmap.add(Paths.image(t.image));
		if (g == null)
			return;

		var w = selCols * t.tileW;
		var h = selRows * t.tileH;
		var cut = new openfl.display.BitmapData(w, h, true, 0);
		cut.copyPixels(g.bitmap, new openfl.geom.Rectangle(selCol * t.tileW, selRow * t.tileH, w, h), new openfl.geom.Point(0, 0));

		var old = tileGhost.graphic;
		tileGhost.loadGraphic(cut);
		if (old != null && old != tileGhost.graphic)
			FlxG.bitmap.remove(old);
		tileGhost.alpha = 0.6;
	}

	function overPalette():Bool
	{
		var m = FlxG.mouse.getScreenPosition(uiCam);
		return m.x >= palBg.x && m.x <= palBg.x + palBg.width && m.y >= palBg.y && m.y <= palBg.y + palBg.height;
	}

	function pickFromPalette(anchor:Bool):Void
	{
		var t = tset();
		if (t == null)
			return;
		var m = FlxG.mouse.getScreenPosition(uiCam);
		var sheetX = palViewX + (m.x - palX()) / palScale;
		var sheetY = palViewY + (m.y - palY()) / palScale;
		var col = Math.floor(sheetX / t.tileW);
		var row = Math.floor(sheetY / t.tileH);
		var per = perRow();
		var down = Std.int(tileCount() / per);
		col = Std.int(clampF(col, 0, per - 1));
		row = Std.int(clampF(row, 0, down - 1));

		if (anchor)
		{
			dragCol = col;
			dragRow = row;
		}
		selCol = col < dragCol ? col : dragCol;
		selRow = row < dragRow ? row : dragRow;
		selCols = Std.int(Math.abs(col - dragCol)) + 1;
		selRows = Std.int(Math.abs(row - dragRow)) + 1;
		refreshPaletteSel();
	}

	function dragPalette():Void
	{
		var dx = FlxG.mouse.deltaScreenX;
		var dy = FlxG.mouse.deltaScreenY;
		if (dx == 0 && dy == 0)
			return;
		palViewX -= dx / palScale;
		palViewY -= dy / palScale;
		redrawPalette();
	}

	function zoomPalette(dir:Int):Void
	{
		var t = tset();
		var before = palScale;
		palScale = clampF(palScale * (dir > 0 ? 1.25 : 0.8), palFit * 0.5, cfg.palette.maxZoom);

		var cx = palViewX + (PAL_W / before) * 0.5;
		var cy = palViewY + (PAL_H / before) * 0.5;
		palViewX = cx - (PAL_W / palScale) * 0.5;
		palViewY = cy - (PAL_H / palScale) * 0.5;
		redrawPalette();
	}

	function paintTile(on:Bool):Void
	{
		var t = tset();
		if (t == null)
			return;
		var m = mouseWorld();
		var c0 = Math.floor(m.x / t.tileW);
		var r0 = Math.floor(m.y / t.tileH);
		var w = DecorTiles.cols(t);
		var h = DecorTiles.rows(t);
		var per = perRow();

		for (dy in 0...selRows)
			for (dx in 0...selCols)
			{
				var c = c0 + dx;
				var r = r0 + dy;
				if (c < 0 || r < 0 || c >= w || r >= h)
					continue;
				var v = on ? (selRow + dy) * per + (selCol + dx) + 1 : 0;
				if (tileSolid)
					solidUnder(c, r, t, on);
				if (doc.tiles[r * w + c] == v)
					continue;
				doc.tiles[r * w + c] = v;
				tileLayer.setTileByIndex(r * w + c, v, true);
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
			{
				if (doc.setWall(c, r, on))
					map.setTileByIndex(r * doc.cols + c, on ? 1 : 0, true);
			}
	}

	function cycleTileset():Void
	{
		if (TilesetDataRegistry.count() <= 1)
			return;
		doc.tilesetIndex = (doc.tilesetIndex + 1) % TilesetDataRegistry.count();
		doc.tiles = DecorTiles.parse(null, tset());
		selCol = 0;
		selRow = 0;
		selCols = 1;
		selRows = 1;
		buildPalette();
		rebuildTiles();
		doc.dirty = true;
		flash("TILESET: " + tset().name + " (CLEARED)");
	}

	function updateTiles():Void
	{
		var t = tset();
		if (t == null)
			return;

		if (FlxG.keys.justPressed.F)
			cycleTileset();
		if (FlxG.keys.justPressed.V)
		{
			tileSolid = !tileSolid;
			flash(tileSolid ? "TILES ALSO MAKE WALLS" : "TILES ARE DECORATION ONLY");
		}

		if (overPalette())
		{
			tileGhost.visible = false;
			if (FlxG.mouse.wheel != 0)
				zoomPalette(FlxG.mouse.wheel);
			else if (FlxG.mouse.pressedRight || FlxG.mouse.pressedMiddle)
				dragPalette();
			else if (FlxG.mouse.pressed)
				pickFromPalette(FlxG.mouse.justPressed);
			return;
		}

		var m = mouseWorld();
		tileGhost.visible = true;
		tileGhost.x = Math.floor(m.x / t.tileW) * t.tileW;
		tileGhost.y = Math.floor(m.y / t.tileH) * t.tileH;

		if (FlxG.keys.justPressed.LBRACKET || FlxG.keys.justPressed.RBRACKET)
		{
			var i = pickIndex() - 1 + (FlxG.keys.justPressed.LBRACKET ? -1 : 1);
			var n = tileCount();
			if (i < 0)
				i = n - 1;
			if (i >= n)
				i = 0;
			selCol = i % perRow();
			selRow = Std.int(i / perRow());
			selCols = 1;
			selRows = 1;
			refreshPaletteSel();
		}

		if (FlxG.mouse.pressed)
			paintTile(true);
		else if (FlxG.mouse.pressedRight)
			paintTile(false);
	}

	function rebuildProps():Void
	{
		propGroup.clear();
		propSprites = [];
		for (pl in doc.props)
		{
			var s = Decor.make(pl.n);
			if (s == null)
			{
				propSprites.push(null);
				continue;
			}
			s.flipX = pl.f == true;
			Decor.place(s, pl.x, pl.y);
			propGroup.add(s);
			propSprites.push(s);
		}
	}

	function buildPropPalette():Void
	{
		var n = PropDataRegistry.count();
		if (n == 0)
			return;

		propPalCols = Std.int(PAL_W / PROP_CELL);
		if (propPalCols < 1)
			propPalCols = 1;
		var rows = Math.ceil(n / propPalCols);

		if (propPal != null)
			propPal.dispose();
		propPal = new openfl.display.BitmapData(propPalCols * PROP_CELL, rows * PROP_CELL, true, 0);

		for (i in 0...n)
		{
			var s = Decor.make(PropDataRegistry.get(i).name);
			if (s == null)
				continue;
			var src = s.graphic.bitmap;
			var k = Math.min((PROP_CELL - 10) / src.width, (PROP_CELL - 10) / src.height);
			var cx = (i % propPalCols) * PROP_CELL;
			var cy = Math.floor(i / propPalCols) * PROP_CELL;

			var m = new openfl.geom.Matrix();
			m.scale(k, k);
			m.translate(cx + (PROP_CELL - src.width * k) * 0.5, cy + (PROP_CELL - src.height * k) * 0.5);
			propPal.draw(src, m, null, null, null, false);
			s.destroy();
		}

		propScrollY = 0;
		redrawPropPalette();
	}

	function redrawPropPalette():Void
	{
		if (propPal == null)
			return;

		palBg.setGraphicSize(Std.int(PAL_W + PAL_PAD * 2), Std.int(PAL_H + PAL_PAD * 2));
		palBg.updateHitbox();
		palBg.x = palX() - PAL_PAD;
		palBg.y = palY() - PAL_PAD;

		propScrollY = clampF(propScrollY, 0, Math.max(0, propPal.height - PAL_H));

		var view = new openfl.display.BitmapData(Std.int(PAL_W), Std.int(PAL_H), true, 0xFF120C14);
		view.copyPixels(propPal, new openfl.geom.Rectangle(0, propScrollY, PAL_W, PAL_H), new openfl.geom.Point(0, 0));

		var old = palSheet.graphic;
		palSheet.loadGraphic(view);
		if (old != null && old != palSheet.graphic)
			FlxG.bitmap.remove(old);
		palSheet.scale.set(1, 1);
		palSheet.updateHitbox();
		palSheet.x = palX();
		palSheet.y = palY();

		palSel.setGraphicSize(PROP_CELL, PROP_CELL);
		palSel.updateHitbox();
		palSel.x = palX() + (propIndex % propPalCols) * PROP_CELL;
		palSel.y = palY() + Math.floor(propIndex / propPalCols) * PROP_CELL - propScrollY;
		palSel.visible = palBg.visible && palSel.y >= palY() - 1 && palSel.y + PROP_CELL <= palY() + PAL_H + 1;
	}

	function pickFromPropPalette():Void
	{
		var m = FlxG.mouse.getScreenPosition(uiCam);
		var col = Math.floor((m.x - palX()) / PROP_CELL);
		var row = Math.floor((m.y - palY() + propScrollY) / PROP_CELL);
		if (col < 0 || col >= propPalCols || row < 0)
			return;
		var i = row * propPalCols + col;
		if (i < 0 || i >= PropDataRegistry.count())
			return;
		propIndex = i;
		refreshGhost();
		redrawPropPalette();
		flash(PropDataRegistry.get(propIndex).name);
	}

	function refreshGhost():Void
	{
		var p = PropDataRegistry.get(propIndex);
		if (p == null)
		{
			ghost.visible = false;
			return;
		}
		var s = Decor.make(p.name);
		if (s == null)
		{
			ghost.visible = false;
			return;
		}
		ghost.loadGraphicFromSprite(s);
		ghost.scale.set(s.scale.x, s.scale.y);
		ghost.updateHitbox();
		ghost.alpha = 0.55;
		s.destroy();
	}

	function cycleProp(dir:Int):Void
	{
		var n = PropDataRegistry.count();
		if (n == 0)
			return;
		propIndex = (propIndex + dir + n) % n;
		refreshGhost();

		var rowTop = Math.floor(propIndex / propPalCols) * PROP_CELL;
		if (rowTop < propScrollY)
			propScrollY = rowTop;
		else if (rowTop + PROP_CELL > propScrollY + PAL_H)
			propScrollY = rowTop + PROP_CELL - PAL_H;
		redrawPropPalette();
		flash(PropDataRegistry.get(propIndex).name);
	}

	function placeProp(x:Float, y:Float):Void
	{
		var p = PropDataRegistry.get(propIndex);
		if (p == null)
			return;
		doc.props.push({n: p.name, x: x, y: y, f: propFlip});
		rebuildProps();
		doc.dirty = true;
	}

	function deletePropAt(x:Float, y:Float):Void
	{
		var i = propSprites.length;
		while (i-- > 0)
		{
			var s = propSprites[i];
			if (s == null)
				continue;
			if (x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height)
			{
				doc.props.splice(i, 1);
				rebuildProps();
				doc.dirty = true;
				flash("PROP REMOVED");
				return;
			}
		}
	}

	function updateProps():Void
	{
		var p = PropDataRegistry.get(propIndex);
		if (p == null)
			return;

		if (overPalette())
		{
			ghost.visible = false;
			if (FlxG.mouse.wheel != 0)
			{
				propScrollY -= FlxG.mouse.wheel * PROP_CELL * 0.5;
				redrawPropPalette();
			}
			else if (FlxG.mouse.justPressed)
				pickFromPropPalette();
			return;
		}

		if (!ghost.exists || ghost.graphic == null)
			refreshGhost();
		var m = mouseWorld();
		ghost.visible = true;
		ghost.flipX = propFlip;
		Decor.place(ghost, m.x, m.y);

		if (FlxG.keys.justPressed.LBRACKET)
			cycleProp(-1);
		if (FlxG.keys.justPressed.RBRACKET)
			cycleProp(1);
		if (FlxG.keys.justPressed.F)
		{
			propFlip = !propFlip;
			flash(propFlip ? "FLIPPED" : "UNFLIPPED");
		}

		if (FlxG.mouse.justPressed)
			placeProp(m.x, m.y);
		if (FlxG.mouse.justPressedRight)
			deletePropAt(m.x, m.y);
	}

	function refreshHelp():Void
	{
		var line = switch (mode)
		{
			case MODE_TILES:
				"TILES - LEFT PAINT   RIGHT ERASE   [ ] STEP   F SHEET   V SOLID   PALETTE: DRAG A PATCH, WHEEL ZOOM, RIGHT-DRAG PAN";
			case MODE_PROPS:
				"PROPS - LEFT PLACE   RIGHT DELETE   F FLIP      PALETTE - CLICK A PROP, WHEEL SCROLLS, [ ] STEPS";
			default:
				"WALLS - LEFT PAINT   RIGHT ERASE   SHIFT BOX   B BRUSH   C CLEAR   L COPY STAGE";
		};
		help.text = line + "\nP MODE   WHEEL ZOOM   SPACE-DRAG PAN   0 RESET VIEW   X SPAWN   Z UNDO   1-5 SLOTS   T THEME   S SAVE   ENTER PLAY   ESC BACK";
	}

	function showPalette(on:Bool):Void
	{
		palBg.visible = on;
		palSheet.visible = on;
		palSel.visible = on;
	}

	function cycleMode():Void
	{
		mode = (mode + 1) % 3;
		ghost.visible = false;
		hover.visible = false;
		rectPreview.visible = false;
		tileGhost.visible = false;
		stroke = false;

		showPalette(mode != MODE_WALLS);
		if (mode == MODE_TILES)
			buildPalette();
		else if (mode == MODE_PROPS)
		{
			refreshGhost();
			buildPropPalette();
		}
		refreshHelp();
		flash(MODE_NAMES[mode]);
	}

	function cycleTheme():Void
	{
		doc.theme = (doc.theme + 1) % ThemeDataRegistry.count();
		applyTheme();
		doc.dirty = true;
		flash("THEME: " + ThemeDataRegistry.get(doc.theme).name);
	}

	function saveSlot():Void
	{
		doc.save(slot);
		flash("SAVED TO SLOT " + slot);
	}

	function clearMap():Void
	{
		doc.pushUndo();
		doc.clearInterior();
		rebuildMap();
		flash("CLEARED (Z UNDOES)");
	}

	function copyStock():Void
	{
		doc.pushUndo();
		doc.copyStockStage();
		placeSpawnMark();
		rebuildMap();
		flash("COPIED THE STOCK STAGE");
	}

	function undo():Void
	{
		if (doc.undo())
			rebuildMap();
	}

	function undoProp():Void
	{
		if (doc.props.length == 0)
			return;
		doc.props.pop();
		rebuildProps();
		doc.dirty = true;
		flash("PROP UNDONE");
	}

	function mouseWorld():FlxPoint
		return FlxG.mouse.getWorldPosition(FlxG.camera);

	function cellAtMouse():{c:Int, r:Int}
	{
		var m = mouseWorld();
		return {
			c: Math.floor(m.x / doc.cell),
			r: Math.floor(m.y / doc.cell)
		};
	}

	function panningView():Bool
		return FlxG.mouse.pressedMiddle || (FlxG.keys.pressed.SPACE && FlxG.mouse.pressed);

	function updateCamera(elapsed:Float):Void
	{
		var pan = PAN_SPEED * elapsed / camZoom;
		if (FlxG.keys.pressed.LEFT)
			FlxG.camera.scroll.x -= pan;
		if (FlxG.keys.pressed.RIGHT)
			FlxG.camera.scroll.x += pan;
		if (FlxG.keys.pressed.UP)
			FlxG.camera.scroll.y -= pan;
		if (FlxG.keys.pressed.DOWN)
			FlxG.camera.scroll.y += pan;

		if (panningView() && !overPalette())
		{
			FlxG.camera.scroll.x -= FlxG.mouse.deltaScreenX / camZoom;
			FlxG.camera.scroll.y -= FlxG.mouse.deltaScreenY / camZoom;
		}

		if (FlxG.keys.justPressed.ZERO)
			setZoom(cfg.view.startZoom, false);
	}

	function setZoom(z:Float, atCursor:Bool):Void
	{
		var before = mouseWorld();
		camZoom = clampF(z, ZOOM_MIN, ZOOM_MAX);
		FlxG.camera.zoom = camZoom;
		if (atCursor)
		{
			var after = mouseWorld();
			FlxG.camera.scroll.x += before.x - after.x;
			FlxG.camera.scroll.y += before.y - after.y;
		}
		else
			FlxG.camera.focusOn(FlxPoint.weak(doc.cols * doc.cell / 2, doc.rows * doc.cell / 2));
	}

	function paintCell(c:Int, r:Int, on:Bool):Void
	{
		var half = Math.floor((brush - 1) / 2);
		for (rr in (r - half)...(r - half + brush))
			for (cc in (c - half)...(c - half + brush))
			{
				if (doc.setWall(cc, rr, on))
					map.setTileByIndex(rr * doc.cols + cc, on ? 1 : 0, true);
			}
	}

	function paintLine(c0:Int, r0:Int, c1:Int, r1:Int, on:Bool):Void
	{
		var steps = Std.int(Math.max(Math.abs(c1 - c0), Math.abs(r1 - r0)));
		if (steps == 0)
		{
			paintCell(c1, r1, on);
			return;
		}
		for (i in 0...steps + 1)
		{
			var t = i / steps;
			paintCell(Math.round(c0 + (c1 - c0) * t), Math.round(r0 + (r1 - r0) * t), on);
		}
	}

	function applyRect(c0:Int, r0:Int, c1:Int, r1:Int, on:Bool):Void
	{
		var cMin = Std.int(Math.min(c0, c1));
		var cMax = Std.int(Math.max(c0, c1));
		var rMin = Std.int(Math.min(r0, r1));
		var rMax = Std.int(Math.max(r0, r1));
		for (r in rMin...rMax + 1)
			for (c in cMin...cMax + 1)
				doc.setWall(c, r, on);
		rebuildMap();
	}

	function playTest():Void
	{
		if (leaving)
			return;
		leaving = true;
		saveSlot();
		CustomArena.set(doc.wallCsv(), doc.spawnX, doc.spawnY, doc.theme, doc.props);
		var ts = tset();
		CustomArena.setTiles(ts == null ? null : ts.name, ts == null ? null : doc.tileCsv());
		FlxG.mouse.visible = false;
		FlxG.switchState(new PlayState());
	}

	function back():Void
	{
		if (leaving)
			return;
		leaving = true;
		if (doc.dirty)
			saveSlot();
		FlxG.switchState(new MainMenuState());
	}

	function switchSlot(n:Int):Void
	{
		if (n == slot)
			return;
		if (doc.dirty)
			saveSlot();
		loadSlot(n);
		placeSpawnMark();
		rebuildMap();
		applyTheme();
		rebuildProps();
		buildPalette();
		rebuildTiles();
		flash("SLOT " + n);
		refreshHud();
	}

	function placeSpawnMark():Void
	{
		if (spawnMark == null)
			return;
		spawnMark.x = doc.spawnX - spawnMark.width / 2;
		spawnMark.y = doc.spawnY - spawnMark.height / 2;
		spawnLabel.x = doc.spawnX - 60;
		spawnLabel.y = doc.spawnY - 42;
	}

	function flash(msg:String):Void
	{
		flashText.text = msg;
		flashTimer = FLASH_TIME;
	}

	function refreshHud():Void
	{
		slotText.text = "SLOT " + slot + (doc.dirty ? "  *UNSAVED*" : "  (SAVED)") + "   THEME: " + ThemeDataRegistry.get(doc.theme).name;
		if (mode == MODE_PROPS)
		{
			var p = PropDataRegistry.get(propIndex);
			brushText.text = "PROPS: " + (p == null ? "NONE" : p.name) + "  (" + doc.props.length + " PLACED)";
		}
		else if (mode == MODE_TILES)
		{
			var t = tset();
			brushText.text = "TILES: " + (t == null ? "NONE" : t.name) + "  #" + pickIndex()
				+ (selCols > 1 || selRows > 1 ? "  PATCH " + selCols + "x" + selRows : "");
		}
		else
			brushText.text = "WALLS   BRUSH " + brush;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (leaving)
			return;

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			flashText.alpha = flashTimer < 0.4 ? flashTimer / 0.4 : 1;
			if (flashTimer <= 0)
				flashText.text = "";
		}

		updateCamera(elapsed);
		if (!overPalette() && FlxG.mouse.wheel != 0)
			setZoom(camZoom * (FlxG.mouse.wheel > 0 ? cfg.view.zoomStep : 1 / cfg.view.zoomStep), true);

		var cell = cellAtMouse();
		if (FlxG.keys.pressed.SPACE)
		{
			hover.visible = false;
			tileGhost.visible = false;
			ghost.visible = false;
			stroke = false;
		}
		else if (mode == MODE_PROPS)
			updateProps();
		else if (mode == MODE_TILES)
			updateTiles();
		else
		{
			updateHover(cell.c, cell.r);
			updateStroke(cell.c, cell.r);
		}
		updateKeys(cell.c, cell.r);
		refreshHud();
	}

	function updateHover(c:Int, r:Int):Void
	{
		var half = Math.floor((brush - 1) / 2);
		hover.visible = !stroke && c >= 1 && r >= 1 && c <= doc.cols - 2 && r <= doc.rows - 2;
		hover.scale.set(brush, brush);

		hover.x = ((c - half) + brush * 0.5) * doc.cell - hover.width / 2;
		hover.y = ((r - half) + brush * 0.5) * doc.cell - hover.height / 2;
	}

	function updateStroke(c:Int, r:Int):Void
	{
		if (!stroke)
		{
			var left = FlxG.mouse.justPressed;
			var right = FlxG.mouse.justPressedRight;
			if (!left && !right)
				return;
			stroke = true;
			strokePaint = left;
			rectMode = FlxG.keys.pressed.SHIFT;
			doc.pushUndo();
			doc.dirty = true;
			if (rectMode)
			{
				rectAnchorC = c;
				rectAnchorR = r;
				rectPreview.visible = true;
				rectPreview.color = strokePaint ? FlxColor.WHITE : 0xFFE0132D;
			}
			else
				paintCell(c, r, strokePaint);
			lastC = c;
			lastR = r;
			return;
		}

		var held = strokePaint ? FlxG.mouse.pressed : FlxG.mouse.pressedRight;
		if (held)
		{
			if (rectMode)
			{
				rectPreview.x = Math.min(rectAnchorC, c) * doc.cell;
				rectPreview.y = Math.min(rectAnchorR, r) * doc.cell;
				rectPreview.scale.set(Math.abs(c - rectAnchorC) + 1, Math.abs(r - rectAnchorR) + 1);
			}
			else if (c != lastC || r != lastR)
			{
				paintLine(lastC, lastR, c, r, strokePaint);
				lastC = c;
				lastR = r;
			}
			return;
		}

		stroke = false;
		if (rectMode)
		{
			rectPreview.visible = false;
			applyRect(rectAnchorC, rectAnchorR, c, r, strokePaint);
		}
		else
			rebuildMap();
	}

	function updateKeys(c:Int, r:Int):Void
	{
		if (FlxG.keys.justPressed.P)
			cycleMode();
		if (FlxG.keys.justPressed.B && mode == MODE_WALLS)
		{
			brush = brush >= cfg.brush.maxSize ? 1 : brush + 1;
			flash("BRUSH " + brush + "X" + brush);
		}
		if (FlxG.keys.justPressed.Z)
		{
			if (isProps)
				undoProp();
			else
				undo();
		}
		if (FlxG.keys.justPressed.C && !isProps)
			clearMap();
		if (FlxG.keys.justPressed.T)
			cycleTheme();
		if (FlxG.keys.justPressed.L && !isProps)
			copyStock();
		if (FlxG.keys.justPressed.S)
			saveSlot();
		if (FlxG.keys.justPressed.X)
		{
			var mw = mouseWorld();
			var px = mw.x;
			var py = mw.y;
			if (px > doc.cell * 2 && py > doc.cell * 2 && px < (doc.cols - 2) * doc.cell && py < (doc.rows - 2) * doc.cell)
			{
				doc.spawnX = px;
				doc.spawnY = py;
				placeSpawnMark();
				doc.dirty = true;
				flash("SPAWN MOVED");
			}
		}

		if (FlxG.keys.justPressed.ONE)
			switchSlot(1);
		if (FlxG.keys.justPressed.TWO)
			switchSlot(2);
		if (FlxG.keys.justPressed.THREE)
			switchSlot(3);
		if (FlxG.keys.justPressed.FOUR)
			switchSlot(4);
		if (FlxG.keys.justPressed.FIVE)
			switchSlot(5);

		if (FlxG.keys.justPressed.ENTER)
			playTest();
		if (FlxG.keys.justPressed.ESCAPE)
			back();
	}
}
