package systems.weapons;

import flixel.FlxG;
import entities.Player;
import entities.enemy.Enemies;
import systems.enemy.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class Spun
{
	public var e:Enemies;
	public var relAng:Float;
	public var dist:Float;

	public function new(e:Enemies, relAng:Float, dist:Float)
	{
		this.e = e;
		this.relAng = relAng;
		this.dist = dist;
	}
}

class YoyoSpin
{
	static inline var INNER:Float = 70;
	static inline var TIP_BAND:Float = 60;
	static inline var SPIN_VISUAL:Float = 1900;

	public var active(get, never):Bool;
	public var onGrab:(Enemies, Bool) -> Void;

	private var cfg = WeaponDataRegistry.get().yoyoSpin;
	private var player:Player;
	private var director:EnemyDirector;
	private var hits:HitPipeline;
	private var flight:YoyoFlight;
	private var running:Bool = false;
	private var timer:Float = 0;
	private var baseAng:Float = 0;
	private var caught:Array<Spun> = [];
	private var bigTouched:Array<Enemies> = [];

	public function new(player:Player, director:EnemyDirector, hits:HitPipeline, flight:YoyoFlight)
	{
		this.player = player;
		this.director = director;
		this.hits = hits;
		this.flight = flight;
	}

	function get_active():Bool
		return running;

	public function captives(out:Array<Enemies>):Void
	{
		for (s in caught)
			if (s.e != null && s.e.exists)
				out.push(s.e);
	}

	public function activate(aimDeg:Float):Void
	{
		running = true;
		timer = cfg.time;
		baseAng = aimDeg;
		caught.resize(0);
		bigTouched.resize(0);
		util.Sfx.at("arms_deploy", player.x + player.width * 0.5, player.y, 0.8);
		FlxG.sound.play(Paths.sound("weapon/throw"), 0.5);
	}

	public function cancel():Void
	{
		if (!running)
			return;
		for (s in caught)
			if (s.e != null && s.e.exists)
			{
				s.e.unseize(0.2);
				if (onGrab != null)
					onGrab(s.e, false);
			}
		caught.resize(0);
		bigTouched.resize(0);
		running = false;
		flight.stop();
	}

	public function update(elapsed:Float, hx:Float, hy:Float):Void
	{
		if (!running)
			return;

		var pcx = player.x + player.width * 0.5;
		var pcy = player.y + player.height * 0.5;

		timer -= elapsed;
		var t = 1 - timer / cfg.time;
		if (t > 1)
			t = 1;
		var ang = (baseAng + cfg.turns * 360 * t) * Math.PI / 180;

		var yx = pcx + Math.cos(ang) * cfg.radius;
		var yy = pcy + Math.sin(ang) * cfg.radius;
		flight.drive(yx, yy, t * cfg.turns * SPIN_VISUAL, hx, hy);

		sweep(pcx, pcy);

		for (s in caught)
		{
			if (s.e == null || !s.e.exists || s.e.isDead)
				continue;
			var ea = ang + s.relAng;
			s.e.velocity.set(0, 0);
			s.e.setPosition(pcx + Math.cos(ea) * s.dist - s.e.width * 0.5, pcy + Math.sin(ea) * s.dist - s.e.height * 0.5);
		}

		if (timer <= 0)
			release(pcx, pcy);
	}

	function sweep(pcx:Float, pcy:Float):Void
	{
		director.eachInCircle(pcx, pcy, cfg.radius + cfg.grabPad, function(e)
		{
			var dx = e.x + e.width * 0.5 - pcx;
			var dy = e.y + e.height * 0.5 - pcy;
			var dist = Math.sqrt(dx * dx + dy * dy);
			if (dist < INNER)
				return;

			if (e.big)
			{
				if (bigTouched.indexOf(e) >= 0)
					return;
				bigTouched.push(e);
				var len = dist <= 0 ? 1 : dist;
				hits.damageSuper(e, dx / len * 1.2, dy / len * 1.2, cfg.stringDamage);
				return;
			}

			if (e.seized || !e.grabbable)
				return;
			for (s in caught)
				if (s.e == e)
					return;

			var damage = dist >= cfg.radius - TIP_BAND ? cfg.grabDamage : cfg.stringDamage;
			hits.damageSuper(e, 0, 0, damage);
			if (e.isDead || !e.exists)
				return;

			e.seized = true;
			e.drag.set(0, 0);
			e.velocity.set(0, 0);
			var yoyoAng = Math.atan2(flight.cy - pcy, flight.cx - pcx);
			caught.push(new Spun(e, Math.atan2(dy, dx) - yoyoAng, dist));
			if (onGrab != null)
				onGrab(e, true);
		});
	}

	function release(pcx:Float, pcy:Float):Void
	{
		var aimAng = Math.atan2(util.Controls.aimY() - pcy, util.Controls.aimX() - pcx) * 180 / Math.PI;
		for (s in caught)
		{
			if (s.e == null || !s.e.exists)
				continue;
			var deg = aimAng + FlxG.random.float(-45, 45);
			var rad = deg * Math.PI / 180;
			var dx = Math.cos(rad);
			var dy = Math.sin(rad);
			s.e.unseize(0.5);
			if (onGrab != null)
				onGrab(s.e, false);
			hits.damageSuper(s.e, dx * cfg.launchPush, dy * cfg.launchPush, cfg.launchDamage);
			if (s.e.exists)
				s.e.velocity.set(dx * cfg.launchSpeed, dy * cfg.launchSpeed);
		}
		caught.resize(0);
		bigTouched.resize(0);
		running = false;
		flight.stop();
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
	}
}
