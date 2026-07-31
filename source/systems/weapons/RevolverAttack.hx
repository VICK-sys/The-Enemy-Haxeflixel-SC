package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.Bullet;
import systems.world.Arena;
import systems.world.PropBlock;
import systems.enemy.EnemyDirector;
import systems.Fx;
import systems.PlayerCombat;
import util.Paths;
import data.WeaponData.WeaponDataRegistry;

class RevolverAttack
{
	static inline var MUZZLE:Float = 24;
	static inline var TWIN_SEP:Float = 34;
	static inline var BIG_SPRITE:String = "bullets/shotgun_bullet_player";

	public var bullets:FlxTypedGroup<Bullet>;
	public var twinSprite:FlxSprite;
	public var rounds:Int;
	public var capacity(get, never):Int;
	public var isReloading(get, never):Bool;

	private var cfg = WeaponDataRegistry.get().revolver;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var fx:Fx;
	private var hits:HitPipeline;
	private var status:PlayerCombat;
	private var reloading:Float = 0;
	private var reloadFrom:Int = 0;
	private var reloadTotal:Float = 0;
	private var fireTimer:Float = 0;
	private var bigTimer:Float = 0;
	private var twin:Bool = false;
	private var twinHandX:Float = 0;
	private var twinHandY:Float = 0;
	private var twinPlaced:Bool = false;

	public function new(arena:Arena, director:EnemyDirector, fx:Fx, hits:HitPipeline, status:PlayerCombat)
	{
		this.arena = arena;
		this.director = director;
		this.fx = fx;
		this.hits = hits;
		this.status = status;
		bullets = new FlxTypedGroup<Bullet>();
		rounds = cfg.cylinder;

		twinSprite = new FlxSprite();
		twinSprite.antialiasing = false;
		twinSprite.scale.set(4, 4);
		twinSprite.visible = false;
	}

	function get_capacity():Int
		return cfg.cylinder;

	function get_isReloading():Bool
		return reloading > 0;

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

	public var twinActive(get, never):Bool;

	function get_twinActive():Bool
		return twin;

	function beginReloadFrom(n:Int):Void
	{
		reloadFrom = n;
		reloadTotal = cfg.reloadTime * util.Levels.actionScale();
		reloading = reloadTotal;
	}

	public function canFire():Bool
		return reloading <= 0 && fireTimer <= 0 && rounds > 0;

	public function canBig():Bool
		return reloading <= 0 && bigTimer <= 0 && fireTimer <= 0 && rounds >= cfg.bigCost;

	public function fire(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		if (!canFire())
			return;

		fireTimer = cfg.fireInterval * util.Levels.actionScale();
		spawn(bx, by, dx, dy, aimDeg, cfg.damage, Bullet.SHOT, cfg.hitRadius);
		rounds--;
		fx.sparksAt(bx + dx * MUZZLE, by + dy * MUZZLE);
		FlxG.sound.play(Paths.sound("revolver"), 0.7);
		if (rounds <= 0)
			beginReloadFrom(0);
	}

	public function fireBig(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		if (!canBig())
			return;

		bigTimer = cfg.bigCooldown * util.Levels.actionScale();
		fireTimer = cfg.fireInterval * util.Levels.actionScale();
		spawn(bx, by, dx, dy, aimDeg, cfg.bigDamage, BIG_SPRITE, cfg.bigRadius);
		rounds -= cfg.bigCost;
		fx.sparksAt(bx + dx * MUZZLE, by + dy * MUZZLE);
		systems.Fx.shake(0.005, 0.15);
		FlxG.sound.play(Paths.sound("revolver"), 0.85);
		FlxG.sound.play(Paths.sound("hammer"), 0.4);
		if (rounds <= 0)
			beginReloadFrom(0);
	}

	public function activateTwin():Void
	{
		twin = true;
		twinPlaced = false;
		twinSprite.loadGraphic(util.HuePalette.graphic("items/revolver", util.SaveData.playerHue()));
		twinSprite.origin.set(twinSprite.width * 0.5, twinSprite.height * 0.5);
		FlxG.sound.play(Paths.sound("power_up"), 0.7);
	}

	public function endTwin():Void
	{
		if (!twin)
			return;
		twin = false;
		twinPlaced = false;
		twinSprite.visible = false;
	}

	public function placeTwin(held:FlxSprite, pcx:Float, pcy:Float, handX:Float, handY:Float, aimDx:Float, aimDy:Float):Void
	{
		twinSprite.visible = twin && held.visible;
		if (!twinSprite.visible)
			return;

		var perpX = -aimDy;
		var perpY = aimDx;
		var lat = (handX - pcx) * perpX + (handY - pcy) * perpY;
		var shift = -2 * lat;
		if (shift > -TWIN_SEP && shift < TWIN_SEP)
			shift = shift >= 0 ? TWIN_SEP : -TWIN_SEP;

		twinHandX = held.x + held.origin.x + perpX * shift;
		twinHandY = held.y + held.origin.y + perpY * shift;
		twinPlaced = true;

		twinSprite.x = twinHandX - twinSprite.origin.x;
		twinSprite.y = twinHandY - twinSprite.origin.y;
		twinSprite.angle = held.angle;
		twinSprite.flipX = held.flipX;
		twinSprite.flipY = held.flipY;
		twinSprite.scale.set(held.scale.x, held.scale.y);
	}

	public function beginReload():Bool
	{
		if (reloading > 0 || rounds >= cfg.cylinder)
			return false;

		beginReloadFrom(rounds);
		return true;
	}

	function spawn(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float, damage:Float, key:String, radius:Float):Bullet
	{
		var b = bullets.recycle(Bullet);
		b.setSprite(key);
		b.fire(bx + dx * MUZZLE, by + dy * MUZZLE, dx, dy, aimDeg, damage, cfg.speed, cfg.range, cfg.knock, radius);

		if (twin)
		{
			var tx = twinPlaced ? twinHandX : bx - dy * TWIN_SEP * 2;
			var ty = twinPlaced ? twinHandY : by + dx * TWIN_SEP * 2;
			var t = bullets.recycle(Bullet);
			t.setSprite(key);
			t.fire(tx + dx * MUZZLE, ty + dy * MUZZLE, dx, dy, aimDeg, damage, cfg.speed, cfg.range, cfg.knock, radius);
			t.fromSuper = true;
			fx.sparksAt(tx + dx * MUZZLE, ty + dy * MUZZLE);
		}
		return b;
	}

	public function reset():Void
	{
		rounds = cfg.cylinder;
		reloading = 0;
		fireTimer = 0;
		bigTimer = 0;
		endTwin();
	}

	public function update(elapsed:Float, bx:Float, by:Float, aimDeg:Float):Void
	{
		if (fireTimer > 0)
			fireTimer -= elapsed;
		if (bigTimer > 0)
			bigTimer -= elapsed;

		if (twin && !status.drainSuper(elapsed / cfg.twinTime))
			endTwin();

		for (b in bullets.members)
		{
			if (b == null || !b.exists)
				continue;

			var cx = b.x + b.width / 2;
			var cy = b.y + b.height / 2;
			var px = cx + b.dirX * b.hitR;
			var py = cy + b.dirY * b.hitR;
			if (arena.wallAt(px, py) || PropBlock.at(px, py))
			{
				fx.breakAt(px, py, true);
				b.kill();
				continue;
			}

			var hit = director.firstInCircle(cx, cy, b.hitR);
			if (hit != null)
			{
				if (b.fromSuper)
					hits.damageSuper(hit, b.dirX * b.knock, b.dirY * b.knock, b.damage);
				else
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
