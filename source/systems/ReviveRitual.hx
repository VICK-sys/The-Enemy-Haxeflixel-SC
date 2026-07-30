package systems;

import flixel.FlxG;
import util.Paths;

class ReviveRitual
{
	static inline var GATHER_TIME:Float = 0.75;
	static inline var FLASH_TIME:Float = 0.5;
	static inline var FLASH_RATE:Float = 22;
	static inline var PULL:Float = 9;

	public var done(default, null):Bool = true;

	private var burst:DeathBurst;
	private var ghost:CoopGhost;
	private var phase:Int = 0;
	private var timer:Float = 0;

	public function new(burst:DeathBurst, ghost:CoopGhost)
	{
		this.burst = burst;
		this.ghost = ghost;
	}

	public function begin():Void
	{
		if (phase != 0)
			return;
		phase = 1;
		timer = GATHER_TIME;
		done = false;
		FlxG.sound.play(Paths.sound("weapon/catch"), 0.7);
	}

	public function cancel():Void
	{
		phase = 0;
		done = true;
		paint(0);
	}

	public function update(elapsed:Float, cx:Float, cy:Float):Void
	{
		if (phase == 0)
			return;

		if (phase == 1)
		{
			timer -= elapsed;
			gather(elapsed, cx, cy);
			if (timer <= 0)
			{
				phase = 2;
				timer = FLASH_TIME;
			}
			return;
		}

		timer -= elapsed;
		hold(cx, cy);
		paint(Std.int(timer * FLASH_RATE) % 2 == 0 ? 255 : 0);

		if (timer <= 0)
		{
			phase = 0;
			paint(0);
			done = true;
			FlxG.sound.play(Paths.sound("weapon/catch"), 0.9);
		}
	}

	function gather(elapsed:Float, cx:Float, cy:Float):Void
	{
		var k = Math.min(1, PULL * elapsed);
		for (p in burst.group.members)
		{
			if (p == null || !p.exists)
				continue;
			p.velocity.set(0, 0);
			p.drag.set(0, 0);
			p.x += (cx - p.width * 0.5 - p.x) * k;
			p.y += (cy - p.height * 0.5 - p.y) * k;
			p.angularVelocity *= 1 - k;
		}
	}

	function hold(cx:Float, cy:Float):Void
	{
		for (p in burst.group.members)
		{
			if (p == null || !p.exists)
				continue;
			p.velocity.set(0, 0);
			p.angularVelocity = 0;
			p.setPosition(cx - p.width * 0.5, cy - p.height * 0.5);
		}
	}

	function paint(add:Int):Void
	{
		for (p in burst.group.members)
			if (p != null && p.exists)
				p.setColorTransform(1, 1, 1, 1, add, add, add, 0);
		if (ghost.sprite.exists)
			ghost.sprite.setColorTransform(1, 1, 1, 1, add, add, add, 0);
	}
}
