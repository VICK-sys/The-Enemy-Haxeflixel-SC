package data;

import util.Paths;

typedef ArenaData = {
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
}
