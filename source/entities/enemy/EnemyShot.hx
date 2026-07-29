package entities.enemy;

import flixel.FlxSprite;
import util.Paths;
import util.WorldClock;

class EnemyShot extends FlxSprite
{
	public static inline var DEFAULT_SPRITE:String = "bullets/bullet_enemy";
	public static inline var TURNED_SPRITE:String = "bullets/bullet_player";

	static inline var DEFLECT_BOOST:Float = 1.35;
	static inline var SCALE:Float = 4;
	static inline var HIT:Float = 48;
	static inline var FADE:Float = 0.1;

	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var damage:Float = 0.25;
	public var friendly:Bool = false;
	public var held:Bool = false;

	private var life:Float = 0;
	private var spriteKey:String = null;
	private var fullLife:Float = 0;

	public function new()
	{
		super();
		antialiasing = false;
		use(DEFAULT_SPRITE);
	}

	function use(key:String):Void
	{
		spriteKey = key;
		loadGraphic(Paths.image(key));
		scale.set(SCALE, SCALE);
		updateHitbox();
		setSize(HIT, HIT);
		centerOffsets();
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, damage:Float, speed:Float, range:Float, sprite:String = null):Void
	{
		revive();
		alpha = 1;
		var want = sprite == null ? DEFAULT_SPRITE : sprite;
		if (want != spriteKey)
			use(want);
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		this.damage = damage;
		friendly = false;
		held = false;
		angle = Math.atan2(dy, dx) * 180 / Math.PI;
		velocity.set(dx * speed, dy * speed);
		fullLife = range / speed;
		life = fullLife;
	}

	public function deflect():Void
	{
		dirX = -dirX;
		dirY = -dirY;
		velocity.set(-velocity.x * DEFLECT_BOOST, -velocity.y * DEFLECT_BOOST);
		angle = Math.atan2(dirY, dirX) * 180 / Math.PI;
		life = fullLife;
		alpha = 1;
		friendly = true;
		use(TURNED_SPRITE);
	}

	public function seize():Void
	{
		held = true;
		velocity.set(0, 0);
	}

	public function hurl(dx:Float, dy:Float, speed:Float):Void
	{
		held = false;
		dirX = dx;
		dirY = dy;
		velocity.set(dx * speed, dy * speed);
		angle = Math.atan2(dy, dx) * 180 / Math.PI;
		life = fullLife;
		alpha = 1;
		friendly = true;
		use(TURNED_SPRITE);
	}

	override public function update(elapsed:Float):Void
	{
		if (held)
			return;
		elapsed *= WorldClock.scale;
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
			kill();
		else if (life < FADE)
			alpha = life / FADE;
	}
}
