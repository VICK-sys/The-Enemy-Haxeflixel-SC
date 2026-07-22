package entities;

import util.DataLoader;
import util.Paths;

typedef EnemyAnimData = {
	name:String,
	prefix:String,
	fps:Int,
	loop:Bool
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
	contactDamage:Float,
	?shotDamage:Float,
	?shotSpeed:Float,
	?shotRange:Float,
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
