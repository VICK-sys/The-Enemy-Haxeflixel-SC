package entities.weapon;

import flixel.FlxObject;
import flixel.FlxSprite;
import util.Paths;

class Arrow extends FlxSprite
{
	public static inline var RADIUS:Float = 30;

	static inline var SPEED:Float = 1800;
	static inline var RANGE:Float = 99999;
	static inline var FADE:Float = 0.1;

	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var damage:Float = 1;
	public var knock:Float = 1;
	public var piercing:Bool = false;
	public var crit:Bool = false;

	private var life:Float = 0;
	private var hitList:Array<FlxObject> = [];

	public static inline var NORMAL:String = "bullets/arrow";
	public static inline var PERFECT:String = "bullets/perfect_arrow";

	public var hue(default, null):Float = 0;

	private var skin:String = NORMAL;

	public function paint(h:Float, perfect:Bool = false):Void
	{
		var want = perfect ? PERFECT : NORMAL;
		if (h == hue && want == skin)
			return;
		hue = h;
		skin = want;
		loadGraphic(util.HuePalette.graphic(want, h));
	}

	public function new()
	{
		super();
		loadGraphic(Paths.image(NORMAL));
		antialiasing = false;
		scale.set(4, 4);
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, angleDeg:Float, damage:Float = 1, speedMult:Float = 1,
			sizeMult:Float = 1, knock:Float = 1):Void
	{
		revive();
		alpha = 1;
		this.damage = damage;
		this.knock = knock;
		piercing = false;
		hitList.resize(0);
		scale.set(4 * sizeMult, 4 * sizeMult);
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		var speed = SPEED * speedMult;
		velocity.set(dx * speed, dy * speed);
		angle = angleDeg;
		life = RANGE / speed;
	}

	public function hasHit(e:FlxObject):Bool
	{
		return hitList.indexOf(e) >= 0;
	}

	public function markHit(e:FlxObject):Void
	{
		hitList.push(e);
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
