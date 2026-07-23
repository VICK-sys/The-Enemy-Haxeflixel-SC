package systems.weapons;

import flixel.FlxG;
import systems.EnemyDirector;
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
		shock = new Shockwave(director, function(e, pushX, pushY) hits.stun(e, pushX, pushY, cfg.stunTime));
	}

	public function slam(pmx:Float, pmy:Float, dx:Float, dy:Float):Void
	{
		var ix = pmx + dx * cfg.reach;
		var iy = pmy + dy * cfg.reach;
		fx.sparksAt(ix, iy);
		fx.slamShake();
		hits.blastRadial(ix, iy, cfg.radius, cfg.push, cfg.damage, dx, dy);
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
		FlxG.sound.play(Paths.sound("hammer"), 0.8);
	}

	public function quake(pmx:Float, pmy:Float, dx:Float, dy:Float):Void
	{
		var qx = pmx + dx * cfg.reach;
		var qy = pmy + dy * cfg.reach;
		shock.blast(qx, qy);
		fx.sparksAt(qx, qy);
		fx.slamShake();
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
		FlxG.sound.play(Paths.sound("hammer"), 1);
	}

	public function update(elapsed:Float):Void
	{
		shock.update(elapsed);
	}
}
