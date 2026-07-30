package entities.weapon;

import flixel.FlxSprite;
import entities.enemy.Enemies;
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
	public var damage:Int = 2;
	public var knock:Float = 1;
	public var seek:Enemies = null;

	private var life:Float = 0;
	private var spriteKey:String = null;

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

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, angleDeg:Float, damage:Int, speed:Float, range:Float,
			knock:Float):Void
	{
		revive();
		alpha = 1;
		this.damage = damage;
		this.knock = knock;
		seek = null;
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		velocity.set(dx * speed, dy * speed);
		angle = angleDeg + ART_TURN;
		life = range / speed;
	}

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
