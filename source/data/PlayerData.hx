package data;

import util.Paths;

typedef SideSkinData = {
	sheet:String,
	frameW:Int,
	frameH:Int,
	offsetX:Float,
	offsetY:Float,
	shadowScaleX:Float,
	idle:Array<Int>,
	walk:Array<Int>,
	jump:Array<Int>,
	fall:Array<Int>,
	hurt:Array<Int>,
	death:Array<Int>,
	idleFps:Int,
	walkFps:Int,
	jumpFps:Int,
	fallFps:Int,
	hurtFps:Int,
	deathFps:Int
}

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
	knockback:Float,
	timestopSlow:Float,
	timestopHold:Float,
	timestopRecover:Float,
	timestopCooldown:Float,
	sideSkin:SideSkinData
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
