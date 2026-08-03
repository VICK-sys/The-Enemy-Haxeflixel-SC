package systems.weapons;

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
	static inline var TURN:Float = 6.5;
	static inline var SLOW_RADIUS:Float = 110;
	static inline var BOUNCE:Float = 1000;

	private var jab = data.WeaponData.WeaponDataRegistry.get().yoyo;
	static inline var BOUNCE_GRACE:Float = 0.12;
	static inline var WOBBLE:Float = 5;
	static inline var WOBBLE_SPIN:Float = 11;

	public var yoyo:FlxSprite;
	public var string:FlxTypedGroup<FlxSprite>;
	public var cx(default, null):Float = 0;
	public var cy(default, null):Float = 0;
	public var active(default, null):Bool = false;
	public var homing(default, null):Bool = false;

	private var cfg = WeaponDataRegistry.get().yoyo;
	private var spin:Float = 1;
	private var flown:Float = 0;
	private var vx:Float = 0;
	private var vy:Float = 0;
	private var grace:Float = 0;
	private var wobble:Float = 0;

	public var hue(default, null):Float = 0;

	public function new()
	{
		yoyo = new FlxSprite();
		yoyo.loadGraphic(util.HuePalette.graphic("items/yoyo_axel", 0));
		yoyo.antialiasing = false;
		yoyo.scale.set(SCALE, SCALE);
		yoyo.kill();
		string = new FlxTypedGroup<FlxSprite>();
	}

	public function setHue(h:Float):Void
	{
		if (h == hue)
			return;
		hue = h;
		yoyo.loadGraphic(util.HuePalette.graphic("items/yoyo_axel", h));
	}

	public function fire(hx:Float, hy:Float, dx:Float, dy:Float, spinDir:Float):Void
	{
		spin = spinDir;
		active = true;
		homing = false;
		flown = 0;
		cx = hx;
		cy = hy;
		vx = dx * cfg.speed;
		vy = dy * cfg.speed;
		grace = 0;
		yoyo.revive();
		place();
	}

	public function recall():Void
		homing = true;

	public function bounce(dx:Float, dy:Float):Void
	{
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len < 0.001)
		{
			dx = -1;
			dy = 0;
			len = 1;
		}
		var kick = jab.bounce == null ? BOUNCE : jab.bounce;
		vx = dx / len * kick;
		vy = dy / len * kick;
		grace = BOUNCE_GRACE;
	}

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

		if (homing)
		{
			var gx = hx - cx;
			var gy = hy - cy;
			var gap = Math.sqrt(gx * gx + gy * gy);
			if (flown >= MIN_FLIGHT && gap < CATCH_DIST)
			{
				stop();
				return;
			}
			if (gap > 0.001)
			{
				var step = cfg.speed * elapsed;
				if (step > gap)
					step = gap;
				cx += gx / gap * step;
				cy += gy / gap * step;
			}
		}
		else
		{
			wobble += elapsed * WOBBLE_SPIN;

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
			var tx = hx + rx / span * want + Math.cos(wobble) * WOBBLE;
			var ty = hy + ry / span * want + Math.sin(wobble * 1.7) * WOBBLE;

			if (grace > 0)
				grace -= elapsed;
			else
			{
				var gx = tx - cx;
				var gy = ty - cy;
				var gap = Math.sqrt(gx * gx + gy * gy);
				var slow = gap / SLOW_RADIUS;
				if (slow > 1)
					slow = 1;
				var k = TURN * elapsed;
				if (k > 1)
					k = 1;
				vx += ((gap > 0.001 ? gx / gap * cfg.speed * slow : 0) - vx) * k;
				vy += ((gap > 0.001 ? gy / gap * cfg.speed * slow : 0) - vy) * k;
			}
			cx += vx * elapsed;
			cy += vy * elapsed;

			var ox = cx - hx;
			var oy = cy - hy;
			var od = Math.sqrt(ox * ox + oy * oy);
			if (od > cfg.reach)
			{
				cx = hx + ox / od * cfg.reach;
				cy = hy + oy / od * cfg.reach;
				var out = (vx * ox + vy * oy) / od;
				if (out > 0)
				{
					vx -= ox / od * out;
					vy -= oy / od * out;
				}
			}
		}

		yoyo.angle += spin * SPIN_RATE * elapsed;
		place();
		Rope.line(string, hx, hy, cx, cy, hue);
	}

	public function drive(px:Float, py:Float, ang:Float, hx:Float, hy:Float):Void
	{
		if (!active)
		{
			active = true;
			yoyo.revive();
		}
		cx = px;
		cy = py;
		yoyo.angle = ang;
		place();
		Rope.line(string, hx, hy, cx, cy, hue);
	}

	function place():Void
		yoyo.setPosition(cx - yoyo.width * 0.5, cy - yoyo.height * 0.5);
}
