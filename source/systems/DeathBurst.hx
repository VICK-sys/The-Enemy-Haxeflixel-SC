package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class DeathBurst
{
	static inline var PARTS:Int = 4;
	static inline var SPEED_MIN:Float = 260;
	static inline var SPEED_MAX:Float = 520;
	static inline var SPIN:Float = 780;
	static inline var DRAG:Float = 420;

	public var group:FlxTypedGroup<FlxSprite>;

	public function new()
		group = new FlxTypedGroup<FlxSprite>();

	public function burst(cx:Float, cy:Float, hue:Float):Void
	{
		for (i in 0...PARTS)
		{
			var p = group.recycle(FlxSprite);
			p.frames = util.HuePalette.sparrow("characters/mufu", hue);
			p.frame = p.frames.getByName("Part0000" + i);
			p.antialiasing = false;
			p.angle = 0;
			p.scale.set(4, 4);
			p.updateHitbox();
			p.setPosition(cx - p.width * 0.5, cy - p.height * 0.5);
			var ang = FlxG.random.float(0, Math.PI * 2);
			var speed = FlxG.random.float(SPEED_MIN, SPEED_MAX);
			p.velocity.set(Math.cos(ang) * speed, Math.sin(ang) * speed);
			p.drag.set(DRAG, DRAG);
			p.angularVelocity = FlxG.random.float(-SPIN, SPIN);
			p.angularDrag = SPIN;
		}
	}

	public function any():Bool
		return group.countLiving() > 0;

	public function clear():Void
	{
		for (p in group.members)
			if (p != null && p.exists)
				p.kill();
	}
}
