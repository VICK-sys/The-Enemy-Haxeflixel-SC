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
	static var over:Bool = false;
	static var wired:Bool = false;

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
		if (want == shown)
			return;
		shown = want;

		var art = switch (want)
		{
			case HAND: "ui/mouse_hover";
			case PRESS: "ui/mouse_click";
			default: "ui/mouse_default";
		}
		FlxG.mouse.load(Paths.image(art), SCALE, want == ARROW ? 0 : Std.int(-TIP_X * SCALE), 0);
	}
}
