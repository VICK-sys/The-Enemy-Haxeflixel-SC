package entities.enemy;

import flixel.FlxG;
import flixel.math.FlxPoint;

enum BrainState
{
	Wandering;
	Following;
	Attacking;
}

class EnemyBrain
{
	static inline var IDLE_DURATION:Float = 3.0;
	static inline var WANDER_DURATION:Float = 2.0;
	public var wanderSpeed:Float = 100;

	private var state:BrainState = Wandering;
	private var wanderCountdown:Float = 0;
	private var idleCountdown:Float = 0;
	private var contactCooldown:Float = 0;
	private var direction:FlxPoint = new FlxPoint(FlxG.random.float() * 2 - 1, FlxG.random.float() * 2 - 1);

	public function new() {}

	public function interrupt():Void
	{
		state = Following;
		wanderCountdown = 0;
		idleCountdown = 0;
	}

	public function update(e:Enemies, elapsed:Float):Void
	{
		if (e.target == null && state != Wandering)
		{
			state = Wandering;
			wanderCountdown = 0;
			idleCountdown = 0;
			e.attack.reset();
		}

		var dirX:Float = 0;
		var dirY:Float = 0;
		var distance:Float = 0;

		if (e.target != null)
		{
			var tmx = e.target.x + e.target.width * 0.5;
			var tmy = e.target.y + e.target.height * 0.5;
			dirX = tmx - (e.x + e.width * 0.5);
			dirY = tmy - (e.y + e.height * 0.5);
			distance = Math.sqrt(dirX * dirX + dirY * dirY);
			e.pathing.tick(elapsed, e.x + e.width * 0.5, e.y + e.height * 0.5, tmx, tmy);
		}

		switch (state)
		{
			case Wandering: updateWandering(e, elapsed, distance);
			case Following: updateFollowing(e, elapsed, dirX, dirY, distance);
			case Attacking:
				if (e.attack.update(e, elapsed, dirX, dirY, distance))
					state = Following;
		}
	}

	function updateWandering(e:Enemies, elapsed:Float, distance:Float):Void
	{
		if (wanderCountdown > 0)
		{
			wanderCountdown -= elapsed;
			if (wanderCountdown <= 0)
			{
				e.velocity.set(0, 0);
				e.animation.play("idle");
				idleCountdown = IDLE_DURATION;
			}
		}
		else if (idleCountdown > 0)
		{
			idleCountdown -= elapsed;
			if (idleCountdown <= 0)
			{
				direction.set(FlxG.random.float() * 2 - 1, FlxG.random.float() * 2 - 1);
				var length = Math.sqrt(direction.x * direction.x + direction.y * direction.y);
				if (length != 0)
				{
					direction.x /= length;
					direction.y /= length;
				}
				beginWander(e);
			}
		}
		else
		{
			beginWander(e);
		}

		if (e.target != null && distance <= e.aggroRange)
		{
			state = Following;
			wanderCountdown = 0;
			idleCountdown = 0;
		}
	}

	function updateFollowing(e:Enemies, elapsed:Float, dirX:Float, dirY:Float, distance:Float):Void
	{
		contactCooldown -= elapsed;
		if (e.wasTouching != NONE && contactCooldown <= 0)
		{
			contactCooldown = 0.15;
			e.pathing.notifyBlocked();
		}

		if (e.attackCooldown <= 0 && distance <= e.attackRange && e.pathing.losClear)
		{
			state = Attacking;
			return;
		}

		if (distance > e.aggroRange)
		{
			state = Wandering;
			return;
		}

		var mvX = dirX;
		var mvY = dirY;
		if (distance != 0)
		{
			mvX /= distance;
			mvY /= distance;
		}
		e.pathing.steer(e.x + e.width * 0.5, e.y + e.height * 0.5, mvX, mvY);

		if (e.pathing.moveX > 0)
			e.flipX = false;
		else if (e.pathing.moveX < 0)
			e.flipX = true;

		if (distance <= e.stopThreshold && e.pathing.losClear)
		{
			e.velocity.set(0, 0);
			e.animation.play("idle");
		}
		else
		{
			e.animation.play("walk");
			var gait = e.gaitScale();
			e.velocity.set(e.pathing.moveX * e.speed * gait, e.pathing.moveY * e.speed * gait);
		}
	}

	function beginWander(e:Enemies):Void
	{
		e.velocity.set(direction.x * wanderSpeed, direction.y * wanderSpeed);

		if (direction.x > 0)
			e.flipX = false;
		else if (direction.x < 0)
			e.flipX = true;

		e.animation.play("walk");
		wanderCountdown = WANDER_DURATION;
	}
}
