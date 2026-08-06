package util;

import flixel.FlxG;
import flixel.sound.FlxSound;

class SoundSweep
{
	#if cpp
	static inline var OVERDUE_SCALE:Float = 2;
	static inline var OVERDUE_PAD:Float = 0.5;

	static var stamps:Map<FlxSound, Float> = new Map();
	static var channels:Map<FlxSound, openfl.media.SoundChannel> = new Map();
	static var drop:Array<FlxSound> = [];
	#end

	public static function init():Void
	{
		#if cpp
		FlxG.signals.postUpdate.add(run);
		#end
	}

	#if cpp
	static function run():Void
	{
		if (FlxG.sound == null)
			return;
		reap(FlxG.sound.music);
		if (FlxG.sound.list != null)
			for (s in FlxG.sound.list.members)
				reap(s);
		drop.resize(0);
		for (s in stamps.keys())
			if (!s.exists || !s.playing)
				drop.push(s);
		for (s in drop)
		{
			stamps.remove(s);
			channels.remove(s);
		}
	}

	static function reap(s:FlxSound):Void
	{
		@:privateAccess
		{
			if (s == null || !s.exists || !s.playing || s._channel == null)
				return;
			var now = haxe.Timer.stamp();
			if (channels.get(s) != s._channel)
			{
				channels.set(s, s._channel);
				stamps.set(s, now);
			}
			var src = s._channel.__audioSource;
			var handle = src == null || src.__backend == null ? null : src.__backend.handle;
			if (handle != null
				&& lime.media.openal.AL.getSourcei(handle, lime.media.openal.AL.SOURCE_STATE) == lime.media.openal.AL.STOPPED)
			{
				s.stopped();
				return;
			}
			if (s._length > 0 && now - stamps.get(s) > s._length / 1000 * OVERDUE_SCALE + OVERDUE_PAD)
				s.stopped();
		}
	}
	#end
}
