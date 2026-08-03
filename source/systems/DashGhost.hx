package systems;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import util.GhostTrail;

class DashGhost
{
	static inline var TINT:Int = 0xFFFF6A6A;
	static inline var ALPHA:Float = 0.5;
	static inline var FADE:Float = 3.4;
	static inline var INTERVAL:Float = 0.02;
	static inline var MIN_SPEED:Float = 60;

	public var trail:GhostTrail;
	public var enabled:Bool = true;

	private var body:FlxSprite;
	private var tint:FlxColor;
	private var lastX:Float = 0;
	private var lastY:Float = 0;
	private var seeded:Bool = false;

	public function new(body:FlxSprite, hue:Float)
	{
		this.body = body;
		trail = new GhostTrail(util.Skins.sheet(), ALPHA, FADE, INTERVAL);
		paint(hue);
	}

	public function paint(hue:Float):Void
	{
		var c:FlxColor = TINT;
		c.hue = c.hue + hue * 360;
		tint = c;
	}

	public function update(elapsed:Float, guarding:Bool):Void
	{
		var cadence = trail.tick(elapsed);
		var dx = body.x - lastX;
		var dy = body.y - lastY;
		lastX = body.x;
		lastY = body.y;
		if (!seeded)
		{
			seeded = true;
			return;
		}
		if (!enabled || !guarding || !cadence || !body.visible || elapsed <= 0)
			return;
		var travel = MIN_SPEED * elapsed;
		if (dx * dx + dy * dy < travel * travel)
			return;
		trail.stampFrame(body, tint);
	}

	public function clear():Void
	{
		for (g in trail.group.members)
			if (g != null && g.exists)
				g.kill();
	}
}
