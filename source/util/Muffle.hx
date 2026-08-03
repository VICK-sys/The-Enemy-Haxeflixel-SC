package util;

import flixel.FlxG;
#if lime_openal
import lime.media.openal.AL;
import lime.media.openal.ALFilter;
import lime.media.openal.ALSource;
#end

class Muffle
{
	public static inline var CUT:Float = 0.06;
	public static inline var DUCK:Float = 0.6;

	static inline var CLOSE_RATE:Float = 9.0;
	static inline var OPEN_RATE:Float = 6.0;
	static inline var SETTLED:Float = 0.001;

	public static var wanted(default, null):Float = 0;
	public static var shown(default, null):Float = 0;
	public static var supported(get, never):Bool;

	#if lime_openal
	static var filter:ALFilter = null;
	static var tried:Bool = false;
	static var wearing:ALSource = null;
	#end

	static function get_supported():Bool
	{
		#if lime_openal
		return make() != null;
		#else
		return false;
		#end
	}

	public static function set(on:Bool):Void
		wanted = on ? 1 : 0;

	public static function clear():Void
	{
		wanted = 0;
		shown = 0;
		apply();
	}

	public static function update(elapsed:Float):Void
	{
		if (shown != wanted)
		{
			var rate = (wanted > shown ? CLOSE_RATE : OPEN_RATE) * elapsed;
			var gap = wanted - shown;
			if (gap < 0)
				gap = -gap;
			shown = gap <= rate || gap < SETTLED ? wanted : shown + (wanted > shown ? rate : -rate);
		}
		apply();
	}

	public static function highGain():Float
		return 1 + (CUT - 1) * shown;

	public static function volumeScale():Float
		return 1 + (DUCK - 1) * shown;

	#if lime_openal
	static function make():ALFilter
	{
		if (tried)
			return filter;
		tried = true;
		filter = AL.createFilter();
		if (filter == null)
			return null;
		AL.filteri(filter, AL.FILTER_TYPE, AL.FILTER_LOWPASS);
		if (AL.getError() != AL.NO_ERROR)
		{
			filter = null;
			return null;
		}
		return filter;
	}

	static function source():ALSource
	{
		var m = FlxG.sound.music;
		if (m == null)
			return null;
		var channel = @:privateAccess m._channel;
		if (channel == null)
			return null;
		var audio = @:privateAccess channel.__audioSource;
		if (audio == null)
			return null;
		var backend = @:privateAccess audio.__backend;
		if (backend == null)
			return null;
		return @:privateAccess backend.handle;
	}
	#end

	static function apply():Void
	{
		#if lime_openal
		var handle = source();
		if (handle == null)
		{
			wearing = null;
			return;
		}

		if (shown <= 0)
		{
			if (wearing != null)
			{
				AL.sourcei(handle, AL.DIRECT_FILTER, AL.FILTER_NULL);
				wearing = null;
			}
			return;
		}

		var f = make();
		if (f == null)
			return;
		AL.filterf(f, AL.LOWPASS_GAIN, 1);
		AL.filterf(f, AL.LOWPASS_GAINHF, highGain());
		AL.sourcei(handle, AL.DIRECT_FILTER, f);
		wearing = handle;
		#end
	}
}
