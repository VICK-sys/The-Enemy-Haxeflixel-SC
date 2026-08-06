package util;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

class HuePalette
{
	public static function nameTint(hue:Float):Int
		return FlxColor.fromHSB(hue * 360, 0.82, 0.98);

	public static function shiftColor(argb:Int, hue:Float):Int
	{
		var c:FlxColor = argb;
		if (c.saturation > 0)
			c.hue = (c.hue + hue * 360) % 360;
		return c;
	}

	public static function fadeColor(argb:Int, hue:Float):Int
	{
		var c:FlxColor = shiftColor(argb, hue);
		if (c.saturation > 0)
			c.saturation = c.saturation * FADE_SATURATION;
		c.brightness = c.brightness * FADE_BRIGHTNESS;
		return c;
	}

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

	static var lastName:String;
	static var lastHue:Float;
	static var lastGraphic:FlxGraphic;

	public static function graphic(name:String, hue:Float):FlxGraphic
	{
		if (lastGraphic != null && lastGraphic.bitmap != null && hue == lastHue && name == lastName)
			return lastGraphic;

		var made:FlxGraphic;
		if (hue == 0)
			made = FlxG.bitmap.add(Paths.image(name));
		else
		{
			var key = name + "|hue" + Math.round(hue * 360);
			made = FlxG.bitmap.get(key);
			if (made == null)
			{
				var src = FlxG.bitmap.add(Paths.image(name)).bitmap;
				made = FlxG.bitmap.add(shift(src, hue), false, key);
				made.persist = true;
			}
		}
		lastName = name;
		lastHue = hue;
		lastGraphic = made;
		return made;
	}

	public static function faded(name:String, hue:Float):FlxGraphic
	{
		var key = name + "|out" + Math.round(hue * 360);
		var found = FlxG.bitmap.get(key);
		if (found != null)
			return found;

		var src = FlxG.bitmap.add(Paths.image(name)).bitmap;
		var made = FlxG.bitmap.add(drain(src, hue), false, key);
		made.persist = true;
		return made;
	}

	static inline var FADE_SATURATION:Float = 0.2;
	static inline var FADE_BRIGHTNESS:Float = 0.5;

	static function drain(src:BitmapData, hue:Float):BitmapData
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
				{
					px.hue = (px.hue + turn) % 360;
					px.saturation = px.saturation * FADE_SATURATION;
				}
				px.brightness = px.brightness * FADE_BRIGHTNESS;
				out.setPixel32(x, y, px);
			}
		}
		return out;
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
