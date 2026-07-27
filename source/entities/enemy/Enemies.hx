package entities.enemy;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import util.Paths;
import util.WorldClock;
import util.SideView;
import data.EnemyData.EnemyDataRegistry;

class Enemies extends FlxSprite
{
	static inline var FLASH_TIME:Float = 0.08;

	public var speed:Float = 300;
	public var aggroRange:Float = 200;
	public var stopThreshold:Float = 170;
	public var attackRange:Float = 150;
	public var contactDamage:Float = 0.25;
	public var shotDamage:Float = 0.25;
	public var shotSpeed:Float = 480;
	public var shotRange:Float = 640;
	public var shotSprite:String = null;
	public var shotSound:String = null;
	public var dropChance:Float = 0;
	public var knockbackTaken:Float = 550;
	public var knockbackDrag:Float = 1600;
	public var stunTime:Float = 0.3;

	public var target:FlxSprite;
	public var kind(default, null):String;
	public var puppet:Bool = false;
	public var netId:Int = -1;
	public var entering:Bool = false;
	public var seized:Bool = false;
	public var throwGrace:Float = 0;
	public var selfDriven:Bool = false;
	public var grabbable:Bool = true;
	public var explodes:Bool = false;
	public var gun:FlxSprite = null;
	public var pathing:EnemyNav = new EnemyNav();
	public var attack:AttackBehavior = new ChargeAttack();
	public var pendingShots:Array<ShotSpec> = [];

	private var shotPool:Array<ShotSpec> = [];

	public var hp:Int = 3;
	public var isDead:Bool = false;
	public var stun:Float = 0;
	public var flashTimer:Float = 0;

	public var shadowOffX:Float = 32;
	public var shadowOffXFlip:Float = 22;
	public var shadowOffY:Float = 90;

	public function applyScale(hpMult:Float, speedMult:Float, damageMult:Float):Void
	{
		hp = Math.round(hp * hpMult);
		if (hp < 1)
			hp = 1;
		speed *= speedMult;
		contactDamage *= damageMult;
		shotDamage *= damageMult;
	}

	public var feetY(get, never):Float;

	function get_feetY():Float
		return y + shadowOffY;

	public var shadowScaleX:Float = 4;
	public var hitOffX:Float = 15;
	public var hitOffXFlip:Float = 15;
	public var hitOffY:Float = 35;

	private var brain:EnemyBrain = new EnemyBrain();

	private var sideStepper:EnemySideStep = new EnemySideStep();
	private var prevBottom:Float = 0;

    public function new(kind:String, x:Float=0, y:Float=0)
    {
        super(x, y);
		this.kind = kind;

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
		shotSprite = data.shotSprite;
		shotSound = data.shotSound;
		dropChance = data.dropChance;
		if (data.knockback != null) knockbackTaken = data.knockback;
		if (data.knockbackDrag != null) knockbackDrag = data.knockbackDrag;
		if (data.stunTime != null) stunTime = data.stunTime;
		brain.wanderSpeed = (data.wanderSpeed != null ? data.wanderSpeed : 100) + FlxG.random.float() * 20;

		if (data.attack == "boss")
		{
			gun = new FlxSprite();
			gun.antialiasing = false;
			attack = new RofelBoss(gun, data.boss);
			selfDriven = true;
			grabbable = false;
			explodes = true;
		}
		else if (data.attack == "shoot")
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

	public function takeHit(pushX:Float, pushY:Float, damage:Int = 1):Void
	{
		if (isDead)
			return;

		brain.interrupt();
		attack.reset();

		hp -= damage;
		flashTimer = FLASH_TIME;
		setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);

		if (hp <= 0)
		{
			isDead = true;
			velocity.set(0, 0);
			drag.set(0, 0);
			pathing.clear();
			this.animation.play("death", true);
			if (!explodes)
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
		if (puppet)
		{
			prevBottom = y + height;
			super.update(elapsed);
			if (flashTimer > 0)
			{
				flashTimer -= elapsed;
				if (flashTimer <= 0)
					setColorTransform(1, 1, 1, alpha, 0, 0, 0, 0);
			}
			return;
		}

		if (WorldClock.scale <= 0 && !seized)
		{
			immovable = true;
			velocity.set(0, 0);
			return;
		}
		if (immovable)
			immovable = false;
		if (!seized)
			elapsed *= WorldClock.scale;

		if (SideView.morphing)
			return;

		prevBottom = y + height;
		super.update(elapsed);

		if (throwGrace > 0)
			throwGrace -= elapsed;

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
				setColorTransform(1, 1, 1, alpha, 0, 0, 0, 0);
		}

		if (isDead)
		{
			velocity.set(0, 0);
			if (SideView.active)
				SideView.settle(this, prevBottom, elapsed);
			return;
		}

		if (seized)
			return;

		if (stun > 0)
		{
			stun -= elapsed;
			if (stun <= 0)
			{
				drag.set(0, 0);
				velocity.set(0, 0);
			}
			if (SideView.active)
				SideView.settle(this, prevBottom, elapsed);
			return;
		}

		if (entering)
		{
			if (target == null)
			{
				velocity.set(0, 0);
				return;
			}

			var ex:Float = target.x + target.width * 0.5 - (x + width * 0.5);
			flipX = ex < 0;
			this.animation.play("walk");

			if (SideView.active)
			{
				velocity.x = ex < 0 ? -speed : speed;
				SideView.settle(this, prevBottom, elapsed);
				return;
			}

			var ey:Float = target.y + target.height * 0.5 - (y + height * 0.5);
			var el:Float = Math.sqrt(ex * ex + ey * ey);
			if (el > 0)
				velocity.set(ex / el * speed, ey / el * speed);
			return;
		}

		if (selfDriven)
		{
			if (target != null)
			{
				var tmx:Float = target.x + target.width * 0.5;
				var tmy:Float = target.y + target.height * 0.5;
				var bdx = tmx - (x + width * 0.5);
				var bdy = tmy - (y + height * 0.5);
				attack.update(this, elapsed, bdx, bdy, Math.sqrt(bdx * bdx + bdy * bdy));
			}
			else
			{
				velocity.set(0, 0);
			}
			return;
		}

		if (SideView.active)
		{
			sideStepper.update(this, elapsed, prevBottom);
			return;
		}

		brain.update(this, elapsed);
	}

	public function unseize(releaseStun:Float = 0):Void
	{
		if (seized)
		{
			seized = false;
			if (releaseStun > 0)
				stun = releaseStun;
			drag.set(knockbackDrag, knockbackDrag);
		}
		throwGrace = 0.35;
	}

	public function requestShot(dirX:Float, dirY:Float, damage:Float, speed:Float, range:Float, sprite:String, sound:String):ShotSpec
	{
		var s = shotPool.length > 0 ? shotPool.pop() : new ShotSpec();
		s.set(dirX, dirY, damage, speed, range, sprite, sound);
		pendingShots.push(s);
		return s;
	}

	public function recycleShots():Void
	{
		while (pendingShots.length > 0)
			shotPool.push(pendingShots.pop());
	}

	override public function destroy():Void
	{
		pathing.clear();
		super.destroy();
	}
}
