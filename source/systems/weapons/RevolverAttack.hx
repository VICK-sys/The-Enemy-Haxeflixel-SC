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
	public var capacity(get, never):Int;
	public var isReloading(get, never):Bool;

	private var cfg = WeaponDataRegistry.get().revolver;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var fx:Fx;
	private var hits:HitPipeline;
	private var reloading:Float = 0;
	private var fanning:Bool = false;
	private var fanTimer:Float = 0;

	public function new(arena:Arena, director:EnemyDirector, fx:Fx, hits:HitPipeline)
	{
		this.arena = arena;
		this.director = director;
		this.fx = fx;
		this.hits = hits;
		bullets = new FlxTypedGroup<Bullet>();
		rounds = cfg.cylinder;
	}

	function get_capacity():Int
		return cfg.cylinder;

	function get_isReloading():Bool
		return reloading > 0;

	public function canFire():Bool
		return reloading <= 0 && !fanning && rounds > 0;

	public function canFan():Bool
		return reloading <= 0 && !fanning && rounds > 0;

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

	public function beginReload():Bool
	{
		if (reloading > 0 || fanning || rounds >= cfg.cylinder)
			return false;

		reloading = cfg.reloadTime;
		return true;
	}

	public function fanFire():Void
	{
		if (!canFan())
			return;

		fanning = true;
		fanTimer = 0;
		FlxG.camera.shake(0.004, 0.25);
	}

	function spawn(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float, damage:Int):Void
	{
		bullets.recycle(Bullet).fire(bx + dx * MUZZLE, by + dy * MUZZLE, dx, dy, aimDeg, damage, cfg.speed, cfg.range, cfg.knock);
	}

	public function reset():Void
	{
		rounds = cfg.cylinder;
		reloading = 0;
		fanning = false;
		fanTimer = 0;
	}

	function fanShot(bx:Float, by:Float, aimDeg:Float):Void
	{
		var deg = aimDeg + (Math.random() * 2 - 1) * cfg.fanJitter;
		var rad = deg * Math.PI / 180;
		var jx = Math.cos(rad);
		var jy = Math.sin(rad);
		spawn(bx, by, jx, jy, deg, cfg.damage);
		fx.sparksAt(bx + jx * MUZZLE, by + jy * MUZZLE);
		FlxG.sound.play(Paths.sound("enemies/pistol"), 0.5);
		rounds--;
		if (rounds <= 0)
		{
			fanning = false;
			reloading = cfg.reloadTime;
		}
	}

	public function update(elapsed:Float, bx:Float, by:Float, aimDeg:Float):Void
	{
		if (fanning)
		{
			fanTimer -= elapsed;
			if (fanTimer <= 0)
			{
				fanTimer = cfg.fanInterval;
				fanShot(bx, by, aimDeg);
			}
		}

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
				FlxG.sound.play(Paths.sound("weapon/catch"), 0.35);
			}
		}
	}
}
