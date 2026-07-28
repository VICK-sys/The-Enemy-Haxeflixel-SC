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
	public static var banked(default, null):Int = 0;

	static var spent:Array<Int> = null;
	static var cfg = null;

	static function conf()
	{
		if (cfg == null)
			cfg = LevelDataRegistry.get();
		return cfg;
	}

	static function load():Void
	{
		if (spent != null)
			return;
		spent = SaveData.statPoints();
		while (spent.length < COUNT)
			spent.push(0);
		exp = SaveData.exp();
	}

	public static function points(stat:Int):Int
	{
		load();
		return stat >= 0 && stat < COUNT ? spent[stat] : 0;
	}

	public static function level():Int
	{
		load();
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
	{
		load();
		return exp >= costNext();
	}

	public static function spend(stat:Int):Bool
	{
		load();
		if (stat < 0 || stat >= COUNT || !canSpend())
			return false;
		exp -= costNext();
		spent[stat]++;
		SaveData.setStats(exp, spent);
		return true;
	}

	public static function award(n:Int):Void
	{
		load();
		if (n <= 0)
			return;
		banked += n;
		exp += n;
		SaveData.setStats(exp, spent);
	}

	public static function clearBanked():Void
		banked = 0;

	public static function killExp():Int
		return conf().expPerKill;

	public static function waveExp():Int
		return conf().expPerWave;

	public static function wipe():Void
	{
		spent = [for (i in 0...COUNT) 0];
		exp = 0;
		banked = 0;
		SaveData.setStats(0, spent);
	}

	public static function healthBonus():Float
		return points(VIGOR) * conf().vigorPerPoint;

	public static function apGainScale():Float
	{
		var c = conf();
		var v = 1 + points(ENDURANCE) * c.enduranceApPerPoint;
		return v > c.enduranceApCap ? c.enduranceApCap : v;
	}

	public static function dashScale():Float
	{
		var c = conf();
		var v = 1 - points(ENDURANCE) * c.enduranceDashPerPoint;
		return v < c.enduranceDashFloor ? c.enduranceDashFloor : v;
	}

	public static function damageBonus():Int
	{
		var c = conf();
		var n = Std.int(points(STRENGTH) / c.strengthPerPoints);
		return n > c.strengthMax ? c.strengthMax : n;
	}

	public static function actionScale():Float
	{
		var c = conf();
		var v = 1 - points(DEXTERITY) * c.dexterityPerPoint;
		return v < c.dexterityFloor ? c.dexterityFloor : v;
	}
}
