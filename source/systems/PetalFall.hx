package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import util.Paths;

class PetalFall
{
	static inline var SCALE:Int = 7;
	static inline var POOL:Int = 12;
	static inline var EVERY:Float = 1.15;

	static inline var LIFE_MIN:Float = 2.6;
	static inline var LIFE_MAX:Float = 4.2;
	static inline var VX_MIN:Float = 26;
	static inline var VX_MAX:Float = 66;
	static inline var VY_MIN:Float = 58;
	static inline var VY_MAX:Float = 106;
	static inline var SWAY:Float = 13;
	static inline var SWAY_RATE:Float = 2.1;
	static inline var HOLD:Float = 0.45;

	// only the right of the bush sheds, and only from the underside of the art
	static inline var RIGHT_FROM:Float = 0.5;
	static inline var ALPHA_FLOOR:Int = 20;

	public var group(default, null):FlxTypedGroup<FlxSprite>;

	private var petals:Array<FlxSprite> = [];
	private var life:Array<Float> = [];
	private var span:Array<Float> = [];
	private var vx:Array<Float> = [];
	private var vy:Array<Float> = [];
	private var wobble:Array<Float> = [];
	private var driftX:Array<Float> = [];

	private var bush:FlxSprite;
	private var edgeX:Array<Int> = [];
	private var edgeY:Array<Int> = [];
	private var timer:Float = 0;

	public function new(bush:FlxSprite, sheet:String)
	{
		this.bush = bush;
		group = new FlxTypedGroup<FlxSprite>();

		traceUnderside(sheet);

		for (i in 0...POOL)
		{
			var s = new FlxSprite(0, 0, Paths.image("props/petal"));
			s.antialiasing = false;
			s.scale.set(SCALE, SCALE);
			s.updateHitbox();
			s.exists = false;
			petals.push(s);
			life.push(0);
			span.push(1);
			vx.push(0);
			vy.push(0);
			wobble.push(0);
			driftX.push(0);
			group.add(s);
		}
	}

	function traceUnderside(sheet:String):Void
	{
		var g = FlxG.bitmap.add(Paths.image(sheet));
		if (g == null)
			return;
		var bmp = g.bitmap;
		var from = Std.int(bmp.width * RIGHT_FROM);
		for (px in from...bmp.width)
		{
			var lowest = -1;
			for (py in 0...bmp.height)
				if ((bmp.getPixel32(px, py) >>> 24) > ALPHA_FLOOR)
					lowest = py;
			if (lowest >= 0)
			{
				edgeX.push(px);
				edgeY.push(lowest);
			}
		}
	}

	public function update(elapsed:Float):Void
	{
		timer -= elapsed;
		if (timer <= 0)
		{
			timer = EVERY;
			release();
		}

		for (i in 0...petals.length)
		{
			var s = petals[i];
			if (!s.exists)
				continue;

			life[i] -= elapsed;
			if (life[i] <= 0)
			{
				s.exists = false;
				continue;
			}

			driftX[i] += vx[i] * elapsed;
			wobble[i] += elapsed * SWAY_RATE;
			s.y += vy[i] * elapsed;
			s.x = driftX[i] + Math.sin(wobble[i]) * SWAY;

			var gone = 1 - life[i] / span[i];
			s.alpha = gone < HOLD ? 1 : 1 - (gone - HOLD) / (1 - HOLD);
		}
	}

	function release():Void
	{
		if (edgeX.length == 0)
			return;

		for (i in 0...petals.length)
		{
			var s = petals[i];
			if (s.exists)
				continue;

			// the bush drifts, so read where it is right now
			var pick = FlxG.random.int(0, edgeX.length - 1);
			var x = bush.x + edgeX[pick] * bush.scale.x;
			var y = bush.y + edgeY[pick] * bush.scale.y;

			s.exists = true;
			s.alpha = 1;
			driftX[i] = x - s.width * 0.5;
			s.x = driftX[i];
			s.y = y - s.height * 0.5;
			vx[i] = FlxG.random.float(VX_MIN, VX_MAX);
			vy[i] = FlxG.random.float(VY_MIN, VY_MAX);
			wobble[i] = FlxG.random.float(0, Math.PI * 2);
			span[i] = FlxG.random.float(LIFE_MIN, LIFE_MAX);
			life[i] = span[i];
			return;
		}
	}
}
