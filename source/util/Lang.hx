package util;

import data.DataLoader;

class Lang
{
	public static inline var EN:String = "en";
	public static inline var JA:String = "ja";
	public static inline var ES:String = "es";

	static inline var BODY_SIZE:Int = 48;
	static inline var TITLE_SIZE:Int = 24;
	static inline var SMALL_SIZE:Int = 24;
	static inline var JA_SIZE:Int = 24;
	static inline var SMALL_STEP:Int = 8;

	public static var codes(default, null):Array<String> = [EN, ES, JA];
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
		code = codes.indexOf(c) >= 0 ? c : EN;
		table = code == EN ? base : read(code);
	}

	public static function cycle(dir:Int = 1):Void
	{
		var i = codes.indexOf(code);
		if (i < 0)
			i = 0;
		set(codes[(i + dir + codes.length) % codes.length]);
		SaveData.setLanguage(code);
		dirty = true;
	}

	public static function consumeChanged():Bool
	{
		var was = dirty;
		dirty = false;
		return was;
	}

	public static function bodyFont():String
		return code == JA ? Paths.font("DotGothic16-Regular") : Paths.font("Unbalanced");

	public static function bodySize():Int
		return code == JA ? JA_SIZE : BODY_SIZE;

	public static function titleFont():String
		return code == JA ? Paths.font("DotGothic16-Regular") : Paths.font("Kirbys-Adventure");

	public static function titleSize():Int
		return code == JA ? JA_SIZE : TITLE_SIZE;

	public static function smallFont():String
		return code == JA ? Paths.font("DotGothic16-Regular") : Paths.font("5mikropix");

	public static function smallSize():Int
		return code == JA ? JA_SIZE : SMALL_SIZE;

	public static function fontFor(size:Int):String
		return size == bodySize() ? bodyFont() : smallFont();

	static var inkBands:Map<String, Array<Int>> = new Map();

	public static function inkBand(font:String, size:Int):Array<Int>
	{
		var key = font + "|" + size;
		if (inkBands.exists(key))
			return inkBands.get(key);

		var probe = new flixel.text.FlxText(0, 0, 240, "WALLS");
		probe.setFormat(font, size, 0xFFFFFFFF, LEFT);
		probe.drawFrame(true);
		var bmp = probe.framePixels;
		var top = -1;
		var bottom = -1;
		if (bmp != null)
			for (y in 0...bmp.height)
			{
				var lit = false;
				for (x in 0...bmp.width)
					if ((bmp.getPixel32(x, y) >>> 24) > 8)
					{
						lit = true;
						break;
					}
				if (lit)
				{
					if (top < 0)
						top = y;
					bottom = y;
				}
			}
		probe.destroy();

		var band = top < 0 ? [0, size] : [top, bottom - top + 1];
		inkBands.set(key, band);
		return band;
	}

	public static function inkTop(font:String, size:Int, boxH:Float):Float
	{
		var band = inkBand(font, size);
		return (boxH - band[1]) * 0.5 - band[0];
	}

	public static function setLeading(t:flixel.text.FlxText, value:Int):Void
	{
		@:privateAccess
		{
			t._defaultFormat.leading = value;
			t.textField.defaultTextFormat = t._defaultFormat;
			t.textField.setTextFormat(t._defaultFormat);
			t._regen = true;
		}
	}

	public static function chatSize(scale:Float):Int
	{
		var steps = Std.int(SMALL_SIZE * scale / SMALL_STEP + 0.5);
		return (steps < 1 ? 1 : steps) * SMALL_STEP;
	}

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
