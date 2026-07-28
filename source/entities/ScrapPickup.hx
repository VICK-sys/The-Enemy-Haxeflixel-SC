package entities;

import flixel.FlxSprite;
import util.Paths;
import util.WorldClock;
import util.SideView;

class ScrapPickup extends FlxSprite
{
	public static inline var SCALE:Float = 4;

	static inline var LIFETIME:Float = 14;
	static inline var BLINK_AT:Float = 3;
	static inline var SPREAD:Float = 26;
	static inline var BOB_RATE:Float = 4.5;
	static inline var BOB_AMP:Float = 3;

	private var life:Float = 0;
	private var bob:Float = 0;
	private var restY:Float = 0;
	private var prevBottom:Float = 0;

	public function new()
	{
		super();
		loadGraphic(Paths.image("items/scrap"));
		antialiasing = false;
		scale.set(SCALE, SCALE);
		updateHitbox();
	}

	public function drop(cx:Float, cy:Float):Void
	{
		revive();
		var ox = flixel.FlxG.random.float(-SPREAD, SPREAD);
		var oy = flixel.FlxG.random.float(-SPREAD, SPREAD);
		setPosition(cx + ox - width / 2, cy + oy - height / 2);
		restY = y;
		bob = flixel.FlxG.random.float(0, Math.PI * 2);
		alpha = 1;
		life = LIFETIME;
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
		y += dy / len * step;
		restY = y;
	}

	override public function update(elapsed:Float):Void
	{
		elapsed *= WorldClock.scale;
		if (SideView.active && !SideView.morphing)
			SideView.settle(this, prevBottom, elapsed);
		else
		{
			velocity.y = 0;
			bob += BOB_RATE * elapsed;
			y = restY + Math.sin(bob) * BOB_AMP;
		}
		prevBottom = y + height;
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
		{
			kill();
			return;
		}
		alpha = life < BLINK_AT ? (Std.int(life * 8) % 2 == 0 ? 1 : 0.3) : 1;
	}
}
