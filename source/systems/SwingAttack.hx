package systems;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.SlashEffect;
import util.Paths;

class SwingAttack
{
	static inline var SPAWN_DIST:Float = 110;
	static inline var MELEE_RANGE:Float = 250;
	static inline var MELEE_ARC_COS:Float = -0.5;

	public var slashes:FlxTypedGroup<SlashEffect>;

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
		slashes.recycle(SlashEffect).fire(pmx + dx * SPAWN_DIST, pmy + dy * SPAWN_DIST, dx, dy, aimDeg);
		strike(pmx, pmy, dx, dy);
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
	}

	function strike(pmx:Float, pmy:Float, aimX:Float, aimY:Float):Void
	{
		director.eachInCircle(pmx, pmy, MELEE_RANGE, function(e)
		{
			var ex = e.x + e.width / 2 - pmx;
			var ey = e.y + e.height / 2 - pmy;
			var elen = Math.sqrt(ex * ex + ey * ey);
			if (elen > 0 && (ex * aimX + ey * aimY) / elen < MELEE_ARC_COS)
				return;

			var push = elen > 0 ? elen : 1;
			hits.damage(e, ex / push, ey / push);
		});
	}
}
