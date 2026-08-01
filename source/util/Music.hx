package util;

import flixel.FlxG;

class Music
{
	static var current:String = null;

	public static var held(default, null):Bool = false;

	public static function hold():Void
	{
		held = true;
		FlxG.sound.pause();
	}

	public static function release():Void
	{
		held = false;
		FlxG.sound.resume();
	}

	public static function play(name:String, volume:Float, loop:Bool = true):Void
	{
		var m = FlxG.sound.music;
		if (current == name && m != null)
		{
			m.volume = volume;
			m.pitch = 1;
			if (!m.playing && !held)
				m.resume();
			return;
		}
		current = name;
		FlxG.sound.playMusic(Paths.music(name), volume, loop);
		if (held && FlxG.sound.music != null)
			FlxG.sound.music.pause();
	}
}
