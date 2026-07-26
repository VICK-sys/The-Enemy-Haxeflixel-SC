package systems.weapons;

import flixel.FlxG;
import entities.enemy.Enemies;
import systems.enemy.EnemyDirector;
import systems.PlayerCombat;
import systems.Fx;
import systems.Pickups;
import util.Paths;
import systems.world.PropBlock;

class HitPipeline
{
	public var remote:Bool = false;
	public var owner:entities.Player;
	public var onClaim:(Enemies, Float, Float, Int, Float) -> Void;
	public var onImpact:(Float, Float) -> Void;

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
		if (owner != null && PropBlock.between(owner.x + owner.width / 2, owner.feetY, e.x + e.width / 2, e.feetY))
			return;
		if (remote)
		{
			claim(e, pushX, pushY, damage, 0);
			return;
		}
		applyHit(e, pushX, pushY, damage, true);
	}

	public function applyHit(e:Enemies, pushX:Float, pushY:Float, damage:Int, rewardable:Bool):Void
	{
		e.takeHit(pushX, pushY, damage);

		FlxG.sound.play(Paths.sound("enemies/hit"), 0.6);
		fx.sparksAt(e.x + e.width / 2, e.y + e.height / 2);
		if (rewardable && onImpact != null)
			onImpact(e.x + e.width / 2, e.y + e.height / 2);

		if (e.isDead)
		{
			fx.killImpact();
			if (rewardable)
				status.rewardKill();
			if (FlxG.random.float() < e.dropChance)
				pickups.drop(e.x + e.width / 2, e.y + e.height / 2);
		}
	}

	function claim(e:Enemies, pushX:Float, pushY:Float, damage:Int, stunTime:Float):Void
	{
		FlxG.sound.play(Paths.sound("enemies/hit"), 0.6);
		fx.sparksAt(e.x + e.width / 2, e.y + e.height / 2);
		e.flashTimer = 0.08;
		e.setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);
		if (onClaim != null)
			onClaim(e, pushX, pushY, damage, stunTime);
	}

	public function stun(e:Enemies, pushX:Float, pushY:Float, duration:Float):Void
	{
		if (remote)
		{
			claim(e, pushX * 0.2, pushY * 0.2, 0, duration);
			return;
		}
		applyHit(e, pushX * 0.2, pushY * 0.2, 0, true);
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
