package systems;

import util.DataLoader;
import util.Paths;

typedef WavePool = {
	types:Array<String>
}

typedef WaveData = {
	firstDelay:Float,
	breather:Float,
	baseCount:Int,
	countPerWave:Int,
	maxCount:Int,
	waves:Array<WavePool>
}

class WaveDataRegistry
{
	static var data:WaveData;

	public static function get():WaveData
	{
		if (data == null)
			data = DataLoader.load(Paths.json("waves"));
		return data;
	}
}
