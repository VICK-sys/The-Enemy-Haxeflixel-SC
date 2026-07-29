package systems.weapons;

class YoyoRope
{
	public static inline var NODES:Int = 14;

	static inline var SLACK:Float = 1.09;
	static inline var DAMP:Float = 0.9;
	static inline var PASSES:Int = 6;
	static inline var SETTLE:Float = 0.09;
	static inline var MAX_STEP:Float = 0.05;

	public var xs:Array<Float> = [for (i in 0...NODES) 0.0];
	public var ys:Array<Float> = [for (i in 0...NODES) 0.0];

	private var lastX:Array<Float> = [for (i in 0...NODES) 0.0];
	private var lastY:Array<Float> = [for (i in 0...NODES) 0.0];

	public function new() {}

	public function reset(hx:Float, hy:Float, cx:Float, cy:Float):Void
	{
		for (i in 0...NODES)
		{
			var t = i / (NODES - 1);
			xs[i] = hx + (cx - hx) * t;
			ys[i] = hy + (cy - hy) * t;
			lastX[i] = xs[i];
			lastY[i] = ys[i];
		}
	}

	public function update(elapsed:Float, hx:Float, hy:Float, cx:Float, cy:Float):Void
	{
		var dt = elapsed > MAX_STEP ? MAX_STEP : elapsed;
		var keep = Math.pow(DAMP, dt * 60);

		for (i in 1...NODES - 1)
		{
			var vx = (xs[i] - lastX[i]) * keep;
			var vy = (ys[i] - lastY[i]) * keep;
			lastX[i] = xs[i];
			lastY[i] = ys[i];
			xs[i] += vx;
			ys[i] += vy;
		}

		var ease = 1 - Math.pow(1 - SETTLE, dt * 60);
		for (i in 1...NODES - 1)
		{
			var t = i / (NODES - 1);
			xs[i] += (hx + (cx - hx) * t - xs[i]) * ease;
			ys[i] += (hy + (cy - hy) * t - ys[i]) * ease;
		}

		pin(hx, hy, cx, cy);

		var dx = cx - hx;
		var dy = cy - hy;
		var rest = Math.sqrt(dx * dx + dy * dy) * SLACK / (NODES - 1);

		for (pass in 0...PASSES)
		{
			for (i in 0...NODES - 1)
			{
				var ax = xs[i + 1] - xs[i];
				var ay = ys[i + 1] - ys[i];
				var len = Math.sqrt(ax * ax + ay * ay);
				if (len < 0.0001)
					continue;
				var pull = (len - rest) / len * 0.5;
				var ox = ax * pull;
				var oy = ay * pull;
				if (i > 0)
				{
					xs[i] += ox;
					ys[i] += oy;
				}
				if (i + 1 < NODES - 1)
				{
					xs[i + 1] -= ox;
					ys[i + 1] -= oy;
				}
			}
			pin(hx, hy, cx, cy);
		}
	}

	function pin(hx:Float, hy:Float, cx:Float, cy:Float):Void
	{
		xs[0] = hx;
		ys[0] = hy;
		xs[NODES - 1] = cx;
		ys[NODES - 1] = cy;
	}
}
