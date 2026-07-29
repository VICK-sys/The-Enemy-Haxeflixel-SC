package util;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

class HuePalette
{
	static inline var BAND:Float = 32;
	static inline var SAT_FLOOR:Float = 0.25;

	public static function sparrow(name:String, hue:Float):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(graphic(name, hue), "assets/images/" + name + ".xml");
	}

	public static function graphic(name:String, hue:Float):FlxGraphic
	{
		if (hue == 0)
			return FlxG.bitmap.add(Paths.image(name));

		var key = name + "|hue" + Math.round(hue * 360);
		var found = FlxG.bitmap.get(key);
		if (found != null)
			return found;

		var src = FlxG.bitmap.add(Paths.image(name)).bitmap;
		var made = FlxG.bitmap.add(shift(src, hue), false, key);
		made.persist = true;
		return made;
	}

	static function shift(src:BitmapData, hue:Float):BitmapData
	{
		var out = new BitmapData(src.width, src.height, true, 0);
		var turn = hue * 360;
		for (y in 0...src.height)
		{
			for (x in 0...src.width)
			{
				var px:FlxColor = src.getPixel32(x, y);
				if (px.alphaFloat <= 0)
					continue;
				var h = px.hue;
				var away = h > 180 ? 360 - h : h;
				if (away < BAND && px.saturation > SAT_FLOOR)
					px.hue = (h + turn) % 360;
				out.setPixel32(x, y, px);
			}
		}
		return out;
	}
}
