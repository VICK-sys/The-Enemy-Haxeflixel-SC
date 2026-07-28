package entities;

import flixel.FlxSprite;
import util.Paths;
import util.WorldClock;

class HealthPickup extends FlxSprite
{
	public static inline var HEAL:Float = 0.5;

	static inline var LIFETIME:Float = 8;
	static inline var SCALE:Float = 4;
	static inline var SHADOW_DROP:Float = 6;

	public var netId:Int = -1;
	public var shadow(default, null):FlxSprite;
	public var mounted:Bool = false;

	private var life:Float = 0;

	public function new()
	{
		super();
		loadGraphic(Paths.image("items/hp_battery"));
		antialiasing = false;
		scale.set(SCALE, SCALE);
		updateHitbox();

		shadow = new FlxSprite();
		shadow.loadGraphic(Paths.image("items/shadow_small"));
		shadow.antialiasing = false;
		shadow.scale.set(SCALE, SCALE);
		shadow.updateHitbox();
		shadow.moves = false;
		shadow.visible = false;
	}

	function placeShadow():Void
	{
		shadow.visible = exists && alive;
		if (!shadow.visible)
			return;
		shadow.x = x + width * 0.5 - shadow.width * 0.5;
		shadow.y = y + height - shadow.height + SHADOW_DROP;
		shadow.alpha = alpha * 0.85;
	}

	override public function kill():Void
	{
		shadow.visible = false;
		super.kill();
	}

	public function drop(cx:Float, cy:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		alpha = 1;
		life = LIFETIME;
		placeShadow();
	}

	override public function update(elapsed:Float):Void
	{
		elapsed *= WorldClock.scale;
		velocity.y = 0;
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
		{
			kill();
			return;
		}
		alpha = life < 2 ? (Std.int(life * 8) % 2 == 0 ? 1 : 0.3) : 1;
		placeShadow();
	}
}
