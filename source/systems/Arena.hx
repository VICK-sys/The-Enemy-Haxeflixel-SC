package systems;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tile.FlxTilemap;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxGradient;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import data.ThemeData.ThemeData;
import data.ThemeData.ThemeDataRegistry;
import data.TilesetData.TilesetData;
import data.TilesetData.TilesetDataRegistry;
import util.CustomArena;
import util.Paths;
import util.WarpShader;
import util.SideView;
import data.ArenaData.ArenaDataRegistry;
import data.SideViewData.SideViewData;
import data.SideViewData.SideViewDataRegistry;

class Arena
{
	static inline var SHAKE_TIME:Float = 2.6;
	static inline var HOLD_TIME:Float = 1.0;
	static inline var REVEAL_TIME:Float = 1.1;
	static inline var REV_IN:Float = 0.6;
	static inline var REV_OUT:Float = 0.8;

	public var map:FlxTilemap;
	public var spawnX:Float;
	public var spawnY:Float;
	public var totemWaveMin:Int;
	public var totemWaveRange:Int;
	public var width(get, never):Float;
	public var height(get, never):Float;
	public var onWhiteout:Void->Void;
	public var onNormal:Void->Void;

	private var bgPath:String;
	private var mapCsv:String;
	private var mapTiles:String;
	private var bg:FlxSprite;
	private var whiteOverlay:FlxSprite;
	private var warp:WarpShader;
	private var pillars:Array<FlxSprite> = [];
	private var pillarLayer:FlxTypedGroup<FlxSprite>;
	private var introPhase:Int = 0;
	private var introTimer:Float = 0;
	private var gridActive:Bool = false;
	private var state:FlxState;
	private var baseRects:Array<FlxRect> = [];
	private var platRects:Array<FlxRect> = [];
	private var sky:FlxSprite;
	private var groundSlab:FlxSprite;
	private var sv:SideViewData;
	private var cell:Int;
	private var wallColor:Int = 0xFF1C1010;
	private var wallTex:BitmapData;
	private var wallRect:Rectangle;
	private var tileSet:TilesetData;
	private var tileGrid:Array<Int>;
	private var tileSheet:BitmapData;

	public function new(state:FlxState)
	{
		this.state = state;
		sv = SideViewDataRegistry.get();
		var data = ArenaDataRegistry.get();
		cell = data.tileSize;
		spawnX = data.spawnX;
		spawnY = data.spawnY;
		totemWaveMin = data.totemWaveMin;
		totemWaveRange = data.totemWaveRange;

		bgPath = data.background;
		mapCsv = Paths.file(data.map);
		mapTiles = Paths.file(data.tiles);

		if (CustomArena.active)
		{
			mapCsv = CustomArena.csv;
			spawnX = CustomArena.spawnX;
			spawnY = CustomArena.spawnY;
			applyTheme(ThemeDataRegistry.get(CustomArena.theme));

			tileSet = TilesetDataRegistry.byName(CustomArena.tileset);
			if (tileSet != null)
			{
				tileGrid = DecorTiles.parse(CustomArena.tiles, tileSet);
				var tg = FlxG.bitmap.add(Paths.image(tileSet.image));
				tileSheet = tg == null ? null : tg.bitmap;
			}
		}

		map = new FlxTilemap();
		map.loadMapFromCSV(mapCsv, mapTiles, cell, cell, AUTO);
		map.visible = false;

		bg = new FlxSprite(0, 0, Paths.image(bgPath));
		bg.setGraphicSize(Std.int(map.width), Std.int(map.height));
		bg.updateHitbox();
		state.add(bg);

		whiteOverlay = new FlxSprite(0, 0);
		whiteOverlay.makeGraphic(Std.int(map.width), Std.int(map.height), 0xFFFFFFFF);
		whiteOverlay.alpha = 0;
		state.add(whiteOverlay);

		state.add(map);

		warp = new WarpShader();

		FlxG.worldBounds.set(0, 0, map.width, map.height);
		SideView.groundY = map.height - sv.groundOffset;
	}

	function applyTheme(t:ThemeData):Void
	{
		bgPath = t.background;
		wallColor = ThemeDataRegistry.colorOf(t);

		if (t.wall == null || t.wall == "")
			return;
		var g = FlxG.bitmap.add(Paths.image(t.wall));
		if (g == null)
			return;
		wallTex = g.bitmap;
		wallRect = t.wallRect != null && t.wallRect.length == 4
			? new Rectangle(t.wallRect[0], t.wallRect[1], t.wallRect[2], t.wallRect[3])
			: new Rectangle(0, 0, wallTex.width, wallTex.height);
	}

	function paintWall(s:FlxSprite, wx:Float, wy:Float, w:Int, h:Int):Void
	{
		var painted = tileSheet != null && tileGrid != null;
		if (wallTex == null && !painted)
		{
			s.makeGraphic(w, h, wallColor);
			return;
		}

		s.makeGraphic(w, h, wallColor, true);

		if (wallTex != null)
		{
			var step = new Point();
			var y:Float = 0;
			while (y < h)
			{
				var x:Float = 0;
				while (x < w)
				{
					step.setTo(x, y);
					s.pixels.copyPixels(wallTex, wallRect, step, null, null, true);
					x += wallRect.width;
				}
				y += wallRect.height;
			}
		}

		if (painted)
			stampPaintedTiles(s, wx, wy, w, h);

		s.dirty = true;
	}

	function stampPaintedTiles(s:FlxSprite, wx:Float, wy:Float, w:Int, h:Int):Void
	{
		var tw = tileSet.tileW;
		var th = tileSet.tileH;
		var per = Std.int(tileSheet.width / tw);
		var gridCols = DecorTiles.cols(tileSet);
		var gridRows = DecorTiles.rows(tileSet);

		var c0 = Math.floor(wx / tw);
		var c1 = Math.floor((wx + w - 1) / tw);
		var r0 = Math.floor(wy / th);
		var r1 = Math.floor((wy + h - 1) / th);

		for (r in r0...r1 + 1)
		{
			if (r < 0 || r >= gridRows)
				continue;
			for (c in c0...c1 + 1)
			{
				if (c < 0 || c >= gridCols)
					continue;
				var v = tileGrid[r * gridCols + c];
				if (v <= 0)
					continue;

				var x0 = Math.max(wx, c * tw);
				var y0 = Math.max(wy, r * th);
				var x1 = Math.min(wx + w, (c + 1) * tw);
				var y1 = Math.min(wy + h, (r + 1) * th);
				if (x1 <= x0 || y1 <= y0)
					continue;

				var srcX = ((v - 1) % per) * tw + (x0 - c * tw);
				var srcY = Math.floor((v - 1) / per) * th + (y0 - r * th);
				s.pixels.copyPixels(tileSheet, new Rectangle(srcX, srcY, x1 - x0, y1 - y0),
					new Point(x0 - wx, y0 - wy), null, null, true);
			}
		}
	}

	public function buildSideAssets():Void
	{
		if (sky != null)
			return;

		sky = FlxGradient.createGradientFlxSprite(Std.int(map.width), Std.int(map.height), [0xFF0C0818, 0xFF221533, 0xFF3A2237]);
		sky.antialiasing = false;
		sky.y = -map.height;
		state.insert(state.members.indexOf(bg) + 1, sky);

		groundSlab = new FlxSprite(0, SideView.groundY - 6);
		paintWall(groundSlab, 0, SideView.groundY - 6, Std.int(map.width), Std.int(map.height - SideView.groundY) + 6);
		groundSlab.alpha = 0;
		state.insert(state.members.indexOf(sky) + 1, groundSlab);
	}

	public function sidePlatforms():Array<FlxRect>
	{
		return platRects;
	}

	public function applySideMorph(t:Float):Void
	{
		bg.y = t * map.height * 0.25;
		bg.alpha = 1 - 0.55 * t;
		if (sky != null)
			sky.y = -map.height + t * map.height;
		if (groundSlab != null)
			groundSlab.alpha = t;

		for (i in 0...pillars.length)
		{
			var s = pillars[i];
			var a = baseRects[i];
			var b = platRects[i];
			var cx = a.x + a.width / 2 + (b.x + b.width / 2 - a.x - a.width / 2) * t;
			var cy = a.y + a.height / 2 + (b.y + b.height / 2 - a.y - a.height / 2) * t;
			var w = a.width + (b.width - a.width) * t;
			var h = a.height + (b.height - a.height) * t;
			s.scale.set(w / a.width, h / a.height);
			s.x = cx - a.width / 2;
			s.y = cy - a.height / 2;
		}
	}

	public function beginBossTransition():Void
	{
		if (introPhase != 0 || gridActive)
			return;
		introPhase = 1;
		introTimer = SHAKE_TIME;
		FlxG.camera.shake(0.012, SHAKE_TIME);
	}

	public function endBossTransition():Void
	{
		if (introPhase != 0 || !gridActive)
			return;
		introPhase = 4;
		introTimer = REV_IN;
		FlxG.camera.shake(0.008, REV_IN);
	}

	public function update(elapsed:Float):Void
	{
		if (gridActive)
			warp.advance(elapsed);

		if (introPhase == 1)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = 1 - Math.max(0, introTimer) / SHAKE_TIME;
			if (introTimer <= 0)
			{
				bg.loadGraphic(Paths.image("stage/grid"));
				bg.setGraphicSize(Std.int(map.width), Std.int(map.height));
				bg.updateHitbox();
				bg.shader = warp;
				clearObstacles();
				gridActive = true;
				introPhase = 2;
				introTimer = HOLD_TIME;
				whiteOverlay.alpha = 1;
				if (onWhiteout != null)
					onWhiteout();
			}
		}
		else if (introPhase == 2)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = 1;
			if (introTimer <= 0)
			{
				introPhase = 3;
				introTimer = REVEAL_TIME;
			}
		}
		else if (introPhase == 4)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = 1 - Math.max(0, introTimer) / REV_IN;
			if (introTimer <= 0)
			{
				bg.loadGraphic(Paths.image(bgPath));
				bg.setGraphicSize(Std.int(map.width), Std.int(map.height));
				bg.updateHitbox();
				bg.shader = null;
				restoreObstacles();
				gridActive = false;
				introPhase = 5;
				introTimer = REV_OUT;
				whiteOverlay.alpha = 1;
				if (onNormal != null)
					onNormal();
			}
		}
		else if (introPhase == 5)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = Math.max(0, introTimer) / REV_OUT;
			if (introTimer <= 0)
			{
				whiteOverlay.alpha = 0;
				introPhase = 0;
			}
		}
		else if (introPhase == 3)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = Math.max(0, introTimer) / REVEAL_TIME;
			if (introTimer <= 0)
			{
				whiteOverlay.alpha = 0;
				introPhase = 0;
			}
		}
	}

	function get_width():Float
		return map.width;

	function get_height():Float
		return map.height;

	public function addPillars(layer:FlxTypedGroup<FlxSprite>):Void
	{
		pillarLayer = layer;
		baseRects = [];
		platRects = [];
		var cols = map.widthInTiles;
		var rows = map.heightInTiles;
		var visited = new Map<Int, Bool>();
		for (r in 1...rows - 1)
		{
			for (c in 1...cols - 1)
			{
				var idx = r * cols + c;
				if (visited.exists(idx) || map.getTileByIndex(idx) <= 0)
					continue;
				var w = 0;
				while (c + w < cols - 1 && !visited.exists(idx + w) && map.getTileByIndex(idx + w) > 0)
					w++;
				var h = 1;
				while (r + h < rows - 1 && rowSolid(c, r + h, w, cols, visited))
					h++;
				for (rr in 0...h)
					for (cc in 0...w)
						visited.set((r + rr) * cols + c + cc, true);
				var pillar = new FlxSprite(c * cell, r * cell);
				paintWall(pillar, c * cell, r * cell, w * cell, h * cell);
				layer.add(pillar);
				pillars.push(pillar);
				baseRects.push(new FlxRect(pillar.x, pillar.y, w * cell, h * cell));
				platRects.push(platformFor(pillar.x + w * cell / 2, pillar.y + h * cell / 2, w * cell));
			}
		}
	}

	function platformFor(cx:Float, cy:Float, w:Float):FlxRect
	{
		var platW = Math.max(w * sv.platformWidthMult, sv.platformWidthMin);
		var top = 120.0;
		var bottom = map.height - 120.0;
		var yNorm = (cy - top) / (bottom - top);
		if (yNorm < 0)
			yNorm = 0;
		if (yNorm > 1)
			yNorm = 1;
		var platTop = sv.platformHigh + (SideView.groundY - sv.platformLowGap - sv.platformHigh) * yNorm;
		var platCx = cx;
		if (platCx < 80 + platW / 2)
			platCx = 80 + platW / 2;
		if (platCx > map.width - 80 - platW / 2)
			platCx = map.width - 80 - platW / 2;
		return new FlxRect(platCx - platW / 2, platTop, platW, sv.platformHeight);
	}

	public function clearObstacles():Void
	{
		for (pillar in pillars)
		{
			if (pillarLayer != null)
				pillarLayer.remove(pillar, true);
			pillar.destroy();
		}
		pillars = [];

		var cols = map.widthInTiles;
		var rows = map.heightInTiles;
		for (r in 1...rows - 1)
			for (c in 1...cols - 1)
			{
				var idx = r * cols + c;
				if (map.getTileByIndex(idx) > 0)
					map.setTileByIndex(idx, 0, true);
			}
	}

	public function restoreObstacles():Void
	{
		map.loadMapFromCSV(mapCsv, mapTiles, cell, cell, AUTO);
		map.visible = false;
		if (pillarLayer != null)
			addPillars(pillarLayer);
	}

	function rowSolid(c:Int, r:Int, w:Int, cols:Int, visited:Map<Int, Bool>):Bool
	{
		for (cc in 0...w)
		{
			var idx = r * cols + c + cc;
			if (visited.exists(idx) || map.getTileByIndex(idx) <= 0)
				return false;
		}
		return true;
	}

	public function wallAt(px:Float, py:Float):Bool
	{
		if (SideView.active)
			return false;
		var tile = map.getTileIndexByCoords(FlxPoint.weak(px, py));
		return tile >= 0 && map.getTileByIndex(tile) > 0;
	}
}
