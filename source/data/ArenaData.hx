package data;

import util.Paths;

typedef ArenaData = {
	cols:Int,
	rows:Int,
	tileSize:Int,
	background:String,
	map:String,
	tiles:String,
	spawnX:Float,
	spawnY:Float,
	totemWaveMin:Int,
	totemWaveRange:Int
}

class ArenaDataRegistry
{
	static var data:ArenaData;

	public static function get():ArenaData
	{
		if (data == null)
			data = DataLoader.load(Paths.json("arena"));
		return data;
	}

	public static function pixelWidth():Int
	{
		var d = get();
		return d.cols * d.tileSize;
	}

	public static function pixelHeight():Int
	{
		var d = get();
		return d.rows * d.tileSize;
	}
}
