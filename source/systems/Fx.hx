package systems;

import flixel.FlxG;
import flixel.effects.particles.FlxEmitter;
import flixel.util.FlxColor;

class Fx
{
	public var sparks:FlxEmitter;

	private var hitstopFrames:Int = 0;

	public function new()
	{
		FlxG.timeScale = 1;

		sparks = new FlxEmitter(0, 0, 60);
		sparks.makeParticles(4, 4, FlxColor.WHITE, 60);
		sparks.speed.set(100, 400);
		sparks.lifespan.set(0.15, 0.35);
	}

	public function update():Void
	{
		if (hitstopFrames > 0)
		{
			hitstopFrames--;
			if (hitstopFrames <= 0)
				FlxG.timeScale = 1;
		}
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
