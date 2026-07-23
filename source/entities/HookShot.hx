package entities;

import flixel.FlxSprite;
import util.Paths;

class HookShot extends FlxSprite
{
	public static inline var RADIUS:Float = 40;
	public static inline var SPEED:Float = 1200;

	public var dirX:Float = 1;
	public var dirY:Float = 0;

	public function new()
	{
		super();
		loadGraphic(Paths.image("items/mufu_hook"));
		antialiasing = false;
		scale.set(4, 4);
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, angleDeg:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		velocity.set(dx * SPEED, dy * SPEED);
		angle = angleDeg + 90;
	}
}
