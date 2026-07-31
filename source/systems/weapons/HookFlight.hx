package systems.weapons;

import entities.enemy.Enemies;
import systems.world.Arena;
import systems.enemy.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;
import systems.world.PropBlock;

class HookFlight
{
	static inline var WALL_PROBE:Float = 50;

	public var active(get, never):Bool;
	public var passenger(get, never):Enemies;
	public var onRelease:Enemies->Void;

	private var cfg = WeaponDataRegistry.get().hook;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var hits:HitPipeline;

	private var victim:Enemies;
	private var timer:Float = 0;
	private var dirX:Float = 1;
	private var dirY:Float = 0;
	private var hitList:Array<Enemies> = [];

	public function new(arena:Arena, director:EnemyDirector, hits:HitPipeline)
	{
		this.arena = arena;
		this.director = director;
		this.hits = hits;
	}

	function get_active():Bool
		return victim != null;

	function get_passenger():Enemies
		return victim;

	public function launch(e:Enemies, dx:Float, dy:Float):Void
	{
		victim = e;
		dirX = dx;
		dirY = dy;
		hitList = [];
		timer = cfg.throwTime;
		victim.velocity.set(dirX * cfg.throwSpeed, dirY * cfg.throwSpeed);
		victim.drag.set(0, 0);
	}

	public function update(elapsed:Float):Void
	{
		if (victim == null)
			return;

		if (!victim.exists || victim.isDead)
		{
			victim = null;
			hitList = [];
			return;
		}

		victim.velocity.set(dirX * cfg.throwSpeed, dirY * cfg.throwSpeed);

		var vcx = victim.x + victim.width / 2;
		var vcy = victim.y + victim.height / 2;
		var px = vcx + dirX * WALL_PROBE;
		var py = vcy + dirY * WALL_PROBE;

		if (arena.wallAt(px, py) || PropBlock.at(px, py))
		{
			land(true);
			return;
		}

		timer -= elapsed;
		if (timer <= 0)
		{
			land(false);
			return;
		}

		var fv = victim;
		director.eachInCircle(vcx, vcy, cfg.throwHitRadius, function(e)
		{
			if (e == fv || e.seized || hitList.contains(e))
				return;
			hitList.push(e);
			hits.damage(e, dirX, dirY);
		});
	}

	function land(hitWall:Bool):Void
	{
		var v = victim;
		victim = null;
		hitList = [];
		v.unseize(cfg.releaseStun);
		if (onRelease != null)
			onRelease(v);
		if (hitWall)
			hits.damageN(v, -dirX * 0.4, -dirY * 0.4, cfg.slamDamage);
	}

	public function stop():Void
	{
		if (victim != null)
		{
			victim.unseize(cfg.releaseStun);
			if (onRelease != null)
				onRelease(victim);
		}
		victim = null;
		hitList = [];
	}
}
