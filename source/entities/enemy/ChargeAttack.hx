package entities.enemy;

import flixel.FlxG;
import util.Paths;

class ChargeAttack implements AttackBehavior
{
	static inline var CROUCH:Float = 0.35;

	public var windupTime:Float = 0.35;
	public var chargeSpeed:Float = 950;
	public var chargeTime:Float = 0.45;
	public var recoverTime:Float = 0.4;
	public var cooldownTime:Float = 0;
	public var chargeAnim:String = "walk";
	public var lift:Float = 0;

	private var started:Bool = false;
	private var phase:Int = 0;
	private var timer:Float = 0;
	private var flier:Enemies = null;
	private var groundOffY:Float = 0;

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
			util.Sfx.at("enemies/charge", e.x + e.width / 2, e.y + e.height / 2, 0.5);
			if (lift > 0)
			{
				flier = e;
				groundOffY = e.offset.y;
			}
		}
		timer -= elapsed;
		switch (phase)
		{
			case 0:
				crouch();
				if (timer <= 0)
				{
					var len:Float = distance != 0 ? distance : 1;
					e.velocity.set(dirX / len * chargeSpeed, dirY / len * chargeSpeed);
					if (dirX > 0) { e.flipX = false; }
					else if (dirX < 0) { e.flipX = true; }
					e.animation.play(chargeAnim);
					phase = 1;
					timer = chargeTime;
				}
			case 1:
				if (timer <= 0)
				{
					land();
					e.velocity.set(0, 0);
					e.animation.play("idle");
					phase = 2;
					timer = recoverTime;
				}
				else
					arc();
			default:
				if (timer <= 0)
				{
					started = false;
					e.attackCooldown = cooldownTime;
					return true;
				}
		}
		return false;
	}

	function crouch():Void
	{
		if (flier == null)
			return;
		var t = windupTime <= 0 ? 1 : 1 - timer / windupTime;
		if (t < 0)
			t = 0;
		else if (t > 1)
			t = 1;
		flier.offset.y = groundOffY - Math.sin(t * Math.PI) * lift * CROUCH;
	}

	function arc():Void
	{
		if (flier == null)
			return;
		var t = chargeTime <= 0 ? 1 : 1 - timer / chargeTime;
		if (t < 0)
			t = 0;
		else if (t > 1)
			t = 1;
		var high = Math.sin(t * Math.PI) * lift;
		flier.offset.y = groundOffY + high;
		flier.lift = high;
	}

	function land():Void
	{
		if (flier == null)
			return;
		flier.offset.y = groundOffY;
		flier.lift = 0;
		flier = null;
	}

	public function reset():Void
	{
		land();
		started = false;
	}
}
