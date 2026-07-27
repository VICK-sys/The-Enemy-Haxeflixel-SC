package util;

import data.DataLoader;

class Lang
{
	public static inline var EN:String = "en";
	public static inline var JA:String = "ja";

	public static var code(default, null):String = EN;

	static var table:Dynamic;
	static var base:Dynamic;
	static var dirty:Bool = false;

	public static function init():Void
	{
		base = read(EN);
		set(SaveData.language());
	}

	public static function set(c:String):Void
	{
		code = c == JA ? JA : EN;
		table = code == EN ? base : read(code);
	}

	public static function cycle():Void
	{
		set(code == EN ? JA : EN);
		SaveData.setLanguage(code);
		dirty = true;
	}

	public static function consumeChanged():Bool
	{
		var was = dirty;
		dirty = false;
		return was;
	}

	public static function font():String
		return code == JA ? Paths.font("DotGothic16-Regular") : null;

	public static function t(key:String, ?args:Array<Dynamic>):String
	{
		var v:Dynamic = table == null ? null : Reflect.field(table, key);
		if (v == null && base != null)
			v = Reflect.field(base, key);
		if (v == null)
			return key;

		var s:String = v;
		if (args != null)
			for (i in 0...args.length)
				s = StringTools.replace(s, "{" + i + "}", Std.string(args[i]));
		return s;
	}

	static function read(c:String):Dynamic
	{
		try
		{
			return DataLoader.load(Paths.json("lang/" + c));
		}
		catch (e:Dynamic)
		{
			return {};
		}
	}
}
