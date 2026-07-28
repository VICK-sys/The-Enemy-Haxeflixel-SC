package data;

import util.Paths;

typedef SwingConfig = {
	spawnDist:Float,
	meleeRange:Float,
	meleeArcCos:Float,
	damage:Int,
	effectScale:Float,
	hitstop:Int,
	hitstopScale:Float,
	hitShake:Float,
	knock:Float,
	hitBrace:Float,
	?cooldown:Float
}

typedef RevolverConfig = {
	cylinder:Int,
	damage:Int,
	reloadTime:Float,
	fanInterval:Float,
	fanJitter:Float,
	speed:Float,
	range:Float,
	hitRadius:Float,
	knock:Float
}

typedef ThrownConfig = {
	maxDist:Float,
	returnSpeed:Float,
	catchCooldown:Float
}

typedef BowChargeConfig = {
	minTime:Float,
	fullTime:Float,
	maxDamage:Int,
	speedBonus:Float,
	sizeBonus:Float,
	knockBonus:Float,
	shotCooldown:Float
}

typedef ArrowRainConfig = {
	volley:Int,
	delay:Float,
	stagger:Float,
	spread:Float,
	fallSpeed:Float,
	hitRadius:Float,
	rechargeTime:Float
}

typedef HookConfig = {
	range:Float,
	pullSpeed:Float,
	pullTimeout:Float,
	grabDist:Float,
	holdDist:Float,
	spinTime:Float,
	throwSpeed:Float,
	throwTime:Float,
	throwHitRadius:Float,
	releaseStun:Float,
	snagDamage:Int
}

typedef DeadEyeConfig = {
	flashTime:Float,
	sepiaAlpha:Float,
	fadeTime:Float,
	markRadius:Float,
	shotInterval:Float,
	damage:Int
}

typedef SuperOrbitConfig = {
	count:Int,
	fireGate:Float
}

typedef ArrowStormConfig = {
	stormTime:Float,
	spawnInterval:Float,
	dropsPer:Int
}

typedef HookArmsConfig = {
	reach:Float,
	reachSpeed:Float,
	grabRadius:Float,
	reelSpeed:Float,
	grabDist:Float,
	throwForce:Float,
	damage:Int,
	cooldown:Float,
	whipTime:Float,
	armsTime:Float
}

typedef WeaponsData = {
	swing:SwingConfig,
	jab:SwingConfig,
	revolver:RevolverConfig,
	thrown:ThrownConfig,
	bowCharge:BowChargeConfig,
	arrowRain:ArrowRainConfig,
	hook:HookConfig,
	deadEye:DeadEyeConfig,
	superOrbit:SuperOrbitConfig,
	arrowStorm:ArrowStormConfig,
	hookArms:HookArmsConfig
}

class WeaponDataRegistry
{
	static var data:WeaponsData;

	public static function get():WeaponsData
	{
		if (data == null)
			data = DataLoader.load(Paths.json("weapons"));
		return data;
	}
}
