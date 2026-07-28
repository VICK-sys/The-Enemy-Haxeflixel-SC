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

	public static function exp():Int
	{
		ensure();
		return save.data.exp != null ? save.data.exp : 0;
	}

	public static function statPoints():Array<Int>
	{
		ensure();
		var raw:Array<Int> = save.data.statPoints;
		return raw == null ? [] : raw.copy();
	}

	public static function setStats(exp:Int, points:Array<Int>):Void
	{
		ensure();
		save.data.exp = exp;
		save.data.statPoints = points.copy();
		save.flush();
	}

	public static function language():String
	{
		ensure();
		return save.data.language != null ? save.data.language : "en";
	}

	public static function setLanguage(c:String):Void
	{
		ensure();
		save.data.language = c;
		save.flush();
	}

	public static function playerName():String
	{
		ensure();
		return save.data.playerName != null ? save.data.playerName : "";
	}

	public static function setPlayerName(n:String):Void
	{
		ensure();
		save.data.playerName = n;
		save.flush();
	}

	public static function lastIp():String
	{
		ensure();
		return save.data.lastIp != null ? save.data.lastIp : "";
	}

	public static function setLastIp(ip:String):Void
	{
		ensure();
		save.data.lastIp = ip;
		save.flush();
	}

	public static function runValue():Int
	{
		ensure();
		return save.data.runValue != null ? save.data.runValue : 0;
	}

	public static function setRunValue(v:Int):Void
	{
		ensure();
		save.data.runValue = v;
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
