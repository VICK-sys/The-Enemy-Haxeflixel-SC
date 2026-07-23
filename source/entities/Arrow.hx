package entities;

import flixel.FlxSprite;
import util.Paths;

class Arrow extends FlxSprite
{
	public static inline var RADIUS:Float = 30;

	static inline var SPEED:Float = 1600;
	static inline var RANGE:Float = 900;

	public var dirX:Float = 1;
	public var dirY:Float = 0;

	private var life:Float = 0;

	public function new()
	{
		super();
		loadGraphic(Paths.image("items/arrow"));
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
		life = RANGE / SPEED;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
			kill();
	}
}
