package systems.weapons;

import flixel.FlxG;
import entities.Player;
import entities.enemy.Enemies;
import entities.weapon.HookShot;
import systems.enemy.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class HookWhirl
{
	private var cfg = WeaponDataRegistry.get().hook;
	private var player:Player;
	private var director:EnemyDirector;
	private var hits:HitPipeline;
	private var hook:HookShot;

	private var timer:Float = 0;
	private var base:Float = 0;
	private var hitList:Array<Enemies> = [];

	public function new(player:Player, director:EnemyDirector, hits:HitPipeline, hook:HookShot)
	{
		this.player = player;
		this.director = director;
		this.hits = hits;
		this.hook = hook;
	}

	public function begin(aimDeg:Float):Void
	{
		base = aimDeg;
		timer = cfg.whirlTime;
		hitList = [];
		hook.revive();
		hook.velocity.set(0, 0);
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
	}

	public function update(elapsed:Float):Bool
	{
		timer -= elapsed;
		var p = 1 - timer / cfg.whirlTime;
		if (p > 1)
			p = 1;

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var ang = (base + 360 * p) * Math.PI / 180;
		var hx = pmx + Math.cos(ang) * cfg.whirlRadius;
		var hy = pmy + Math.sin(ang) * cfg.whirlRadius;
		hook.velocity.set(0, 0);
		hook.setPosition(hx - hook.width / 2, hy - hook.height / 2);
		hook.angle = ang * 180 / Math.PI + 90;

		director.eachInCircle(hx, hy, cfg.whirlHitRadius, function(e)
		{
			if (e.seized || hitList.contains(e))
				return;
			hitList.push(e);
			hits.damage(e, Math.cos(ang), Math.sin(ang));
		});

		if (timer > 0)
			return true;
		hitList = [];
		return false;
	}

	public function stop():Void
		hitList = [];
}
