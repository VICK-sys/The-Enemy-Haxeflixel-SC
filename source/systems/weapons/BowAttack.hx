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

	private var cfg = WeaponDataRegistry.get().bowCharge;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var fx:Fx;
	private var hits:HitPipeline;
	private var chargeTime:Float = 0;
	private var fullNoted:Bool = false;
	private var drawSound:FlxSound;

	public function new(arena:Arena, director:EnemyDirector, fx:Fx, hits:HitPipeline)
	{
		this.arena = arena;
		this.director = director;
		this.fx = fx;
		this.hits = hits;
		arrows = new FlxTypedGroup<Arrow>();
		rain = new ArrowRain(fx, hits);
		drawSound = FlxG.sound.load(Paths.sound("scythe/spin"), 0.4, true);
	}

	function get_charge():Float
	{
		if (chargeTime <= cfg.minTime)
			return 0;
		var t = (chargeTime - cfg.minTime) / (cfg.fullTime - cfg.minTime);
		return t < 0 ? 0 : (t > 1 ? 1 : t);
	}

	public function beginCharge():Void
	{
		charging = true;
		chargeTime = 0;
		fullNoted = false;
	}

	public function cancelCharge():Void
	{
		if (drawSound.playing)
			drawSound.stop();
		charging = false;
		chargeTime = 0;
		fullNoted = false;
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
			FlxG.sound.play(Paths.sound("scythe/catch"), 0.5);
		}
	}

	public function release(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		var t = charge;
		cancelCharge();
		shoot(bx, by, dx, dy, aimDeg, t);
	}

	public function shoot(bx:Float, by:Float, dx:Float, dy:Float, aimDeg:Float, power:Float = 0):Void
	{
		var damage = 1 + Math.floor(power * (cfg.maxDamage - 1));
		arrows.recycle(Arrow).fire(bx + dx * 10, by + dy * 10, dx, dy, aimDeg, damage, 1 + power * cfg.speedBonus,
			1 + power * cfg.sizeBonus, 1 + power * cfg.knockBonus);
		FlxG.sound.play(Paths.sound("bow"), 0.7 + power * 0.3);
		if (power >= 1)
		{
			fx.sparksAt(bx + dx * 30, by + dy * 30);
			FlxG.camera.shake(0.004, 0.18);
		}
	}

	public function rainFire(tx:Float, ty:Float, bx:Float, by:Float):Void
	{
		rain.fire(tx, ty, bx, by);
		FlxG.sound.play(Paths.sound("bow"), 0.7);
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
			var hit = director.firstInCircle(acx, acy, Arrow.RADIUS);
			if (hit != null)
			{
				hits.damageN(hit, arrow.dirX * arrow.knock, arrow.dirY * arrow.knock, arrow.damage);
				arrow.kill();
			}
		}

		tickCharge(elapsed);
		rain.update(elapsed);
	}
}
