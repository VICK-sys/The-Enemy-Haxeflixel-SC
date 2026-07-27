package systems.weapons;

import flixel.FlxG;
import systems.enemy.EnemyDirector;
import systems.Fx;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class HammerAttack
{
	public var shock:Shockwave;

	private var cfg = WeaponDataRegistry.get().hammer;

	private var director:EnemyDirector;
	private var fx:Fx;
	private var hits:HitPipeline;

	public function new(director:EnemyDirector, fx:Fx, hits:HitPipeline)
	{
		this.director = director;
		this.fx = fx;
		this.hits = hits;
		shock = new Shockwave(director, hits, cfg.stunTime);
	}

	public function update(elapsed:Float):Void
	{
		shock.update(elapsed);
	}
}
