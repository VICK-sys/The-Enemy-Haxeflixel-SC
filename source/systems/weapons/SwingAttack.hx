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

	public function new(director:EnemyDirector, hits:HitPipeline, fx:systems.Fx, cfg:SwingConfig)
	{
		this.director = director;
		this.hits = hits;
		this.fx = fx;
		this.cfg = cfg;
		slashes = new FlxTypedGroup<SlashEffect>();
	}

	public function fire(pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		slashes.recycle(SlashEffect).fire(pmx + dx * cfg.spawnDist, pmy + dy * cfg.spawnDist, dx, dy, aimDeg, cfg.effectScale);
		strike(pmx, pmy, dx, dy);
		guardTimer = GUARD_TIME;
		guardX = dx;
		guardY = dy;
		deflect(pmx, pmy, dx, dy);
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
	}

	public function update(elapsed:Float, pmx:Float, pmy:Float):Void
	{
		if (guardTimer <= 0)
			return;
		guardTimer -= elapsed;
		deflect(pmx, pmy, guardX, guardY);
	}

	function strike(pmx:Float, pmy:Float, aimX:Float, aimY:Float):Void
	{
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
			hits.damageN(e, ex / push, ey / push, cfg.damage);
			e.brace(cfg.hitstop, cfg.hitBrace);
		});
	}

	function deflect(pmx:Float, pmy:Float, aimX:Float, aimY:Float):Void
	{
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

			shot.deflect();
			FlxG.sound.play(Paths.sound("weapon/catch"), 0.5);
		}
	}
}
