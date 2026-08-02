package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class DeathBurst
{
	static inline var PARTS:Int = 4;
	static inline var SPEED:Float = 480;
	static inline var SPEED_VARY:Float = 0.28;
	static inline var SPREAD:Float = 0.3;
	static inline var SPIN:Float = 70;
	static inline var TILT:Float = 20;
	static inline var DRAG:Float = 700;
	static inline var WHITE_HOLD:Float = 0.08;
	static inline var FADE_TIME:Float = 0.14;
	static inline var SPIN_DRAG:Float = 260;

	static var LAYOUT:Array<Array<Float>> = [
		[2, 10, -0.4, 0.35, 0.7],
		[0, -46, 0.15, -1, 0.7],
		[16, 40, 0.8, 0.5, 0.65],
		[-6, -4, -0.9, -0.3, 0.85]
	];

	public var group:FlxTypedGroup<FlxSprite>;

	private var life:Float = 0;

	public function new()
		group = new FlxTypedGroup<FlxSprite>();

	public function burst(cx:Float, cy:Float, hue:Float, faceLeft:Bool = false, ?sheet:String):Void
	{
		var side = faceLeft ? -1 : 1;
		life = 0;

		for (i in 0...PARTS)
		{
			var row = LAYOUT[i];
			var p = group.recycle(FlxSprite);
			p.frames = util.HuePalette.sparrow(sheet != null ? sheet : util.Skins.sheet(), hue);
			p.frame = p.frames.getByName("Part0000" + i);
			p.antialiasing = false;
			p.scale.set(4, 4);
			p.updateHitbox();
			p.angle = FlxG.random.float(-TILT, TILT);
			p.alpha = 1;
			p.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
			p.setPosition(cx + row[0] * side - p.width * 0.5, cy + row[1] - p.height * 0.5);

			var ang = Math.atan2(row[3], row[2] * side) + FlxG.random.float(-SPREAD, SPREAD);
			var speed = SPEED * row[4] * FlxG.random.float(1 - SPEED_VARY, 1 + SPEED_VARY);
			p.velocity.set(Math.cos(ang) * speed, Math.sin(ang) * speed);
			p.drag.set(DRAG, DRAG);
			p.angularVelocity = FlxG.random.float(-SPIN, SPIN);
			p.angularDrag = SPIN_DRAG;
		}
	}

	public function update(elapsed:Float):Void
	{
		if (life >= WHITE_HOLD + FADE_TIME || group.countLiving() <= 0)
			return;

		life += elapsed;
		var lit:Float = 1;
		if (life > WHITE_HOLD)
		{
			lit = 1 - (life - WHITE_HOLD) / FADE_TIME;
			if (lit < 0)
				lit = 0;
		}

		var add = Std.int(255 * lit);
		var own = 1 - lit;
		for (p in group.members)
			if (p != null && p.exists)
				p.setColorTransform(own, own, own, 1, add, add, add, 0);
	}

	public function any():Bool
		return group.countLiving() > 0;

	public function clear():Void
	{
		for (p in group.members)
			if (p != null && p.exists)
			{
				p.alpha = 1;
				p.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
				p.kill();
			}
	}
}
