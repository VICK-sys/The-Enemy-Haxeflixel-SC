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
	static var locked:Array<Int> = [for (i in 0...COUNT) 0];
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
		{
			spent[i] = 0;
			locked[i] = 0;
		}
	}

	public static function points(stat:Int):Int
		return stat >= 0 && stat < COUNT ? spent[stat] : 0;

	public static function shown(stat:Int):Int
		return points(stat) + 1;

	public static function lockIn():Void
	{
		for (i in 0...COUNT)
			locked[i] = spent[i];
	}

	public static function level():Int
	{
		var n = 1;
		for (v in spent)
			n += v;
		return n;
	}

	public static function costOf(stat:Int):Int
		return conf().baseCost + conf().costStep * points(stat);

	public static function canRefund(stat:Int):Bool
		return stat >= 0 && stat < COUNT && spent[stat] > locked[stat];

	public static function refund(stat:Int):Bool
	{
		if (!canRefund(stat))
			return false;
		spent[stat]--;
		exp += costOf(stat);
		return true;
	}

	public static function canSpendOn(stat:Int):Bool
		return stat >= 0 && stat < COUNT && exp >= costOf(stat);

	public static function spend(stat:Int):Bool
	{
		if (!canSpendOn(stat))
			return false;
		exp -= costOf(stat);
		spent[stat]++;
		return true;
	}

	public static function award(n:Int):Void
	{
		if (n > 0)
			exp += n;
	}

	public static function scrapValue():Int
		return conf().scrapValue;


	public static function healthAt(pts:Int):Float
		return pts * conf().vigorPerPoint;

	public static function healthBonus():Float
		return healthAt(points(VIGOR));

	public static function superGainAt(pts:Int):Float
		return 1 + pts * conf().enduranceSuperPerPoint;

	public static function superGainScale():Float
		return superGainAt(points(ENDURANCE));

	public static function dashAt(pts:Int):Float
		return Math.pow(1 - conf().enduranceDashPerPoint, pts);

	public static function dashScale():Float
		return dashAt(points(ENDURANCE));

	public static function damageAt(pts:Int):Float
		return pts * conf().strengthPerPoint;

	public static function damageBonus():Float
		return damageAt(points(STRENGTH));

	public static function actionAt(pts:Int):Float
		return Math.pow(1 - conf().dexterityPerPoint, pts);

	public static function actionScale():Float
		return actionAt(points(DEXTERITY));
}
