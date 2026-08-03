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
		animation.addByPrefix("sword", "Sword", 12, false);
		animation.addByPrefix("spear", "Spear", 12, false);
		animation.addByPrefix("dagger", "Dagger", 12, false);
		antialiasing = false;
		scale.set(4, 4);
	}

	public function fire(cx:Float, cy:Float, dx:Float, dy:Float, angleDeg:Float, size:Float = 1, kind:String = "sword"):Void
	{
		revive();
		scale.set(4 * size, 4 * size);
		setPosition(cx - width / 2, cy - height / 2);
		velocity.set(dx * DRIFT, dy * DRIFT);
		angle = angleDeg;
		alpha = 1;
		life = EFFECT_TIME;
		animation.play(animation.getByName(kind) != null ? kind : "sword", true);
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
