package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import util.Paths;

class ScrapDemo extends TutorialDemo
{
	static inline var LOOP:Float = 4.6;
	static inline var ENEMY_X:Float = 870;
	static inline var HOME_X:Float = 410;

	static inline var COUNT_X:Float = 300;
	static inline var COUNT_Y:Float = 452;

	static var THROW_X:Array<Float> = [-52, 4, 56];
	static var THROW_Y:Array<Float> = [26, 44, 20];

	private var actor:FlxSprite;
	private var foe:FlxSprite;
	private var pieces:Array<FlxSprite> = [];
	private var taken:Array<Bool> = [];
	private var count:FlxText;
	private var counted:Int = 0;
	private var lastT:Float = 0;

	public function new(cam:FlxCamera)
	{
		super(cam);

		foe = sprite();
		foe.frames = Paths.sparrow("enemies/enemy");
		foe.animation.addByPrefix("walk", "Run", 12, true);
		foe.scale.set(4, 4);
		foe.width = 75;
		foe.height = 95;
		foe.offset.set(-15, -19);
		foe.animation.play("walk");
		foe.flipX = true;

		for (i in 0...THROW_X.length)
		{
			var p = sprite();
			p.loadGraphic(Paths.image("items/scrap" + (i + 1)));
			p.scale.set(4, 4);
			p.updateHitbox();
			p.alpha = 0;
			pieces.push(p);
			taken.push(false);
		}

		var icon = sprite();
		icon.loadGraphic(Paths.image("items/scrap"));
		icon.scale.set(4, 4);
		icon.updateHitbox();
		icon.setPosition(COUNT_X, COUNT_Y - icon.height * 0.5);

		count = label(COUNT_Y - 18, 26, "0");
		count.alignment = LEFT;
		count.x = COUNT_X + icon.width + 14;

		actor = player();
		actor.animation.play("idle");
		center(actor, HOME_X, TutorialDemo.CY);
		standWith(foe, ENEMY_X, actor);

		step(0);
	}

	override function step(elapsed:Float):Void
	{
		var t = time % LOOP;
		if (t < lastT)
		{
			counted = 0;
			for (i in 0...taken.length)
				taken[i] = false;
		}
		lastT = t;

		var fcx = ENEMY_X;
		var fcy = TutorialDemo.CY;

		if (t < 0.8)
		{
			foe.alpha = 1;
			for (p in pieces)
				p.alpha = 0;
			center(actor, HOME_X, TutorialDemo.CY);
			actor.flipX = false;
			actor.animation.play("idle");
		}
		else if (t < 1.3)
		{
			var p = (t - 0.8) / 0.5;
			foe.alpha = 1 - p;
			for (i in 0...pieces.length)
			{
				var s = pieces[i];
				var ease = FlxEase.quadOut(p);
				s.alpha = 1;
				s.x = fcx + THROW_X[i] * ease - s.width * 0.5;
				s.y = fcy + THROW_Y[i] * ease - Math.sin(Math.PI * p) * 30 - s.height * 0.5;
			}
		}
		else if (t < 2.7)
		{
			foe.alpha = 0;
			var walk = (t - 1.3) / 1.4;
			var px = HOME_X + (ENEMY_X + 40 - HOME_X) * walk;
			actor.flipX = false;
			actor.animation.play("walk");
			center(actor, px, TutorialDemo.CY);
			for (i in 0...pieces.length)
			{
				var s = pieces[i];
				if (taken[i])
					continue;
				s.y = fcy + THROW_Y[i] - s.height * 0.5 + Math.sin(time * 5 + i) * 4;
				if (px >= s.x + s.width * 0.5)
				{
					taken[i] = true;
					s.alpha = 0;
					counted++;
					FlxG.sound.play(Paths.sound("bulletLoad"), 0.3);
				}
			}
		}
		else if (t < 3.4)
		{
			actor.animation.play("idle");
		}
		else
		{
			var back = (t - 3.4) / 1.2;
			if (back > 1)
				back = 1;
			var px = ENEMY_X + 40 + (HOME_X - ENEMY_X - 40) * back;
			actor.flipX = true;
			actor.animation.play("walk");
			center(actor, px, TutorialDemo.CY);
			foe.alpha = back;
		}

		count.text = Std.string(counted);
	}
}
