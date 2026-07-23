package systems.weapons;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.Arrow;
import systems.Arena;
import systems.EnemyDirector;
import systems.Fx;
import util.Paths;

class BowAttack
{
	public var arrows:FlxTypedGroup<Arrow>;
	public var rain:ArrowRain;

	private var arena:Arena;
	private var director:EnemyDirector;
	private var hits:HitPipeline;

	public function new(arena:Arena, director:EnemyDirector, fx:Fx, hits:HitPipeline)
	{
		this.arena = arena;
		this.director = director;
		this.hits = hits;
		arrows = new FlxTypedGroup<Arrow>();
		rain = new ArrowRain(fx, hits);
	}

	public function shoot(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		arrows.recycle(Arrow).fire(bx + dx * 10, by + dy * 10, dx, dy, aimDeg);
		FlxG.sound.play(Paths.sound("bow"), 0.7);
	}

	public function rainFire(tx:Float, ty:Float, bx:Float, by:Float):Void
	{
		rain.fire(tx, ty, bx, by);
		FlxG.sound.play(Paths.sound("bow"), 0.7);
	}

	public function update(elapsed:Float):Void
	{
		for (arrow in arrows.members)
		{
			if (arrow == null || !arrow.exists)
				continue;
			var acx = arrow.x + arrow.width / 2;
			var acy = arrow.y + arrow.height / 2;
			if (arena.wallAt(acx + arrow.dirX * Arrow.RADIUS, acy + arrow.dirY * Arrow.RADIUS))
			{
				arrow.kill();
				continue;
			}
			var hit = director.firstInCircle(acx, acy, Arrow.RADIUS);
			if (hit != null)
			{
				hits.damage(hit, arrow.dirX, arrow.dirY);
				arrow.kill();
			}
		}

		rain.update(elapsed);
	}
}
