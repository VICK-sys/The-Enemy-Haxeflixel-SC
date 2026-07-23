package systems.weapons;

import flixel.FlxG;
import entities.enemy.Enemies;
import systems.EnemyDirector;
import systems.PlayerCombat;
import systems.Fx;
import systems.Pickups;
import util.Paths;

class HitPipeline
{
	private var status:PlayerCombat;
	private var fx:Fx;
	private var pickups:Pickups;
	private var director:EnemyDirector;

	public function new(status:PlayerCombat, fx:Fx, pickups:Pickups, director:EnemyDirector)
	{
		this.status = status;
		this.fx = fx;
		this.pickups = pickups;
		this.director = director;
	}

	public function damage(e:Enemies, pushX:Float, pushY:Float):Void
	{
		damageN(e, pushX, pushY, 1);
	}

	public function damageN(e:Enemies, pushX:Float, pushY:Float, damage:Int):Void
	{
		e.takeHit(pushX, pushY, damage);

		FlxG.sound.play(Paths.sound("enemies/hit"), 0.6);
		fx.sparksAt(e.x + e.width / 2, e.y + e.height / 2);

		if (e.isDead)
		{
			fx.killImpact();
			status.rewardKill();
			if (FlxG.random.float() < e.dropChance)
				pickups.drop(e.x + e.width / 2, e.y + e.height / 2);
		}
	}

	public function stun(e:Enemies, pushX:Float, pushY:Float, duration:Float):Void
	{
		damageN(e, pushX * 0.2, pushY * 0.2, 0);
		e.stun = duration;
	}

	public function blastRadial(cx:Float, cy:Float, radius:Float, force:Float, damage:Int, fallbackX:Float = 0, fallbackY:Float = -1):Void
	{
		director.eachInCircle(cx, cy, radius, function(e)
		{
			var ex = e.x + e.width / 2 - cx;
			var ey = e.y + e.height / 2 - cy;
			var len = Math.sqrt(ex * ex + ey * ey);
			if (len <= 0)
			{
				ex = fallbackX;
				ey = fallbackY;
				len = 1;
			}
			damageN(e, ex / len * force, ey / len * force, damage);
		});
	}
}
