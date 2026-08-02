package util;

class Skins
{
	public static var SHEETS:Array<String> = ["characters/mufu", "characters/robot"];
	public static var NAMES:Array<String> = ["lobby.skinDefault", "lobby.skinRobot"];

	public static function count():Int
		return SHEETS.length;

	public static function clamp(i:Int):Int
	{
		if (i < 0 || i >= SHEETS.length)
			return 0;
		return i;
	}

	public static function of(i:Int):String
		return SHEETS[clamp(i)];

	public static function nameOf(i:Int):String
		return Lang.t(NAMES[clamp(i)]);

	public static function sheet():String
		return of(SaveData.playerSkin());
}
