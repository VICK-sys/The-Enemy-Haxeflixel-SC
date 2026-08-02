package entities.weapon;

import flixel.FlxSprite;
import util.Paths;

class Bullet extends FlxSprite
{
	public static inline var SHOT:String = "bullets/normal_bullet_player";

	static inline var ART_TURN:Float = 90;
	static inline var SCALE:Float = 4;
	static inline var HIT:Float = 48;
	static inline var FADE:Float = 0.1;

	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var damage:Float = 2;
	public var knock:Float = 1;
	public var hitR:Float = 48;
	public var fromSuper:Bool = false;
	public var hitsLeft:Int = 1;
	public var pierces:Bool = false;

	private var life:Float = 0;
	private var spriteKey:String = null;
	private var struck:Array<entities.enemy.Enemies> = [];

	public function new()
	{
		super();
		antialiasing = false;
		setSprite(SHOT);
	}

	public function setSprite(key:String):Void
	{
		if (key == spriteKey)
			return;
		spriteKey = key;
		loadGraphic(Paths.image(key));
		scale.set(SCALE, SCALE);
		updateHitbox();
		setSize(HIT, HIT);
		centerOffsets();
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, angleDeg:Float, damage:Float, speed:Float, range:Float,
			knock:Float, hitRadius:Float = 48, targets:Int = 1):Void
	{
		revive();
		alpha = 1;
		this.damage = damage;
		this.knock = knock;
		hitR = hitRadius;
		fromSuper = false;
		hitsLeft = targets < 1 ? 1 : targets;
		pierces = hitsLeft > 1;
		struck.resize(0);
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		velocity.set(dx * speed, dy * speed);
		angle = angleDeg + ART_TURN;
		life = range / speed;
	}

	public function hasStruck(e:entities.enemy.Enemies):Bool
		return struck.indexOf(e) >= 0;

	public function markStruck(e:entities.enemy.Enemies):Void
		struck.push(e);

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
			kill();
		else if (life < FADE)
			alpha = life / FADE;
	}
}
