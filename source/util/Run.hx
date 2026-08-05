package util;

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

	public static function allows(name:String):Bool
	{
		var e = RunDataRegistry.event(name);
		return e != null && value >= e.min && value <= e.max;
	}
}
