package systems;

import flixel.FlxG;
import entities.enemy.Enemies;
import util.Paths;

class HitPipeline
{
	private var status:PlayerCombat;
	private var fx:Fx;
	private var pickups:Pickups;

	public function new(status:PlayerCombat, fx:Fx, pickups:Pickups)
	{
		this.status = status;
		this.fx = fx;
		this.pickups = pickups;
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
}
