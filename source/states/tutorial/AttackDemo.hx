package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import util.Paths;

class AttackDemo extends TutorialDemo
{
	private var actor:FlxSprite;
	private var held:FlxSprite;
	private var cursorIcon:FlxSprite;
	private var slash:FlxSprite;
	private var swingTimer:Float = 0;
	private var swingBase:Float = 0;
	private var swingDir:Int = 1;
	private var heldAngle:Float = 0;

	public function new(cam:FlxCamera)
	{
		super(cam);
		actor = player();
		actor.animation.play("idle");
		center(actor, TutorialDemo.CX - 60, TutorialDemo.CY);

		slash = sprite();
		slash.frames = Paths.sparrow("effects/attacks_gfx");
		slash.animation.addByPrefix("slash", "Sword", 12, false);
		slash.scale.set(4, 4);
		slash.kill();

		held = sprite();
		held.loadGraphic(Paths.image("items/mufu_scythe"));
		held.scale.set(4, 4);
		held.origin.set(held.width * 0.5, held.height);

		cursorIcon = sprite();
		cursorIcon.loadGraphic(Paths.image("ui/mouse"));
		cursorIcon.scale.set(3, 3);

		step(0);
	}

	override function step(elapsed:Float):Void
	{
		var a = time * 1.1;
		var tx = TutorialDemo.CX - 60 + Math.cos(a) * 230;
		var ty = TutorialDemo.CY + Math.sin(a) * 110;
		cursorIcon.setPosition(tx - cursorIcon.width / 2, ty - cursorIcon.height / 2);

		var pcx = actor.x + actor.width * 0.5;
		var pcy = actor.y + actor.height * 0.5;
		var theta = Math.atan2(ty - pcy, tx - pcx) * 180 / Math.PI;
		var flip = Math.abs(theta) > 90;
		held.flipX = flip;
		var target = flip ? theta - 180 : theta;

		swingTimer -= elapsed;
		if (time % 1.4 < elapsed && swingTimer <= -0.5)
		{
			swingTimer = 0.2;
			swingDir = flip ? -1 : 1;
			swingBase = target;
			var dx = Math.cos(theta * Math.PI / 180);
			var dy = Math.sin(theta * Math.PI / 180);
			slash.revive();
			slash.animation.play("slash", true);
			slash.setPosition(pcx + dx * 110 - slash.width / 2, pcy + dy * 110 - slash.height / 2);
			slash.angle = theta;
			slash.alpha = 1;
			slash.velocity.set(dx * 150, dy * 150);
			FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.3);
		}

		if (swingTimer > 0)
		{
			var p = 1 - swingTimer / 0.2;
			heldAngle = swingBase + swingDir * 300 * (FlxEase.quintOut(p) - 0.5);
			var s = 4 + 2.5 * Math.sin(Math.PI * p);
			held.scale.set(s, s);
		}
		else
		{
			held.scale.set(4, 4);
			var delta = ((target - heldAngle) % 360 + 540) % 360 - 180;
			heldAngle += delta * (1 - Math.pow(0.75, elapsed * 60));
		}
		held.angle = heldAngle;
		held.x = actor.x - held.origin.x + 30;
		held.y = actor.y - held.origin.y + 65;

		if (slash.exists)
		{
			slash.alpha -= 4 * elapsed;
			if (slash.alpha <= 0)
				slash.kill();
		}
	}
}
