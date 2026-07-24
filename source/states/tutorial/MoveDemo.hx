package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxSprite;

class MoveDemo extends TutorialDemo
{
	private var actor:FlxSprite;
	private var lines:Array<FlxSprite> = [];
	private var lineTimer:Float = 0;

	public function new(cam:FlxCamera)
	{
		super(cam);
		actor = player();
		for (i in 0...6)
		{
			var l = sprite();
			l.makeGraphic(44, 4, 0xFFFFFFFF);
			l.alpha = 0;
			lines.push(l);
		}
		step(0);
	}

	override function step(elapsed:Float):Void
	{
		for (l in lines)
			if (l.alpha > 0)
				l.alpha -= 3 * elapsed;

		var t = time % 3.0;
		var px:Float;
		if (t < 1.2)
		{
			px = 470 + t / 1.2 * 150;
			actor.flipX = false;
			actor.animation.play("walk");
		}
		else if (t < 1.5)
		{
			px = 620 + (t - 1.2) / 0.3 * 190;
			actor.flipX = false;
			lineTimer -= elapsed;
			if (lineTimer <= 0)
			{
				lineTimer = 0.05;
				for (l in lines)
					if (l.alpha <= 0)
					{
						l.alpha = 0.7;
						l.setPosition(px - 90, TutorialDemo.CY + 10 + Math.random() * 40 - 20);
						break;
					}
			}
		}
		else
		{
			px = 810 - (t - 1.5) / 1.5 * 340;
			actor.flipX = true;
			actor.animation.play("walk");
		}
		center(actor, px, TutorialDemo.CY);
	}
}
