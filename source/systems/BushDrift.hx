package systems;

import flixel.FlxSprite;

class BushDrift
{
	static inline var REACH:Float = 3;
	static inline var SPEED:Float = 5;

	private var sprites:Array<FlxSprite> = [];
	private var homeX:Array<Float> = [];
	private var homeY:Array<Float> = [];
	private var backwards:Array<Bool> = [];
	private var walked:Float = 0;

	public function new() {}

	public function add(s:FlxSprite, reverse:Bool):Void
	{
		sprites.push(s);
		homeX.push(s.x);
		homeY.push(s.y);
		backwards.push(reverse);
	}

	public function update(elapsed:Float):Void
	{
		if (sprites.length == 0)
			return;

		var loop = REACH * 8;
		walked = (walked + elapsed * SPEED) % loop;

		for (i in 0...sprites.length)
		{
			var u = backwards[i] ? (loop - walked) % loop : walked;
			var leg = Std.int(u / (REACH * 2));
			var run = u - leg * REACH * 2;

			var dx = 0.0;
			var dy = 0.0;
			switch (leg)
			{
				case 0:
					dx = -REACH;
					dy = REACH - run;
				case 1:
					dx = -REACH + run;
					dy = -REACH;
				case 2:
					dx = REACH;
					dy = -REACH + run;
				default:
					dx = REACH - run;
					dy = REACH;
			}

			sprites[i].x = homeX[i] + dx;
			sprites[i].y = homeY[i] + dy;
		}
	}
}
