package entities.enemy;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import util.Paths;
import util.WorldClock;
import data.EnemyData.EnemyDataRegistry;

class Enemies extends FlxSprite
{
	static inline var FLASH_TIME:Float = 0.08;

	static inline var ENTER_CLIMB:Float = 0.7;
	static inline var ENTER_SIDE:Float = 0.714;

	public var speed:Float = 300;
	public var aggroRange:Float = 200;
	public var stopThreshold:Float = 170;
	public var attackRange:Float = 150;
	public var contactDamage:Float = 0.25;
	public var contactPush:Float = 0;
	public var shotDamage:Float = 0.25;
	public var shotSpeed:Float = 480;
	public var shotRange:Float = 99999;
	public var shotSprite:String = null;
	public var shotSound:String = null;
	public var dropChance:Float = 0;
	public var knockbackTaken:Float = 550;
	public var knockbackDrag:Float = 1600;

	static inline var CORPSE_KNOCK:Float = 0.85;
	static inline var BIG_KNOCK:Float = 0.4;
	static inline var NORMAL_KNOCK:Float = 1.35;
	public var stunTime:Float = 0.3;
	public var hitRecover:Float = 0;
	public var hitRecoil:Float = 0;
	public var stunImmunity:Float = 0;
	private var stunLock:Float = 0;

	public var target:FlxSprite;
	public var kind(default, null):String;
	public var bossBody(default, null):Bool = false;
	public var big(default, null):Bool = false;

	public var hitRadius(get, never):Float;

	function get_hitRadius():Float
		return width * 0.5;
	public var puppet:Bool = false;
	public var netId:Int = -1;
	public var entering:Bool = false;
	public var seized:Bool = false;
	public var throwGrace:Float = 0;
	public var selfDriven:Bool = false;
	public var grabbable:Bool = true;
	public var explodes:Bool = false;
	public var gun:FlxSprite = null;
	public var ramming:Bool = false;
	public var poise:Bool = false;
	public var buried:Bool = false;
	public var railed:Bool = false;
	public var pendingSummons:Array<{kind:String, x:Float, y:Float}> = [];
	public var pathing:EnemyNav = new EnemyNav();
	public var attack:AttackBehavior;
	public var pendingShots:Array<ShotSpec> = [];

	private var shotPool:Array<ShotSpec> = [];

	public var hp:Float = 3;
	public var isDead:Bool = false;
	public var stun:Float = 0;
	public var flashTimer:Float = 0;

	private var braceFrames:Int = 0;
	private var braceVX:Float = 0;
	private var braceVY:Float = 0;
	private var braceAmp:Float = 0;
	private var braceOffX:Float = 0;
	private var braceOffY:Float = 0;
	private var flung:Bool = false;

	public var shadowOffX:Float = 32;
	public var shadowOffXFlip:Float = 22;
	public var shadowOffY:Float = 90;

	public function applyScale(hpMult:Float, speedMult:Float, damageMult:Float):Void
	{
		hp *= hpMult;
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


    public function new(kind:String, x:Float=0, y:Float=0)
    {
        super(x, y);
		this.kind = kind;

		util.PixelPerfectShader.on(this);
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
		contactPush = data.contactPush == null ? 0 : data.contactPush;
		shotDamage = data.shotDamage != null ? data.shotDamage : 0.25;
		if (data.shotSpeed != null) shotSpeed = data.shotSpeed;
		if (data.shotRange != null) shotRange = data.shotRange;
		shotSprite = data.shotSprite;
		shotSound = data.shotSound;
		dropChance = data.dropChance;
		if (data.knockback != null) knockbackTaken = data.knockback;
		if (data.knockbackDrag != null) knockbackDrag = data.knockbackDrag;
		if (data.stunTime != null) stunTime = data.stunTime;
		if (data.stunImmunity != null) stunImmunity = data.stunImmunity;
		if (data.hitRecover != null) hitRecover = data.hitRecover;
		if (data.hitRecoil != null) hitRecoil = data.hitRecoil;
		brain.wanderSpeed = (data.wanderSpeed != null ? data.wanderSpeed : 100) + FlxG.random.float() * 20;

		if (data.attack == "domo")
		{
			bossBody = true;
			gun = new FlxSprite();
			gun.loadGraphic(Paths.image("enemies/domos_shotgun"));
			util.PixelPerfectShader.on(gun);
			gun.origin.set(gun.frameWidth * 0.5, gun.frameHeight * 0.5);
			gun.scale.set(4, 4);
			attack = new DomoBoss(data.domo);
			selfDriven = true;
			grabbable = false;
			explodes = true;
		}
		else if (data.attack == "boss")
		{
			bossBody = true;
			gun = new FlxSprite();
			util.PixelPerfectShader.on(gun);
			attack = new RofelBoss(gun, data.boss);
			selfDriven = true;
			grabbable = false;
			explodes = true;
		}
		else if (data.attack == "flank")
		{
			attack = new FlankAttack(data.flank);
		}
		else if (data.attack == "worm")
		{
			bossBody = true;
			selfDriven = true;
			grabbable = false;
			explodes = true;
			railed = true;
			poise = true;
			attack = new WormPart();
		}
		else
		{
			var charge = new ChargeAttack();
			if (data.chargeAnim != null) charge.chargeAnim = data.chargeAnim;
			if (data.chargeWindup != null) charge.windupTime = data.chargeWindup;
			if (data.chargeSpeed != null) charge.chargeSpeed = data.chargeSpeed;
			if (data.chargeTime != null) charge.chargeTime = data.chargeTime;
			if (data.chargeRecover != null) charge.recoverTime = data.chargeRecover;
			attack = charge;
		}

		if (data.big == true || bossBody)
			big = true;
		if (big)
			grabbable = false;

		shadowOffX = data.shadowOffX;
		shadowOffXFlip = data.shadowOffXFlip;
		shadowOffY = data.shadowOffY;
		shadowScaleX = data.shadowScaleX;
		hitOffX = data.hitOffX;
		hitOffXFlip = data.hitOffXFlip;
		hitOffY = data.hitOffY;
    }

	public function takeHit(pushX:Float, pushY:Float, damage:Float = 1):Void
	{
		if (isDead || buried)
			return;

		var shaken = !poise && stunLock <= 0;

		if (shaken)
		{
			brain.interrupt();
			attack.reset();
		}

		hp -= damage;
		flashTimer = FLASH_TIME;
		setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);

		if (hp <= 0)
		{
			isDead = true;
			flung = true;
			velocity.set(pushX * knockbackTaken * knockScale() * CORPSE_KNOCK, pushY * knockbackTaken * knockScale() * CORPSE_KNOCK);
			drag.set(knockbackDrag, knockbackDrag);
			pathing.clear();
			this.animation.play("death", true);
			if (!explodes)
				FlxTween.tween(this, {alpha: 0}, 0.6, {startDelay: 1.2, onComplete: function(t:FlxTween) kill()});
		}
		else if (shaken)
		{
			this.animation.play("hurt", true);
			velocity.set(pushX * knockbackTaken * knockScale(), pushY * knockbackTaken * knockScale());
			drag.set(knockbackDrag, knockbackDrag);
			stun = stunTime;
			stunLock = stunTime + stunImmunity;
		}
	}

	function knockScale():Float
		return big ? BIG_KNOCK : NORMAL_KNOCK;

	public function brace(frames:Int, amp:Float, pushX:Float, pushY:Float):Void
	{
		if (frames <= 1 || amp <= 0)
			return;
		if (isDead)
		{
			braceVX = pushX * knockbackTaken * knockScale() * CORPSE_KNOCK;
			braceVY = pushY * knockbackTaken * knockScale() * CORPSE_KNOCK;
		}
		else
		{
			braceVX = velocity.x;
			braceVY = velocity.y;
		}
		velocity.set(0, 0);
		braceOffX = offset.x;
		braceOffY = offset.y;
		braceAmp = amp;
		braceFrames = frames;
	}

	function tickBrace():Void
	{
		braceFrames--;
		if (braceFrames > 0)
		{
			offset.set(braceOffX + FlxG.random.float(-braceAmp, braceAmp),
				braceOffY + FlxG.random.float(-braceAmp, braceAmp));
			return;
		}
		offset.set(braceOffX, braceOffY);
		velocity.set(braceVX, braceVY);
		drag.set(knockbackDrag, knockbackDrag);
		flung = isDead;
	}

    override public function update(elapsed:Float):Void
	{
		if (puppet)
		{
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

		super.update(elapsed);

		if (throwGrace > 0)
			throwGrace -= elapsed;

		if (stunLock > 0)
			stunLock -= elapsed;

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
				setColorTransform(1, 1, 1, alpha, 0, 0, 0, 0);
		}

		if (isDead)
		{
			if (braceFrames > 0)
				tickBrace();
			else if (!flung)
				velocity.set(0, 0);
			return;
		}

		if (seized)
			return;

		if (braceFrames > 0)
		{
			tickBrace();
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
			if (target == null)
			{
				velocity.set(0, 0);
				return;
			}

			var ex:Float = target.x + target.width * 0.5 - (x + width * 0.5);
			flipX = ex < 0;
			this.animation.play("walk");

			var ey:Float = target.y + target.height * 0.5 - (y + height * 0.5);
			var el:Float = Math.sqrt(ex * ex + ey * ey);
			if (el > 0)
			{
				var ux:Float = ex / el;
				var uy:Float = ey / el;
				if (uy > -ENTER_CLIMB)
				{
					uy = -ENTER_CLIMB;
					ux = ux < 0 ? -ENTER_SIDE : ENTER_SIDE;
				}
				velocity.set(ux * speed, uy * speed);
			}
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
				pathing.tick(elapsed, x + width * 0.5, y + height * 0.5, tmx, tmy);
				attack.update(this, elapsed, bdx, bdy, Math.sqrt(bdx * bdx + bdy * bdy));
			}
			else
			{
				velocity.set(0, 0);
			}
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

	public static var census:Map<String, Int> = new Map();

	public static function countOf(kind:String):Int
		return census.exists(kind) ? census.get(kind) : 0;

	public function summon(kind:String, cx:Float, cy:Float):Void
		pendingSummons.push({kind: kind, x: cx, y: cy});

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
