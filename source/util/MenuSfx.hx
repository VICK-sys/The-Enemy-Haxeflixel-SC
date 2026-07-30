package util;

import flixel.FlxG;

class MenuSfx
{
	static inline var HOVER_VOL:Float = 0.2;
	static inline var CLICK_VOL:Float = 0.3;
	static inline var CANCEL_VOL:Float = 0.45;

	public static function hover():Void
		FlxG.sound.play(Paths.sound("menu/hover"), HOVER_VOL);

	public static function click():Void
		FlxG.sound.play(Paths.sound("menu/click"), CLICK_VOL);

	public static function cancel():Void
		FlxG.sound.play(Paths.sound("menu/cancel"), CANCEL_VOL);
}
