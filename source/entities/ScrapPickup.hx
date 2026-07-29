package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import util.Paths;
import util.WorldClock;

class ScrapPickup extends FlxSprite
{
	public static inline var SCALE:Float = 4;

	static inline var LIFETIME:Float = 14;
	static inline var BLINK_AT:Float = 3;
	static inline var SPREAD:Float = 26;
	static inline var BOB_RATE:Float = 4.5;
	static inline var BOB_AMP:Float = 3;
	static inline var VARIANTS:Int = 5;
	static inline var SHADOW_LIFT:Float = 6;

	public var shadow(default, null):FlxSprite;
	public var mounted:Bool = false;

	private var life:Float = 0;
	private var bob:Float = 0;
	private var restY:Float = 0;
	private var scatterX:Float = 0;
	private var scatterY:Float = 0;

	public function new()
	{
		super();
		wear(1);

		shadow = new FlxSprite();
		shadow.loadGraphic(Paths.image("items/shadow_small"));
		shadow.antialiasing = false;
		shadow.scale.set(SCALE, SCALE);
		shadow.updateHitbox();
		shadow.moves = false;
		shadow.visible = false;
	}

	function wear(n:Int):Void
	{
		loadGraphic(Paths.image("items/scrap" + n));
		antialiasing = false;
		scale.set(SCALE, SCALE);
		updateHitbox();
	}

	public function drop(cx:Float, cy:Float):Void
	{
		revive();
		wear(FlxG.random.int(1, VARIANTS));
		velocity.set(0, 0);
		var ox = FlxG.random.float(-SPREAD, SPREAD);
		var oy = FlxG.random.float(-SPREAD, SPREAD);
		setPosition(cx + ox - width / 2, cy + oy - height / 2);
		restY = y;
		bob = FlxG.random.float(0, Math.PI * 2);
		var ang = FlxG.random.float(0, Math.PI * 2);
		var kick = FlxG.random.float(140, 260);
		scatterX = Math.cos(ang) * kick;
		scatterY = Math.sin(ang) * kick;
		alpha = 1;
		life = LIFETIME;
		placeShadow();
	}

	public function pullTo(px:Float, py:Float, speed:Float, elapsed:Float):Void
	{
		var dx = px - (x + width / 2);
		var dy = py - (y + height / 2);
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len <= 0)
			return;
		var step = speed * elapsed;
		if (step > len)
			step = len;
		x += dx / len * step;
		restY += dy / len * step;
		y = restY + Math.sin(bob) * BOB_AMP;
	}

	function placeShadow():Void
	{
		shadow.visible = exists && alive;
		if (!shadow.visible)
			return;
		shadow.x = x + width * 0.5 - shadow.width * 0.5;
		shadow.y = restY + height - shadow.height + SHADOW_LIFT;
		shadow.alpha = alpha * 0.85;
	}

	override public function kill():Void
	{
		shadow.visible = false;
		super.kill();
	}

	override public function update(elapsed:Float):Void
	{
		elapsed *= WorldClock.scale;
		velocity.y = 0;
		if (scatterX != 0 || scatterY != 0)
		{
			x += scatterX * elapsed;
			restY += scatterY * elapsed;
			var fade = Math.pow(0.001, elapsed);
			scatterX *= fade;
			scatterY *= fade;
			if (Math.abs(scatterX) + Math.abs(scatterY) < 10)
				scatterX = scatterY = 0;
		}
		bob += BOB_RATE * elapsed;
		y = restY + Math.sin(bob) * BOB_AMP;
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
		{
			kill();
			return;
		}
		alpha = life < BLINK_AT ? (Std.int(life * 8) % 2 == 0 ? 1 : 0.3) : 1;
		placeShadow();
	}
}
