package util;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

class HuePalette
{
	public static function sparrow(name:String, hue:Float):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(graphic(name, hue), "assets/images/" + name + ".xml");
	}

	public static function liveFrames(name:String, hue:Float):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(live(name, hue), "assets/images/" + name + ".xml");
	}

	public static function live(name:String, hue:Float):FlxGraphic
	{
		var key = name + "|live";
		var src = FlxG.bitmap.add(Paths.image(name)).bitmap;
		var g = FlxG.bitmap.get(key);
		if (g == null)
		{
			g = FlxG.bitmap.add(new BitmapData(src.width, src.height, true, 0), false, key);
			g.persist = true;
		}

		var dst = g.bitmap;
		var turn = hue * 360;
		dst.lock();
		for (y in 0...src.height)
		{
			for (x in 0...src.width)
			{
				var px:FlxColor = src.getPixel32(x, y);
				if (px.alphaFloat > 0 && px.saturation > 0)
					px.hue = (px.hue + turn) % 360;
				dst.setPixel32(x, y, px);
			}
		}
		dst.unlock();
		return g;
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
				if (px.saturation > 0)
					px.hue = (px.hue + turn) % 360;
				out.setPixel32(x, y, px);
			}
		}
		return out;
	}
}
