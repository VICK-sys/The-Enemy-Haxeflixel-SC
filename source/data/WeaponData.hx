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
	?cooldown:Float,
	?deflects:Bool,
	?effect:String,
	?hitLift:Float,
	?hitPush:Float
}

typedef YoyoConfig = {
	reach:Float,
	speed:Float,
	holdTime:Float,
	hitRadius:Float,
	hitGap:Float,
	damage:Int,
	hitstop:Int,
	hitstopScale:Float,
	hitShake:Float,
	knock:Float,
	hitBrace:Float,
	cooldown:Float,
	restCooldown:Float
}

typedef RevolverConfig = {
	cylinder:Int,
	damage:Float,
	reloadTime:Float,
	fireInterval:Float,
	speed:Float,
	range:Float,
	hitRadius:Float,
	knock:Float,
	bigCost:Int,
	bigDamage:Float,
	bigCooldown:Float,
	bigRadius:Float,
	twinTime:Float
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
	sweetWindow:Float,
	sweetBonus:Int,
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
	rechargeTime:Float,
	?bossScale:Float
}

typedef HookConfig = {
	range:Float,
	speed:Float,
	pullSpeed:Float,
	pullTimeout:Float,
	grabDist:Float,
	holdDist:Float,
	spinTime:Float,
	throwSpeed:Float,
	throwTime:Float,
	throwHitRadius:Float,
	releaseStun:Float,
	snagDamage:Int,
	slamDamage:Float
}

typedef BounceConfig = {
	strikes:Int,
	hopTime:Float,
	radius:Float,
	damage:Float,
	force:Float,
	catapultSpeed:Float
}

typedef ArrowStormConfig = {
	stormTime:Float,
	spawnInterval:Float,
	dropsPer:Int,
	radius:Float
}

typedef YoyoSpinConfig = {
	radius:Float,
	grabPad:Float,
	time:Float,
	turns:Float,
	grabDamage:Float,
	stringDamage:Float,
	launchSpeed:Float,
	launchPush:Float,
	launchDamage:Float
}

typedef WeaponsData = {
	swing:SwingConfig,
	yoyo:YoyoConfig,
	revolver:RevolverConfig,
	thrown:ThrownConfig,
	bowCharge:BowChargeConfig,
	arrowRain:ArrowRainConfig,
	hook:HookConfig,
	bounceStrike:BounceConfig,
	arrowStorm:ArrowStormConfig,
	yoyoSpin:YoyoSpinConfig,
	bash:SwingConfig
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
