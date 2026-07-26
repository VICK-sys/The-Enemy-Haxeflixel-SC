package systems.world;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class FootCollide
{
	public static inline var DEPTH:Float = 24;

	static var box:FlxObject;

	public static function against(s:FlxSprite, feetY:Float, solids:FlxTypedGroup<FlxSprite>):Void
	{
		if (s == null || solids == null || solids.length == 0)
			return;

		if (box == null)
		{
			box = new FlxObject();
			box.moves = false;
		}

		box.width = s.width;
		box.height = DEPTH;
		box.x = s.x;
		box.y = feetY - DEPTH;
		box.last.set(box.x - (s.x - s.last.x), box.y - (s.y - s.last.y));

		var fromX = box.x;
		var fromY = box.y;
		FlxG.collide(box, solids);
		s.x += box.x - fromX;
		s.y += box.y - fromY;
	}
}
