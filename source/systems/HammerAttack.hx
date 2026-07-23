package systems;

import flixel.FlxG;
import util.Paths;

class HammerAttack
{
	static inline var REACH:Float = 140;
	static inline var RADIUS:Float = 160;
	static inline var DAMAGE:Int = 2;
	static inline var PUSH:Float = 1.6;
	static inline var STUN_TIME:Float = 2.0;

	public var shock:Shockwave;

	private var director:EnemyDirector;
	private var fx:Fx;
	private var hits:HitPipeline;

	public function new(director:EnemyDirector, fx:Fx, hits:HitPipeline)
	{
		this.director = director;
		this.fx = fx;
		this.hits = hits;
		shock = new Shockwave(director, function(e, pushX, pushY) hits.stun(e, pushX, pushY, STUN_TIME));
	}

	public function slam(pmx:Float, pmy:Float, dx:Float, dy:Float):Void
	{
		var ix = pmx + dx * REACH;
		var iy = pmy + dy * REACH;
		fx.sparksAt(ix, iy);
		fx.slamShake();
		director.eachInCircle(ix, iy, RADIUS, function(e)
		{
			var ex = e.x + e.width / 2 - ix;
			var ey = e.y + e.height / 2 - iy;
			var elen = Math.sqrt(ex * ex + ey * ey);
			if (elen <= 0)
			{
				ex = dx;
				ey = dy;
				elen = 1;
			}
			hits.damageN(e, ex / elen * PUSH, ey / elen * PUSH, DAMAGE);
		});
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
		FlxG.sound.play(Paths.sound("hammer"), 0.8);
	}

	public function quake(pmx:Float, pmy:Float, dx:Float, dy:Float):Void
	{
		var qx = pmx + dx * REACH;
		var qy = pmy + dy * REACH;
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
