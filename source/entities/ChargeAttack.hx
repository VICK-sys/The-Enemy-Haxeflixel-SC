package entities;

class ChargeAttack implements AttackBehavior
{
	static inline var WINDUP:Float = 0.35;
	static inline var SPEED:Float = 950;
	static inline var TIME:Float = 0.45;
	static inline var RECOVER:Float = 0.4;

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
			timer = WINDUP;
			e.velocity.set(0, 0);
			if (dirX > 0) { e.flipX = false; }
			else if (dirX < 0) { e.flipX = true; }
			e.animation.play("idle");
		}
		timer -= elapsed;
		switch (phase)
		{
			case 0:
				if (timer <= 0)
				{
					var len:Float = distance != 0 ? distance : 1;
					e.velocity.set(dirX / len * SPEED, dirY / len * SPEED);
					if (dirX > 0) { e.flipX = false; }
					else if (dirX < 0) { e.flipX = true; }
					e.animation.play("walk");
					phase = 1;
					timer = TIME;
				}
			case 1:
				if (timer <= 0)
				{
					e.velocity.set(0, 0);
					e.animation.play("idle");
					phase = 2;
					timer = RECOVER;
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
