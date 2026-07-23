package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

class Fx
{
	static inline var DASH_LINE_FADE:Float = 3;

	public var sparks:FlxEmitter;
	public var dashTrail:FlxTypedGroup<FlxSprite>;

	private var hitstopFrames:Int = 0;

	public function new()
	{
		FlxG.timeScale = 1;

		sparks = new FlxEmitter(0, 0, 60);
		sparks.makeParticles(4, 4, FlxColor.WHITE, 60);
		sparks.speed.set(100, 400);
		sparks.lifespan.set(0.15, 0.35);

		dashTrail = new FlxTypedGroup<FlxSprite>();
	}

	public function update():Void
	{
		if (hitstopFrames > 0)
		{
			hitstopFrames--;
			if (hitstopFrames <= 0)
				FlxG.timeScale = 1;
		}

		for (l in dashTrail.members)
		{
			if (l == null || !l.exists)
				continue;
			l.alpha -= DASH_LINE_FADE * FlxG.elapsed;
			if (l.alpha <= 0)
				l.kill();
		}
	}

	public function dashLine(cx:Float, cy:Float, dx:Float, dy:Float):Void
	{
		var l = dashTrail.recycle(FlxSprite);
		if (l.graphic == null)
		{
			l.makeGraphic(44, 4, FlxColor.WHITE);
			l.antialiasing = false;
		}
		var off = (FlxG.random.float() * 2 - 1) * 35;
		var lx = cx - dx * 50 - dy * off;
		var ly = cy - dy * 50 + dx * off;
		l.setPosition(lx - l.width / 2, ly - l.height / 2);
		l.angle = Math.atan2(dy, dx) * 180 / Math.PI;
		l.alpha = 0.7;
	}

	public function sparksAt(x:Float, y:Float):Void
	{
		sparks.setPosition(x, y);
		sparks.start(true, 0, 8);
	}

	public function killImpact():Void
	{
		hitstopFrames = 4;
		FlxG.timeScale = 0.05;
		FlxG.camera.shake(0.004, 0.1);
	}

	public function hurtShake():Void
	{
		FlxG.camera.shake(0.012, 0.2);
	}

	public function slamShake():Void
	{
		FlxG.camera.shake(0.009, 0.15);
	}
}
