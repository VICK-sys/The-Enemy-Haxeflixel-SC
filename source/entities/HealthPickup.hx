package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import util.Paths;
import util.WorldClock;

class HealthPickup extends FlxSprite
{
	public static inline var HEAL:Float = 0.5;

	static inline var LIFETIME:Float = 8;
	static inline var SCALE:Float = 4;
	static inline var SHADOW_DROP:Float = 6;
	static inline var BOB_RATE:Float = 4.4;
	static inline var BOB_RISE:Float = 7;
	static inline var SHINE_RATE:Float = 3.1;
	static inline var SHINE_MAX:Float = 95;
	static inline var SHADOW_SHRINK:Float = 0.22;

	public var netId:Int = -1;
	public var puppet:Bool = false;
	public var shadow(default, null):FlxSprite;
	public var mounted:Bool = false;

	private var life:Float = 0;
	private var baseOffY:Float = 0;
	private var shimmer:Float = 0;

	private var scatterX:Float = 0;
	private var scatterY:Float = 0;

	public function new()
	{
		super();
		loadGraphic(util.Outline.graphic("items/hp_battery"));
		antialiasing = false;
		scale.set(SCALE, SCALE);
		updateHitbox();
		baseOffY = offset.y;

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
		var lift = BOB_RISE > 0 ? (offset.y - baseOffY) / BOB_RISE : 0;
		shadow.scale.set(SCALE * (1 - lift * SHADOW_SHRINK), SCALE);
		shadow.updateHitbox();
		shadow.x = x + width * 0.5 - shadow.width * 0.5;
		shadow.y = y + height - shadow.height + SHADOW_DROP;
		shadow.alpha = alpha * (0.85 - lift * 0.25);
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
		var ang = FlxG.random.float(0, Math.PI * 2);
		var kick = FlxG.random.float(140, 260);
		scatterX = Math.cos(ang) * kick;
		scatterY = Math.sin(ang) * kick;
		alpha = 1;
		life = LIFETIME;
		shimmer = FlxG.random.float(0, 6);
		placeShadow();
	}

	override public function update(elapsed:Float):Void
	{
		elapsed *= WorldClock.scale;
		velocity.y = 0;
		if (!puppet && (scatterX != 0 || scatterY != 0))
		{
			x += scatterX * elapsed;
			y += scatterY * elapsed;
			var fade = Math.pow(0.001, elapsed);
			scatterX *= fade;
			scatterY *= fade;
			if (Math.abs(scatterX) + Math.abs(scatterY) < 10)
				scatterX = scatterY = 0;
		}
		super.update(elapsed);
		if (!puppet)
		{
			life -= elapsed;
			if (life <= 0)
			{
				kill();
				return;
			}
			alpha = life < 2 ? (Std.int(life * 8) % 2 == 0 ? 1 : 0.3) : 1;
		}
		shimmer += elapsed;
		offset.y = baseOffY + (Math.sin(shimmer * BOB_RATE) + 1) * 0.5 * BOB_RISE;
		var lit = Std.int((Math.sin(shimmer * SHINE_RATE) + 1) * 0.5 * SHINE_MAX);
		setColorTransform(1, 1, 1, alpha, lit, lit, lit, 0);
		placeShadow();
	}
}
