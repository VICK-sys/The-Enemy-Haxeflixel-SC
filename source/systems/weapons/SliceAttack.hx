package systems.weapons;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.SliceProjectile;
import systems.Arena;
import systems.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class SliceAttack
{
	public var slices:FlxTypedGroup<SliceProjectile>;

	private var cfg = WeaponDataRegistry.get().slice;

	private var arena:Arena;
	private var director:EnemyDirector;
	private var hits:HitPipeline;

	public function new(arena:Arena, director:EnemyDirector, hits:HitPipeline)
	{
		this.arena = arena;
		this.director = director;
		this.hits = hits;
		slices = new FlxTypedGroup<SliceProjectile>();
	}

	public function fire(pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		slices.recycle(SliceProjectile).fire(pmx + dx * cfg.spawnDist, pmy + dy * cfg.spawnDist, dx, dy, aimDeg);
		FlxG.sound.play(Paths.sound("scythe/slice"), 0.7);
	}

	public function update():Void
	{
		for (slice in slices.members)
		{
			if (slice == null || !slice.exists || slice.fading)
				continue;
			var scx = slice.x + slice.width / 2;
			var scy = slice.y + slice.height / 2;
			if (arena.wallAt(scx + slice.dirX * SliceProjectile.RADIUS, scy + slice.dirY * SliceProjectile.RADIUS))
			{
				slice.velocity.set(0, 0);
				slice.fading = true;
				continue;
			}
			var s = slice;
			director.eachInCircle(scx, scy, SliceProjectile.RADIUS, function(e)
			{
				if (s.hasHit(e))
					return;
				s.markHit(e);
				hits.damage(e, s.dirX, s.dirY);
			});
		}
	}
}
