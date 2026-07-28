package util;

import data.LevelData.LevelDataRegistry;

class Levels
{
	public static inline var VIGOR:Int = 0;
	public static inline var ENDURANCE:Int = 1;
	public static inline var STRENGTH:Int = 2;
	public static inline var DEXTERITY:Int = 3;
	public static inline var COUNT:Int = 4;

	public static var exp(default, null):Int = 0;

	static var spent:Array<Int> = [for (i in 0...COUNT) 0];
	static var cfg = null;

	static function conf()
	{
		if (cfg == null)
			cfg = LevelDataRegistry.get();
		return cfg;
	}

	public static function startRun():Void
	{
		exp = 0;
		for (i in 0...COUNT)
			spent[i] = 0;
	}

	public static function points(stat:Int):Int
		return stat >= 0 && stat < COUNT ? spent[stat] : 0;

	public static function level():Int
	{
		var n = 1;
		for (v in spent)
			n += v;
		return n;
	}

	public static function costNext():Int
	{
		var c = conf();
		var lv = level();
		return Std.int(c.baseCost * Math.pow(c.costGrowth, lv - 1)) + c.costFlat * (lv - 1);
	}

	public static function canSpend():Bool
		return exp >= costNext();

	public static function spend(stat:Int):Bool
	{
		if (stat < 0 || stat >= COUNT || !canSpend())
			return false;
		exp -= costNext();
		spent[stat]++;
		return true;
	}

	public static function award(n:Int):Void
	{
		if (n > 0)
			exp += n;
	}

	public static function killExp():Int
		return conf().expPerKill;

	public static function waveExp():Int
		return conf().expPerWave;

	public static function healthAt(pts:Int):Float
		return pts * conf().vigorPerPoint;

	public static function healthBonus():Float
		return healthAt(points(VIGOR));

	public static function apGainAt(pts:Int):Float
	{
		var c = conf();
		var v = 1 + pts * c.enduranceApPerPoint;
		return v > c.enduranceApCap ? c.enduranceApCap : v;
	}

	public static function apGainScale():Float
		return apGainAt(points(ENDURANCE));

	public static function dashAt(pts:Int):Float
	{
		var c = conf();
		var v = 1 - pts * c.enduranceDashPerPoint;
		return v < c.enduranceDashFloor ? c.enduranceDashFloor : v;
	}

	public static function dashScale():Float
		return dashAt(points(ENDURANCE));

	public static function damageAt(pts:Int):Int
	{
		var c = conf();
		var n = Std.int(pts / c.strengthPerPoints);
		return n > c.strengthMax ? c.strengthMax : n;
	}

	public static function damageBonus():Int
		return damageAt(points(STRENGTH));

	public static function actionAt(pts:Int):Float
	{
		var c = conf();
		var v = 1 - pts * c.dexterityPerPoint;
		return v < c.dexterityFloor ? c.dexterityFloor : v;
	}

	public static function actionScale():Float
		return actionAt(points(DEXTERITY));
}
