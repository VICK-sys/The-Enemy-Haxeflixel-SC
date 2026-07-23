package systems.weapons;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import util.Paths;

class Rope
{
	static inline var STEP:Float = 30;

	public static function clear(rope:FlxTypedGroup<FlxSprite>):Void
	{
		for (s in rope.members)
			if (s != null)
				s.kill();
	}

	public static function line(rope:FlxTypedGroup<FlxSprite>, ax:Float, ay:Float, bx:Float, by:Float):Void
	{
		clear(rope);
		var dx = bx - ax;
		var dy = by - ay;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len < 8)
			return;
		var ux = dx / len;
		var uy = dy / len;
		var ang = Math.atan2(dy, dx) * 180 / Math.PI - 90;
		var count = Math.ceil(len / STEP);
		for (i in 0...count)
			place(rope, ax + ux * STEP * (i + 0.5), ay + uy * STEP * (i + 0.5), ang);
	}

	public static function curve(rope:FlxTypedGroup<FlxSprite>, ax:Float, ay:Float, bx:Float, by:Float, ccx:Float, ccy:Float):Void
	{
		clear(rope);
		var dx = bx - ax;
		var dy = by - ay;
		var dist = Math.sqrt(dx * dx + dy * dy);
		if (dist < 8)
			return;
		var count = Math.ceil(dist / STEP) + 2;
		for (i in 0...count)
		{
			var t = (i + 0.5) / count;
			var mt = 1 - t;
			var qx = mt * mt * ax + 2 * mt * t * ccx + t * t * bx;
			var qy = mt * mt * ay + 2 * mt * t * ccy + t * t * by;
			var tvx = 2 * mt * (ccx - ax) + 2 * t * (bx - ccx);
			var tvy = 2 * mt * (ccy - ay) + 2 * t * (by - ccy);
			place(rope, qx, qy, Math.atan2(tvy, tvx) * 180 / Math.PI - 90);
		}
	}

	static function place(rope:FlxTypedGroup<FlxSprite>, cx:Float, cy:Float, ang:Float):Void
	{
		var s = rope.recycle(FlxSprite);
		if (s.graphic == null)
		{
			s.loadGraphic(Paths.image("items/rope"));
			s.antialiasing = false;
		}
		s.setPosition(cx - s.width / 2, cy - s.height / 2);
		s.angle = ang;
	}
}
