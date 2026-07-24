package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import systems.MenuList;
import util.DiscordPresence;
import util.Music;
import util.SaveData;

class MainMenuState extends FlxState
{
	static inline var ACCENT:Int = 0xFFE0132D;

	private var list:MenuList;
	private var best:FlxText;
	private var leaving:Bool = false;

	override public function create()
	{
		persistentUpdate = true;
		FlxG.camera.bgColor = 0xFF000000;
		FlxG.mouse.visible = true;
		DiscordPresence.menu();

		var title = new FlxText(0, 110, FlxG.width, "THE ENEMY");
		title.setFormat(null, 96, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, ACCENT, 4);
		add(title);

		var labels = ["PLAY", "OPTIONS"];
		#if !html5
		labels.push("QUIT");
		#end
		list = new MenuList(labels, 380, 78, 44);
		list.onChoose = choose;
		add(list);

		best = new FlxText(16, FlxG.height - 30, 0, "");
		best.setFormat(null, 16, FlxColor.WHITE, LEFT);
		best.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(best);
		refreshBest();

		subStateClosed.add(function(_)
		{
			list.enabled = true;
			refreshBest();
		});

		Music.play("stage/gloomDoomWoods", 0.3);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	function refreshBest():Void
	{
		var n = SaveData.bestWave();
		best.text = n > 0 ? "BEST: WAVE " + n : "";
	}

	function choose(i:Int):Void
	{
		if (leaving)
			return;

		switch (i)
		{
			case 0:
				startGame();
			case 1:
				list.enabled = false;
				FlxG.inputs.reset();
				openSubState(new OptionsSubState());
			default:
				quit();
		}
	}

	function startGame():Void
	{
		leaving = true;
		list.enabled = false;
		FlxG.camera.fade(FlxColor.BLACK, 0.4, false, function()
		{
			FlxG.mouse.visible = false;
			FlxG.switchState(new PlayState());
		});
	}

	function quit():Void
	{
		leaving = true;
		list.enabled = false;
		FlxG.camera.fade(FlxColor.BLACK, 0.25, false, function()
		{
			DiscordPresence.shutdown();
			lime.system.System.exit(0);
		});
	}
}
