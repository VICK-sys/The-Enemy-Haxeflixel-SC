package entities;

import flixel.FlxG;
import util.Paths;

class ChargeAttack implements AttackBehavior
{
	public var windupTime:Float = 0.35;
	public var chargeSpeed:Float = 950;
	public var chargeTime:Float = 0.45;
	public var recoverTime:Float = 0.4;

	private var started:Bool = false;
	private var phase:Int = 0;
	private var timer:Float = 0;

	public function new() {}

	public function update(e:Enemies, elapsed:Float, dirX:Float, dirY:Float, distance:Float):Bool
	{
		if (!started)
		{
			started = true;
			phase = 0;
			timer = windupTime;
			e.velocity.set(0, 0);
			if (dirX > 0) { e.flipX = false; }
			else if (dirX < 0) { e.flipX = true; }
			e.animation.play("idle");
			FlxG.sound.play(Paths.sound("enemies/charge"), 0.5);
		}
		timer -= elapsed;
		switch (phase)
		{
			case 0:
				if (timer <= 0)
				{
					var len:Float = distance != 0 ? distance : 1;
					e.velocity.set(dirX / len * chargeSpeed, dirY / len * chargeSpeed);
					if (dirX > 0) { e.flipX = false; }
					else if (dirX < 0) { e.flipX = true; }
					e.animation.play("walk");
					phase = 1;
					timer = chargeTime;
				}
			case 1:
				if (timer <= 0)
				{
					e.velocity.set(0, 0);
					e.animation.play("idle");
					phase = 2;
					timer = recoverTime;
				}
			default:
				if (timer <= 0)
				{
					started = false;
					return true;
				}
		}
		return false;
	}

	public function reset():Void
	{
		started = false;
	}
}
