package entities.enemy;

import flixel.FlxG;
import data.EnemyData.DomoData;

class DomoBoss implements AttackBehavior
{
	static inline var CHASE:Int = 0;
	static inline var SHOT:Int = 1;
	static inline var SUMMON:Int = 2;
	static inline var DASH_WIND:Int = 3;
	static inline var DASH:Int = 4;
	static inline var DASH_REST:Int = 5;

	static inline var BRAKE:Float = 6;
	static inline var PLANT:Float = 18;
	static inline var STRAFE_HOLD:Float = 1.4;
	static inline var STRAFE_VARY:Float = 1.3;

	private var cfg:DomoData;
	private var phase:Int = CHASE;
	private var timer:Float = 0;
	private var cooldown:Float = 1.0;
	private var burstsLeft:Int = 0;
	private var dashesLeft:Int = 0;
	private var dashX:Float = 1;
	private var dashY:Float = 0;
	private var strafeDir:Int = 1;
	private var strafeTimer:Float = 0;
	private var sprayIn:Float = 0;
	private var sprayN:Int = 0;

	private var closeDist:Float;
	private var closeReact:Float;
	private var dashCooldown:Float;
	private var sprayDelay:Float;

	public function new(cfg:DomoData)
	{
		this.cfg = cfg;
		closeDist = cfg.closeDist != null ? cfg.closeDist : cfg.prefMin;
		closeReact = cfg.closeReact != null ? cfg.closeReact : 0;
		dashCooldown = cfg.dashCooldown != null ? cfg.dashCooldown : cfg.cooldown;
		sprayDelay = cfg.sprayDelay != null ? cfg.sprayDelay : 0;
	}

	public function update(e:Enemies, elapsed:Float, dirX:Float, dirY:Float, distance:Float):Bool
	{
		var d = distance > 0 ? distance : 1;
		var ax = dirX / d;
		var ay = dirY / d;
		timer -= elapsed;

		switch (phase)
		{
			case CHASE:
				face(e, ax);
				hover(e, elapsed, ax, ay, distance);
				cooldown -= elapsed;
				if (distance < closeDist && cooldown > closeReact)
					cooldown = closeReact;
				if (cooldown <= 0)
					pick(e, distance);
			case SHOT:
				face(e, ax);
				brake(e, elapsed);
				if (timer <= 0)
				{
					volley(e, ax, ay, cfg.shotCount);
					burstsLeft--;
					if (burstsLeft <= 0)
						rest(e);
					else
						timer = cfg.shotGap;
				}
			case SUMMON:
				brake(e, elapsed);
				if (timer <= 0)
				{
					if (!crowded())
						ring(e);
					rest(e);
				}
			case DASH_WIND:
				face(e, ax);
				brake(e, elapsed);
				dashX = ax;
				dashY = ay;
				if (timer <= 0)
				{
					phase = DASH;
					timer = cfg.dashTime;
					e.velocity.set(dashX * cfg.dashSpeed, dashY * cfg.dashSpeed);
					util.Sfx.at("enemies/charge", e.x + e.width * 0.5, e.y + e.height * 0.5, 0.6);
				}
			case DASH_REST:
				face(e, ax);
				brakeAt(e, elapsed, PLANT);
				if (sprayIn > 0)
				{
					sprayIn -= elapsed;
					if (sprayIn <= 0)
						spray(e, ax, ay, sprayN, distance);
				}
				if (timer <= 0)
				{
					sprayIn = 0;
					if (dashesLeft > 0)
					{
						phase = DASH_WIND;
						timer = cfg.dashGap;
					}
					else
						rest(e, dashCooldown);
				}
			default:
				var turn = Math.min(1, cfg.dashTurn * elapsed);
				dashX += (ax - dashX) * turn;
				dashY += (ay - dashY) * turn;
				var l = Math.sqrt(dashX * dashX + dashY * dashY);
				if (l > 0)
				{
					dashX /= l;
					dashY /= l;
				}
				e.velocity.set(dashX * cfg.dashSpeed, dashY * cfg.dashSpeed);
				if (timer <= 0)
				{
					sprayN = cfg.dashCount - dashesLeft;
					sprayIn = sprayDelay;
					if (sprayIn <= 0)
						spray(e, ax, ay, sprayN, distance);
					dashesLeft--;
					phase = DASH_REST;
					timer = cfg.dashRest;
				}
		}

		holdGun(e, ax, ay);
		e.poise = phase != CHASE;
		e.ramming = phase == DASH;
		return false;
	}

	function hover(e:Enemies, elapsed:Float, ax:Float, ay:Float, distance:Float):Void
	{
		if (!e.pathing.fireClear)
		{
			e.pathing.steer(e.x + e.width * 0.5, e.y + e.height * 0.5, ax, ay);
			e.velocity.set(e.pathing.moveX * e.speed, e.pathing.moveY * e.speed);
			if (e.animation.name != "hurt" || e.animation.finished)
				e.animation.play("walk");
			return;
		}

		strafeTimer -= elapsed;
		if (strafeTimer <= 0)
		{
			strafeDir = -strafeDir;
			strafeTimer = STRAFE_HOLD + FlxG.random.float() * STRAFE_VARY;
		}
		if (e.wasTouching != flixel.util.FlxDirectionFlags.NONE)
			strafeDir = -strafeDir;

		var mvx = 0.0;
		var mvy = 0.0;
		if (distance > cfg.prefMax)
		{
			mvx += ax;
			mvy += ay;
		}
		mvx += -ay * strafeDir * cfg.strafeWeight;
		mvy += ax * strafeDir * cfg.strafeWeight;

		var ml = Math.sqrt(mvx * mvx + mvy * mvy);
		if (ml > 0)
			e.velocity.set(mvx / ml * e.speed, mvy / ml * e.speed);
		else
			e.velocity.set(0, 0);

		if (e.animation.name != "hurt" || e.animation.finished)
			e.animation.play(ml > 0 ? "walk" : "idle");
	}

	function crowded():Bool
		return Enemies.countOf(cfg.summonKind) > cfg.summonCap;

	function pick(e:Enemies, distance:Float):Void
	{
		if (distance < closeDist)
		{
			beginDash(e);
			return;
		}
		if (distance > cfg.farDist)
		{
			if (!crowded() && FlxG.random.bool())
				beginSummon(e);
			else
				beginDash(e);
			return;
		}
		if (!e.pathing.fireClear)
		{
			if (!crowded() && FlxG.random.bool(35))
				beginSummon(e);
			else
				beginDash(e);
			return;
		}
		if (distance < cfg.shotMin)
		{
			if (!crowded() && FlxG.random.bool(25))
				beginSummon(e);
			else
				beginDash(e);
			return;
		}
		var r = FlxG.random.float();
		if (r < 0.55)
			beginShot(e);
		else if (r < 0.8 || crowded())
			beginDash(e);
		else
			beginSummon(e);
	}

	function beginShot(e:Enemies):Void
	{
		phase = SHOT;
		timer = cfg.shotWindup;
		burstsLeft = cfg.shotBursts;
		e.poise = true;
	}

	function beginSummon(e:Enemies):Void
	{
		phase = SUMMON;
		timer = cfg.summonTime;
		e.poise = true;
	}

	function beginDash(e:Enemies):Void
	{
		phase = DASH_WIND;
		timer = cfg.dashWindup;
		dashesLeft = cfg.dashCount;
		e.poise = true;
	}

	function rest(e:Enemies, ?wait:Float):Void
	{
		phase = CHASE;
		cooldown = wait != null ? wait : cfg.cooldown;
		sprayIn = 0;
		e.poise = false;
	}

	function spray(e:Enemies, ax:Float, ay:Float, index:Int, distance:Float):Void
	{
		var list = cfg.dashShots;
		if (list == null || list.length == 0 || distance < cfg.shotMin)
			return;
		var n = index < list.length ? list[index] : list[list.length - 1];
		if (n > 0)
			volley(e, ax, ay, n);
	}

	function volley(e:Enemies, ax:Float, ay:Float, count:Int):Void
	{
		var cx = e.x + e.width * 0.5;
		var cy = e.y + e.height * 0.5;
		var aimDeg = Math.atan2(ay, ax) * 180 / Math.PI;
		for (i in 0...count)
		{
			var offset = (i - (count - 1) * 0.5) * cfg.shotSpread + (FlxG.random.float() - 0.5) * 3;
			var rad = (aimDeg + offset) * Math.PI / 180;
			e.requestShot(Math.cos(rad), Math.sin(rad), cfg.shotDamage, cfg.shotSpeed, cfg.shotRange,
				"bullets/shotgun_bullet_enemy", "enemies/shoot").at(cx + ax * cfg.muzzle, cy + ay * cfg.muzzle);
		}
	}

	function ring(e:Enemies):Void
	{
		var cx = e.x + e.width * 0.5;
		var cy = e.y + e.height * 0.5;
		e.summon(cfg.summonKind, cx, cy - cfg.summonDist);
		e.summon(cfg.summonKind, cx + cfg.summonDist, cy);
		e.summon(cfg.summonKind, cx, cy + cfg.summonDist);
		e.summon(cfg.summonKind, cx - cfg.summonDist, cy);
		util.Sfx.at("power_up", cx, cy, 0.6);
	}

	function holdGun(e:Enemies, ax:Float, ay:Float):Void
	{
		if (e.gun == null)
			return;
		var hx = e.x + e.width * 0.5 + ax * cfg.gunDist;
		var hy = e.y + e.height * 0.5 + ay * cfg.gunDist;
		e.gun.x = hx - e.gun.frameWidth * 0.5;
		e.gun.y = hy - e.gun.frameHeight * 0.5;
		var deg = Math.atan2(ay, ax) * 180 / Math.PI;
		e.gun.angle = deg;
		e.gun.flipY = Math.abs(deg) > 90;
	}

	inline function face(e:Enemies, ax:Float):Void
	{
		if (ax > 0.05)
			e.flipX = false;
		else if (ax < -0.05)
			e.flipX = true;
	}

	inline function brake(e:Enemies, elapsed:Float):Void
		brakeAt(e, elapsed, BRAKE);

	inline function brakeAt(e:Enemies, elapsed:Float, rate:Float):Void
	{
		var k = Math.min(1, rate * elapsed);
		e.velocity.x += (0 - e.velocity.x) * k;
		e.velocity.y += (0 - e.velocity.y) * k;
	}

	public function reset():Void
	{
		phase = CHASE;
		timer = 0;
		sprayIn = 0;
	}
}
