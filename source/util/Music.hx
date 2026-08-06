package util;

import flixel.FlxG;
import flixel.sound.FlxSound;

class Music
{
	static var runTracks:Array<String> = ["stage/outerDrylands", "stage/jungleJam"];
	static var runTrack:String = null;
	static var current:String = null;
	static var base:Float = 1;
	static var hooked:Bool = false;
	static var paused:Array<FlxSound> = [];

	public static var held(default, null):Bool = false;

	public static function rollRunTrack():Void
		runTrack = runTracks[Std.random(runTracks.length)];

	public static function getRunTrack():String
	{
		if (runTrack == null)
			rollRunTrack();
		return runTrack;
	}

	public static function hold():Void
	{
		if (held)
			return;
		held = true;
		hook();
		Muffle.set(true);
		paused.resize(0);
		for (s in FlxG.sound.list.members)
			if (s != null && s.exists && s.playing)
			{
				if (s.autoDestroy)
					s.stop();
				else
				{
					s.pause();
					paused.push(s);
				}
			}
	}

	public static function release():Void
	{
		if (!held)
			return;
		held = false;
		Muffle.set(false);
		for (s in paused)
			if (s != null && s.exists && !s.playing)
				s.resume();
		paused.resize(0);
	}

	public static function play(name:String, volume:Float, loop:Bool = true):Void
	{
		hook();
		base = volume;
		var m = FlxG.sound.music;
		if (current == name && m != null && m.exists)
		{
			m.volume = volume * Muffle.volumeScale();
			m.pitch = 1;
			if (!m.playing)
				m.play();
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
