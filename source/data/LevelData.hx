package data;

import util.Paths;

typedef LevelSet =
{
	scrapValue:Int,
	expPerWave:Int,

	baseCost:Int,
	costGrowth:Float,
	costFlat:Int,

	vigorPerPoint:Float,
	enduranceDashPerPoint:Float,
	enduranceApPerPoint:Float,
	strengthPerPoints:Int,
	dexterityPerPoint:Float,

	enduranceDashFloor:Float,
	enduranceApCap:Float,
	strengthMax:Int,
	dexterityFloor:Float
}

class LevelDataRegistry
{
	static var data:LevelSet;

	public static function get():LevelSet
	{
		if (data == null)
			data = DataLoader.load(Paths.json("levels"));
		return data;
	}
}
