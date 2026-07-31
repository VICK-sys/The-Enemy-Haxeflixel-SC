package data;

import util.Paths;

typedef WavePool = {
	types:Array<String>
}

typedef WaveScaling = {
	hpPerWave:Float,
	speedPerWave:Float,
	damagePerWave:Float,
	bossHpPerWave:Float,
	bossSpeedPerWave:Float,
	bossDamagePerWave:Float,
	breatherPerWave:Float,
	breatherMin:Float
}

typedef WaveData = {
	firstDelay:Float,
	breather:Float,
	baseCount:Int,
	countPerWave:Int,
	spawnBatch:Int,
	spawnEvery:Float,
	bossWaveMin:Int,
	bossWaveRange:Int,
	bossRepeat:Int,
	duoChance:Float,
	scaling:WaveScaling,
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
