package data;

import util.Paths;

typedef SwingConfig = {
	spawnDist:Float,
	meleeRange:Float,
	meleeArcCos:Float
}

typedef SliceConfig = {
	spawnDist:Float
}

typedef HammerConfig = {
	reach:Float,
	radius:Float,
	damage:Int,
	push:Float,
	stunTime:Float
}

typedef ShockwaveConfig = {
	waveRadius:Float,
	waveTime:Float
}

typedef ThrownConfig = {
	maxDist:Float,
	returnSpeed:Float
}

typedef ArrowRainConfig = {
	volley:Int,
	delay:Float,
	stagger:Float,
	spread:Float,
	fallSpeed:Float,
	hitRadius:Float
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
	whirlTime:Float,
	whirlRadius:Float,
	whirlHitRadius:Float,
	grappleRange:Float,
	grapplePullSpeed:Float,
	grappleRadius:Float,
	grappleFling:Float,
	grappleCatch:Float,
	grappleTimeout:Float
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
	slice:SliceConfig,
	hammer:HammerConfig,
	shockwave:ShockwaveConfig,
	thrown:ThrownConfig,
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
