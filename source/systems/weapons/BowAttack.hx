package systems.weapons;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.Arrow;
import systems.world.Arena;
import systems.enemy.EnemyDirector;
import systems.Fx;
import util.Paths;
import data.WeaponData.WeaponDataRegistry;

class BowAttack
{
	static inline var DRAW_PITCH_LOW:Float = 0.6;
	static inline var DRAW_PITCH_RISE:Float = 0.8;

	public var arrows:FlxTypedGroup<Arrow>;
	public var rain:ArrowRain;
	public var charging:Bool = false;
	public var charge(get, never):Float;
	public var onFull:Void->Void;

	private var cfg = WeaponDataRegistry.get().bowCharge;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var fx:Fx;
	private var hits:HitPipeline;
	private var chargeTime:Float = 0;
	private var fullNoted:Bool = false;
	private var sweetTimer:Float = 0;
	private var cooldown:Float = 0;
	private var cooldownTotal:Float = 0;
	private var drawSound:FlxSound;
	private var reloadSound:FlxSound;

	public function new(arena:Arena, director:EnemyDirector, fx:Fx, hits:HitPipeline)
	{
		this.arena = arena;
		this.director = director;
		this.fx = fx;
		this.hits = hits;
		arrows = new FlxTypedGroup<Arrow>();
		rain = new ArrowRain(fx, hits);
		rain.hue = util.SaveData.playerHue();
		drawSound = FlxG.sound.create(Paths.sound("weapon/spin")).setup(0.4, true);
		reloadSound = FlxG.sound.create(Paths.sound("weapon/crossbowReload")).setup(0.55);
	}

	function get_charge():Float
	{
		if (chargeTime <= cfg.minTime)
			return 0;
		var t = (chargeTime - cfg.minTime) / (cfg.fullTime - cfg.minTime);
		return t < 0 ? 0 : (t > 1 ? 1 : t);
	}

	public var recovering(get, never):Bool;

	function get_recovering():Bool
		return cooldown > 0;

	public var recoverProgress(get, never):Float;

	function get_recoverProgress():Float
	{
		if (cooldown <= 0 || cooldownTotal <= 0)
			return 0;
		return 1 - cooldown / cooldownTotal;
	}

	public function beginCharge():Void
	{
		if (cooldown > 0)
			return;
		charging = true;
		chargeTime = 0;
		fullNoted = false;
		sweetTimer = 0;
	}

	public function hushReload():Void
	{
		if (reloadSound != null && reloadSound.playing)
			reloadSound.stop();
	}

	public function cancelCharge():Void
	{
		if (drawSound.playing)
			drawSound.stop();
		charging = false;
		chargeTime = 0;
		fullNoted = false;
		sweetTimer = 0;
	}

	public function tickCharge(elapsed:Float):Void
	{
		if (!charging)
			return;

		var before = chargeTime;
		chargeTime += elapsed;

		if (before <= cfg.minTime && chargeTime > cfg.minTime)
		{
			drawSound.pitch = DRAW_PITCH_LOW;
			drawSound.play(true);
		}
		if (drawSound.playing)
			drawSound.pitch = DRAW_PITCH_LOW + charge * DRAW_PITCH_RISE;

		if (!fullNoted && charge >= 1)
		{
			fullNoted = true;
			sweetTimer = cfg.sweetWindow;
			FlxG.sound.play(Paths.sound("weapon/catch"), 0.5);
			if (onFull != null)
				onFull();
		}
		else if (sweetTimer > 0)
			sweetTimer -= elapsed;
	}

	public function release(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float):Bool
	{
		var t = charge;
		var hot = sweetTimer > 0;
		cancelCharge();
		shoot(bx, by, dx, dy, aimDeg, t, hot);
		return hot;
	}

	public function shoot(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float, power:Float = 0, hot:Bool = false):Void
	{
		var damage = hot ? cfg.damage * cfg.sweetMult : cfg.damage * (1 + power * (cfg.fullMult - 1));
		var arrow = arrows.recycle(Arrow);
		arrow.paint(util.SaveData.playerHue(), hot);
		arrow.fire(bx + dx * 10, by + dy * 10, dx, dy, aimDeg, damage, 1 + power * cfg.speedBonus,
			1 + power * cfg.sizeBonus, 1 + power * cfg.knockBonus);
		FlxG.sound.play(Paths.sound("crossbow_fire"), 0.7 + power * 0.3);
		if (power >= 1)
		{
			arrow.piercing = true;
			fx.sparksAt(bx + dx * 30, by + dy * 30);
			systems.Fx.shake(0.004, 0.18);
		}
		cooldownTotal = cfg.shotCooldown * util.Levels.actionScale();
		cooldown = cooldownTotal;
		if (reloadSound.playing)
			reloadSound.stop();
		reloadSound.play(true);
	}

	public function update(elapsed:Float):Void
	{
		for (arrow in arrows.members)
		{
			if (arrow == null || !arrow.exists)
				continue;
			var acx = arrow.x + arrow.width / 2;
			var acy = arrow.y + arrow.height / 2;
			if (arena.wallAt(acx + arrow.dirX * Arrow.RADIUS, acy + arrow.dirY * Arrow.RADIUS)
				|| systems.world.PropBlock.at(acx + arrow.dirX * Arrow.RADIUS, acy + arrow.dirY * Arrow.RADIUS))
			{
				arrow.kill();
				continue;
			}
			if (arrow.piercing)
			{
				director.eachInCircle(acx, acy, Arrow.RADIUS, function(e)
				{
					if (arrow.hasHit(e))
						return;
					arrow.markHit(e);
					hits.damageN(e, arrow.dirX * arrow.knock, arrow.dirY * arrow.knock, arrow.damage);
				});
				continue;
			}

			var hit = director.firstInCircle(acx, acy, Arrow.RADIUS);
			if (hit != null)
			{
				hits.damageN(hit, arrow.dirX * arrow.knock, arrow.dirY * arrow.knock, arrow.damage);
				arrow.kill();
			}
		}

		if (cooldown > 0)
			cooldown -= elapsed;
		tickCharge(elapsed);
		rain.update(elapsed);
	}
}
