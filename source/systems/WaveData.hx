package systems;

import haxe.Json;
import openfl.utils.Assets;
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
		{
			var path = Paths.json("waves");
			var text = Assets.getText(path);
			if (text == null)
				throw "Missing wave data: " + path;
			data = Json.parse(text);
		}
		return data;
	}
}
