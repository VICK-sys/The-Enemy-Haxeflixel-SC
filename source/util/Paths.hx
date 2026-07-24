package util;

import flixel.graphics.frames.FlxAtlasFrames;

class Paths
{
	public static inline function image(name:String):String
		return "assets/images/" + name + ".png";

	public static inline function sound(name:String):String
		return "assets/sounds/" + name + ".ogg";

	public static inline function music(name:String):String
		return "assets/music/" + name + ".ogg";

	public static inline function file(name:String):String
		return "assets/" + name;

	public static inline function json(name:String):String
		return "assets/data/" + name + ".json";

	public static inline function font(name:String):String
		return "assets/fonts/" + name + ".ttf";

	public static function sparrow(name:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(image(name), "assets/images/" + name + ".xml");
}
