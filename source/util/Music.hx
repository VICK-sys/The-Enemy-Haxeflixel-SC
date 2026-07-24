package util;

import flixel.FlxG;

class Music
{
	static var current:String = null;

	public static function play(name:String, volume:Float, loop:Bool = true):Void
	{
		var m = FlxG.sound.music;
		if (current == name && m != null)
		{
			m.volume = volume;
			m.pitch = 1;
			if (!m.playing)
				m.resume();
			return;
		}
		current = name;
		FlxG.sound.playMusic(Paths.music(name), volume, loop);
	}
}
