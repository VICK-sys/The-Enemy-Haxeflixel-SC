package systems;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class PropBlock
{
	public static var solids:FlxTypedGroup<FlxSprite>;

	public static function at(x:Float, y:Float):Bool
	{
		if (solids == null)
			return false;
		for (s in solids.members)
			if (s != null && x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height)
				return true;
		return false;
	}

	static inline var INSET:Float = 3;

	public static function between(x0:Float, y0:Float, x1:Float, y1:Float):Bool
	{
		if (solids == null)
			return false;
		for (s in solids.members)
		{
			if (s == null || s.width <= INSET * 2 || s.height <= INSET * 2)
				continue;
			if (crosses(x0, y0, x1, y1, s.x + INSET, s.y + INSET, s.width - INSET * 2, s.height - INSET * 2))
				return true;
		}
		return false;
	}

	static function crosses(x0:Float, y0:Float, x1:Float, y1:Float, bx:Float, by:Float, bw:Float, bh:Float):Bool
	{
		var dx = x1 - x0;
		var dy = y1 - y0;
		var tmin = 0.0;
		var tmax = 1.0;

		if (Math.abs(dx) < 0.00001)
		{
			if (x0 < bx || x0 > bx + bw)
				return false;
		}
		else
		{
			var t1 = (bx - x0) / dx;
			var t2 = (bx + bw - x0) / dx;
			if (t1 > t2)
			{
				var swap = t1;
				t1 = t2;
				t2 = swap;
			}
			if (t1 > tmin)
				tmin = t1;
			if (t2 < tmax)
				tmax = t2;
			if (tmin > tmax)
				return false;
		}

		if (Math.abs(dy) < 0.00001)
			return y0 >= by && y0 <= by + bh;

		var t3 = (by - y0) / dy;
		var t4 = (by + bh - y0) / dy;
		if (t3 > t4)
		{
			var swap = t3;
			t3 = t4;
			t4 = swap;
		}
		if (t3 > tmin)
			tmin = t3;
		if (t4 < tmax)
			tmax = t4;
		return tmin <= tmax;
	}
}
