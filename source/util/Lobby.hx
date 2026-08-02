package util;

import data.ArenaData.ArenaDataRegistry;

class Lobby
{
	public static inline var COLS:Int = 128;
	public static inline var ROWS:Int = 78;

	public static var active:Bool = false;

	public static function cell():Int
		return ArenaDataRegistry.get().tileSize;

	public static function width():Float
		return COLS * cell();

	public static function height():Float
		return ROWS * cell();

	public static function room():MapStore.StoredMap
	{
		var lines = [];
		for (r in 0...ROWS)
		{
			var line = [];
			for (c in 0...COLS)
				line.push(r == 0 || c == 0 || r == ROWS - 1 || c == COLS - 1 ? "1" : "0");
			lines.push(line.join(","));
		}
		return {
			sx: width() * 0.5,
			sy: height() * 0.74,
			csv: lines.join("\n"),
			props: []
		};
	}

	public static function enter():Void
	{
		active = true;
		CustomArena.fromStored(room());
		CustomArena.fromEditor = false;
	}

	public static function leave():Void
	{
		active = false;
		CustomArena.clear();
	}
}
