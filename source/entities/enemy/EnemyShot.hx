package entities.enemy;

import flixel.FlxSprite;
import util.Paths;
import util.WorldClock;

class EnemyShot extends FlxSprite
{
	public static inline var DEFAULT_SPRITE:String = "bullets/round_bullet_enemy";
	public static inline var TURNED_SPRITE:String = "bullets/round_bullet_player";

	static inline var ENEMY_TAIL:String = "_enemy";
	static inline var PLAYER_TAIL:String = "_player";

	static inline var ART_TURN:Float = 90;
	static inline var DEFLECT_BOOST:Float = 1.35;
	static inline var DEFLECT_CARRY:Float = 0.4;
	static inline var SCALE:Float = 4;
	static inline var HIT:Float = 28;
	static inline var FADE:Float = 0.1;

	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var damage:Float = 0.25;
	public var friendly:Bool = false;
	public var superTurned:Bool = false;
	public var held:Bool = false;
	public var lastX:Float = 0;
	public var lastY:Float = 0;

	private var life:Float = 0;
	private var spriteKey:String = null;
	private var fullLife:Float = 0;

	public function new()
	{
		super();
		util.PixelPerfectShader.on(this);
		use(DEFAULT_SPRITE);
	}

	static function turnedKey(key:String):String
	{
		if (key == null)
			return TURNED_SPRITE;
		if (StringTools.endsWith(key, ENEMY_TAIL))
			return key.substr(0, key.length - ENEMY_TAIL.length) + PLAYER_TAIL;
		return key;
	}

	function turnArt():Void
	{
		var want = turnedKey(spriteKey);
		if (want != spriteKey)
			use(want);
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
		lastX = cx;
		lastY = cy;
		dirX = dx;
		dirY = dy;
		this.damage = damage;
		friendly = false;
		superTurned = false;
		held = false;
		angle = Math.atan2(dy, dx) * 180 / Math.PI + ART_TURN;
		velocity.set(dx * speed, dy * speed);
		fullLife = range / speed;
		life = fullLife;
	}

	public function deflect(aimX:Float, aimY:Float, fromSuper:Bool = false):Void
	{
		superTurned = fromSuper;
		var speed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y) * DEFLECT_BOOST;
		var nx = aimX + dirX * DEFLECT_CARRY;
		var ny = aimY + dirY * DEFLECT_CARRY;
		var len = Math.sqrt(nx * nx + ny * ny);
		if (len < 0.001)
		{
			nx = -dirX;
			ny = -dirY;
			len = 1;
		}
		dirX = nx / len;
		dirY = ny / len;
		velocity.set(dirX * speed, dirY * speed);
		angle = Math.atan2(dirY, dirX) * 180 / Math.PI + ART_TURN;
		life = fullLife;
		alpha = 1;
		friendly = true;
		turnArt();
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
		angle = Math.atan2(dy, dx) * 180 / Math.PI + ART_TURN;
		life = fullLife;
		alpha = 1;
		friendly = true;
		turnArt();
	}

	override public function update(elapsed:Float):Void
	{
		if (held)
			return;
		lastX = x + width / 2;
		lastY = y + height / 2;
		elapsed *= WorldClock.scale;
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
			kill();
		else if (life < FADE)
			alpha = life / FADE;
	}
}
