package entities.weapon;

import flixel.FlxSprite;
import util.Paths;

class RainArrow extends FlxSprite
{
	static inline var ASCEND_FADE:Float = 0.35;
	static inline var DROP_FADE_PART:Float = 0.45;

	public var impactY:Float = 0;
	public var ascending:Bool = false;
	public var marker:FlxSprite;

	private var fadeTimer:Float = 0;
	private var fadeFromY:Float = 0;
	private var fadeSpan:Float = 1;

	public function new()
	{
		super();
		loadGraphic(Paths.image("bullets/arrow"));
		antialiasing = false;
		scale.set(4, 4);
	}

	public function launchUp(cx:Float, cy:Float, angleDeg:Float, speed:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		ascending = true;
		marker = null;
		alpha = 1;
		angle = angleDeg;
		var rad = angleDeg * Math.PI / 180;
		velocity.set(Math.cos(rad) * speed, Math.sin(rad) * speed);
		fadeTimer = ASCEND_FADE;
	}

	public function drop(ix:Float, iy:Float, dropHeight:Float, fallSpeed:Float):Void
	{
		revive();
		ascending = false;
		alpha = 0;
		impactY = iy;
		setPosition(ix - width / 2, iy - dropHeight - height / 2);
		velocity.set(0, fallSpeed);
		angle = 90;
		fadeFromY = y;
		fadeSpan = dropHeight * DROP_FADE_PART;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (ascending)
		{
			fadeTimer -= elapsed;
			alpha = fadeTimer > 0 ? fadeTimer / ASCEND_FADE : 0;
			if (fadeTimer <= 0)
				kill();
		}
		else if (alpha < 1)
		{
			var fallen = y - fadeFromY;
			alpha = fallen <= 0 ? 0 : (fallen >= fadeSpan ? 1 : fallen / fadeSpan);
		}
	}
}
