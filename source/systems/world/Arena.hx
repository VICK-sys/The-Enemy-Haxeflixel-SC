package systems.world;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.group.FlxGroup.FlxTypedGroup;
import util.CustomArena;
import util.Paths;
import util.WarpShader;
import data.ArenaData.ArenaDataRegistry;

class Arena
{
	static inline var SHAKE_TIME:Float = 2.6;
	static inline var HOLD_TIME:Float = 1.0;
	static inline var REVEAL_TIME:Float = 1.1;
	static inline var REV_IN:Float = 0.6;
	static inline var REV_OUT:Float = 0.8;

	static inline var IDLE:Int = 0;
	static inline var BOSS_IN:Int = 1;
	static inline var BOSS_WAIT:Int = 2;
	static inline var BOSS_REVEAL:Int = 3;
	static inline var NORMAL_IN:Int = 4;
	static inline var NORMAL_REVEAL:Int = 5;
	static inline var FLASH_IN:Int = 6;
	static inline var FLASH_WAIT:Int = 7;
	static inline var FLASH_KEEP:Int = 8;
	static inline var FADE_OUT:Int = 9;

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
	private var flashPeak:Void->Void;
	private var flashDone:Void->Void;
	private var flashHold:Float = 0;
	private var fadeSpan:Float = 0;
	private var introTimer:Float = 0;
	private var gridActive:Bool = false;
	private var state:FlxState;
	private var cell:Int;
	private var skin:WallSkin;

	public function new(state:FlxState)
	{
		this.state = state;
		var data = ArenaDataRegistry.get();
		cell = data.tileSize;
		spawnX = data.spawnX;
		spawnY = data.spawnY;

		bgPath = data.background;
		mapCsv = Paths.file(data.map);
		mapTiles = Paths.file(data.tiles);

		skin = new WallSkin();
		if (CustomArena.active)
		{
			mapCsv = CustomArena.csv;
			spawnX = CustomArena.spawnX;
			spawnY = CustomArena.spawnY;
			if (skin.background != null)
				bgPath = skin.background;
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
	}

	public function beginBossTransition():Void
	{
		if (introPhase != IDLE || gridActive)
			return;
		introPhase = BOSS_IN;
		introTimer = SHAKE_TIME;
		systems.Fx.shake(0.012, SHAKE_TIME);
	}

	public function fadeFromWhite(time:Float):Void
	{
		whiteOverlay.alpha = 1;
		fadeSpan = time;
		introPhase = FADE_OUT;
		introTimer = time;
	}

	public function raiseWhite(state:flixel.FlxState):Void
	{
		state.remove(whiteOverlay, true);
		state.add(whiteOverlay);
	}

	public function beginWhiteFlash(onPeak:Void->Void, onDone:Void->Void, hold:Float):Void
	{
		if (introPhase != IDLE || gridActive)
			return;
		flashPeak = onPeak;
		flashDone = onDone;
		flashHold = hold;
		introPhase = FLASH_IN;
		introTimer = SHAKE_TIME;
		systems.Fx.shake(0.012, SHAKE_TIME);
	}

	public function endBossTransition():Void
	{
		if (introPhase != IDLE || !gridActive)
			return;
		introPhase = NORMAL_IN;
		introTimer = REV_IN;
		systems.Fx.shake(0.008, REV_IN);
	}

	public function update(elapsed:Float):Void
	{
		if (gridActive)
			warp.advance(elapsed);

		if (introPhase == BOSS_IN)
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
				introPhase = BOSS_WAIT;
				introTimer = HOLD_TIME;
				whiteOverlay.alpha = 1;
				if (onWhiteout != null)
					onWhiteout();
			}
		}
		else if (introPhase == BOSS_WAIT)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = 1;
			if (introTimer <= 0)
			{
				introPhase = BOSS_REVEAL;
				introTimer = REVEAL_TIME;
			}
		}
		else if (introPhase == BOSS_REVEAL)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = Math.max(0, introTimer) / REVEAL_TIME;
			if (introTimer <= 0)
			{
				whiteOverlay.alpha = 0;
				introPhase = IDLE;
			}
		}
		else if (introPhase == NORMAL_IN)
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
				introPhase = NORMAL_REVEAL;
				introTimer = REV_OUT;
				whiteOverlay.alpha = 1;
				if (onNormal != null)
					onNormal();
			}
		}
		else if (introPhase == NORMAL_REVEAL)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = Math.max(0, introTimer) / REV_OUT;
			if (introTimer <= 0)
			{
				whiteOverlay.alpha = 0;
				introPhase = IDLE;
			}
		}
		else if (introPhase == FLASH_IN)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = 1 - Math.max(0, introTimer) / SHAKE_TIME;
			if (introTimer <= 0)
			{
				whiteOverlay.alpha = 1;
				introPhase = FLASH_WAIT;
				introTimer = flashHold;
				var peak = flashPeak;
				flashPeak = null;
				if (peak != null)
					peak();
			}
		}
		else if (introPhase == FLASH_WAIT)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = 1;
			if (introTimer <= 0)
			{
				introPhase = FLASH_KEEP;
				var done = flashDone;
				flashDone = null;
				if (done != null)
					done();
			}
		}
		else if (introPhase == FLASH_KEEP)
			whiteOverlay.alpha = 1;
		else if (introPhase == FADE_OUT)
		{
			introTimer -= elapsed;
			whiteOverlay.alpha = fadeSpan > 0 ? Math.max(0, introTimer) / fadeSpan : 0;
			if (introTimer <= 0)
			{
				whiteOverlay.alpha = 0;
				introPhase = IDLE;
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
				if (visited.exists(idx) || map.getTileIndex(idx) <= 0)
					continue;
				var w = 0;
				while (c + w < cols - 1 && !visited.exists(idx + w) && map.getTileIndex(idx + w) > 0)
					w++;
				var h = 1;
				while (r + h < rows - 1 && rowSolid(c, r + h, w, cols, visited))
					h++;
				for (rr in 0...h)
					for (cc in 0...w)
						visited.set((r + rr) * cols + c + cc, true);
				var pillar = new FlxSprite(c * cell, r * cell);
				skin.paint(pillar, c * cell, r * cell, w * cell, h * cell);
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
				if (map.getTileIndex(idx) > 0)
					map.setTileIndex(idx, 0, true);
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
			if (visited.exists(idx) || map.getTileIndex(idx) <= 0)
				return false;
		}
		return true;
	}

	public function wallAt(px:Float, py:Float):Bool
	{
		return map.getTileIndexAt(px, py) > 0;
	}
}
