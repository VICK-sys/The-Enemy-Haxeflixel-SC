package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxSprite;
import util.Paths;

class SuperDemo extends TutorialDemo
{
	private var actor:FlxSprite;
	private var blades:Array<FlxSprite> = [];

	public function new(cam:FlxCamera)
	{
		super(cam);
		actor = player();
		actor.animation.play("idle");
		for (i in 0...6)
		{
			var b = sprite();
			b.loadGraphic(Paths.image("items/mufu_scythe"));
			b.scale.set(3, 3);
			blades.push(b);
		}
		step(0);
	}

	override function step(elapsed:Float):Void
	{
		var lift = 26 + Math.sin(time * 3) * 6;
		center(actor, TutorialDemo.CX, TutorialDemo.CY - lift + 20);

		for (i in 0...blades.length)
		{
			var phase = (time * 120 + i * 60) * Math.PI / 180;
			var depth = Math.sin(phase);
			var b = blades[i];
			var bx = TutorialDemo.CX + Math.cos(phase) * 130;
			var by = TutorialDemo.CY - lift + 20 + depth * 45;
			var s = 3 + depth * 0.4;
			b.scale.set(s, s);
			b.alpha = 0.85 + 0.15 * depth;
			b.setPosition(bx - b.width / 2, by - b.height / 2);
		}
	}
}
