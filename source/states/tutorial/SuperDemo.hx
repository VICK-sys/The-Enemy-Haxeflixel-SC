package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import util.Paths;

class SuperDemo extends TutorialDemo
{
	static inline var HOP_TIME:Float = 0.8;
	static inline var APEX:Float = 60;
	static inline var SPIN:Float = 360;
	static inline var GROUND:Float = 20;
	static inline var SCALE:Float = 3;
	static inline var POP:Float = 1.4;
	static inline var POP_TIME:Float = 0.25;
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
		hammer.scale.set(SCALE, SCALE);
		hammer.origin.set(hammer.width * 0.5, hammer.height);

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

		var pcx = actor.x + actor.width * 0.5;
		var pcy = actor.y + actor.height * 0.5;
		var rad = turn * Math.PI / 180;
		var cos = Math.cos(rad);
		var sin = Math.sin(rad);
		var relX = actor.x + systems.weapons.HeldWeapon.HAND_DX - pcx;
		var relY = actor.y + systems.weapons.HeldWeapon.HAND_DY - pcy;
		hammer.x = pcx + (relX * cos - relY * sin) - hammer.origin.x;
		hammer.y = pcy + (relX * sin + relY * cos) - hammer.origin.y;
		hammer.angle = turn + 180;

		var pop = cycle < POP_TIME ? POP * (1 - cycle / POP_TIME) : 0;
		hammer.scale.set(SCALE + pop, SCALE + pop);

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
