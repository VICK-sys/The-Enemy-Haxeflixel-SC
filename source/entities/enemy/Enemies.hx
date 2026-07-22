package entities.enemy;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import util.Paths;
import data.EnemyData.EnemyDataRegistry;

enum State {
	Wandering;
	Following;
	Attacking;
}

class Enemies extends FlxSprite
{
	static inline var IDLE_DURATION:Float = 3.0;
	static inline var WANDER_DURATION:Float = 2.0;
	static inline var FLASH_TIME:Float = 0.08;

	public var speed:Float = 300;
	public var aggroRange:Float = 200;
	public var stopThreshold:Float = 170;
	public var attackRange:Float = 150;
	public var contactDamage:Float = 0.25;
	public var shotDamage:Float = 0.25;
	public var shotSpeed:Float = 480;
	public var shotRange:Float = 640;
	public var dropChance:Float = 0;
	public var knockbackTaken:Float = 550;
	public var knockbackDrag:Float = 1600;
	public var stunTime:Float = 0.3;

	public var target:FlxSprite;
	public var entering:Bool = false;
	public var pathing:EnemyNav = new EnemyNav();
	public var attack:AttackBehavior = new ChargeAttack();
	public var shootRequested:Bool = false;

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

	private var wanderCountdown:Float = 0;
	private var idleCountdown:Float = 0;
	private var wanderSpeed:Float = 0;
	private var wanderDirection:FlxPoint = new FlxPoint(FlxG.random.float() * 2 - 1, FlxG.random.float() * 2 - 1);
	private var currentState:State = Wandering;

    public function new(kind:String, x:Float=0, y:Float=0)
    {
        super(x, y);

		this.antialiasing = false;
		this.scale.set(4, 4);

		var data = EnemyDataRegistry.get(kind);
		this.frames = Paths.sparrow(data.sprite);
		for (a in data.animations)
			this.animation.addByPrefix(a.name, a.prefix, a.fps, a.loop);
		this.width = data.width;
		this.height = data.height;
		this.offset.set(data.offsetX, data.offsetY);
		pathing.bodyRadius = data.width * 0.6;

		hp = data.hp;
		speed = data.speed;
		aggroRange = data.aggroRange;
		stopThreshold = data.stopThreshold;
		attackRange = data.attackRange;
		contactDamage = data.contactDamage;
		shotDamage = data.shotDamage != null ? data.shotDamage : 0.25;
		if (data.shotSpeed != null) shotSpeed = data.shotSpeed;
		if (data.shotRange != null) shotRange = data.shotRange;
		dropChance = data.dropChance;
		if (data.knockback != null) knockbackTaken = data.knockback;
		if (data.knockbackDrag != null) knockbackDrag = data.knockbackDrag;
		if (data.stunTime != null) stunTime = data.stunTime;
		wanderSpeed = (data.wanderSpeed != null ? data.wanderSpeed : 100) + FlxG.random.float() * 20;

		if (data.attack == "shoot")
		{
			var shoot = new ShootAttack();
			if (data.shootWindup != null) shoot.windupTime = data.shootWindup;
			if (data.shootStep != null) shoot.stepTime = data.shootStep;
			if (data.shootGap != null) shoot.gapTime = data.shootGap;
			if (data.shootDisengage != null) shoot.disengageSlack = data.shootDisengage;
			attack = shoot;
		}
		else
		{
			var charge = new ChargeAttack();
			if (data.chargeWindup != null) charge.windupTime = data.chargeWindup;
			if (data.chargeSpeed != null) charge.chargeSpeed = data.chargeSpeed;
			if (data.chargeTime != null) charge.chargeTime = data.chargeTime;
			if (data.chargeRecover != null) charge.recoverTime = data.chargeRecover;
			attack = charge;
		}

		shadowOffX = data.shadowOffX;
		shadowOffXFlip = data.shadowOffXFlip;
		shadowOffY = data.shadowOffY;
		shadowScaleX = data.shadowScaleX;
		hitOffX = data.hitOffX;
		hitOffXFlip = data.hitOffXFlip;
		hitOffY = data.hitOffY;
    }

	public function takeHit(pushX:Float, pushY:Float):Void
	{
		if (isDead)
			return;

		wanderCountdown = 0;
		idleCountdown = 0;
		attack.reset();

		hp--;
		flashTimer = FLASH_TIME;
		setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);

		if (hp <= 0)
		{
			isDead = true;
			velocity.set(0, 0);
			drag.set(0, 0);
			pathing.clear();
			this.animation.play("death", true);
			FlxTween.tween(this, {alpha: 0}, 0.6, {startDelay: 1.2, onComplete: function(t:FlxTween) kill()});
		}
		else
		{
			this.animation.play("hurt", true);
			velocity.set(pushX * knockbackTaken, pushY * knockbackTaken);
			drag.set(knockbackDrag, knockbackDrag);
			stun = stunTime;
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

		if (entering)
		{
			if (target != null)
			{
				var ex:Float = target.x + target.width * 0.5 - (x + width * 0.5);
				var ey:Float = target.y + target.height * 0.5 - (y + height * 0.5);
				var el:Float = Math.sqrt(ex * ex + ey * ey);
				if (el > 0)
					velocity.set(ex / el * speed, ey / el * speed);
				flipX = ex < 0;
				this.animation.play("walk");
			}
			else
			{
				velocity.set(0, 0);
			}
			return;
		}

		if (target == null && currentState != Wandering)
		{
			currentState = Wandering;
			wanderCountdown = 0;
			idleCountdown = 0;
			attack.reset();
		}

		var dirX:Float = 0;
		var dirY:Float = 0;
		var distance:Float = 0;
		if (target != null)
		{
			var tmx:Float = target.x + target.width * 0.5;
			var tmy:Float = target.y + target.height * 0.5;
			dirX = tmx - (x + width * 0.5);
			dirY = tmy - (y + height * 0.5);
			distance = Math.sqrt(dirX * dirX + dirY * dirY);

			pathing.tick(elapsed, x + width * 0.5, y + height * 0.5, tmx, tmy);
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
					if (wasTouching != NONE)
						pathing.notifyBlocked();
					if (distance <= attackRange && pathing.losClear)
					{
						currentState = Attacking;
					}
					else if (distance > aggroRange)
					{
						currentState = Wandering;
					}
					else
					{
						var mvX:Float = dirX;
						var mvY:Float = dirY;
						if (distance != 0)
						{
							mvX /= distance;
							mvY /= distance;
						}
						pathing.steer(x + width * 0.5, y + height * 0.5, mvX, mvY);

						if (pathing.moveX > 0) { this.flipX = false; }
						else if (pathing.moveX < 0) { this.flipX = true; }

						if (distance <= stopThreshold && pathing.losClear)
						{
							velocity.set(0, 0);
							this.animation.play("idle");
						}
						else
						{
							velocity.set(pathing.moveX * speed, pathing.moveY * speed);
							this.animation.play("walk");
						}
					}
				case Attacking:
					if (attack.update(this, elapsed, dirX, dirY, distance))
						currentState = Following;
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

	override public function destroy():Void
	{
		pathing.clear();
		super.destroy();
	}
}
