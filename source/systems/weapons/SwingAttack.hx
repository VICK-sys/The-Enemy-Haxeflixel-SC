package systems.weapons;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.SlashEffect;
import systems.enemy.EnemyDirector;
import data.WeaponData.SwingConfig;
import util.Paths;

class SwingAttack
{
	static inline var GUARD_TIME:Float = 0.2;

	public var slashes:FlxTypedGroup<SlashEffect>;

	private var cfg:SwingConfig;
	private var director:EnemyDirector;
	private var hits:HitPipeline;
	private var fx:systems.Fx;
	private var guardTimer:Float = 0;
	private var guardX:Float = 1;
	private var guardY:Float = 0;
	private var cooldown:Float = 0;
	private var cooldownTotal:Float = 0;

	public var reach(get, never):Float;

	function get_reach():Float
		return cfg.meleeRange;

	public var hitLift(get, never):Float;

	function get_hitLift():Float
		return cfg.hitLift == null ? 0 : cfg.hitLift;

	public var hitPush(get, never):Float;

	function get_hitPush():Float
		return cfg.hitPush == null ? 0 : cfg.hitPush;

	public var ready(get, never):Bool;

	function get_ready():Bool
		return cooldown <= 0;

	public var recovering(get, never):Bool;

	function get_recovering():Bool
		return cooldown > 0;

	public var recoverProgress(get, never):Float;

	function get_recoverProgress():Float
	{
		if (cooldown <= 0 || cooldownTotal <= 0)
			return 0;
		return 1 - cooldown / cooldownTotal;
	}

	public function coolFor(time:Float):Void
	{
		if (time <= 0)
			return;
		cooldownTotal = time * util.Levels.actionScale();
		cooldown = cooldownTotal;
	}

	public function new(director:EnemyDirector, hits:HitPipeline, fx:systems.Fx, cfg:SwingConfig)
	{
		this.director = director;
		this.hits = hits;
		this.fx = fx;
		this.cfg = cfg;
		slashes = new FlxTypedGroup<SlashEffect>();
	}

	public function fire(pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float, ?ox:Float, ?oy:Float):Void
	{
		if (cfg.cooldown != null)
			coolFor(cfg.cooldown);
		var ex = ox == null ? pmx : ox;
		var ey = oy == null ? pmy : oy;
		slashes.recycle(SlashEffect).fire(ex + dx * cfg.spawnDist, ey + dy * cfg.spawnDist, dx, dy, aimDeg, cfg.effectScale,
			cfg.effect == null ? "sword" : cfg.effect);
		strike(pmx, pmy, dx, dy);
		guardTimer = GUARD_TIME;
		guardX = dx;
		guardY = dy;
		deflect(pmx, pmy, dx, dy);
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
	}

	public function update(elapsed:Float, pmx:Float, pmy:Float):Void
	{
		if (cooldown > 0)
			cooldown -= elapsed;
		if (guardTimer <= 0)
			return;
		guardTimer -= elapsed;
		deflect(pmx, pmy, guardX, guardY);
	}

	function strike(pmx:Float, pmy:Float, aimX:Float, aimY:Float):Void
	{
		pmx += aimX * hitPush;
		pmy += aimY * hitPush - hitLift;
		var connected = false;
		director.eachInCircle(pmx, pmy, cfg.meleeRange, function(e)
		{
			var ex = e.x + e.width / 2 - pmx;
			var ey = e.y + e.height / 2 - pmy;
			var elen = Math.sqrt(ex * ex + ey * ey);
			if (elen > 0 && (ex * aimX + ey * aimY) / elen < cfg.meleeArcCos)
				return;

			if (!connected)
			{
				connected = true;
				fx.meleeImpact(cfg.hitstop, cfg.hitstopScale, cfg.hitShake);
			}

			var push = (elen > 0 ? elen : 1) / cfg.knock;
			var vx = ex / push;
			var vy = ey / push;
			hits.damageN(e, vx, vy, cfg.damage);
			e.brace(cfg.hitstop, cfg.hitBrace, vx, vy);
		});
	}

	function deflect(pmx:Float, pmy:Float, aimX:Float, aimY:Float):Void
	{
		if (cfg.deflects == false)
			return;

		pmx += aimX * hitPush;
		pmy += aimY * hitPush - hitLift;

		for (shot in director.shots.members)
		{
			if (shot == null || !shot.exists || shot.friendly)
				continue;

			var sx = shot.x + shot.width / 2 - pmx;
			var sy = shot.y + shot.height / 2 - pmy;
			var slen = Math.sqrt(sx * sx + sy * sy);
			if (slen > cfg.meleeRange)
				continue;
			if (slen > 0 && (sx * aimX + sy * aimY) / slen < cfg.meleeArcCos)
				continue;

			shot.deflect(aimX, aimY);
			FlxG.sound.play(Paths.sound("weapon/catch"), 0.5);
		}
	}
}
