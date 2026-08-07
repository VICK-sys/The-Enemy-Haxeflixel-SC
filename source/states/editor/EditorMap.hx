package states.editor;

import data.ArenaData.ArenaDataRegistry;
import data.PropData.PropPlace;
import data.TilesetData.TilesetData;
import data.TilesetData.TilesetDataRegistry;
import systems.world.DecorTiles;
import util.MapStore;
import util.Paths;

typedef EditorSnapshot =
{
	walls:Array<Bool>,
	tiles:Array<Int>,
	props:Array<PropPlace>
}

class EditorMap
{
	public var cols(default, null):Int;
	public var rows(default, null):Int;

	public var pixelW(get, never):Int;
	public var pixelH(get, never):Int;

	function get_pixelW():Int
		return cols * cell;

	function get_pixelH():Int
		return rows * cell;
	public var cell(default, null):Int;

	public var walls:Array<Bool>;
	public var tiles:Array<Int>;
	public var props:Array<PropPlace> = [];
	public var spawnX:Float;
	public var spawnY:Float;
	public var shopX:Float;
	public var shopY:Float;
	public var tilesetIndex:Int = 0;
	public var dirty:Bool = false;

	private var undoStack:Array<EditorSnapshot> = [];
	private var undoDepth:Int;
	private var tilesW:Int = 0;
	private var tilesH:Int = 0;

	public var loadDroppedFloor(default, null):Bool = false;

	public function new(undoDepth:Int)
	{
		var d = ArenaDataRegistry.get();
		cols = d.cols;
		rows = d.rows;
		cell = d.tileSize;
		this.undoDepth = undoDepth;
		blank();
	}

	public function tileset():TilesetData
		return TilesetDataRegistry.get(tilesetIndex);

	function resetTileGrid(csv:String):Void
	{
		var t = tileset();
		tiles = DecorTiles.parse(csv, t, pixelW, pixelH);
		tilesW = t == null ? 0 : DecorTiles.cols(t, pixelW);
		tilesH = t == null ? 0 : DecorTiles.rows(t, pixelH);
	}

	public function syncTileGrid():Bool
	{
		var t = tileset();
		if (t == null)
			return false;
		if (DecorTiles.cols(t, pixelW) == tilesW && DecorTiles.rows(t, pixelH) == tilesH)
			return false;
		resetTileGrid(null);
		dirty = true;
		return true;
	}

	public function blank():Void
	{
		walls = [for (i in 0...cols * rows) false];
		closeRing();
		shopX = defaultShopX();
		shopY = defaultShopY();
		spawnX = cols * cell / 2;
		spawnY = rows * cell / 2;
		props = [];
		tilesetIndex = 0;
		resetTileGrid(null);
		undoStack = [];
	}

	public static inline var MIN_SIDE:Int = 20;
	public static inline var MAX_SIDE:Int = 400;

	public function wallsPerTile():Int
	{
		var t = tileset();
		if (t == null)
			return 1;
		var n = Std.int(DecorTiles.cellW(t) / cell);
		return n < 1 ? 1 : n;
	}

	function snapSide(v:Int):Int
	{
		var step = wallsPerTile();
		var up = Math.ceil(v / step) * step;
		return clampSide(up);
	}

	public function resize(newCols:Int, newRows:Int):Bool
	{
		newCols = snapSide(newCols);
		newRows = snapSide(newRows);
		if (newCols == cols && newRows == rows)
			return false;

		var oldWalls = walls;
		var oldCols = cols;
		var oldRows = rows;
		var oldTiles = tiles;
		var oldTileW = tilesW;
		var oldTileH = tilesH;
		var t = tileset();

		cols = newCols;
		rows = newRows;

		walls = [for (i in 0...cols * rows) false];
		var keepC = oldCols < cols ? oldCols : cols;
		var keepR = oldRows < rows ? oldRows : rows;
		for (r in 0...keepR)
			for (c in 0...keepC)
				walls[r * cols + c] = oldWalls[r * oldCols + c];
		closeRing();

		tiles = [for (i in 0...DecorTiles.cols(t, pixelW) * DecorTiles.rows(t, pixelH)) 0];
		tilesW = t == null ? 0 : DecorTiles.cols(t, pixelW);
		tilesH = t == null ? 0 : DecorTiles.rows(t, pixelH);
		var tc = oldTileW < tilesW ? oldTileW : tilesW;
		var tr = oldTileH < tilesH ? oldTileH : tilesH;
		for (r in 0...tr)
			for (c in 0...tc)
				tiles[r * tilesW + c] = oldTiles[r * oldTileW + c];

		clampMarks();
		dirty = true;
		return true;
	}

	function clampSide(v:Int):Int
		return v < MIN_SIDE ? MIN_SIDE : (v > MAX_SIDE ? MAX_SIDE : v);

	function clampMarks():Void
	{
		var w = pixelW - cell;
		var h = pixelH - cell;
		if (spawnX > w)
			spawnX = w;
		if (spawnY > h)
			spawnY = h;
		if (shopX > w)
			shopX = w;
		if (shopY > h)
			shopY = h;
		var kept:Array<PropPlace> = [];
		for (p in props)
			if (p.x <= pixelW && p.y <= pixelH)
				kept.push(p);
		props = kept;
	}

	public function closeRing():Void
	{
		for (c in 0...cols)
		{
			walls[c] = true;
			walls[(rows - 1) * cols + c] = true;
		}
		for (r in 0...rows)
		{
			walls[r * cols] = true;
			walls[r * cols + cols - 1] = true;
		}
	}

	public function inside(c:Int, r:Int):Bool
		return c >= 1 && r >= 1 && c <= cols - 2 && r <= rows - 2;

	public function wallAt(c:Int, r:Int):Bool
		return walls[r * cols + c];

	public function setWall(c:Int, r:Int, on:Bool):Bool
	{
		if (!inside(c, r) || walls[r * cols + c] == on)
			return false;
		walls[r * cols + c] = on;
		dirty = true;
		return true;
	}

	public function clearInterior():Void
	{
		for (r in 1...rows - 1)
			for (c in 1...cols - 1)
				walls[r * cols + c] = false;
		dirty = true;
	}

	public function pushUndo():Void
	{
		undoStack.push({walls: walls.copy(), tiles: tiles.copy(), props: props.copy()});
		if (undoStack.length > undoDepth)
			undoStack.shift();
	}

	public function undo():Bool
	{
		var prev = undoStack.pop();
		if (prev == null)
			return false;
		walls = prev.walls;
		props = prev.props;
		if (prev.tiles.length == tilesW * tilesH)
			tiles = prev.tiles;
		else
			resetTileGrid(null);
		dirty = true;
		return true;
	}

	public function wallCsv():String
	{
		closeRing();
		var out = [];
		for (r in 0...rows)
		{
			var line = [];
			for (c in 0...cols)
				line.push(walls[r * cols + c] ? "1" : "0");
			out.push(line.join(","));
		}
		return out.join("\n");
	}

	public function readWallCsv(csv:String):Void
	{
		walls = [for (i in 0...cols * rows) false];
		var lines = csv.split("\n");
		for (r in 0...rows)
		{
			if (r >= lines.length)
				break;
			var cells = lines[r].split(",");
			for (c in 0...cols)
				if (c < cells.length)
					walls[r * cols + c] = Std.parseInt(cells[c]) > 0;
		}
		closeRing();
	}

	public function tileCsv():String
	{
		var t = tileset();
		return t == null ? null : DecorTiles.toCsv(tiles, t, pixelW, pixelH);
	}

	public function useTileset(i:Int):Void
	{
		tilesetIndex = i;
		resetTileGrid(null);
		dirty = true;
	}

	public function defaultShopX():Float
		return cols * cell / 2;

	public function defaultShopY():Float
		return rows * cell / 3;

	public function load(slot:Int):Void
	{
		var stored = MapStore.load(slot);
		if (stored == null)
		{
			blank();
			dirty = false;
			return;
		}

		readWallCsv(stored.csv);
		spawnX = stored.sx;
		spawnY = stored.sy;
		shopX = stored.shopX == null ? defaultShopX() : stored.shopX;
		shopY = stored.shopY == null ? defaultShopY() : stored.shopY;
		props = stored.props == null ? [] : stored.props;
		tilesetIndex = TilesetDataRegistry.indexOf(stored.tileset);
		var t = tileset();
		var stale = t != null && stored.tileW != null && stored.tileW != 0 && stored.tileW != t.tileW;
		resetTileGrid(stale ? null : stored.tiles);
		loadDroppedFloor = stale;
		undoStack = [];
		dirty = false;
	}

	public function save(slot:Int):Void
	{
		var t = tileset();
		MapStore.store(slot, {
			sx: spawnX,
			sy: spawnY,
			csv: wallCsv(),
			props: props,
			tileset: t == null ? null : t.name,
			tiles: tileCsv(),
			tileW: t == null ? 0 : t.tileW,
			cols: cols,
			rows: rows,
			shopX: shopX,
			shopY: shopY
		});
		dirty = false;
	}

	public function copyStockStage():Void
	{
		var d = ArenaDataRegistry.get();
		readWallCsv(openfl.utils.Assets.getText(Paths.file(d.map)));
		spawnX = d.spawnX;
		spawnY = d.spawnY;
		dirty = true;
	}
}
