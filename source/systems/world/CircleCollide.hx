package systems.world;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tile.FlxTilemap;

class CircleCollide
{
	static inline var PASSES:Int = 4;
	static inline var SKIN:Float = 0.01;

	public static function resolve(s:FlxSprite, r:Float, map:FlxTilemap, solids:FlxTypedGroup<FlxSprite>):Void
	{
		for (pass in 0...PASSES)
		{
			var moved = false;
			if (map != null && againstTiles(s, r, map))
				moved = true;
			if (solids != null && againstRects(s, r, solids))
				moved = true;
			if (!moved)
				return;
		}
	}

	public static function separate(a:FlxSprite, ra:Float, b:FlxSprite, rb:Float):Bool
	{
		var ax = a.x + a.width * 0.5;
		var ay = a.y + a.height * 0.5;
		var bx = b.x + b.width * 0.5;
		var by = b.y + b.height * 0.5;
		var dx = ax - bx;
		var dy = ay - by;
		var reach = ra + rb;
		var far = dx * dx + dy * dy;
		if (far >= reach * reach)
			return false;

		if (far < 0.0001)
		{
			dx = 1;
			dy = 0;
			far = 1;
		}
		var d = Math.sqrt(far);
		var out = (reach - d) * 0.5 + SKIN;
		a.x += dx / d * out;
		a.y += dy / d * out;
		b.x -= dx / d * out;
		b.y -= dy / d * out;
		return true;
	}

	static function againstTiles(s:FlxSprite, r:Float, map:FlxTilemap):Bool
	{
		var tw:Float = map.tileWidth;
		var th:Float = map.tileHeight;
		if (tw <= 0 || th <= 0)
			return false;

		var cx = s.x + s.width * 0.5;
		var cy = s.y + s.height * 0.5;
		var x0 = Math.floor((cx - r - map.x) / tw);
		var x1 = Math.floor((cx + r - map.x) / tw);
		var y0 = Math.floor((cy - r - map.y) / th);
		var y1 = Math.floor((cy + r - map.y) / th);

		var hit = false;
		var ty = y0;
		while (ty <= y1)
		{
			var tx = x0;
			while (tx <= x1)
			{
				var wx = map.x + tx * tw;
				var wy = map.y + ty * th;
				if (map.getTileIndexAt(wx + tw * 0.5, wy + th * 0.5) > 0 && push(s, r, wx, wy, tw, th))
					hit = true;
				tx++;
			}
			ty++;
		}
		return hit;
	}

	static function againstRects(s:FlxSprite, r:Float, solids:FlxTypedGroup<FlxSprite>):Bool
	{
		var hit = false;
		for (b in solids.members)
			if (b != null && b.exists && push(s, r, b.x, b.y, b.width, b.height))
				hit = true;
		return hit;
	}

	static function push(s:FlxSprite, r:Float, bx:Float, by:Float, bw:Float, bh:Float):Bool
	{
		var cx = s.x + s.width * 0.5;
		var cy = s.y + s.height * 0.5;
		var nx = cx < bx ? bx : (cx > bx + bw ? bx + bw : cx);
		var ny = cy < by ? by : (cy > by + bh ? by + bh : cy);
		var dx = cx - nx;
		var dy = cy - ny;
		var far = dx * dx + dy * dy;
		if (far >= r * r)
			return false;

		if (far > 0.0001)
		{
			var d = Math.sqrt(far);
			var out = r - d + SKIN;
			s.x += dx / d * out;
			s.y += dy / d * out;
			return true;
		}

		var left = cx - bx;
		var right = bx + bw - cx;
		var top = cy - by;
		var bottom = by + bh - cy;
		var least = left;
		if (right < least)
			least = right;
		if (top < least)
			least = top;
		if (bottom < least)
			least = bottom;

		if (least == left)
			s.x -= left + r + SKIN;
		else if (least == right)
			s.x += right + r + SKIN;
		else if (least == top)
			s.y -= top + r + SKIN;
		else
			s.y += bottom + r + SKIN;
		return true;
	}
}
