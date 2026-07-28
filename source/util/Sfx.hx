package util;

import flixel.FlxG;
import flixel.sound.FlxSound;

class Sfx
{
	public static var positional:Bool = true;

	static inline var RANGE:Float = 1000;
	static inline var FLOOR:Float = 0.3;
	static inline var PAN_SPAN:Float = 780;

	public static function at(name:String, x:Float, y:Float, volume:Float = 1):Void
	{
		if (!positional)
		{
			FlxG.sound.play(Paths.sound(name), volume);
			return;
		}
		var s = FlxG.sound.play(Paths.sound(name), volume * fade(x, y));
		if (s != null)
			s.pan = panOf(x);
	}

	public static function tune(sound:FlxSound, x:Float, y:Float, volume:Float):Void
	{
		if (sound == null)
			return;
		if (!positional)
		{
			sound.volume = volume;
			sound.pan = 0;
			return;
		}
		sound.volume = volume * fade(x, y);
		sound.pan = panOf(x);
	}

	static function fade(x:Float, y:Float):Float
	{
		var dx = x - viewX();
		var dy = y - viewY();
		var dist = Math.sqrt(dx * dx + dy * dy);
		var near = 1 - Math.min(1, dist / RANGE);
		return FLOOR + (1 - FLOOR) * near;
	}

	static function panOf(x:Float):Float
	{
		var p = (x - viewX()) / PAN_SPAN;
		return p < -1 ? -1 : (p > 1 ? 1 : p);
	}

	static function viewX():Float
		return FlxG.camera.scroll.x + FlxG.width * 0.5;

	static function viewY():Float
		return FlxG.camera.scroll.y + FlxG.height * 0.5;
}
