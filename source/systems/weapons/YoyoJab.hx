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
	public var recovering(get, never):Bool;
	public var recoverProgress(get, never):Float;

	private var cfg = WeaponDataRegistry.get().yoyo;
	private var director:EnemyDirector;
	private var hits:HitPipeline;
	private var fx:systems.Fx;
	private var struck:Array<Enemies> = [];
	private var strikeAt:Array<Float> = [];
	private var cooldown:Float = 0;
	private var cooldownTotal:Float = 0;
	private var holdLeft:Float = 0;
	private var tired:Bool = false;
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

	function get_recovering():Bool
		return cooldown > 0;

	function get_recoverProgress():Float
	{
		if (cooldown <= 0 || cooldownTotal <= 0)
			return 0;
		return 1 - cooldown / cooldownTotal;
	}

	public function fire(hx:Float, hy:Float, dx:Float, dy:Float):Void
	{
		struck.resize(0);
		strikeAt.resize(0);
		spin = -spin;
		tired = false;
		holdLeft = cfg.holdTime * util.Levels.actionScale();
		flight.fire(hx, hy, dx, dy, spin);
		FlxG.sound.play(Paths.sound("weapon/throw"), 0.45);
	}

	public function release():Void
	{
		if (flight.active && !flight.homing)
			flight.recall();
	}

	public function stop():Void
	{
		flight.stop();
		struck.resize(0);
		strikeAt.resize(0);
	}

	public function update(elapsed:Float, hx:Float, hy:Float, aimX:Float, aimY:Float):Void
	{
		if (cooldown > 0)
			cooldown -= elapsed;
		for (i in 0...strikeAt.length)
			strikeAt[i] -= elapsed;

		if (flight.active && !flight.homing)
		{
			holdLeft -= elapsed;
			if (holdLeft <= 0)
			{
				tired = true;
				flight.recall();
			}
		}

		var was = flight.active;
		flight.update(elapsed, hx, hy, aimX, aimY);

		if (flight.active)
			sweep(hx, hy);
		else if (was)
		{
			cooldownTotal = (tired ? cfg.restCooldown : cfg.cooldown) * util.Levels.actionScale();
			cooldown = cooldownTotal;
			tired = false;
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
		var push = flight.homing ? -cfg.knock : cfg.knock;
		vx = vx / len * push;
		vy = vy / len * push;

		var connected = false;
		director.eachInCircle(cx, cy, cfg.hitRadius, function(e)
		{
			var at = struck.indexOf(e);
			if (at >= 0)
			{
				if (strikeAt[at] > 0)
					return;
				strikeAt[at] = cfg.hitGap;
			}
			else
			{
				struck.push(e);
				strikeAt.push(cfg.hitGap);
			}

			if (!connected)
			{
				connected = true;
				fx.meleeImpact(cfg.hitstop, cfg.hitstopScale, cfg.hitShake);
			}

			hits.damageN(e, vx, vy, cfg.damage);
			e.brace(cfg.hitstop, cfg.hitBrace, vx, vy);
			flight.bounce(cx - (e.x + e.width * 0.5), cy - (e.y + e.height * 0.5));
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
