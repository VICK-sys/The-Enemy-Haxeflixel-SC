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

	public var yoyo:FlxSprite;
	public var string:FlxTypedGroup<FlxSprite>;
	public var cx(default, null):Float = 0;
	public var cy(default, null):Float = 0;
	public var active(default, null):Bool = false;
	public var homing(default, null):Bool = false;

	private var cfg = WeaponDataRegistry.get().yoyo;
	private var spin:Float = 1;

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
		cx = hx;
		cy = hy;
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

		var tx = hx;
		var ty = hy;
		if (!homing)
		{
			var rx = aimX - hx;
			var ry = aimY - hy;
			var reach = Math.sqrt(rx * rx + ry * ry);
			if (reach > cfg.reach)
			{
				rx = rx / reach * cfg.reach;
				ry = ry / reach * cfg.reach;
			}
			tx = hx + rx;
			ty = hy + ry;
		}

		var gx = tx - cx;
		var gy = ty - cy;
		var gap = Math.sqrt(gx * gx + gy * gy);
		if (gap > 0.001)
		{
			var step = gap * (1 - Math.pow(1 - cfg.chaseEase, elapsed * 60));
			var cap = cfg.speed * elapsed;
			if (step > cap)
				step = cap;
			cx += gx / gap * step;
			cy += gy / gap * step;
		}

		if (homing)
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
		Rope.line(string, hx, hy, cx, cy);
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
		Rope.line(string, hx, hy, cx, cy);
	}

	function place():Void
		yoyo.setPosition(cx - yoyo.width * 0.5, cy - yoyo.height * 0.5);
}
