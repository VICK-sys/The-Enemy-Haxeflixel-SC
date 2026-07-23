package util;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class GhostTrail
{
	public var group:FlxTypedGroup<FlxSprite>;

	private var graphic:String;
	private var baseAlpha:Float;
	private var fadeRate:Float;
	private var interval:Float;
	private var timer:Float = 0;

	public function new(graphic:String, baseAlpha:Float, fadeRate:Float, interval:Float)
	{
		this.graphic = graphic;
		this.baseAlpha = baseAlpha;
		this.fadeRate = fadeRate;
		this.interval = interval;
		group = new FlxTypedGroup<FlxSprite>();
	}

	public function tick(elapsed:Float):Bool
	{
		for (g in group.members)
		{
			if (g == null || !g.exists)
				continue;
			g.alpha -= fadeRate * elapsed;
			if (g.alpha <= 0)
				g.kill();
		}

		timer -= elapsed;
		if (timer > 0)
			return false;
		timer = interval;
		return true;
	}

	public function stamp(s:FlxSprite):Void
	{
		var g = group.recycle(FlxSprite);
		if (g.graphic == null)
		{
			g.loadGraphic(Paths.image(graphic));
			g.antialiasing = false;
		}
		g.setPosition(s.x, s.y);
		g.angle = s.angle;
		g.scale.set(s.scale.x, s.scale.y);
		g.color = s.color;
		g.alpha = baseAlpha;
	}

	public function drained():Bool
		return group.countLiving() == 0;
}
