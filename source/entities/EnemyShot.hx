package entities;

import flixel.FlxSprite;

class EnemyShot extends FlxSprite
{
	static inline var SPEED:Float = 480;
	static inline var RANGE:Float = 640;

	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var damage:Float = 0.25;

	private var life:Float = 0;

	public function new()
	{
		super();
		makeGraphic(12, 12, 0xFF6FBF3F);
		antialiasing = false;
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, damage:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		this.damage = damage;
		velocity.set(dx * SPEED, dy * SPEED);
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
