package systems.weapons;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import util.Paths;

class Rope
{
	static inline var STEP:Float = 30;
	static inline var STRAND_SCALE:Float = 4;
	static inline var SAMPLES:Int = 24;

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

	public static function chain(rope:FlxTypedGroup<FlxSprite>, xs:Array<Float>, ys:Array<Float>):Void
	{
		clear(rope);

		var n = xs.length;
		var arc = 0.0;
		for (i in 1...n)
		{
			var dx = xs[i] - xs[i - 1];
			var dy = ys[i] - ys[i - 1];
			arc += Math.sqrt(dx * dx + dy * dy);
		}
		if (arc < 8)
			return;

		var count = Math.ceil(arc / STEP);
		var span = arc / count;
		var walked = 0.0;
		var next = span * 0.5;
		var placed = 0;

		for (i in 1...n)
		{
			var ax = xs[i - 1];
			var ay = ys[i - 1];
			var dx = xs[i] - ax;
			var dy = ys[i] - ay;
			var seg = Math.sqrt(dx * dx + dy * dy);
			var ang = Math.atan2(dy, dx) * 180 / Math.PI - 90;
			while (placed < count && walked + seg >= next)
			{
				var f = seg <= 0 ? 0.0 : (next - walked) / seg;
				place(rope, ax + dx * f, ay + dy * f, ang);
				placed++;
				next += span;
			}
			walked += seg;
		}
	}

	public static function curve(rope:FlxTypedGroup<FlxSprite>, ax:Float, ay:Float, bx:Float, by:Float, ccx:Float, ccy:Float):Void
	{
		clear(rope);

		var arc = 0.0;
		var px = ax;
		var py = ay;
		for (i in 1...SAMPLES + 1)
		{
			var t = i / SAMPLES;
			var mt = 1 - t;
			var qx = mt * mt * ax + 2 * mt * t * ccx + t * t * bx;
			var qy = mt * mt * ay + 2 * mt * t * ccy + t * t * by;
			arc += Math.sqrt((qx - px) * (qx - px) + (qy - py) * (qy - py));
			px = qx;
			py = qy;
		}
		if (arc < 8)
			return;

		var count = Math.ceil(arc / STEP);
		var span = arc / count;
		var walked = 0.0;
		var next = span * 0.5;
		var placed = 0;
		px = ax;
		py = ay;
		for (i in 1...SAMPLES + 1)
		{
			var t = i / SAMPLES;
			var mt = 1 - t;
			var qx = mt * mt * ax + 2 * mt * t * ccx + t * t * bx;
			var qy = mt * mt * ay + 2 * mt * t * ccy + t * t * by;
			var seg = Math.sqrt((qx - px) * (qx - px) + (qy - py) * (qy - py));
			while (placed < count && walked + seg >= next)
			{
				var f = seg <= 0 ? 0.0 : (next - walked) / seg;
				var at = (i - 1 + f) / SAMPLES;
				var amt = 1 - at;
				var tvx = 2 * amt * (ccx - ax) + 2 * at * (bx - ccx);
				var tvy = 2 * amt * (ccy - ay) + 2 * at * (by - ccy);
				place(rope, px + (qx - px) * f, py + (qy - py) * f, Math.atan2(tvy, tvx) * 180 / Math.PI - 90);
				placed++;
				next += span;
			}
			walked += seg;
			px = qx;
			py = qy;
		}
	}

	static function place(rope:FlxTypedGroup<FlxSprite>, cx:Float, cy:Float, ang:Float):Void
	{
		var s = rope.recycle(FlxSprite);
		if (s.graphic == null)
		{
			s.loadGraphic(Paths.image("items/yoyo_string"));
			s.antialiasing = false;
			s.scale.set(STRAND_SCALE, STRAND_SCALE);
		}
		s.setPosition(cx - s.width / 2, cy - s.height / 2);
		s.angle = ang;
	}
}
