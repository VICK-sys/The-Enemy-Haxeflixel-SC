package data;

import util.Paths;

typedef PlayerData = {
	moveSpeed:Float,
	walkScale:Float,
	rampStart:Float,
	rampRate:Float,
	rampReset:Float,
	drag:Float,
	dashSpeed:Float,
	dashTime:Float,
	dashCooldown:Float,
	dashIframes:Float,
	dropLowHealthBonus:Float,
	healthMax:Float,
	superMax:Float,
	superPerDamage:Float,
	superCooldown:Float,
	iframeTime:Float,
	hurtLockTime:Float,
	hurtSlowTime:Float,
	hurtMoveScale:Float,
	knockback:Float,
	timestopSlow:Float,
	timestopHold:Float,
	timestopRecover:Float,
	timestopCooldown:Float
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
