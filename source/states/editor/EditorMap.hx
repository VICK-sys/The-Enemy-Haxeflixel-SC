package states.editor;

import data.ArenaData.ArenaDataRegistry;
import data.PropData.PropPlace;
import data.TilesetData.TilesetData;
import data.TilesetData.TilesetDataRegistry;
import systems.DecorTiles;
import util.MapStore;
import util.Paths;

class EditorMap
{
	public var cols(default, null):Int;
	public var rows(default, null):Int;
	public var cell(default, null):Int;

	public var walls:Array<Bool>;
	public var tiles:Array<Int>;
	public var props:Array<PropPlace> = [];
	public var spawnX:Float;
	public var spawnY:Float;
	public var theme:Int = 0;
	public var tilesetIndex:Int = 0;
	public var dirty:Bool = false;

	private var undoStack:Array<Array<Bool>> = [];
	private var undoDepth:Int;

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

	public function blank():Void
	{
		walls = [for (i in 0...cols * rows) false];
		closeRing();
		spawnX = cols * cell / 2;
		spawnY = rows * cell / 2;
		props = [];
		theme = 0;
		tilesetIndex = 0;
		tiles = DecorTiles.parse(null, tileset());
		undoStack = [];
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
		undoStack.push(walls.copy());
		if (undoStack.length > undoDepth)
			undoStack.shift();
	}

	public function undo():Bool
	{
		var prev = undoStack.pop();
		if (prev == null)
			return false;
		walls = prev;
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
		return t == null ? null : DecorTiles.toCsv(tiles, t);
	}

	public function useTileset(i:Int):Void
	{
		tilesetIndex = i;
		tiles = DecorTiles.parse(null, tileset());
		dirty = true;
	}

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
		theme = stored.theme == null ? 0 : stored.theme;
		props = stored.props == null ? [] : stored.props;
		tilesetIndex = TilesetDataRegistry.indexOf(stored.tileset);
		tiles = DecorTiles.parse(stored.tiles, tileset());
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
			theme: theme,
			props: props,
			tileset: t == null ? null : t.name,
			tiles: tileCsv()
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
