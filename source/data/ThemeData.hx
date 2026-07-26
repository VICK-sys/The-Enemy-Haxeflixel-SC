package data;

import util.Library;
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
	static var baseWall:String;
	static var baseRect:Array<Int>;
	static var appliedAt:Int = -1;

	public static function all():Array<ThemeData>
	{
		if (data == null)
		{
			data = DataLoader.load(Paths.json("themes"));
			if (data.themes.length > 0)
			{
				baseWall = data.themes[0].wall;
				baseRect = data.themes[0].wallRect;
			}
		}

		Library.ensure();
		if (appliedAt != Library.version && data.themes.length > 0)
		{
			var w = Library.wallImage;
			data.themes[0].wall = w == null ? baseWall : w;
			data.themes[0].wallRect = w == null ? baseRect : [];
			appliedAt = Library.version;
		}
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
