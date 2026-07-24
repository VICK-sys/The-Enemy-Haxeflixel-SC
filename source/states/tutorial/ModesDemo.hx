package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import util.Paths;

class ModesDemo extends TutorialDemo
{
	private var modeIcon:FlxSprite;
	private var modeLabel:FlxText;
	private var cycleIndex:Int = 0;
	private var cycleTimer:Float = 0;
	private var switchTimer:Float = 0;

	public function new(cam:FlxCamera)
	{
		super(cam);
		modeIcon = sprite();
		modeLabel = label(TutorialDemo.CY + 100, 28, "");
		label(TutorialDemo.CY - 160, 24, "Q");
		setModeIcon(0);
		step(0);
	}

	override function step(elapsed:Float):Void
	{
		cycleTimer -= elapsed;
		if (cycleTimer <= 0)
		{
			cycleTimer = 1.1;
			cycleIndex = (cycleIndex + 1) % 3;
			switchTimer = 0.3;
			setModeIcon(cycleIndex);
			FlxG.sound.play(Paths.sound("scythe/catch"), 0.25);
		}
		if (switchTimer > 0)
		{
			switchTimer -= elapsed;
			var p = 1 - switchTimer / 0.3;
			if (p > 1)
				p = 1;
			var ease = 1 - (1 - p) * (1 - p) * (1 - p);
			modeIcon.alpha = ease;
			modeLabel.alpha = 0.3 + 0.7 * ease;
		}
		else
		{
			modeIcon.alpha = 1;
			modeLabel.alpha = 1;
		}
	}

	function setModeIcon(i:Int):Void
	{
		var baseAngle:Float = 0;
		if (i == 2)
		{
			modeIcon.loadGraphic(Paths.image("items/mufu_scythe"));
			baseAngle = 30;
		}
		else
		{
			modeIcon.frames = Paths.sparrow("effects/attacks_gfx");
			if (modeIcon.animation.getByName("slash") == null)
				modeIcon.animation.addByPrefix("slash", "Sword", 0, false);
			var anim = modeIcon.animation.getByName("slash");
			modeIcon.animation.play("slash", true, false, i == 1 && anim.numFrames > 3 ? anim.numFrames - 3 : 0);
			modeIcon.animation.pause();
			baseAngle = i == 1 ? -35 : 0;
		}
		modeIcon.setGraphicSize(0, 130);
		modeIcon.updateHitbox();
		modeIcon.setPosition(TutorialDemo.CX - modeIcon.width / 2, TutorialDemo.CY - modeIcon.height / 2);
		modeIcon.angle = baseAngle;
		modeLabel.text = ["SWING", "AIR SLICE", "THROW"][i];
	}
}
