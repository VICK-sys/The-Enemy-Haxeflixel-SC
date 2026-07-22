package entities;

import flixel.FlxObject;
import flixel.FlxSprite;
import util.Paths;

class SlashProjectile extends FlxSprite
{
	public static inline var RADIUS:Float = 125;

	static inline var SPEED:Float = 1100;
	static inline var RANGE:Float = 420;
	static inline var FADE_TIME:Float = 0.12;
	static inline var HITBOX:Float = 250;

	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var fading:Bool = false;

	private var life:Float = 0;
	private var hitList:Array<FlxObject> = [];

	public function new()
	{
		super();
		frames = Paths.sparrow("effects/attacks_gfx");
		animation.addByPrefix("slash", "Sword", 12, false);
		antialiasing = false;
		scale.set(4, 4);
		setSize(HITBOX, HITBOX);
		centerOffsets();
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, angleDeg:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		dirX = dx;
		dirY = dy;
		velocity.set(dx * SPEED, dy * SPEED);
		angle = angleDeg;
		alpha = 1;
		fading = false;
		life = RANGE / SPEED;
		hitList.resize(0);
		animation.play("slash", true);
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

		if (!fading)
		{
			life -= elapsed;
			if (life <= 0)
				fading = true;
		}
		else
		{
			alpha -= elapsed / FADE_TIME;
			if (alpha <= 0)
				kill();
		}
	}
}
