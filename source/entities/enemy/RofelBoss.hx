package entities.enemy;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxDirectionFlags;
import data.EnemyData.BossData;
import data.EnemyData.GunData;
import util.Paths;

class RofelBoss implements AttackBehavior
{
	static inline var GUN_SCALE:Float = 4;
	static inline var SOUND:String = "enemies/pistol";

	private var gun:FlxSprite;
	private var cfg:BossData;
	private var guns:Array<GunData>;
	private var curGun:Int = -1;
	private var loadedGun:String = null;
	private var shotsLeft:Int = 0;
	private var volleyTimer:Float = 0;
	private var cooldownTimer:Float = 0;
	private var strafeDir:Int = 1;
	private var strafeTimer:Float = 0;

	public function new(gun:FlxSprite, cfg:BossData)
	{
		this.gun = gun;
		this.cfg = cfg;
		guns = cfg.guns;
	}

	public function update(e:Enemies, elapsed:Float, dirX:Float, dirY:Float, distance:Float):Bool
	{
		var d = distance > 0 ? distance : 1;
		var ax = dirX / d;
		var ay = dirY / d;
		var aimDeg = Math.atan2(ay, ax) * 180 / Math.PI;
		var cx = e.x + e.width * 0.5;
		var cy = e.y + e.height * 0.5;

		move(e, elapsed, ax, ay, distance);

		if (curGun < 0)
			selectGun(FlxG.random.int(0, guns.length - 1));

		var g = guns[curGun];
		var handX = cx + ax * cfg.gunDist;
		var handY = cy + ay * cfg.gunDist;

		if (shotsLeft > 0)
		{
			volleyTimer -= elapsed;
			if (volleyTimer <= 0)
			{
				fireVolley(e, g, handX + ax * g.muzzle, handY + ay * g.muzzle, aimDeg);
				shotsLeft--;
				volleyTimer = g.burstInterval;
				if (shotsLeft <= 0)
					cooldownTimer = g.cooldown;
			}
		}
		else
		{
			cooldownTimer -= elapsed;
			if (cooldownTimer <= 0)
			{
				var next = FlxG.random.int(0, guns.length - 2);
				if (next >= curGun)
					next++;
				selectGun(next);
			}
		}

		updateGun(handX, handY, aimDeg);
		return false;
	}

	function move(e:Enemies, elapsed:Float, ax:Float, ay:Float, distance:Float):Void
	{
		strafeTimer -= elapsed;
		if (strafeTimer <= 0)
		{
			strafeDir = -strafeDir;
			strafeTimer = 1.4 + FlxG.random.float() * 1.3;
		}
		if (e.wasTouching != FlxDirectionFlags.NONE)
			strafeDir = -strafeDir;

		var mvx = 0.0;
		var mvy = 0.0;
		if (distance < cfg.prefMin)
		{
			mvx -= ax;
			mvy -= ay;
		}
		else if (distance > cfg.prefMax)
		{
			mvx += ax;
			mvy += ay;
		}
		mvx += -ay * strafeDir * cfg.strafeWeight;
		mvy += ax * strafeDir * cfg.strafeWeight;

		var ml = Math.sqrt(mvx * mvx + mvy * mvy);
		if (ml > 0)
		{
			mvx /= ml;
			mvy /= ml;
		}
		e.velocity.set(mvx * cfg.moveSpeed, mvy * cfg.moveSpeed);
		e.flipX = ax < 0;
		e.animation.play("walk");
	}

	function fireVolley(e:Enemies, g:GunData, mx:Float, my:Float, aimDeg:Float):Void
	{
		for (i in 0...g.count)
		{
			var offset = (i - (g.count - 1) * 0.5) * g.spread + (FlxG.random.float() - 0.5) * 3;
			var rad = (aimDeg + offset) * Math.PI / 180;
			e.requestShot(Math.cos(rad), Math.sin(rad), g.damage, g.speed, g.range, g.bullet, SOUND).at(mx, my);
		}
	}

	function selectGun(i:Int):Void
	{
		curGun = i;
		shotsLeft = guns[i].burst;
		volleyTimer = 0.22;
		cooldownTimer = 0;
	}

	function updateGun(handX:Float, handY:Float, aimDeg:Float):Void
	{
		var g = guns[curGun];
		if (g.image != loadedGun)
		{
			loadedGun = g.image;
			gun.loadGraphic(Paths.image(g.image));
			gun.origin.set(gun.frameWidth * 0.5, gun.frameHeight * 0.5);
			gun.scale.set(GUN_SCALE, GUN_SCALE);
		}
		gun.x = handX - gun.frameWidth * 0.5;
		gun.y = handY - gun.frameHeight * 0.5;
		gun.angle = aimDeg;
		gun.flipY = Math.abs(aimDeg) > 90;
	}

	public function reset():Void {}
}
