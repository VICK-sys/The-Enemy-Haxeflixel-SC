package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import util.Paths;

class SuperDemo extends TutorialDemo
{
	static inline var SWINGS:Int = 8;
	static inline var WINDUP:Float = 0.22;
	static inline var GAP:Float = 0.16;
	static inline var FINISH_TIME:Float = 0.34;
	static inline var REST:Float = 0.9;
	static inline var ARC:Float = 180;
	static inline var BASE:Float = 65;
	static inline var HELD_SCALE:Float = 4;
	static inline var LUNGE:Float = 26;
	static inline var DEMO:Float = 0.62;

	private var actor:FlxSprite;
	private var held:FlxSprite;
	private var slash:FlxSprite;
	private var finishSlash:FlxSprite;
	private var lastSwing:Int = -1;
	private var finished:Bool = false;
	private var pendingCut:Int = 0;
	private var reach:Float;

	public function new(cam:FlxCamera)
	{
		super(cam);

		var cfg = data.WeaponData.WeaponDataRegistry.get().flurry;
		var hit = 4 * cfg.swing.effectScale * DEMO;
		reach = cfg.swing.spawnDist * DEMO;

		actor = player();
		actor.animation.play("idle");
		actor.scale.set(4 * DEMO, 4 * DEMO);

		slash = sprite();
		slash.frames = Paths.sparrow("effects/attacks_gfx");
		slash.animation.addByPrefix("slash", "Sword", 12, false);
		slash.scale.set(hit, hit);
		slash.kill();

		finishSlash = sprite();
		finishSlash.frames = Paths.sparrow("effects/attacks_gfx");
		finishSlash.animation.addByPrefix("slash", "Sword", 12, false);
		finishSlash.scale.set(hit, hit);
		finishSlash.kill();

		held = sprite();
		held.loadGraphic(Paths.image("items/hammer"));
		held.scale.set(HELD_SCALE * DEMO, HELD_SCALE * DEMO);
		held.origin.set(held.width * 0.5, held.height);

		step(0);
	}

	inline function cycle():Float
		return WINDUP + SWINGS * GAP + FINISH_TIME + REST;

	function cut(rising:Bool, big:Bool):Void
	{
		var s = big ? finishSlash : slash;
		var hx = held.x + held.origin.x + reach;
		var hy = held.y + held.origin.y;
		s.revive();
		s.animation.play("slash", true);
		s.alpha = 1;
		s.flipY = rising;
		s.angle = 0;
		s.setPosition(hx - s.width * 0.5, hy - s.height * 0.5);
		FlxG.sound.play(Paths.sound(big ? "weapon/gigaSwing" : "weapon/gigaHit"), big ? 0.35 : 0.16);
	}

	override function step(elapsed:Float):Void
	{
		var t = time % cycle();
		var swingsEnd = WINDUP + SWINGS * GAP;
		var lunge = 0.0;
		var angle = BASE;
		var scale = HELD_SCALE * DEMO;

		if (t < WINDUP)
		{
			var p = t / WINDUP;
			angle = BASE - 90 * FlxEase.quadOut(p);
			scale = (HELD_SCALE + 0.5 * p) * DEMO;
			lastSwing = -1;
			finished = false;
		}
		else if (t < swingsEnd)
		{
			var i = Std.int((t - WINDUP) / GAP);
			var p = ((t - WINDUP) % GAP) / GAP;
			var rising = i % 2 == 1;
			var dir = rising ? -1 : 1;
			angle = BASE + dir * ARC * (FlxEase.quintOut(p) - 0.5);
			scale = (HELD_SCALE + 0.7 * Math.sin(Math.PI * p)) * DEMO;
			lunge = LUNGE * DEMO * Math.sin(Math.PI * p);
			if (i != lastSwing)
			{
				lastSwing = i;
				pendingCut = rising ? 1 : 2;
			}
		}
		else if (t < swingsEnd + FINISH_TIME)
		{
			var p = (t - swingsEnd) / FINISH_TIME;
			angle = BASE + ARC * (FlxEase.quintOut(p) - 0.5);
			scale = (HELD_SCALE + 1.3 * Math.sin(Math.PI * p)) * DEMO;
			lunge = LUNGE * 2 * DEMO * Math.sin(Math.PI * p);
			if (!finished)
			{
				finished = true;
				pendingCut = 3;
			}
		}

		center(actor, TutorialDemo.CX - 40 + lunge, TutorialDemo.CY);

		held.scale.set(scale, scale);
		held.angle = angle;
		held.x = actor.x - held.origin.x + systems.weapons.HeldWeapon.HAND_DX * DEMO;
		held.y = actor.y - held.origin.y + systems.weapons.HeldWeapon.HAND_DY * DEMO;

		if (pendingCut > 0)
		{
			cut(pendingCut == 1, pendingCut == 3);
			pendingCut = 0;
		}

		fade(slash, 5, elapsed);
		fade(finishSlash, 2.5, elapsed);
	}

	function fade(s:FlxSprite, rate:Float, elapsed:Float):Void
	{
		if (!s.exists)
			return;
		s.alpha -= rate * elapsed;
		if (s.alpha <= 0)
			s.kill();
	}
}
