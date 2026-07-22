package util;

import flixel.util.FlxSave;

class SaveData
{
	static var save:FlxSave;

	static function ensure():Void
	{
		if (save == null)
		{
			save = new FlxSave();
			save.bind("TheEnemy");
		}
	}

	public static function bestWave():Int
	{
		ensure();
		return save.data.bestWave != null ? save.data.bestWave : 0;
	}

	public static function submitWave(wave:Int):Void
	{
		ensure();
		if (save.data.bestWave == null || wave > save.data.bestWave)
		{
			save.data.bestWave = wave;
			save.flush();
		}
	}
}
