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
	?boss:BossData,
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
}
