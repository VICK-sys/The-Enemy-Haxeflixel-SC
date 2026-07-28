package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import util.Paths;

class PetalFall
{
	static inline var SCALE:Int = 7;
	static inline var POOL:Int = 24;
	static inline var EVERY:Float = 0.34;

	static inline var LIFE_MIN:Float = 2.6;
	static inline var LIFE_MAX:Float = 4.2;
	static inline var VX_MIN:Float = 26;
	static inline var VX_MAX:Float = 66;
	static inline var VY_MIN:Float = 58;
	static inline var VY_MAX:Float = 106;
	static inline var SWAY:Float = 13;
	static inline var SWAY_RATE:Float = 2.1;
	static inline var HOLD:Float = 0.45;

	// the band they break off from, as fractions of the tree's drawn box
	static inline var X0:Float = 0.02;
	static inline var X1:Float = 0.46;
	static inline var Y0:Float = 0.58;
	static inline var Y1:Float = 0.76;

	private var petals:Array<FlxSprite> = [];
	private var life:Array<Float> = [];
	private var span:Array<Float> = [];
	private var vx:Array<Float> = [];
	private var vy:Array<Float> = [];
	private var wobble:Array<Float> = [];
	private var driftX:Array<Float> = [];

	private var left:Float;
	private var top:Float;
	private var wide:Float;
	private var tall:Float;
	private var timer:Float = 0;

	public function new(into:FlxTypedGroup<FlxSprite>, treeX:Float, treeFeetY:Float, treeW:Float, treeH:Float)
	{
		left = treeX + treeW * X0;
		wide = treeW * (X1 - X0);
		top = treeFeetY - treeH + treeH * Y0;
		tall = treeH * (Y1 - Y0);

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
			into.add(s);
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
		for (i in 0...petals.length)
		{
			var s = petals[i];
			if (s.exists)
				continue;

			s.exists = true;
			s.alpha = 1;
			driftX[i] = left + FlxG.random.float(0, wide);
			s.x = driftX[i];
			s.y = top + FlxG.random.float(0, tall);
			vx[i] = FlxG.random.float(VX_MIN, VX_MAX);
			vy[i] = FlxG.random.float(VY_MIN, VY_MAX);
			wobble[i] = FlxG.random.float(0, Math.PI * 2);
			span[i] = FlxG.random.float(LIFE_MIN, LIFE_MAX);
			life[i] = span[i];
			return;
		}
	}
}
