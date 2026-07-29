package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class YoyoFlight
{
	static inline var SPIN_RATE:Float = 1500;
	static inline var SCALE:Float = 4;
	static inline var CATCH_DIST:Float = 28;
	static inline var MIN_REACH:Float = 140;
	static inline var MIN_FLIGHT:Float = 0.1;

	public var yoyo:FlxSprite;
	public var string:FlxTypedGroup<FlxSprite>;
	public var cx(default, null):Float = 0;
	public var cy(default, null):Float = 0;
	public var active(default, null):Bool = false;
	public var homing(default, null):Bool = false;

	private var cfg = WeaponDataRegistry.get().yoyo;
	private var spin:Float = 1;
	private var flown:Float = 0;
	private var cord:YoyoRope = new YoyoRope();

	public function new()
	{
		yoyo = new FlxSprite();
		yoyo.loadGraphic(Paths.image("items/yoyo_axel"));
		yoyo.antialiasing = false;
		yoyo.scale.set(SCALE, SCALE);
		yoyo.kill();
		string = new FlxTypedGroup<FlxSprite>();
	}

	public function fire(hx:Float, hy:Float, spinDir:Float):Void
	{
		spin = spinDir;
		active = true;
		homing = false;
		flown = 0;
		cx = hx;
		cy = hy;
		cord.reset(hx, hy, hx, hy);
		yoyo.revive();
		place();
	}

	public function recall():Void
		homing = true;

	public function stop():Void
	{
		active = false;
		homing = false;
		yoyo.kill();
		Rope.clear(string);
	}

	public function update(elapsed:Float, hx:Float, hy:Float, aimX:Float, aimY:Float):Void
	{
		if (!active)
			return;

		flown += elapsed;

		var tx = hx;
		var ty = hy;
		if (!homing)
		{
			var rx = aimX - hx;
			var ry = aimY - hy;
			var span = Math.sqrt(rx * rx + ry * ry);
			if (span < 0.001)
			{
				rx = 1;
				ry = 0;
				span = 1;
			}
			var want = span > cfg.reach ? cfg.reach : (span < MIN_REACH ? MIN_REACH : span);
			tx = hx + rx / span * want;
			ty = hy + ry / span * want;
		}

		var gx = tx - cx;
		var gy = ty - cy;
		var gap = Math.sqrt(gx * gx + gy * gy);
		if (gap > 0.001)
		{
			var step:Float;
			if (homing)
				step = cfg.speed * elapsed;
			else
			{
				step = gap * (1 - Math.pow(1 - cfg.chaseEase, elapsed * 60));
				var cap = cfg.speed * elapsed;
				if (step > cap)
					step = cap;
			}
			if (step > gap)
				step = gap;
			cx += gx / gap * step;
			cy += gy / gap * step;
		}

		if (homing && flown >= MIN_FLIGHT)
		{
			var hdx = cx - hx;
			var hdy = cy - hy;
			if (hdx * hdx + hdy * hdy < CATCH_DIST * CATCH_DIST)
			{
				stop();
				return;
			}
		}

		yoyo.angle += spin * SPIN_RATE * elapsed;
		place();
		cord.update(elapsed, hx, hy, cx, cy);
		Rope.chain(string, cord.xs, cord.ys);
	}

	public function drive(px:Float, py:Float, ang:Float, hx:Float, hy:Float):Void
	{
		if (!active)
		{
			active = true;
			yoyo.revive();
			cord.reset(hx, hy, px, py);
		}
		cx = px;
		cy = py;
		yoyo.angle = ang;
		place();
		cord.update(FlxG.elapsed, hx, hy, cx, cy);
		Rope.chain(string, cord.xs, cord.ys);
	}

	function place():Void
		yoyo.setPosition(cx - yoyo.width * 0.5, cy - yoyo.height * 0.5);
}
