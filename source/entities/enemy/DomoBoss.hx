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

	static inline var BRAKE:Float = 6;
	static inline var SIGN_LIFT:Float = 26;

	private var cfg:DomoData;
	private var phase:Int = CHASE;
	private var timer:Float = 0;
	private var cooldown:Float = 1.0;
	private var burstsLeft:Int = 0;
	private var dashesLeft:Int = 0;
	private var dashX:Float = 1;
	private var dashY:Float = 0;

	public function new(cfg:DomoData)
	{
		this.cfg = cfg;
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
				e.velocity.set(ax * e.speed, ay * e.speed);
				cooldown -= elapsed;
				if (cooldown <= 0)
					pick(e, distance);
			case SHOT:
				face(e, ax);
				brake(e, elapsed);
				if (timer <= 0)
				{
					volley(e, ax, ay);
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
					dashesLeft--;
					if (dashesLeft > 0)
					{
						phase = DASH_WIND;
						timer = cfg.dashGap;
					}
					else
						rest(e);
				}
		}

		sign(e, phase == SHOT);
		e.poise = phase == SHOT;
		e.ramming = phase == DASH;
		return false;
	}

	function pick(e:Enemies, distance:Float):Void
	{
		if (distance > cfg.farDist)
		{
			if (FlxG.random.bool())
				beginSummon();
			else
				beginDash();
			return;
		}
		var r = FlxG.random.float();
		if (r < 0.55)
			beginShot();
		else if (r < 0.8)
			beginDash();
		else
			beginSummon();
	}

	function beginShot():Void
	{
		phase = SHOT;
		timer = cfg.shotWindup;
		burstsLeft = cfg.shotBursts;
	}

	function beginSummon():Void
	{
		phase = SUMMON;
		timer = cfg.summonTime;
	}

	function beginDash():Void
	{
		phase = DASH_WIND;
		timer = cfg.dashWindup;
		dashesLeft = cfg.dashCount;
	}

	function rest(e:Enemies):Void
	{
		phase = CHASE;
		cooldown = cfg.cooldown;
	}

	function volley(e:Enemies, ax:Float, ay:Float):Void
	{
		var cx = e.x + e.width * 0.5;
		var cy = e.y + e.height * 0.5;
		var aimDeg = Math.atan2(ay, ax) * 180 / Math.PI;
		for (i in 0...cfg.shotCount)
		{
			var offset = (i - (cfg.shotCount - 1) * 0.5) * cfg.shotSpread + (FlxG.random.float() - 0.5) * 3;
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

	function sign(e:Enemies, on:Bool):Void
	{
		if (e.gun == null)
			return;
		e.gun.visible = on && !e.isDead;
		if (on)
		{
			e.gun.x = e.x + e.width * 0.5 - e.gun.width * 0.5;
			e.gun.y = e.y - e.offset.y - e.gun.height - SIGN_LIFT;
		}
	}

	inline function face(e:Enemies, ax:Float):Void
	{
		if (ax > 0.05)
			e.flipX = false;
		else if (ax < -0.05)
			e.flipX = true;
	}

	inline function brake(e:Enemies, elapsed:Float):Void
	{
		var k = Math.min(1, BRAKE * elapsed);
		e.velocity.x += (0 - e.velocity.x) * k;
		e.velocity.y += (0 - e.velocity.y) * k;
	}

	public function reset():Void
	{
		phase = CHASE;
		timer = 0;
		cooldown = 1.0;
	}
}
