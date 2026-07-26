package systems.world;

import flixel.FlxSprite;

class PropSprite extends FlxSprite
{
	public static inline var SORTED:Int = 0;
	public static inline var GROUND:Int = 1;
	public static inline var OVERHEAD:Int = 2;

	public var baseOffset:Float = 0;
	public var layerMode:Int = SORTED;
	public var sortY:Float = 0;
}
