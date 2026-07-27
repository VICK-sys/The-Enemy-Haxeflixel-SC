package states;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.MenuList;
import util.SaveData;
import util.Lang;

class OptionsSubState extends FlxSubState
{
	static inline var RESET_WINDOW:Float = 3.0;

	private var cam:FlxCamera;
	private var list:MenuList;
	private var title:FlxText;
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

		title = new FlxText(0, 120, FlxG.width, Lang.t("options.title"));
		title.setFormat(Lang.font(), 56, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		add(title);

		list = new MenuList(["", "", "", "", "", ""], 260, 60, 30);
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
		list.setLabel(0, Lang.t("options.volume", [Math.round(shownVolume * 100)]));
		list.setLabel(1, Lang.t("options.fullscreen", [onOff(SaveData.fullscreen())]));
		list.setLabel(2, Lang.t("options.fps", [onOff(SaveData.showFps())]));
		list.setLabel(3, Lang.t("options.language", [Lang.t("lang.name")]));
		list.setLabel(4, Lang.t(resetArmed ? "options.resetBestConfirm" : "options.resetBest"));
		list.setLabel(5, Lang.t("common.back"));
	}

	function onOff(b:Bool):String
		return Lang.t(b ? "common.on" : "common.off");

	function switchLanguage(dir:Int = 1):Void
	{
		Lang.cycle(dir);
		title.text = Lang.t("options.title");
		title.font = Lang.font();
		for (i in 0...6)
			list.rowAt(i).font = Lang.font();
		refreshLabels();
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
				switchLanguage();
				return;
			case 4:
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
			case 3:
				switchLanguage(dir);
				return;
		}
		refreshLabels();
	}
}
