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
	public var onPellet:(Float, Float, Float) -> Void;

	private var cfg = WeaponDataRegistry.get().revolver;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var fx:Fx;
	private var hits:HitPipeline;
	private var reloading:Float = 0;
	private var reloadFrom:Int = 0;
	private var reloadTotal:Float = 0;
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

	public var isFanning(get, never):Bool;

	function get_isFanning():Bool
		return fanning;

	public function cancelFan():Void
	{
		if (!fanning)
			return;
		fanning = false;
		fanTimer = 0;
	}

	public var displayRounds(get, never):Int;

	function get_displayRounds():Int
		return reloading > 0 ? reloadFrom : rounds;

	public var reloadProgress(get, never):Float;

	function get_reloadProgress():Float
	{
		if (reloading <= 0 || reloadTotal <= 0)
			return 0;
		return 1 - reloading / reloadTotal;
	}

	function beginReloadFrom(n:Int):Void
	{
		reloadFrom = n;
		reloadTotal = cfg.reloadTime * util.Levels.actionScale();
		reloading = reloadTotal;
	}

	public function canFire():Bool
		return reloading <= 0 && !fanning && rounds > 0;

	public function canFan():Bool
		return reloading <= 0 && !fanning && rounds > 0;

	public function fire(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		if (!canFire())
			return;

		spawn(bx, by, dx, dy, aimDeg, cfg.damage, Bullet.SHOT);
		rounds--;
		fx.sparksAt(bx + dx * MUZZLE, by + dy * MUZZLE);
		FlxG.sound.play(Paths.sound("revolver"), 0.7);
		if (rounds <= 0)
			beginReloadFrom(0);
	}

	public function fireAt(bx:Float, by:Float, target:entities.enemy.Enemies, damage:Int):Void
	{
		if (rounds <= 0 || target == null)
			return;

		var dx = target.x + target.width / 2 - bx;
		var dy = target.y + target.height / 2 - by;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len <= 0)
		{
			dx = 1;
			dy = 0;
			len = 1;
		}
		dx /= len;
		dy /= len;

		var b = spawn(bx, by, dx, dy, Math.atan2(dy, dx) * 180 / Math.PI, damage, Bullet.SHOT);
		b.seek = target;
		rounds--;
		fx.sparksAt(bx + dx * MUZZLE, by + dy * MUZZLE);
		FlxG.sound.play(Paths.sound("revolver"), 0.75);
		if (rounds <= 0)
			beginReloadFrom(0);
	}

	public function beginReload():Bool
	{
		if (reloading > 0 || fanning || rounds >= cfg.cylinder)
			return false;

		beginReloadFrom(rounds);
		return true;
	}

	public function fanFire():Void
	{
		if (!canFan())
			return;

		fanning = true;
		fanTimer = 0;
		systems.Fx.shake(0.004, 0.25);
	}

	function spawn(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float, damage:Int, key:String):Bullet
	{
		var b = bullets.recycle(Bullet);
		b.setSprite(key);
		b.fire(bx + dx * MUZZLE, by + dy * MUZZLE, dx, dy, aimDeg, damage, cfg.speed, cfg.range, cfg.knock);
		return b;
	}

	function steer(b:Bullet):Void
	{
		if (b.seek == null)
			return;
		if (!b.seek.exists || b.seek.isDead)
		{
			b.seek = null;
			return;
		}
		var dx = b.seek.x + b.seek.width / 2 - (b.x + b.width / 2);
		var dy = b.seek.y + b.seek.height / 2 - (b.y + b.height / 2);
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len <= 0)
			return;
		b.dirX = dx / len;
		b.dirY = dy / len;
		b.velocity.set(b.dirX * cfg.speed, b.dirY * cfg.speed);
		b.angle = Math.atan2(b.dirY, b.dirX) * 180 / Math.PI;
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
		spawn(bx, by, jx, jy, deg, cfg.damage, Bullet.SHOT);
		fx.sparksAt(bx + jx * MUZZLE, by + jy * MUZZLE);
		FlxG.sound.play(Paths.sound("revolver"), 0.55);
		if (onPellet != null)
			onPellet(bx, by, deg);
		rounds--;
		if (rounds <= 0)
		{
			fanning = false;
			beginReloadFrom(0);
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

			steer(b);

			var cx = b.x + b.width / 2;
			var cy = b.y + b.height / 2;
			var px = cx + b.dirX * cfg.hitRadius;
			var py = cy + b.dirY * cfg.hitRadius;
			if (arena.wallAt(px, py) || PropBlock.at(px, py))
			{
				fx.breakAt(px, py, true);
				b.kill();
				continue;
			}

			if (b.seek != null)
			{
				var tcx = b.seek.x + b.seek.width / 2;
				var tcy = b.seek.y + b.seek.height / 2;
				var dx = tcx - cx;
				var dy = tcy - cy;
				if (dx * dx + dy * dy <= cfg.hitRadius * cfg.hitRadius || b.seek.overlaps(b))
				{
					hits.damageN(b.seek, b.dirX * b.knock, b.dirY * b.knock, b.damage);
					fx.impactAt(cx, cy);
					b.kill();
				}
				continue;
			}

			var hit = director.firstInCircle(cx, cy, cfg.hitRadius);
			if (hit != null)
			{
				hits.damageN(hit, b.dirX * b.knock, b.dirY * b.knock, b.damage);
				fx.impactAt(cx, cy);
				b.kill();
			}
		}

		if (reloading > 0)
		{
			reloading -= elapsed;
			if (reloading <= 0)
			{
				rounds = cfg.cylinder;
				FlxG.sound.play(Paths.sound("bulletLoad"), 0.55);
				FlxG.sound.play(Paths.sound("weapon/catch"), 0.3);
			}
		}
	}
}
