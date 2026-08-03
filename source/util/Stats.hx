package util;

class Stats
{
	public static inline var KILLS:String = "kills";
	public static inline var RUNS:String = "runs";
	public static inline var DEATHS:String = "deaths";
	public static inline var WAVES:String = "waves";
	public static inline var BOSSES:String = "bosses";
	public static inline var TIME:String = "time";
	public static inline var BEST_KILLS:String = "bestKills";
	public static inline var BEST_TIME:String = "bestTime";

	static inline var FLUSH_EVERY:Float = 15;

	public static var runKills(default, null):Int = 0;
	public static var runTime(default, null):Float = 0;

	static var dirty:Bool = false;
	static var sinceFlush:Float = 0;

	public static function total(key:String):Float
		return SaveData.stat(key);

	public static function beginRun():Void
	{
		runKills = 0;
		runTime = 0;
		bump(RUNS, 1);
		commit();
	}

	public static function addKill():Void
	{
		runKills++;
		bump(KILLS, 1);
		if (runKills > SaveData.stat(BEST_KILLS))
			SaveData.setStat(BEST_KILLS, runKills, false);
	}

	public static function addDeath():Void
	{
		bump(DEATHS, 1);
		commit();
	}

	public static function addWave():Void
	{
		bump(WAVES, 1);
		commit();
	}

	public static function addBoss():Void
	{
		bump(BOSSES, 1);
		commit();
	}

	public static function weaponBest(weapon:Int):Int
		return Std.int(SaveData.stat("wave" + weapon));

	public static function submitWeaponWave(weapon:Int, wave:Int):Void
	{
		if (weapon < 0 || wave <= SaveData.stat("wave" + weapon))
			return;
		SaveData.setStat("wave" + weapon, wave, false);
		dirty = true;
	}

	public static function tick(elapsed:Float):Void
	{
		runTime += elapsed;
		bump(TIME, elapsed);
		if (runTime > SaveData.stat(BEST_TIME))
			SaveData.setStat(BEST_TIME, runTime, false);
		sinceFlush += elapsed;
		if (sinceFlush >= FLUSH_EVERY)
			commit();
	}

	public static function commit():Void
	{
		sinceFlush = 0;
		if (!dirty)
			return;
		dirty = false;
		SaveData.commit();
	}

	public static function clock(seconds:Float):String
	{
		var whole = Std.int(seconds);
		if (whole < 0)
			whole = 0;
		return pad(Std.int(whole / 3600)) + ":" + pad(Std.int(whole / 60) % 60) + ":" + pad(whole % 60);
	}

	static function bump(key:String, by:Float):Void
	{
		SaveData.setStat(key, SaveData.stat(key) + by, false);
		dirty = true;
	}

	static function pad(v:Int):String
		return v < 10 ? "0" + v : "" + v;
}
