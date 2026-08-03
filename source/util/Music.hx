package util;

import flixel.FlxG;

class Music
{
	static var current:String = null;
	static var base:Float = 1;
	static var hooked:Bool = false;

	public static var held(default, null):Bool = false;

	public static function hold():Void
	{
		held = true;
		hook();
		Muffle.set(true);
		for (s in FlxG.sound.list.members)
			if (s != null && s.exists && s.playing)
				s.pause();
	}

	public static function release():Void
	{
		held = false;
		Muffle.set(false);
		for (s in FlxG.sound.list.members)
			if (s != null && s.exists && !s.playing)
				s.resume();
	}

	public static function play(name:String, volume:Float, loop:Bool = true):Void
	{
		hook();
		base = volume;
		var m = FlxG.sound.music;
		if (current == name && m != null)
		{
			m.volume = volume * Muffle.volumeScale();
			m.pitch = 1;
			if (!m.playing)
				m.resume();
			return;
		}
		current = name;
		FlxG.sound.playMusic(Paths.music(name), volume * Muffle.volumeScale(), loop);
	}

	static function hook():Void
	{
		if (hooked)
			return;
		hooked = true;
		FlxG.signals.postUpdate.add(tick);
	}

	static function tick():Void
	{
		Muffle.update(FlxG.elapsed);
		var m = FlxG.sound.music;
		if (m != null)
			m.volume = base * Muffle.volumeScale();
	}
}
