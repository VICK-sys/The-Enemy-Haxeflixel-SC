package systems;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.group.FlxGroup.FlxTypedGroup;
import util.Paths;
import util.WarpShader;
import data.ArenaData.ArenaDataRegistry;

class Arena
{
	static inline var TILE_WIDTH:Int = 16;
	static inline var TILE_HEIGHT:Int = 16;
	static inline var SHAKE_TIME:Float = 2.6;
	static inline var HOLD_TIME:Float = 1.0;
	static inline var REVEAL_TIME:Float = 1.1;
	static inline var REV_IN:Float = 0.6;
	static inline var REV_OUT:Float = 0.8;

	public var map:FlxTilemap;
	public var spawnX:Float;
	public var spawnY:Float;
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

	public function new(state:FlxState)
	{
		var data = ArenaDataRegistry.get();
		spawnX = data.spawnX;
		spawnY = data.spawnY;

		bgPath = data.background;
		mapCsv = Paths.file(data.map);
		mapTiles = Paths.file(data.tiles);

		map = new FlxTilemap();
		map.loadMapFromCSV(mapCsv, mapTiles, TILE_WIDTH, TILE_HEIGHT, AUTO);
		map.visible = false;

		bg = new FlxSprite(0, 0, Paths.image(data.background));
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
				var pillar = new FlxSprite(c * TILE_WIDTH, r * TILE_HEIGHT);
				pillar.makeGraphic(w * TILE_WIDTH, h * TILE_HEIGHT, 0xFF1C1010);
				layer.add(pillar);
				pillars.push(pillar);
			}
		}
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
		map.loadMapFromCSV(mapCsv, mapTiles, TILE_WIDTH, TILE_HEIGHT, AUTO);
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
		var tile = map.getTileIndexByCoords(FlxPoint.weak(px, py));
		return tile >= 0 && map.getTileByIndex(tile) > 0;
	}
}
