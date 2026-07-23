package entities.weapon;

import flixel.FlxSprite;
import util.Paths;

class SlashEffect extends FlxSprite
{
	static inline var DRIFT:Float = 150;
	static inline var EFFECT_TIME:Float = 0.25;

	private var life:Float = 0;

	public function new()
	{
		super();
		frames = Paths.sparrow("effects/attacks_gfx");
		animation.addByPrefix("slash", "Sword", 12, false);
		antialiasing = false;
		scale.set(4, 4);
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, angleDeg:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		velocity.set(dx * DRIFT, dy * DRIFT);
		angle = angleDeg;
		alpha = 1;
		life = EFFECT_TIME;
		animation.play("slash", true);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		life -= elapsed;
		alpha = life > 0 ? life / EFFECT_TIME : 0;
		if (life <= 0)
			kill();
	}
}
