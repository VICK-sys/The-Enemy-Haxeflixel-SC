package entities;

import flixel.FlxSprite;
import util.Paths;

class RainArrow extends FlxSprite
{
	static inline var ASCEND_FADE:Float = 0.35;

	public var impactY:Float = 0;
	public var ascending:Bool = false;
	public var marker:FlxSprite;

	private var fadeTimer:Float = 0;

	public function new()
	{
		super();
		loadGraphic(Paths.image("items/arrow"));
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
		angle = angleDeg + 90;
		var rad = angleDeg * Math.PI / 180;
		velocity.set(Math.cos(rad) * speed, Math.sin(rad) * speed);
		fadeTimer = ASCEND_FADE;
	}

	public function drop(ix:Float, iy:Float, dropHeight:Float, fallSpeed:Float):Void
	{
		revive();
		ascending = false;
		alpha = 1;
		impactY = iy;
		setPosition(ix - width / 2, iy - dropHeight - height / 2);
		velocity.set(0, fallSpeed);
		angle = 180;
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
	}
}
