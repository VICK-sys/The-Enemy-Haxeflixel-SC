package util;

class WorldClock
{
	public static var timeStop:Float = 1;
	public static var superSlow:Float = 1;

	public static var scale(get, never):Float;

	static function get_scale():Float
		return timeStop < superSlow ? timeStop : superSlow;

	public static function reset():Void
	{
		timeStop = 1;
		superSlow = 1;
	}
}
