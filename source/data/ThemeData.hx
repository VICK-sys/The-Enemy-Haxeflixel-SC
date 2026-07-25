package data;

import util.Paths;

typedef ThemeData =
{
	name:String,
	background:String,
	wall:String,
	wallRect:Array<Int>,
	wallColor:String
}

typedef ThemeSet =
{
	themes:Array<ThemeData>
}

class ThemeDataRegistry
{
	static var data:ThemeSet;

	public static function all():Array<ThemeData>
	{
		if (data == null)
			data = DataLoader.load(Paths.json("themes"));
		return data.themes;
	}

	public static function get(i:Int):ThemeData
	{
		var list = all();
		if (i < 0 || i >= list.length)
			i = 0;
		return list[i];
	}

	public static function count():Int
		return all().length;

	public static function colorOf(t:ThemeData):Int
	{
		if (t.wallColor == null)
			return 0xFF1C1010;
		var hex = StringTools.startsWith(t.wallColor, "0x") ? t.wallColor.substr(2) : t.wallColor;
		var c = Std.parseInt("0x" + hex);
		return c == null ? 0xFF1C1010 : (0xFF000000 | c);
	}
}
