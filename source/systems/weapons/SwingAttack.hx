package systems.weapons;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.SlashEffect;
import systems.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class SwingAttack
{
	public var slashes:FlxTypedGroup<SlashEffect>;

	private var cfg = WeaponDataRegistry.get().swing;
	private var director:EnemyDirector;
	private var hits:HitPipeline;

	public function new(director:EnemyDirector, hits:HitPipeline)
	{
		this.director = director;
		this.hits = hits;
		slashes = new FlxTypedGroup<SlashEffect>();
	}

	public function fire(pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		slashes.recycle(SlashEffect).fire(pmx + dx * cfg.spawnDist, pmy + dy * cfg.spawnDist, dx, dy, aimDeg);
		strike(pmx, pmy, dx, dy);
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
	}

	function strike(pmx:Float, pmy:Float, aimX:Float, aimY:Float):Void
	{
		director.eachInCircle(pmx, pmy, cfg.meleeRange, function(e)
		{
			var ex = e.x + e.width / 2 - pmx;
			var ey = e.y + e.height / 2 - pmy;
			var elen = Math.sqrt(ex * ex + ey * ey);
			if (elen > 0 && (ex * aimX + ey * aimY) / elen < cfg.meleeArcCos)
				return;

			var push = elen > 0 ? elen : 1;
			hits.damage(e, ex / push, ey / push);
		});
	}
}
