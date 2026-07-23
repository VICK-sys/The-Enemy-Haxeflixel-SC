package entities.weapon;

import flixel.FlxSprite;
import entities.enemy.Enemies;
import util.Paths;

class HookShot extends FlxSprite
{
	public static inline var RADIUS:Float = 40;
	public static inline var SPEED:Float = 1200;

	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var life:Float = 0;
	public var hitDone:Bool = false;
	public var reeling:Bool = false;
	public var spinning:Bool = false;
	public var spinTimer:Float = 0;
	public var spinBase:Float = 0;
	public var target:Enemies = null;

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
