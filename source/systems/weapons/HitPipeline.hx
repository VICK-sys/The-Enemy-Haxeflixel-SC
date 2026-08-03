package systems.weapons;

import flixel.FlxG;
import entities.enemy.Enemies;
import systems.enemy.EnemyDirector;
import systems.PlayerCombat;
import systems.Fx;
import systems.Pickups;
import systems.Scraps;
import util.Paths;
import systems.world.PropBlock;

class HitPipeline
{
	static inline var DROP_RATE:Float = 0.5;

	public var remote:Bool = false;
	public var owner:entities.Player;
	public var wantHeal:Void->Bool;
	public var onClaim:(Enemies, Float, Float, Float, Float) -> Void;
	public var onImpact:(Float, Float) -> Void;
	public var onNumber:(Float, Float, Float, Int, Dynamic) -> Void;

	private var status:PlayerCombat;
	private var fx:Fx;
	private var pickups:Pickups;
	private var scraps:Scraps;
	private var director:EnemyDirector;

	public function new(status:PlayerCombat, fx:Fx, pickups:Pickups, scraps:Scraps, director:EnemyDirector)
	{
		this.status = status;
		this.fx = fx;
		this.pickups = pickups;
		this.scraps = scraps;
		this.director = director;
	}

	public function damage(e:Enemies, pushX:Float, pushY:Float):Void
	{
		damageN(e, pushX, pushY, 1);
	}

	public function damageN(e:Enemies, pushX:Float, pushY:Float, damage:Float, feedMeter:Bool = true, crit:Bool = false):Void
		route(e, pushX, pushY, damage, feedMeter, crit);

	public function damageSuper(e:Enemies, pushX:Float, pushY:Float, damage:Float, crit:Bool = false):Void
		route(e, pushX, pushY, damage, false, crit);

	function route(e:Enemies, pushX:Float, pushY:Float, damage:Float, feedMeter:Bool, crit:Bool = false):Void
	{
		damage += util.Levels.damageBonus();
		if (owner != null && PropBlock.between(owner.x + owner.width / 2, owner.feetY, e.x + e.width / 2, e.feetY))
		{
			number(e, 0, DamageNumbers.BLOCKED);
			return;
		}
		if (remote)
		{
			claim(e, pushX, pushY, damage, 0, feedMeter, crit);
			return;
		}
		applyHit(e, pushX, pushY, damage, true, feedMeter, crit);
	}

	function number(e:Enemies, amount:Float, kind:Int):Void
	{
		if (onNumber != null)
			onNumber(e.x + e.width / 2, e.y, amount, kind, e);
	}

	public function applyHit(e:Enemies, pushX:Float, pushY:Float, damage:Float, rewardable:Bool, feedMeter:Bool = true,
			crit:Bool = false):Void
	{
		var landed = damage < e.hp ? damage : e.hp;
		var shrugged = e.isDead || e.buried;
		e.takeHit(pushX, pushY, damage);
		number(e, shrugged ? 0 : damage, shrugged ? DamageNumbers.BLOCKED : (crit ? DamageNumbers.CRIT : DamageNumbers.HIT));
		if (rewardable && feedMeter)
			status.rewardDamage(landed);

		util.Sfx.at("enemies/hit", e.x + e.width / 2, e.y + e.height / 2, 0.6);
		fx.sparksAt(e.x + e.width / 2, e.y + e.height / 2);
		if (rewardable && onImpact != null)
			onImpact(e.x + e.width / 2, e.y + e.height / 2);

		if (e.isDead)
		{
			fx.killImpact();
			if (rewardable)
			{
				status.rewardKill();
				scraps.drop(e.x + e.width / 2, e.y + e.height / 2);
			}
			var hurt = wantHeal == null ? status.health < status.healthMax : wantHeal();
			if (hurt && FlxG.random.float() < e.dropChance * DROP_RATE * status.dropScale())
				pickups.drop(e.x + e.width / 2, e.y + e.height / 2);
		}
	}

	function claim(e:Enemies, pushX:Float, pushY:Float, damage:Float, stunTime:Float, feedMeter:Bool = true,
			crit:Bool = false):Void
	{
		if (feedMeter)
			status.rewardDamage(damage < e.hp ? damage : e.hp);
		var shrugged = e.isDead || e.buried;
		number(e, shrugged ? 0 : damage, shrugged ? DamageNumbers.BLOCKED : (crit ? DamageNumbers.CRIT : DamageNumbers.HIT));
		util.Sfx.at("enemies/hit", e.x + e.width / 2, e.y + e.height / 2, 0.6);
		fx.sparksAt(e.x + e.width / 2, e.y + e.height / 2);
		e.flashTimer = 0.08;
		e.setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);
		if (onClaim != null)
			onClaim(e, pushX, pushY, damage, stunTime);
	}

	public function blastRadial(cx:Float, cy:Float, radius:Float, force:Float, damage:Float, bossScale:Float = 1):Void
		blast(cx, cy, radius, force, damage, bossScale, true);

	public function blastRadialSuper(cx:Float, cy:Float, radius:Float, force:Float, damage:Float, bossScale:Float = 1):Void
		blast(cx, cy, radius, force, damage, bossScale, false);

	function blast(cx:Float, cy:Float, radius:Float, force:Float, damage:Float, bossScale:Float, feedMeter:Bool):Void
	{
		director.eachInCircle(cx, cy, radius, function(e)
		{
			var dmg = e.bossBody ? damage * bossScale : damage;
			var ex = e.x + e.width / 2 - cx;
			var ey = e.y + e.height / 2 - cy;
			var len = Math.sqrt(ex * ex + ey * ey);
			if (len <= 0)
			{
				ex = 0;
				ey = -1;
				len = 1;
			}
			if (feedMeter)
				damageN(e, ex / len * force, ey / len * force, dmg);
			else
				damageSuper(e, ex / len * force, ey / len * force, dmg);
		});
	}
}
