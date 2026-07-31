package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import util.Paths;

class SuperDemo extends TutorialDemo
{
	static inline var HOP_TIME:Float = 0.8;
	static inline var APEX:Float = 130;
	static inline var SPIN:Float = 360;
	static inline var GROUND:Float = 60;
	static inline var HAND:Float = 74;
	static inline var RING_TIME:Float = 0.4;
	static inline var RING_W:Float = 300;
	static inline var RING_H:Float = 74;

	private var actor:FlxSprite;
	private var hammer:FlxSprite;
	private var ring:FlxSprite;

	public function new(cam:FlxCamera)
	{
		super(cam);

		ring = sprite();
		ring.loadGraphic(Paths.image("effects/shadow"));
		ring.color = FlxColor.WHITE;
		ring.alpha = 0;

		actor = player();
		actor.animation.play("idle");

		hammer = sprite();
		hammer.loadGraphic(Paths.image("items/hammer"));
		hammer.scale.set(3, 3);
		hammer.updateHitbox();

		step(0);
	}

	override function step(elapsed:Float):Void
	{
		var cycle = time % HOP_TIME;
		var t = cycle / HOP_TIME;
		var groundY = TutorialDemo.CY + GROUND;
		var bodyY = groundY - APEX * Math.sin(Math.PI * t);
		var turn = SPIN * t;

		center(actor, TutorialDemo.CX, bodyY);
		actor.angle = turn;

		var rad = (turn - 90) * Math.PI / 180;
		hammer.angle = turn + 180;
		hammer.setPosition(TutorialDemo.CX + Math.cos(rad) * HAND - hammer.width / 2,
			bodyY + Math.sin(rad) * HAND - hammer.height / 2);

		if (cycle < RING_TIME)
		{
			var k = cycle / RING_TIME;
			ring.setGraphicSize(Std.int(RING_W * k), Std.int(RING_H * k));
			ring.updateHitbox();
			center(ring, TutorialDemo.CX, groundY + 34);
			ring.alpha = 0.55 * (1 - k);
		}
		else
			ring.alpha = 0;
	}
}
