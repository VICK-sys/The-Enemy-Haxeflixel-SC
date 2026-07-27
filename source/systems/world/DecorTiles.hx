package systems.world;

import flixel.tile.FlxTilemap;
import data.ArenaData.ArenaDataRegistry;
import data.TilesetData.TilesetData;
import data.TilesetData.TilesetDataRegistry;
import util.Paths;

class DecorTiles
{
	static var boundsCache:Map<String, Array<Int>> = new Map();

	public static function contentCells(t:TilesetData):Array<Int>
	{
		var key = t.image + ":" + t.tileW + "x" + t.tileH;
		if (boundsCache.exists(key))
			return boundsCache.get(key);

		var g = flixel.FlxG.bitmap.add(Paths.image(t.image));
		var full = [0, 0, 1, 1];
		if (g != null)
		{
			var bmp = g.bitmap;
			var minX = bmp.width, minY = bmp.height, maxX = -1, maxY = -1;
			var y = 0;
			while (y < bmp.height)
			{
				var x = 0;
				while (x < bmp.width)
				{
					if ((bmp.getPixel32(x, y) >>> 24) > 8)
					{
						if (x < minX) minX = x;
						if (y < minY) minY = y;
						if (x > maxX) maxX = x;
						if (y > maxY) maxY = y;
					}
					x += 2;
				}
				y += 2;
			}
			if (maxX < 0)
				full = [0, 0, Math.ceil(bmp.width / t.tileW), Math.ceil(bmp.height / t.tileH)];
			else
				full = [
					Math.floor(minX / t.tileW),
					Math.floor(minY / t.tileH),
					Math.ceil((maxX + 2) / t.tileW) - Math.floor(minX / t.tileW),
					Math.ceil((maxY + 2) / t.tileH) - Math.floor(minY / t.tileH)
				];
		}
		boundsCache.set(key, full);
		return full;
	}

	public static function cols(t:TilesetData):Int
		return Math.ceil(ArenaDataRegistry.pixelWidth() / t.tileW);

	public static function rows(t:TilesetData):Int
		return Math.ceil(ArenaDataRegistry.pixelHeight() / t.tileH);

	public static function blankCsv(t:TilesetData):String
	{
		var out = [];
		for (r in 0...rows(t))
		{
			var line = [];
			for (c in 0...cols(t))
				line.push("0");
			out.push(line.join(","));
		}
		return out.join("\n");
	}

	public static function parse(csv:String, t:TilesetData):Array<Int>
	{
		var w = cols(t);
		var h = rows(t);
		var grid = [for (i in 0...w * h) 0];
		if (csv == null || csv == "")
			return grid;
		var lines = csv.split("\n");
		for (r in 0...h)
		{
			if (r >= lines.length)
				break;
			var cells = lines[r].split(",");
			for (c in 0...w)
				if (c < cells.length)
				{
					var v = Std.parseInt(cells[c]);
					grid[r * w + c] = v == null ? 0 : v;
				}
		}
		return grid;
	}

	public static function toCsv(grid:Array<Int>, t:TilesetData):String
	{
		var w = cols(t);
		var h = rows(t);
		var out = [];
		for (r in 0...h)
		{
			var line = [];
			for (c in 0...w)
			{
				var i = r * w + c;
				line.push(Std.string(i < grid.length ? grid[i] : 0));
			}
			out.push(line.join(","));
		}
		return out.join("\n");
	}

	public static function build(csv:String, setName:String):FlxTilemap
	{
		var t = TilesetDataRegistry.byName(setName);
		if (t == null || csv == null || csv == "")
			return null;
		var m = new FlxTilemap();
		m.loadMapFromCSV(csv, Paths.image(t.image), t.tileW, t.tileH, null, 1, 1, 999999);
		return m;
	}
}
