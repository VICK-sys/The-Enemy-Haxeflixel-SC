package systems;

import flixel.FlxSprite;

class BackGear
{
	static inline var SPIN:Float = 220;
	static inline var OFF_X:Float = 20;
	static inline var LEAN_IN:Float = 10;
	static inline var OFF_Y:Float = 15;
	static inline var PIVOT_X:Float = 20;
	static inline var PIVOT_Y:Float = 19;
	static inline var PLACE_X:Float = 20;
	static inline var PLACE_Y:Float = 23;
	static inline var SCALE:Float = 4;

	public var sprite:FlxSprite;

	private var hue:Float = -1;

	public function new()
	{
		sprite = new FlxSprite();
		paint(0);
		sprite.antialiasing = false;
		sprite.scale.set(SCALE, SCALE);
		sprite.width = 1;
		sprite.height = 1;
	}

	public function paint(h:Float):Void
	{
		if (h == hue)
			return;
		hue = h;
		sprite.frames = util.HuePalette.sparrow("characters/mufu", h);
		sprite.frame = sprite.frames.getByName("Part00000");
		sprite.origin.set(PIVOT_X, PIVOT_Y);
	}

	public function update(elapsed:Float, cx:Float, cy:Float, facingLeft:Bool, moving:Bool, shown:Bool):Void
	{
		sprite.visible = shown;
		if (!shown)
			return;
		sprite.angle += SPIN * elapsed;
		var off = OFF_X - (moving ? LEAN_IN : 0);
		sprite.setPosition(cx + (facingLeft ? off : -off) - PLACE_X, cy + OFF_Y - PLACE_Y);
	}
}
