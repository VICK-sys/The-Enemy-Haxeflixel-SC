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
	static inline var TWIN_SIDE:Float = 25;
	static inline var TWIN_FWD:Float = 28;
	static inline var TWIN_SHADE:Int = 0xFF8A8A8A;
	static inline var TWIN_STAGGER:Float = 0.09;
	static inline var TWIN_RELOAD:Float = 0.3;
	static inline var TWIN_KICK:Float = 16;
	static inline var KICK_FADE:Float = 7;
	static inline var BIG_SPRITE:String = "bullets/shotgun_bullet_player";
	static inline var BIG_TARGETS:Int = 2;
	static inline var SPIN_AT:Float = 2 / 11;
	static inline var SPIN_END_AT:Float = 8 / 11;
	static inline var SPIN_VOL:Float = 0.5;
	static inline var SPIN_END_VOL:Float = 0.45;
	static inline var TWIN_SPIN_GAP:Float = 0.13;
	static inline var TWIN_SPIN_VOL:Float = 0.4;
	static inline var TWIN_SPIN_END_VOL:Float = 0.36;

	public var bullets:FlxTypedGroup<Bullet>;
	public var twinSprite:FlxSprite;
	public var onTwinShot:(Float, Float, Float, Float, Float, Bool) -> Void;
	public var rounds:Int;
	public var twinRounds(default, null):Int = 0;
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
	private var twinReloadFrom:Int = 0;
	private var reloadTotal:Float = 0;
	private var spinSound:flixel.sound.FlxSound;
	private var spinEndSound:flixel.sound.FlxSound;
	private var spinSoundB:flixel.sound.FlxSound;
	private var spinEndSoundB:flixel.sound.FlxSound;
	private var spunStart:Bool = false;
	private var spunEnd:Bool = false;
	private var spinBDelay:Float = 0;
	private var spinEndBDelay:Float = 0;
	private var fireTimer:Float = 0;
	private var bigTimer:Float = 0;
	private var twin:Bool = false;
	private var twinHandX:Float = 0;
	private var twinHandY:Float = 0;
	private var twinPlaced:Bool = false;
	private var twinKick:Float = 0;
	private var twinFlip:Bool = false;
	private var pendDelay:Float = 0;
	private var pendCost:Int = 1;
	private var pendDx:Float = 1;
	private var pendDy:Float = 0;
	private var pendDeg:Float = 0;
	private var pendDamage:Float = 0;
	private var pendRadius:Float = 0;
	private var pendTargets:Int = 1;
	private var pendKey:String = null;

	public function new(arena:Arena, director:EnemyDirector, fx:Fx, hits:HitPipeline, status:PlayerCombat)
	{
		this.arena = arena;
		this.director = director;
		this.fx = fx;
		this.hits = hits;
		this.status = status;
		bullets = new FlxTypedGroup<Bullet>();
		rounds = cfg.cylinder;

		spinSound = FlxG.sound.create(Paths.sound("weapon/gunSpin"));
		spinSound.volume = SPIN_VOL;
		spinEndSound = FlxG.sound.create(Paths.sound("weapon/gunSpinEnd"));
		spinEndSound.volume = SPIN_END_VOL;
		spinSoundB = FlxG.sound.create(Paths.sound("weapon/gunSpin"));
		spinSoundB.volume = TWIN_SPIN_VOL;
		spinEndSoundB = FlxG.sound.create(Paths.sound("weapon/gunSpinEnd"));
		spinEndSoundB.volume = TWIN_SPIN_END_VOL;

		twinSprite = new FlxSprite();
		util.PixelPerfectShader.on(twinSprite);
		twinSprite.scale.set(4, 4);
		twinSprite.color = TWIN_SHADE;
		twinSprite.visible = false;
	}

	function get_capacity():Int
		return cfg.cylinder;

	function get_isReloading():Bool
		return reloading > 0;

	public var displayRounds(get, never):Int;

	function get_displayRounds():Int
		return reloading > 0 ? reloadFrom : rounds;

	public var displayTwinRounds(get, never):Int;

	function get_displayTwinRounds():Int
	{
		if (reloading > 0)
			return twinReloadFrom;
		return settledTwin();
	}

	function settledTwin():Int
	{
		var n = twinRounds - (pendKey != null ? pendCost : 0);
		return n < 0 ? 0 : n;
	}

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

	function beginReloadFrom(n:Int, quick:Bool = false):Void
	{
		reloadFrom = n;
		twinReloadFrom = settledTwin();
		reloadTotal = cfg.reloadTime * (quick ? TWIN_RELOAD : 1) * util.Levels.actionScale();
		reloading = reloadTotal;
		spunStart = false;
		spunEnd = false;
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
		spawn(bx, by, dx, dy, aimDeg, cfg.damage, Bullet.SHOT, cfg.hitRadius, 1);
		rounds--;
		fx.sparksAt(bx + dx * MUZZLE, by + dy * MUZZLE);
		FlxG.sound.play(Paths.sound("revolver/shot" + (1 + Std.random(3))), 0.7);
		if (rounds <= 0)
			beginReloadFrom(0);
	}

	public function fireBig(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		if (!canBig())
			return;

		bigTimer = cfg.bigCooldown * util.Levels.actionScale();
		fireTimer = cfg.fireInterval * util.Levels.actionScale();
		spawn(bx, by, dx, dy, aimDeg, cfg.bigDamage, BIG_SPRITE, cfg.bigRadius, cfg.bigCost, BIG_TARGETS);
		rounds -= cfg.bigCost;
		fx.sparksAt(bx + dx * MUZZLE, by + dy * MUZZLE);
		systems.Fx.shake(0.005, 0.15);
		FlxG.sound.play(Paths.sound("revolver/rclick" + (1 + Std.random(2))), 0.85);
		FlxG.sound.play(Paths.sound("hammer"), 0.4);
		if (rounds <= 0)
			beginReloadFrom(0);
	}

	public function activateTwin():Void
	{
		twin = true;
		twinPlaced = false;
		twinRounds = 0;
		twinSprite.loadGraphic(util.HuePalette.graphic("items/revolver", util.SaveData.playerHue()));
		twinSprite.origin.set(twinSprite.width * 0.5, twinSprite.height * 0.5);
		twinSprite.color = TWIN_SHADE;
		beginReloadFrom(reloading > 0 ? reloadFrom : rounds, true);
		FlxG.sound.play(Paths.sound("power_up"), 0.7);
	}

	public function endTwin():Void
	{
		if (!twin)
			return;
		twin = false;
		twinPlaced = false;
		twinRounds = 0;
		twinKick = 0;
		pendDelay = 0;
		pendKey = null;
		spinBDelay = 0;
		spinEndBDelay = 0;
		twinSprite.visible = false;
	}

	public function placeTwin(held:FlxSprite, pcx:Float, pcy:Float, handX:Float, handY:Float, aimDx:Float, aimDy:Float):Void
	{
		twinSprite.visible = twin && held.visible;
		if (!twinSprite.visible)
			return;

		var perpX = -aimDy;
		var perpY = aimDx;
		var shift = perpY > 0 ? -TWIN_SIDE : (perpY < 0 ? TWIN_SIDE : (perpX > 0 ? -TWIN_SIDE : TWIN_SIDE));

		twinHandX = held.x + held.origin.x + perpX * shift + aimDx * TWIN_FWD;
		twinHandY = held.y + held.origin.y + perpY * shift + aimDy * TWIN_FWD;
		twinPlaced = true;
		twinFlip = held.flipY;

		if (held.frames != null && twinSprite.frames != held.frames)
		{
			twinSprite.frames = held.frames;
			twinSprite.origin.set(twinSprite.width * 0.5, twinSprite.height * 0.5);
			twinSprite.color = TWIN_SHADE;
		}
		twinSprite.animation.frameIndex = held.animation.frameIndex;

		twinSprite.x = twinHandX - twinSprite.origin.x;
		twinSprite.y = twinHandY - twinSprite.origin.y;
		twinSprite.angle = held.angle + (twinFlip ? twinKick : -twinKick);
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

	function freshTarget(b:Bullet, cx:Float, cy:Float):entities.enemy.Enemies
	{
		var found:entities.enemy.Enemies = null;
		director.eachInCircle(cx, cy, b.hitR, function(e)
		{
			if (found == null && !b.hasStruck(e))
				found = e;
		});
		return found;
	}

	function spawn(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float, damage:Float, key:String, radius:Float, cost:Int,
			targets:Int = 1):Bullet
	{
		var b = bullets.recycle(Bullet);
		b.setSprite(key);
		b.fire(bx + dx * MUZZLE, by + dy * MUZZLE, dx, dy, aimDeg, damage, cfg.speed, cfg.range, cfg.knock, radius, targets);

		if (twin && twinRounds >= cost)
		{
			pendDelay = TWIN_STAGGER;
			pendCost = cost;
			pendDx = dx;
			pendDy = dy;
			pendDeg = aimDeg;
			pendDamage = damage;
			pendRadius = radius;
			pendTargets = targets;
			pendKey = key;
		}
		return b;
	}

	function fireTwin():Void
	{
		if (pendKey == null)
			return;
		var tx = twinHandX + pendDx * MUZZLE;
		var ty = twinHandY + pendDy * MUZZLE;
		var t = bullets.recycle(Bullet);
		t.setSprite(pendKey);
		t.fire(tx, ty, pendDx, pendDy, pendDeg, pendDamage * cfg.twinScale, cfg.speed, cfg.range, cfg.knock, pendRadius, pendTargets);
		t.fromSuper = true;
		if (onTwinShot != null)
			onTwinShot(twinHandX, twinHandY, pendDx, pendDy, pendDeg, pendKey == BIG_SPRITE);
		pendKey = null;
		twinRounds -= pendCost;
		if (twinRounds < 0)
			twinRounds = 0;
		twinKick = TWIN_KICK;
		fx.sparksAt(tx, ty);
		FlxG.sound.play(Paths.sound("revolver/shot" + (1 + Std.random(3))), 0.55);
	}

	public function reset():Void
	{
		if (spinSound.playing)
			spinSound.stop();
		if (spinEndSound.playing)
			spinEndSound.stop();
		if (spinSoundB.playing)
			spinSoundB.stop();
		if (spinEndSoundB.playing)
			spinEndSoundB.stop();
		spunStart = false;
		spunEnd = false;
		spinBDelay = 0;
		spinEndBDelay = 0;
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

		if (twinKick > 0)
		{
			twinKick -= TWIN_KICK * KICK_FADE * elapsed;
			if (twinKick < 0)
				twinKick = 0;
		}

		if (spinBDelay > 0)
		{
			spinBDelay -= elapsed;
			if (spinBDelay <= 0)
				spinSoundB.play(true);
		}

		if (spinEndBDelay > 0)
		{
			spinEndBDelay -= elapsed;
			if (spinEndBDelay <= 0)
				spinEndSoundB.play(true);
		}

		if (pendDelay > 0)
		{
			pendDelay -= elapsed;
			if (pendDelay <= 0)
				fireTwin();
		}

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

			var hit = b.pierces ? freshTarget(b, cx, cy) : director.firstInCircle(cx, cy, b.hitR);
			if (hit != null)
			{
				b.markStruck(hit);
				if (b.fromSuper)
					hits.damageSuper(hit, b.dirX * b.knock, b.dirY * b.knock, b.damage);
				else
					hits.damageN(hit, b.dirX * b.knock, b.dirY * b.knock, b.damage);
				fx.impactAt(cx, cy);
				b.hitsLeft--;
				if (b.hitsLeft <= 0)
					b.kill();
			}
		}

		if (reloading > 0)
		{
			reloading -= elapsed;
			var at = reloadTotal > 0 ? 1 - reloading / reloadTotal : 1;
			if (!spunStart && at >= SPIN_AT)
			{
				spunStart = true;
				spinSound.play(true);
				if (twin)
					spinBDelay = TWIN_SPIN_GAP;
			}
			if (!spunEnd && at >= SPIN_END_AT)
			{
				spunEnd = true;
				spinEndSound.play(true);
				if (twin)
					spinEndBDelay = TWIN_SPIN_GAP;
			}
			if (reloading <= 0)
			{
				rounds = cfg.cylinder;
				if (twin)
					twinRounds = cfg.cylinder;
				FlxG.sound.play(Paths.sound("revolver/reload"), 0.6);
				FlxG.sound.play(Paths.sound("weapon/catch"), 0.3);
			}
		}
	}
}
