package ui;

import flixel.FlxG;
import util.Paths;

class MenuCursor
{
	static inline var SCALE:Float = 3;
	static inline var TIP_X:Int = 4;

	static inline var NONE:Int = -1;
	static inline var ARROW:Int = 0;
	static inline var HAND:Int = 1;
	static inline var PRESS:Int = 2;

	static var shown:Int = NONE;
	static var shownScale:Float = -1;
	static var over:Bool = false;
	static var wired:Bool = false;

	static function viewScale():Float
	{
		var m = FlxG.scaleMode;
		return m != null && m.scale.x > 0 ? m.scale.x : 1;
	}

	public static function init():Void
	{
		if (wired)
			return;
		wired = true;
		FlxG.signals.postUpdate.add(tick);
	}

	public static function markHover():Void
		over = true;

	static function tick():Void
	{
		if (!FlxG.mouse.visible)
		{
			shown = NONE;
			over = false;
			return;
		}

		var want = over ? (FlxG.mouse.pressed ? PRESS : HAND) : ARROW;
		over = false;
		var size = SCALE * viewScale();
		if (want == shown && size == shownScale)
			return;
		shown = want;
		shownScale = size;

		var art = switch (want)
		{
			case HAND: "ui/mouse_hover";
			case PRESS: "ui/mouse_click";
			default: "ui/mouse_default";
		}
		FlxG.mouse.load(Paths.image(art), size, want == ARROW ? 0 : Std.int(-TIP_X * size), 0);
	}
}
