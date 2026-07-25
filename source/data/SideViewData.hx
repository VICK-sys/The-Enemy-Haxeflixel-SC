package data;

import util.Paths;

typedef SideViewData = {
	gravity:Float,
	maxFall:Float,
	playerJump:Float,
	enemyJump:Float,
	groundOffset:Float,
	platformHigh:Float,
	platformLowGap:Float,
	platformHeight:Float,
	platformWidthMult:Float,
	platformWidthMin:Float,
	enemyHighFeet:Float,
	morphTime:Float,
	revertTime:Float,
	telegraphTime:Float,
	fallTime:Float,
	fallHeight:Float,
	impactRadius:Float,
	impactDamage:Int,
	landMin:Float,
	landMax:Float
}

class SideViewDataRegistry
{
	static var data:SideViewData;

	public static function get():SideViewData
	{
		if (data == null)
			data = DataLoader.load(Paths.json("sideview"));
		return data;
	}
}
