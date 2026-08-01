package data;

import util.Paths;

typedef EnemyAnimData = {
	name:String,
	prefix:String,
	fps:Int,
	loop:Bool
}

typedef GunData = {
	image:String,
	bullet:String,
	speed:Float,
	count:Int,
	spread:Float,
	damage:Float,
	burst:Int,
	burstInterval:Float,
	cooldown:Float,
	range:Float,
	muzzle:Float
}

typedef BossData = {
	moveSpeed:Float,
	prefMin:Float,
	prefMax:Float,
	strafeWeight:Float,
	gunDist:Float,
	guns:Array<GunData>
}

typedef KnightData = {
	hoverSpeed:Float,
	hoverTime:Float,
	prefMin:Float,
	prefMax:Float,
	strafeWeight:Float,
	windTime:Float,
	flySpeed:Float,
	flyTime:Float,
	slashTime:Float,
	slashScale:Float,
	restTime:Float
}

typedef FlankData = {
	standoff:Float,
	minDist:Float,
	arcMin:Float,
	arcMax:Float,
	slideMax:Float,
	windup:Float,
	startTime:Float,
	shots:Int,
	shotGap:Float,
	endTime:Float,
	rest:Float,
	disengage:Float
}

typedef DomoData = {
	farDist:Float,
	cooldown:Float,
	shotWindup:Float,
	shotBursts:Int,
	shotGap:Float,
	shotCount:Int,
	shotSpread:Float,
	shotSpeed:Float,
	shotDamage:Float,
	shotRange:Float,
	muzzle:Float,
	gunDist:Float,
	summonTime:Float,
	summonKind:String,
	summonDist:Float,
	summonCap:Int,
	dashCount:Int,
	dashWindup:Float,
	dashSpeed:Float,
	dashTime:Float,
	dashGap:Float,
	dashTurn:Float
}

typedef EnemyData = {
	sprite:String,
	width:Float,
	height:Float,
	offsetX:Float,
	offsetY:Float,
	animations:Array<EnemyAnimData>,
	hp:Int,
	speed:Float,
	aggroRange:Float,
	stopThreshold:Float,
	attackRange:Float,
	attack:String,
	?big:Bool,
	?boss:BossData,
	?knight:KnightData,
	?domo:DomoData,
	?flank:FlankData,
	?chargeAnim:String,
	contactDamage:Float,
	?shotDamage:Float,
	?shotSpeed:Float,
	?shotRange:Float,
	?shotSprite:String,
	?shotSound:String,
	dropChance:Float,
	?knockback:Float,
	?knockbackDrag:Float,
	?stunTime:Float,
	?wanderSpeed:Float,
	?chargeWindup:Float,
	?chargeSpeed:Float,
	?chargeTime:Float,
	?chargeRecover:Float,
	?shootWindup:Float,
	?shootStep:Float,
	?shootGap:Float,
	?shootDisengage:Float,
	shadowOffX:Float,
	shadowOffXFlip:Float,
	shadowOffY:Float,
	shadowScaleX:Float,
	hitOffX:Float,
	hitOffXFlip:Float,
	hitOffY:Float
}

class EnemyDataRegistry
{
	static var cache:Map<String, EnemyData> = new Map();

	public static function get(kind:String):EnemyData
	{
		var data = cache.get(kind);
		if (data == null)
		{
			data = DataLoader.load(Paths.json("enemies/" + kind));
			cache.set(kind, data);
		}
		return data;
	}

	public static function has(kind:String):Bool
	{
		if (kind == null)
			return false;
		return cache.exists(kind) || openfl.utils.Assets.exists(Paths.json("enemies/" + kind));
	}
}
