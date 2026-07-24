package entities.enemy;

import flixel.FlxSprite;
import util.Paths;
import util.WorldClock;

class EnemyShot extends FlxSprite
{
	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var damage:Float = 0.25;

	private var life:Float = 0;
	private var spriteKey:String = null;

	public function new()
	{
		super();
		makeGraphic(12, 12, 0xFF6FBF3F);
		antialiasing = false;
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, damage:Float, speed:Float, range:Float, sprite:String = null):Void
	{
		revive();
		if (sprite != spriteKey)
		{
			spriteKey = sprite;
			if (sprite == null)
			{
				makeGraphic(12, 12, 0xFF6FBF3F);
				scale.set(1, 1);
			}
			else
			{
				loadGraphic(Paths.image(sprite));
				scale.set(3, 3);
				updateHitbox();
			}
		}
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		this.damage = damage;
		angle = sprite == null ? 0 : Math.atan2(dy, dx) * 180 / Math.PI;
		velocity.set(dx * speed, dy * speed);
		life = range / speed;
	}

	override public function update(elapsed:Float):Void
	{
		elapsed *= WorldClock.scale;
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
			kill();
	}
}
