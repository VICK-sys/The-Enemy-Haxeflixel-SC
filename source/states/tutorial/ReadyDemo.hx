package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import util.Lang;
import util.Paths;

class ReadyDemo extends TutorialDemo
{
	static inline var LOOP:Float = 3.8;
	static inline var READY_AT:Float = 1.3;
	static inline var WAVE_AT:Float = 2.5;

	private var actor:FlxSprite;
	private var bubble:FlxSprite;
	private var prompt:FlxText;
	private var wave:FlxText;
	private var popped:Bool = false;
	private var lastT:Float = 0;

	public function new(cam:FlxCamera)
	{
		super(cam);

		actor = player();
		actor.animation.play("idle");
		center(actor, TutorialDemo.CX, TutorialDemo.CY + 30);

		bubble = sprite();
		bubble.loadGraphic(Paths.image("ui/speech_ready"));
		bubble.scale.set(4, 4);
		bubble.updateHitbox();
		bubble.x = actor.x + actor.width * 0.5 - bubble.width * 0.5;
		bubble.y = actor.y - bubble.height - 18;
		bubble.visible = false;

		prompt = label(196, 22, Lang.t("ready.prompt"));
		wave = label(258, 30, Lang.t("hud.wave", [2]));
		wave.alpha = 0;

		step(0);
	}

	override function step(elapsed:Float):Void
	{
		var t = time % LOOP;
		if (t < lastT)
			popped = false;
		lastT = t;

		if (t < READY_AT)
		{
			bubble.visible = false;
			prompt.alpha = 0.6 + Math.sin(time * 5) * 0.4;
			wave.alpha = 0;
		}
		else
		{
			if (!popped)
			{
				popped = true;
				FlxG.sound.play(Paths.sound("weapon/catch"), 0.3);
			}
			bubble.visible = true;
			prompt.alpha = 0;
			if (t >= WAVE_AT)
			{
				var p = (t - WAVE_AT) / 0.3;
				if (p > 1)
					p = 1;
				wave.alpha = p;
			}
		}
	}
}
