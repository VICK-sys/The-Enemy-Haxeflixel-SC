package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.Paths;

class WeaponsDemo extends TutorialDemo
{
	private var items:Array<FlxSprite> = [];
	private var itemBase:Array<Float> = [];
	private var itemLabels:Array<FlxText> = [];
	private var cycleIndex:Int = 0;
	private var cycleTimer:Float = 0;
	private var switchTimer:Float = 0;

	public function new(cam:FlxCamera)
	{
		super(cam);
		var names = ["mufu_scythe", "mufu_hammer", "mufu_bow", "mufu_hook"];
		for (i in 0...4)
		{
			var s = sprite();
			s.loadGraphic(Paths.image("items/" + names[i]));
			s.setGraphicSize(0, 130);
			s.updateHitbox();
			s.setPosition(TutorialDemo.CX + (i - 1.5) * 160 - s.width / 2, TutorialDemo.CY - s.height / 2);
			items.push(s);
			itemBase.push(s.scale.y);

			var l = new FlxText(0, TutorialDemo.CY + 90, 0, Std.string(i + 1));
			l.setFormat(null, 24, FlxColor.WHITE, CENTER);
			l.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			l.cameras = [cam];
			add(l);
			l.x = TutorialDemo.CX + (i - 1.5) * 160 - l.width / 2;
			itemLabels.push(l);
		}
		step(0);
	}

	override function step(elapsed:Float):Void
	{
		cycleTimer -= elapsed;
		if (cycleTimer <= 0)
		{
			cycleTimer = 0.9;
			cycleIndex = (cycleIndex + 1) % 4;
			switchTimer = 0.3;
			FlxG.sound.play(Paths.sound("scythe/catch"), 0.25);
		}
		if (switchTimer > 0)
			switchTimer -= elapsed;

		var p = 1 - switchTimer / 0.3;
		if (p > 1)
			p = 1;
		var ease = 1 - (1 - p) * (1 - p) * (1 - p);
		for (i in 0...4)
		{
			var s = items[i];
			if (i == cycleIndex)
			{
				var mult = 1.25 + (1 - ease) * 0.5;
				s.scale.set(itemBase[i] * mult, itemBase[i] * mult);
				s.angle = -180 * (1 - ease);
				s.alpha = 1;
				itemLabels[i].alpha = 1;
			}
			else
			{
				s.scale.set(itemBase[i], itemBase[i]);
				s.angle = 0;
				s.alpha = 0.35;
				itemLabels[i].alpha = 0.35;
			}
		}
	}
}
