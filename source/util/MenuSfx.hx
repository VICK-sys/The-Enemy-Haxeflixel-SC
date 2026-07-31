package util;

import flixel.FlxG;

class MenuSfx
{
	static inline var HOVER_VOL:Float = 0.2;
	static inline var CLICK_VOL:Float = 0.3;
	static inline var CANCEL_VOL:Float = 0.45;
	static inline var UP_VOL:Float = 0.25;
	static inline var DOWN_VOL:Float = 0.2;

	public static function step(dir:Int):Void
	{
		if (dir > 0)
			FlxG.sound.play(Paths.sound("menu/scroll_up"), UP_VOL);
		else
			FlxG.sound.play(Paths.sound("menu/scroll_down"), DOWN_VOL);
	}

	public static function hover():Void
		FlxG.sound.play(Paths.sound("menu/hover"), HOVER_VOL);

	public static function click():Void
		FlxG.sound.play(Paths.sound("menu/click"), CLICK_VOL);

	public static function cancel():Void
		FlxG.sound.play(Paths.sound("menu/cancel"), CANCEL_VOL);
}
