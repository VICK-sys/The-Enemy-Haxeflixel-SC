package data;

import util.Paths;

typedef LevelSet =
{
	scrapValue:Int,

	baseCost:Int,
	costGrowth:Float,
	costFlat:Int,

	vigorPerPoint:Float,
	enduranceDashPerPoint:Float,
	enduranceSuperPerPoint:Float,
	strengthPerPoints:Int,
	dexterityPerPoint:Float
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
