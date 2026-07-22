package entities;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.FlxG;

enum State {
	Wandering;
	Following;
	Attacking;
}

class Enemies extends FlxSprite
{
	static inline var IDLE_DURATION:Float = 3.0;
	static inline var WANDER_DURATION:Float = 2.0;
	static inline var KNOCKBACK_SPEED:Float = 550;
	static inline var KNOCKBACK_DRAG:Float = 1600;
	static inline var STUN_TIME:Float = 0.3;
	static inline var FLASH_TIME:Float = 0.08;
	static inline var ATTACK_WINDUP:Float = 0.5;
	static inline var ATTACK_STEP:Float = 0.2;

	public var speed:Float = 300;
	public var aggroRange:Float = 200;
	public var stopThreshold:Float = 170;
	public var attackRange:Float = 150;

	private var animations:Array<String> = ["sstart", "sloop", "send"];
	private var currentAnimationIndex:Int = 0;

	private var attackLoopRunning:Bool = false;
	private var attackWindup:Float = 0;
	private var attackStepTimer:Float = 0;
	private var wanderCountdown:Float = 0;
	private var idleCountdown:Float = 0;
	private var wanderSpeed:Float = 100 + FlxG.random.float() * 20;
	private var wanderDirection:FlxPoint = new FlxPoint(FlxG.random.float() * 2 - 1, FlxG.random.float() * 2 - 1);
	private var currentState:State = Wandering;

	public var target:FlxSprite;

	public var hp:Int = 3;
	public var isDead:Bool = false;
	public var stun:Float = 0;
	public var flashTimer:Float = 0;

	public var shadowOffX:Float = 32;
	public var shadowOffXFlip:Float = 22;
	public var shadowOffY:Float = 90;
	public var shadowScaleX:Float = 4;
	public var hitOffX:Float = 15;
	public var hitOffXFlip:Float = 15;
	public var hitOffY:Float = 35;

    public function new(x:Float=0, y:Float=0)
    {
        super(x, y);

		this.antialiasing = false;
		this.width = 75;
		this.scale.set(4, 4);
    }

	public function takeHit(pushX:Float, pushY:Float):Void
	{
		if (isDead)
			return;

		wanderCountdown = 0;
		idleCountdown = 0;
		attackLoopRunning = false;
		attackWindup = 0;
		attackStepTimer = 0;

		hp--;
		flashTimer = FLASH_TIME;
		setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);

		if (hp <= 0)
		{
			isDead = true;
			velocity.set(0, 0);
			drag.set(0, 0);
			this.animation.play("death", true);
			FlxTween.tween(this, {alpha: 0}, 0.6, {startDelay: 1.2, onComplete: function(t:FlxTween) kill()});
		}
		else
		{
			this.animation.play("hurt", true);
			velocity.set(pushX * KNOCKBACK_SPEED, pushY * KNOCKBACK_SPEED);
			drag.set(KNOCKBACK_DRAG, KNOCKBACK_DRAG);
			stun = STUN_TIME;
		}
	}

    override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
				setColorTransform(1, 1, 1, alpha, 0, 0, 0, 0);
		}

		if (isDead)
		{
			velocity.set(0, 0);
			return;
		}

		if (stun > 0)
		{
			stun -= elapsed;
			if (stun <= 0)
			{
				drag.set(0, 0);
				velocity.set(0, 0);
			}
			return;
		}

		if (target == null && currentState != Wandering)
		{
			currentState = Wandering;
			wanderCountdown = 0;
			idleCountdown = 0;
			attackLoopRunning = false;
			attackWindup = 0;
			attackStepTimer = 0;
		}

		var dirX:Float = 0;
		var dirY:Float = 0;
		var distance:Float = 0;
		if (target != null)
		{
			dirX = target.x + target.width * 0.5 - (x + width * 0.5);
			dirY = target.y + target.height * 0.5 - (y + height * 0.5);
			distance = Math.sqrt(dirX * dirX + dirY * dirY);
		}

		switch (currentState)
		{
				case Wandering:
					if (wanderCountdown > 0)
					{
						wanderCountdown -= elapsed;
						if (wanderCountdown <= 0)
						{
							velocity.set(0, 0);
							this.animation.play("idle");
							idleCountdown = IDLE_DURATION;
						}
					}
					else if (idleCountdown > 0)
					{
						idleCountdown -= elapsed;
						if (idleCountdown <= 0)
						{
							wanderDirection.set(FlxG.random.float() * 2 - 1, FlxG.random.float() * 2 - 1);
							var length:Float = Math.sqrt(wanderDirection.x * wanderDirection.x + wanderDirection.y * wanderDirection.y);
							if (length != 0)
							{
								wanderDirection.x /= length;
								wanderDirection.y /= length;
							}
							beginWander();
						}
					}
					else
					{
						beginWander();
					}
					if (target != null && distance <= aggroRange)
					{
						currentState = Following;
						wanderCountdown = 0;
						idleCountdown = 0;
					}
				case Following:
					if (distance <= attackRange)
					{
						currentState = Attacking;
					}
					else if (distance > aggroRange)
					{
						currentState = Wandering;
					}
					else
					{
						if (dirX > 0) { this.flipX = false; }
						else if (dirX < 0) { this.flipX = true; }

						if (distance <= stopThreshold)
						{
							velocity.set(0, 0);
							this.animation.play("idle");
						}
						else
						{
							if (distance != 0)
							{
								dirX /= distance;
								dirY /= distance;
							}
							velocity.set(dirX * speed, dirY * speed);
							this.animation.play("walk");
						}
					}
				case Attacking:
					velocity.set(0, 0);
					if (!attackLoopRunning)
					{
						attackLoopRunning = true;
						currentAnimationIndex = 0;
						attackWindup = ATTACK_WINDUP;
						attackStepTimer = 0;
					}
					if (attackWindup > 0)
					{
						attackWindup -= elapsed;
						if (attackWindup <= 0)
						{
							if (this.animation.getByName("sstart") == null)
								this.animation.play("idle");
							else
								playNextAnimation();
						}
					}
					else if (attackStepTimer > 0)
					{
						attackStepTimer -= elapsed;
						if (attackStepTimer <= 0)
							playNextAnimation();
					}
					if (distance > attackRange)
					{
						currentState = Following;
						attackLoopRunning = false;
						attackWindup = 0;
						attackStepTimer = 0;
					}
		}
	}

	private function beginWander():Void
	{
		velocity.set(wanderDirection.x * wanderSpeed, wanderDirection.y * wanderSpeed);

		if (wanderDirection.x > 0) { this.flipX = false; }
		else if (wanderDirection.x < 0) { this.flipX = true; }

		this.animation.play("walk");
		wanderCountdown = WANDER_DURATION;
	}

	private function playNextAnimation():Void
	{
		if (currentAnimationIndex >= animations.length)
		{
			currentAnimationIndex = 0;
		}

		this.animation.play(animations[currentAnimationIndex]);
		currentAnimationIndex++;
		attackStepTimer = ATTACK_STEP;
	}
}
