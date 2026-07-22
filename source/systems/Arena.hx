package systems;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.group.FlxGroup.FlxTypedGroup;
import util.Paths;

class Arena
{
	static inline var TILE_WIDTH:Int = 16;
	static inline var TILE_HEIGHT:Int = 16;

	public var map:FlxTilemap;
	public var width(get, never):Float;
	public var height(get, never):Float;

	public function new(state:FlxState)
	{
		state.add(new FlxSprite(0, 0, Paths.image("stages/theEnemy")));

		map = new FlxTilemap();
		map.loadMapFromCSV(Paths.file("default_auto.txt"), Paths.file("auto_tiles.png"), TILE_WIDTH, TILE_HEIGHT, AUTO);
		map.visible = false;
		state.add(map);

		FlxG.worldBounds.set(0, 0, map.width, map.height);
	}

	function get_width():Float
		return map.width;

	function get_height():Float
		return map.height;

	public function addPillars(layer:FlxTypedGroup<FlxSprite>):Void
	{
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
			}
		}
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
