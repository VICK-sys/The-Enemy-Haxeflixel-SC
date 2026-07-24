package util;

import flixel.FlxG;
import flixel.util.FlxSave;

class SaveData
{
	static var save:FlxSave;

	static function ensure():Void
	{
		if (save == null)
		{
			save = new FlxSave();
			save.bind("TheEnemy");
		}
	}

	public static function bestWave():Int
	{
		ensure();
		return save.data.bestWave != null ? save.data.bestWave : 0;
	}

	public static function submitWave(wave:Int):Void
	{
		ensure();
		if (save.data.bestWave == null || wave > save.data.bestWave)
		{
			save.data.bestWave = wave;
			save.flush();
		}
	}

	public static function resetBest():Void
	{
		ensure();
		save.data.bestWave = 0;
		save.flush();
	}

	public static function volume():Float
	{
		ensure();
		return save.data.volume != null ? save.data.volume : 1.0;
	}

	public static function setVolume(v:Float):Void
	{
		ensure();
		if (v < 0)
			v = 0;
		if (v > 1)
			v = 1;
		save.data.volume = Math.round(v * 10) / 10;
		save.flush();
	}

	public static function fullscreen():Bool
	{
		ensure();
		return save.data.fullscreen != null ? save.data.fullscreen : false;
	}

	public static function setFullscreen(b:Bool):Void
	{
		ensure();
		save.data.fullscreen = b;
		save.flush();
	}

	public static function showFps():Bool
	{
		ensure();
		return save.data.showFps != null ? save.data.showFps : true;
	}

	public static function setShowFps(b:Bool):Void
	{
		ensure();
		save.data.showFps = b;
		save.flush();
	}

	public static function applySettings():Void
	{
		FlxG.sound.volume = volume();
		FlxG.fullscreen = fullscreen();
		if (Main.counter != null)
			Main.counter.visible = showFps();
	}
}
