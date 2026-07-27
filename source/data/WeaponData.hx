package data;

import util.Paths;

typedef SwingConfig = {
	spawnDist:Float,
	meleeRange:Float,
	meleeArcCos:Float,
	damage:Int,
	effectScale:Float
}

typedef HammerConfig = {
	reach:Float,
	radius:Float,
	damage:Int,
	push:Float,
	stunTime:Float
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

typedef ShockwaveConfig = {
	waveRadius:Float,
	waveTime:Float
}

typedef ThrownConfig = {
	maxDist:Float,
	returnSpeed:Float
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

typedef SuperScythesConfig = {
	count:Int,
	fireGate:Float
}

typedef BounceStrikeConfig = {
	strikes:Int,
	hopTime:Float,
	radius:Float,
	damage:Int,
	force:Float,
	catapultSpeed:Float
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
	hammer:HammerConfig,
	revolver:RevolverConfig,
	shockwave:ShockwaveConfig,
	thrown:ThrownConfig,
	bowCharge:BowChargeConfig,
	arrowRain:ArrowRainConfig,
	hook:HookConfig,
	superScythes:SuperScythesConfig,
	bounceStrike:BounceStrikeConfig,
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
