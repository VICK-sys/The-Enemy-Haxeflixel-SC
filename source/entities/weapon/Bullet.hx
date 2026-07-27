package entities.weapon;

import flixel.FlxSprite;
import util.Paths;

class Bullet extends FlxSprite
{
	static inline var SCALE:Float = 2;

	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var damage:Int = 2;
	public var knock:Float = 1;

	private var life:Float = 0;

	public function new()
	{
		super();
		loadGraphic(Paths.image("enemies/rofel_bullet"));
		antialiasing = false;
		scale.set(SCALE, SCALE);
		updateHitbox();
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, angleDeg:Float, damage:Int, speed:Float, range:Float,
			knock:Float):Void
	{
		revive();
		this.damage = damage;
		this.knock = knock;
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		velocity.set(dx * speed, dy * speed);
		angle = angleDeg;
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
