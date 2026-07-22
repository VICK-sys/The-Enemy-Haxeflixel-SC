package entities.enemy;

import flixel.FlxSprite;

class EnemyShot extends FlxSprite
{
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

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, damage:Float, speed:Float, range:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		this.damage = damage;
		velocity.set(dx * speed, dy * speed);
		life = range / speed;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
			kill();
	}
}
