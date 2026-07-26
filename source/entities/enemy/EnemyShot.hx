package entities.enemy;

import flixel.FlxSprite;
import util.Paths;
import util.WorldClock;

class EnemyShot extends FlxSprite
{
	static inline var DEFLECT_BOOST:Float = 1.35;

	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var damage:Float = 0.25;
	public var friendly:Bool = false;

	private var life:Float = 0;
	private var spriteKey:String = null;
	private var fullLife:Float = 0;

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
		friendly = false;
		setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		angle = sprite == null ? 0 : Math.atan2(dy, dx) * 180 / Math.PI;
		velocity.set(dx * speed, dy * speed);
		fullLife = range / speed;
		life = fullLife;
	}

	public function deflect():Void
	{
		dirX = -dirX;
		dirY = -dirY;
		velocity.set(-velocity.x * DEFLECT_BOOST, -velocity.y * DEFLECT_BOOST);
		if (spriteKey != null)
			angle = Math.atan2(dirY, dirX) * 180 / Math.PI;
		life = fullLife;
		friendly = true;
		setColorTransform(1, 1, 1, 1, 0, 90, 150, 0);
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
