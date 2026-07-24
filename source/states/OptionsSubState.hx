package states;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import systems.MenuList;
import util.SaveData;

class OptionsSubState extends FlxSubState
{
	static inline var RESET_WINDOW:Float = 3.0;

	private var cam:FlxCamera;
	private var list:MenuList;
	private var resetArmed:Bool = false;
	private var resetTimer:Float = 0;
	private var shownVolume:Float = -1;

	public function new(?cam:FlxCamera)
	{
		super();
		this.cam = cam;
	}

	override public function create():Void
	{
		var shade = new FlxSprite();
		shade.makeGraphic(FlxG.width, FlxG.height, 0xC8000000);
		add(shade);

		var title = new FlxText(0, 120, FlxG.width, "OPTIONS");
		title.setFormat(null, 56, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		add(title);

		list = new MenuList(["", "", "", "", "BACK"], 280, 66, 32);
		list.onChoose = choose;
		list.onAdjust = adjust;
		add(list);

		if (cam != null)
		{
			shade.cameras = [cam];
			title.cameras = [cam];
			list.cameras = [cam];
		}

		refreshLabels();

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (resetArmed)
		{
			resetTimer -= elapsed;
			if (resetTimer <= 0)
			{
				resetArmed = false;
				refreshLabels();
			}
		}

		if (SaveData.volume() != shownVolume)
			refreshLabels();

		if (FlxG.keys.justPressed.ESCAPE)
			close();
	}

	function refreshLabels():Void
	{
		shownVolume = SaveData.volume();
		list.setLabel(0, "VOLUME  < " + Math.round(shownVolume * 100) + "% >");
		list.setLabel(1, "FULLSCREEN  " + (SaveData.fullscreen() ? "ON" : "OFF"));
		list.setLabel(2, "FPS COUNTER  " + (SaveData.showFps() ? "ON" : "OFF"));
		list.setLabel(3, resetArmed ? "RESET BEST WAVE?  PRESS AGAIN" : "RESET BEST WAVE");
	}

	function choose(i:Int):Void
	{
		switch (i)
		{
			case 0:
				var v = SaveData.volume() + 0.1;
				if (v > 1.001)
					v = 0;
				SaveData.setVolume(v);
				SaveData.applySettings();
			case 1:
				SaveData.setFullscreen(!SaveData.fullscreen());
				SaveData.applySettings();
			case 2:
				SaveData.setShowFps(!SaveData.showFps());
				SaveData.applySettings();
			case 3:
				if (resetArmed)
				{
					SaveData.resetBest();
					resetArmed = false;
				}
				else
				{
					resetArmed = true;
					resetTimer = RESET_WINDOW;
				}
			default:
				close();
		}
		refreshLabels();
	}

	function adjust(i:Int, dir:Int):Void
	{
		switch (i)
		{
			case 0:
				SaveData.setVolume(SaveData.volume() + dir * 0.1);
				SaveData.applySettings();
			case 1:
				SaveData.setFullscreen(!SaveData.fullscreen());
				SaveData.applySettings();
			case 2:
				SaveData.setShowFps(!SaveData.showFps());
				SaveData.applySettings();
		}
		refreshLabels();
	}
}
