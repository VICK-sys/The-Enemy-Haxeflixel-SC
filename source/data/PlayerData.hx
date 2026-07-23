package data;

import util.Paths;

typedef PlayerData = {
	moveSpeed:Float,
	rampStart:Float,
	rampRate:Float,
	rampReset:Float,
	drag:Float,
	dashSpeed:Float,
	dashTime:Float,
	dashCooldown:Float,
	dashIframes:Float,
	healthMax:Float,
	apMax:Float,
	apPerKill:Float,
	iframeTime:Float,
	hurtLockTime:Float,
	knockback:Float
}

class PlayerDataRegistry
{
	static var data:PlayerData;

	public static function get():PlayerData
	{
		if (data == null)
			data = DataLoader.load(Paths.json("player"));
		return data;
	}
}
