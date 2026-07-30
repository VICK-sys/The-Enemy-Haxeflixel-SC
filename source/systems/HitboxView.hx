package systems;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class HitboxView
{
	static inline var THICK:Float = 2;
	static inline var DOT_ARC:Float = 2.2;
	static inline var DOTS_MIN:Int = 24;
	static inline var SHADE:Float = 0.85;

	public static inline var BODY:Int = 0xFF33E0FF;
	public static inline var FOE:Int = 0xFFFF3355;
	public static inline var LOOT:Int = 0xFF6BFF6B;
	public static inline var SOLID:Int = 0xFFFF66FF;
	public static inline var FEET:Int = 0xFFFFD447;
	public static inline var REACH:Int = 0xFFFF9A2E;

	public var group:FlxTypedGroup<FlxSprite>;
	public var on:Bool = false;

	public function new()
		group = new FlxTypedGroup<FlxSprite>();

	public function toggle():Void
	{
		on = !on;
		if (!on)
			clear();
	}

	public function clear():Void
	{
		for (s in group.members)
			if (s != null && s.exists)
				s.kill();
	}

	public function box(x:Float, y:Float, w:Float, h:Float, color:Int):Void
	{
		bar(x, y, w, THICK, color);
		bar(x, y + h - THICK, w, THICK, color);
		bar(x, y, THICK, h, color);
		bar(x + w - THICK, y, THICK, h, color);
	}

	public function ray(x:Float, y:Float, dx:Float, dy:Float, len:Float, color:Int):Void
	{
		var s = bar(x, y - THICK * 0.5, len, THICK, color);
		s.origin.set(0, THICK * 0.5);
		s.angle = Math.atan2(dy, dx) * 180 / Math.PI;
	}

	public function circle(cx:Float, cy:Float, r:Float, color:Int):Void
	{
		var steps = Std.int(2 * Math.PI * r / DOT_ARC);
		if (steps < DOTS_MIN)
			steps = DOTS_MIN;
		for (i in 0...steps)
		{
			var a = i / steps * Math.PI * 2;
			bar(cx + Math.cos(a) * r - THICK * 0.5, cy + Math.sin(a) * r - THICK * 0.5, THICK, THICK, color);
		}
	}

	public function span(x:Float, y:Float, w:Float, color:Int):Void
		bar(x, y - THICK * 0.5, w, THICK, color);

	function bar(x:Float, y:Float, w:Float, h:Float, color:Int):FlxSprite
	{
		var s = group.recycle(FlxSprite);
		if (s.graphic == null)
		{
			s.makeGraphic(1, 1, 0xFFFFFFFF);
			s.antialiasing = false;
		}
		s.origin.set(0, 0);
		s.scale.set(w, h);
		s.setPosition(x, y);
		s.angle = 0;
		s.color = color;
		s.alpha = SHADE;
		return s;
	}
}
