package systems.weapons;

import flixel.FlxG;
import entities.enemy.Enemies;
import systems.enemy.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class YoyoJab
{
	public var flight:YoyoFlight;

	public var active(get, never):Bool;
	public var ready(get, never):Bool;

	private var cfg = WeaponDataRegistry.get().yoyo;
	private var director:EnemyDirector;
	private var hits:HitPipeline;
	private var fx:systems.Fx;
	private var struck:Array<Enemies> = [];
	private var cooldown:Float = 0;
	private var spin:Float = 1;

	public function new(director:EnemyDirector, hits:HitPipeline, fx:systems.Fx)
	{
		this.director = director;
		this.hits = hits;
		this.fx = fx;
		flight = new YoyoFlight();
	}

	function get_active():Bool
		return flight.active;

	function get_ready():Bool
		return !flight.active && cooldown <= 0;

	public function fire(hx:Float, hy:Float, dx:Float, dy:Float):Void
	{
		struck.resize(0);
		spin = -spin;
		flight.fire(hx, hy, dx, dy, spin);
		FlxG.sound.play(Paths.sound("weapon/throw"), 0.45);
	}

	public function stop():Void
	{
		flight.stop();
		struck.resize(0);
	}

	public function update(elapsed:Float, hx:Float, hy:Float):Void
	{
		if (cooldown > 0)
			cooldown -= elapsed;

		var wasOut = flight.active;
		flight.update(elapsed, hx, hy);

		if (flight.active)
			sweep(hx, hy);
		else if (wasOut)
		{
			cooldown = cfg.cooldown * util.Levels.actionScale();
			FlxG.sound.play(Paths.sound("weapon/catch"), 0.3);
		}
	}

	function sweep(hx:Float, hy:Float):Void
	{
		var cx = flight.cx;
		var cy = flight.cy;
		var vx = cx - hx;
		var vy = cy - hy;
		var len = Math.sqrt(vx * vx + vy * vy);
		if (len <= 0)
			len = 1;
		var push = flight.returning ? -cfg.knock : cfg.knock;
		vx = vx / len * push;
		vy = vy / len * push;

		var connected = false;
		director.eachInCircle(cx, cy, cfg.hitRadius, function(e)
		{
			if (struck.indexOf(e) >= 0)
				return;
			struck.push(e);

			if (!connected)
			{
				connected = true;
				fx.meleeImpact(cfg.hitstop, cfg.hitstopScale, cfg.hitShake);
			}

			hits.damageN(e, vx, vy, cfg.damage);
			e.brace(cfg.hitstop, cfg.hitBrace, vx, vy);
		});

		for (shot in director.shots.members)
		{
			if (shot == null || !shot.exists || shot.friendly)
				continue;
			var sx = shot.x + shot.width / 2 - cx;
			var sy = shot.y + shot.height / 2 - cy;
			if (sx * sx + sy * sy > cfg.hitRadius * cfg.hitRadius)
				continue;
			shot.deflect();
			FlxG.sound.play(Paths.sound("weapon/catch"), 0.5);
		}
	}
}
