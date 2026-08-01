package entities.enemy;

import flixel.FlxG;
import flixel.FlxSprite;
import data.EnemyData.FlankData;

class FlankAttack implements AttackBehavior
{
	static inline var SLIDE:Int = 0;
	static inline var WIND:Int = 1;
	static inline var FIRE:Int = 2;
	static inline var REST:Int = 3;

	static inline var ANG_BAND:Float = 0.25;
	static inline var RADIAL_BAND:Float = 140;
	static inline var ARRIVE_ANG:Float = 0.12;
	static inline var ARRIVE_RAD:Float = 60;
	static inline var SPREAD:Float = 0.9;
	static inline var TRIES:Int = 4;
	static inline var FLIP_CHANCE:Float = 25;
	static inline var STALL_TIME:Float = 0.5;
	static inline var STALL_ARC:Float = 0.08;
	static inline var STALL_STEP:Float = 20;

	static var posts:Array<{e:Enemies, t:FlxSprite, a:Float}> = [];

	private var cfg:FlankData;
	private var phase:Int = SLIDE;
	private var timer:Float = 0;
	private var post:Float = 0;
	private var side:Bool = true;
	private var shotsLeft:Int = 0;
	private var stall:Float = 0;
	private var lastBear:Float = 0;
	private var lastRad:Float = 0;
	private var ended:Bool = false;
	private var started:Bool = false;
	private var pendingFire:Bool = false;

	public function new(cfg:FlankData)
	{
		this.cfg = cfg;
		side = FlxG.random.bool();
	}

	public function update(e:Enemies, elapsed:Float, dirX:Float, dirY:Float, distance:Float):Bool
	{
		var d = distance > 0 ? distance : 1;
		var inX = dirX / d;
		var inY = dirY / d;

		if (inX > 0)
			e.flipX = false;
		else if (inX < 0)
			e.flipX = true;

		if (pendingFire)
		{
			pendingFire = false;
			e.requestShot(inX, inY, e.shotDamage, e.shotSpeed, e.shotRange, e.shotSprite,
				e.shotSound != null ? e.shotSound : "enemies/shoot");
		}

		if (!started)
		{
			started = true;
			repost(e, inX, inY);
		}

		switch (phase)
		{
			case SLIDE:
				slide(e, elapsed, inX, inY, d);
			case WIND:
				plant(e);
				timer -= elapsed;
				if (timer <= 0)
					open(e);
			case FIRE:
				plant(e);
				burn(e, elapsed);
			default:
				plant(e);
				timer -= elapsed;
				if (timer <= 0)
					repost(e, inX, inY);
		}

		if (phase != SLIDE && d < cfg.minDist)
			repost(e, inX, inY);

		if (distance > e.attackRange + cfg.disengage || !e.pathing.fireClear)
		{
			started = false;
			return true;
		}
		return false;
	}

	function slide(e:Enemies, elapsed:Float, inX:Float, inY:Float, d:Float):Void
	{
		timer -= elapsed;

		var bx = -inX;
		var by = -inY;
		var here = Math.atan2(by, bx);
		var diff = wrap(post - here);

		stall += elapsed;
		if (Math.abs(wrap(here - lastBear)) > STALL_ARC || Math.abs(lastRad - d) > STALL_STEP)
		{
			stall = 0;
			lastBear = here;
			lastRad = d;
		}

		var tanX = diff >= 0 ? -by : by;
		var tanY = diff >= 0 ? bx : -bx;

		var swing = Math.abs(diff) / ANG_BAND;
		if (swing > 1)
			swing = 1;

		var radial = (d - cfg.standoff) / RADIAL_BAND;
		if (radial > 1)
			radial = 1;
		else if (radial < -1)
			radial = -1;

		var mvX = tanX * swing + inX * radial;
		var mvY = tanY * swing + inY * radial;
		var l = Math.sqrt(mvX * mvX + mvY * mvY);
		if (l > 0.01)
		{
			e.velocity.set(mvX / l * e.speed, mvY / l * e.speed);
			e.animation.play("walk");
		}
		else
			e.velocity.set(0, 0);

		var landed = Math.abs(diff) < ARRIVE_ANG && Math.abs(d - cfg.standoff) < ARRIVE_RAD;
		if (landed || stall > STALL_TIME || timer <= 0)
		{
			phase = WIND;
			timer = cfg.windup;
			e.velocity.set(0, 0);
			e.animation.play("idle");
		}
	}

	function open(e:Enemies):Void
	{
		phase = FIRE;
		shotsLeft = cfg.shots;
		ended = false;
		timer = cfg.startTime;
		e.animation.play("sstart", true);
	}

	function burn(e:Enemies, elapsed:Float):Void
	{
		timer -= elapsed;
		if (timer > 0)
			return;

		if (shotsLeft > 0)
		{
			shotsLeft--;
			pendingFire = true;
			timer = cfg.shotGap;
			e.animation.play("sloop", true);
		}
		else if (!ended)
		{
			ended = true;
			timer = cfg.endTime;
			e.animation.play("send", true);
		}
		else
		{
			phase = REST;
			timer = cfg.rest;
			e.animation.play("idle");
		}
	}

	function repost(e:Enemies, inX:Float, inY:Float):Void
	{
		if (FlxG.random.bool(FLIP_CHANCE))
			side = !side;

		var here = Math.atan2(-inY, -inX);
		var pick = here;
		for (i in 0...TRIES)
		{
			var arc = FlxG.random.float(cfg.arcMin, cfg.arcMax) * Math.PI / 180;
			pick = wrap(here + (side ? arc : -arc));
			if (!taken(e, pick))
				break;
			side = !side;
		}

		post = pick;
		claim(e, pick);
		phase = SLIDE;
		timer = cfg.slideMax;
		stall = 0;
		lastBear = here;
		lastRad = 0;
		ended = false;
	}

	static function taken(e:Enemies, a:Float):Bool
	{
		for (p in posts)
		{
			if (p.e == e || p.t != e.target || !p.e.exists || p.e.isDead)
				continue;
			if (Math.abs(wrap(a - p.a)) < SPREAD)
				return true;
		}
		return false;
	}

	static function claim(e:Enemies, a:Float):Void
	{
		var i = posts.length;
		while (i-- > 0)
		{
			var p = posts[i];
			if (p.e == e || !p.e.exists || p.e.isDead)
				posts.splice(i, 1);
		}
		posts.push({e: e, t: e.target, a: a});
	}

	static function wrap(a:Float):Float
	{
		while (a > Math.PI)
			a -= Math.PI * 2;
		while (a < -Math.PI)
			a += Math.PI * 2;
		return a;
	}

	inline function plant(e:Enemies):Void
		e.velocity.set(0, 0);

	public function reset():Void
	{
		started = false;
		pendingFire = false;
		phase = SLIDE;
	}
}
