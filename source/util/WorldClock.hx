package util;

class WorldClock
{
	public static var timeStop:Float = 1;

	public static var scale(get, never):Float;

	static function get_scale():Float
		return timeStop;

	public static function reset():Void
		timeStop = 1;
}
