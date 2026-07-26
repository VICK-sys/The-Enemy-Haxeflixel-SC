package util;

import data.RunData.RunEvent;
import data.RunData.RunDataRegistry;

class Run
{
	static inline var UNSET:Int = 0;

	public static var value(get, never):Int;

	static var current:Int = UNSET;

	static function get_value():Int
	{
		if (current == UNSET)
			current = SaveData.runValue();
		if (current == UNSET)
			reroll();
		return current;
	}

	public static function reroll():Int
	{
		var cfg = RunDataRegistry.get();
		var span = cfg.max - cfg.min;
		current = cfg.min + (span > 0 ? Std.random(span + 1) : 0);
		SaveData.setRunValue(current);
		return current;
	}

	public static function force(v:Int):Void
	{
		current = v;
		SaveData.setRunValue(v);
	}

	public static function allows(name:String):Bool
	{
		var e = RunDataRegistry.event(name);
		return e != null && value >= e.min && value <= e.max;
	}

	public static function inRange(min:Int, max:Int):Bool
		return value >= min && value <= max;

	public static function windowOf(name:String):String
	{
		var e = RunDataRegistry.event(name);
		return e == null ? "undefined" : e.min + "-" + e.max;
	}

	public static function report():String
	{
		var out = ["RUN = " + value];
		for (n in RunDataRegistry.names())
			out.push("  " + n + " " + windowOf(n) + (allows(n) ? "  ACTIVE" : ""));
		return out.join("\n");
	}
}
