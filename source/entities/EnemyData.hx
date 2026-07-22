package entities;

import haxe.Json;
import openfl.utils.Assets;
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
			var path = Paths.json("enemies/" + kind);
			var text = Assets.getText(path);
			if (text == null)
				throw "Missing enemy data: " + path;
			data = Json.parse(text);
			cache.set(kind, data);
		}
		return data;
	}
}
