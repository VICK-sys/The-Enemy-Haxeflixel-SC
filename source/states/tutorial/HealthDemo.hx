package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxSprite;

class HealthDemo extends TutorialDemo
{
	private var actor:FlxSprite;
	private var heart:FlxSprite;
	private var barFill:FlxSprite;

	public function new(cam:FlxCamera)
	{
		super(cam);
		actor = player();

		heart = sprite();
		heart.makeGraphic(12, 12, 0xFFE04848);
		heart.scale.set(3, 3);
		heart.setPosition(770 - 6, TutorialDemo.CY + 20 - 6);

		var barBack = sprite();
		barBack.makeGraphic(200, 18, 0xFF2A2A2A);
		barBack.setPosition(TutorialDemo.CX - 100, 190);

		barFill = sprite();
		barFill.makeGraphic(192, 10, 0xFFD22C3C);
		barFill.origin.set(0, 5);
		barFill.setPosition(TutorialDemo.CX - 96, 194);
		barFill.scale.x = 0.5;

		step(0);
	}

	override function step(elapsed:Float):Void
	{
		var t = time % 2.8;
		if (t < 1.4)
		{
			center(actor, 480 + t / 1.4 * 230, TutorialDemo.CY);
			actor.flipX = false;
			actor.animation.play("walk");
			heart.alpha = 1;
			heart.scale.set(3, 3);
			heart.y = TutorialDemo.CY + 14 + Math.sin(time * 4) * 4;
			barFill.scale.x = 0.5;
		}
		else if (t < 1.8)
		{
			actor.animation.play("idle");
			var p = (t - 1.4) / 0.4;
			heart.scale.set(3 + p * 3, 3 + p * 3);
			heart.alpha = 1 - p;
			barFill.scale.x = 0.5 + p * 0.5;
		}
		else
		{
			actor.animation.play("idle");
			heart.alpha = 0;
			barFill.scale.x = 1;
		}
	}
}
