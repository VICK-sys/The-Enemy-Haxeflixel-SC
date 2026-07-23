package entities.enemy;

class ShootAttack implements AttackBehavior
{
	public var windupTime:Float = 0.5;
	public var stepTime:Float = 0.2;
	public var gapTime:Float = 1.2;
	public var disengageSlack:Float = 120;

	private var animations:Array<String> = ["sstart", "sloop", "send"];
	private var started:Bool = false;
	private var windup:Float = 0;
	private var stepTimer:Float = 0;
	private var animIndex:Int = 0;
	private var pendingFire:Bool = false;

	public function new() {}

	public function update(e:Enemies, elapsed:Float, dirX:Float, dirY:Float, distance:Float):Bool
	{
		e.velocity.set(0, 0);
		if (dirX > 0) { e.flipX = false; }
		else if (dirX < 0) { e.flipX = true; }

		if (pendingFire)
		{
			pendingFire = false;
			var d = distance > 0 ? distance : 1;
			e.requestShot(dirX / d, dirY / d, e.shotDamage, e.shotSpeed, e.shotRange, e.shotSprite,
				e.shotSound != null ? e.shotSound : "enemies/shoot");
		}
		if (!started)
		{
			started = true;
			animIndex = 0;
			windup = windupTime;
			stepTimer = 0;
			e.animation.play("idle");
		}
		if (windup > 0)
		{
			windup -= elapsed;
			if (windup <= 0)
			{
				if (e.animation.getByName("sstart") == null)
					e.animation.play("idle");
				else
					playNext(e);
			}
		}
		else if (stepTimer > 0)
		{
			stepTimer -= elapsed;
			if (stepTimer <= 0)
				playNext(e);
		}
		if (distance > e.attackRange + disengageSlack || !e.pathing.losClear)
		{
			started = false;
			return true;
		}
		return false;
	}

	public function reset():Void
	{
		started = false;
	}

	function playNext(e:Enemies):Void
	{
		if (animIndex >= animations.length)
			animIndex = 0;
		var name = animations[animIndex];
		e.animation.play(name);
		if (name == "sloop")
			pendingFire = true;
		animIndex++;
		stepTimer = animIndex >= animations.length ? gapTime : stepTime;
	}
}
