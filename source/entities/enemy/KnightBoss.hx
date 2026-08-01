package entities.enemy;

import flixel.FlxG;
import data.EnemyData.KnightData;

class KnightBoss implements AttackBehavior
{
	static inline var HOVER:Int = 0;
	static inline var WIND:Int = 1;
	static inline var FLY:Int = 2;
	static inline var SLASH:Int = 3;
	static inline var REST:Int = 4;

	static inline var CLOSE_ENOUGH:Float = 90;
	static inline var DRIFT_EASE:Float = 3;

	private var cfg:KnightData;
	private var phase:Int = HOVER;
	private var timer:Float = 0;
	private var flyX:Float = 1;
	private var flyY:Float = 0;
	private var baseDamage:Float = -1;
	private var strafeDir:Int = 1;
	private var strafeTimer:Float = 0;

	public function new(cfg:KnightData)
	{
		this.cfg = cfg;
		timer = cfg.hoverTime;
	}

	public function update(e:Enemies, elapsed:Float, dirX:Float, dirY:Float, distance:Float):Bool
	{
		if (baseDamage < 0)
			baseDamage = e.contactDamage;

		if (phase != SLASH)
			e.contactDamage = baseDamage;

		var d = distance > 0 ? distance : 1;
		var ax = dirX / d;
		var ay = dirY / d;
		timer -= elapsed;

		switch (phase)
		{
			case HOVER:
				face(e, ax);
				hover(e, elapsed, ax, ay, distance);
				if (timer <= 0)
					enter(e, WIND, cfg.windTime);
			case WIND:
				face(e, ax);
				e.velocity.x += (0 - e.velocity.x) * Math.min(1, DRIFT_EASE * elapsed);
				e.velocity.y += (0 - e.velocity.y) * Math.min(1, DRIFT_EASE * elapsed);
				flyX = ax;
				flyY = ay;
				if (timer <= 0)
				{
					enter(e, FLY, cfg.flyTime);
					e.velocity.set(flyX * cfg.flySpeed, flyY * cfg.flySpeed);
					util.Sfx.at("enemies/charge", e.x + e.width * 0.5, e.y + e.height * 0.5, 0.55);
				}
			case FLY:
				face(e, flyX);
				if (timer <= 0 || distance < CLOSE_ENOUGH)
					strike(e);
			case SLASH:
				face(e, flyX);
				e.velocity.x += (0 - e.velocity.x) * Math.min(1, DRIFT_EASE * 2 * elapsed);
				e.velocity.y += (0 - e.velocity.y) * Math.min(1, DRIFT_EASE * 2 * elapsed);
				if (timer <= 0)
					enter(e, REST, cfg.restTime);
			default:
				face(e, ax);
				hover(e, elapsed, ax, ay, distance);
				if (timer <= 0)
					enter(e, HOVER, cfg.hoverTime);
		}

		dress(e);
		return false;
	}

	function strike(e:Enemies):Void
	{
		enter(e, SLASH, cfg.slashTime);
		e.contactDamage = baseDamage * cfg.slashScale;
		util.Sfx.at("swing/swing" + (1 + Std.random(8)), e.x + e.width * 0.5, e.y + e.height * 0.5, 0.7);
	}

	inline function enter(e:Enemies, next:Int, time:Float):Void
	{
		phase = next;
		timer = time;
	}

	function dress(e:Enemies):Void
	{
		if (e.animation.name == "hurt" && !e.animation.finished)
			return;
		var want = switch (phase)
		{
			case WIND: "flurryPrep";
			case FLY: "turning";
			case SLASH: "slashAttack";
			default: "idleSword";
		};
		if (e.animation.name != want)
			e.animation.play(want);
	}

	inline function face(e:Enemies, ax:Float):Void
	{
		if (ax > 0.05)
			e.flipX = false;
		else if (ax < -0.05)
			e.flipX = true;
	}

	function hover(e:Enemies, elapsed:Float, ax:Float, ay:Float, distance:Float):Void
	{
		strafeTimer -= elapsed;
		if (strafeTimer <= 0)
		{
			strafeTimer = FlxG.random.float(0.7, 1.6);
			strafeDir = FlxG.random.bool() ? 1 : -1;
		}

		var pull:Float = 0;
		if (distance > cfg.prefMax)
			pull = 1;
		else if (distance < cfg.prefMin)
			pull = -1;

		var vx = ax * pull * cfg.hoverSpeed - ay * strafeDir * cfg.hoverSpeed * cfg.strafeWeight;
		var vy = ay * pull * cfg.hoverSpeed + ax * strafeDir * cfg.hoverSpeed * cfg.strafeWeight;
		var k = Math.min(1, DRIFT_EASE * elapsed);
		e.velocity.x += (vx - e.velocity.x) * k;
		e.velocity.y += (vy - e.velocity.y) * k;
	}

	public function reset():Void
	{
		phase = HOVER;
		timer = cfg.hoverTime;
		strafeTimer = 0;
	}
}
