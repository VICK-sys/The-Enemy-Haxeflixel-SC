package util;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

class Outline
{
	public static function graphic(name:String, tint:FlxColor = FlxColor.WHITE):FlxGraphic
	{
		var key = name + "|edge" + tint;
		var found = FlxG.bitmap.get(key);
		if (found != null)
			return found;

		var src = FlxG.bitmap.add(Paths.image(name)).bitmap;
		var made = FlxG.bitmap.add(edge(src, tint), false, key);
		made.persist = true;
		return made;
	}

	static function edge(src:BitmapData, tint:FlxColor):BitmapData
	{
		var out = new BitmapData(src.width + 2, src.height + 2, true, 0);
		out.lock();
		for (y in 0...src.height)
			for (x in 0...src.width)
				out.setPixel32(x + 1, y + 1, src.getPixel32(x, y));

		for (y in 0...out.height)
		{
			for (x in 0...out.width)
			{
				var here:FlxColor = out.getPixel32(x, y);
				if (here.alphaFloat > 0)
					continue;
				if (touches(src, x - 1, y - 1))
					out.setPixel32(x, y, tint);
			}
		}
		out.unlock();
		return out;
	}

	static function touches(src:BitmapData, x:Int, y:Int):Bool
	{
		for (oy in -1...2)
		{
			for (ox in -1...2)
			{
				if (ox == 0 && oy == 0)
					continue;
				var nx = x + ox;
				var ny = y + oy;
				if (nx < 0 || ny < 0 || nx >= src.width || ny >= src.height)
					continue;
				var px:FlxColor = src.getPixel32(nx, ny);
				if (px.alphaFloat > 0)
					return true;
			}
		}
		return false;
	}
}
