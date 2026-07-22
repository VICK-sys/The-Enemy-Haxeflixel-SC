package entities;

import flixel.FlxSprite;

class HealthPickup extends FlxSprite
{
	public static inline var HEAL:Float = 0.5;

	static inline var LIFETIME:Float = 8;

	private var life:Float = 0;

	public function new()
	{
		super();
		makeGraphic(12, 12, 0xFFE04848);
		antialiasing = false;
	}

	public function drop(cx:Float, cy:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		alpha = 1;
		life = LIFETIME;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
		{
			kill();
			return;
		}
		alpha = life < 2 ? (Std.int(life * 8) % 2 == 0 ? 1 : 0.3) : 1;
	}
}
