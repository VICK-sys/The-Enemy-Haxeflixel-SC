package systems.weapons;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.Bullet;
import systems.world.Arena;
import systems.world.PropBlock;
import systems.enemy.EnemyDirector;
import systems.Fx;
import util.Paths;
import data.WeaponData.WeaponDataRegistry;

class RevolverAttack
{
	static inline var MUZZLE:Float = 24;

	public var bullets:FlxTypedGroup<Bullet>;
	public var rounds:Int;
	public var gauge(get, never):Float;

	private var cfg = WeaponDataRegistry.get().revolver;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var fx:Fx;
	private var hits:HitPipeline;
	private var reloading:Float = 0;

	public function new(arena:Arena, director:EnemyDirector, fx:Fx, hits:HitPipeline)
	{
		this.arena = arena;
		this.director = director;
		this.fx = fx;
		this.hits = hits;
		bullets = new FlxTypedGroup<Bullet>();
		rounds = cfg.cylinder;
	}

	function get_gauge():Float
	{
		if (reloading > 0)
			return 1 - reloading / cfg.reloadTime;
		return rounds / cfg.cylinder;
	}

	public function canFire():Bool
		return reloading <= 0 && rounds > 0;

	public function canFan():Bool
		return reloading <= 0 && rounds > 0;

	public function fire(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		if (!canFire())
			return;

		spawn(bx, by, dx, dy, aimDeg, cfg.damage);
		rounds--;
		fx.sparksAt(bx + dx * MUZZLE, by + dy * MUZZLE);
		FlxG.sound.play(Paths.sound("enemies/pistol"), 0.65);
		if (rounds <= 0)
			reloading = cfg.reloadTime;
	}

	public function fanFire(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		if (!canFan())
			return;

		var n = rounds;
		for (i in 0...n)
		{
			var t = n == 1 ? 0.0 : (i / (n - 1) - 0.5) * 2;
			var deg = aimDeg + t * cfg.spread;
			var rad = deg * Math.PI / 180;
			spawn(bx, by, Math.cos(rad), Math.sin(rad), deg, cfg.fanDamage);
		}
		rounds = 0;
		reloading = cfg.reloadTime;
		fx.sparksAt(bx + dx * MUZZLE, by + dy * MUZZLE);
		FlxG.sound.play(Paths.sound("enemies/shoot"), 0.75);
		FlxG.camera.shake(0.006, 0.2);
	}

	function spawn(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float, damage:Int):Void
	{
		bullets.recycle(Bullet).fire(bx + dx * MUZZLE, by + dy * MUZZLE, dx, dy, aimDeg, damage, cfg.speed, cfg.range, cfg.knock);
	}

	public function reset():Void
	{
		rounds = cfg.cylinder;
		reloading = 0;
	}

	public function update(elapsed:Float):Void
	{
		for (b in bullets.members)
		{
			if (b == null || !b.exists)
				continue;

			var cx = b.x + b.width / 2;
			var cy = b.y + b.height / 2;
			var px = cx + b.dirX * cfg.hitRadius;
			var py = cy + b.dirY * cfg.hitRadius;
			if (arena.wallAt(px, py) || PropBlock.at(px, py))
			{
				b.kill();
				continue;
			}

			var hit = director.firstInCircle(cx, cy, cfg.hitRadius);
			if (hit != null)
			{
				hits.damageN(hit, b.dirX * b.knock, b.dirY * b.knock, b.damage);
				b.kill();
			}
		}

		if (reloading > 0)
		{
			reloading -= elapsed;
			if (reloading <= 0)
			{
				rounds = cfg.cylinder;
				FlxG.sound.play(Paths.sound("scythe/catch"), 0.35);
			}
		}
	}
}
