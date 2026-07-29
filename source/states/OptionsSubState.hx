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
	static inline var ROWS:Int = 15;

	static var FPS_STEPS:Array<Int> = [60, 120, 144, 165, 240];
	static var ASPECTS:Array<String> = ["auto", "4:3", "16:9", "16:10", "21:9"];
	static var DISPLAYS:Array<String> = ["windowed", "borderless", "fullscreen"];

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
		shade.makeGraphic(FlxG.width, FlxG.height, 0xF6000000);
		add(shade);

		title = new FlxText(0, 40, FlxG.width, Lang.t("options.title"));
		title.setFormat(Lang.font(), 44, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		add(title);

		list = new MenuList([for (i in 0...ROWS) ""], 106, 38, 22);
		list.onChoose = choose;
		list.onAdjust = adjust;
		list.marker.scale.set(1.6, 1.6);
		list.marker.updateHitbox();
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

		if (util.Controls.menuBack())
			close();
	}

	function refreshLabels():Void
	{
		shownVolume = SaveData.volume();
		list.setLabel(0, Lang.t("options.volume", [Math.round(shownVolume * 100)]));
		list.setLabel(1, Lang.t("options.display", [Lang.t("display." + SaveData.displayMode())]));
		list.setLabel(2, Lang.t("options.vsync", [onOff(SaveData.vsync())]));
		list.setLabel(3, Lang.t("options.framerate", [fpsLabel()]));
		list.setLabel(4, Lang.t("options.aspect", [aspectLabel()]));
		list.setLabel(5, Lang.t("options.camera", [Math.round(SaveData.cameraLean() * 100)]));
		list.setLabel(6, Lang.t("options.shake", [Math.round(SaveData.shakeAmount() * 100)]));
		list.setLabel(7, Lang.t("options.freeze", [Math.round(SaveData.freezeAmount() * 100)]));
		list.setLabel(8, Lang.t("options.hud", [onOff(SaveData.showHud())]));
		list.setLabel(9, Lang.t("options.sound3d", [onOff(SaveData.sound3d())]));
		list.setLabel(10, Lang.t("options.fps", [onOff(SaveData.showFps())]));
		list.setLabel(11, Lang.t("options.language", [Lang.t("lang.name")]));
		list.setLabel(12, Lang.t("options.controls"));
		list.setLabel(13, Lang.t(resetArmed ? "options.resetBestConfirm" : "options.resetBest"));
		list.setLabel(14, Lang.t("common.back"));
	}

	function onOff(b:Bool):String
		return Lang.t(b ? "common.on" : "common.off");

	function fpsLabel():String
	{
		if (SaveData.vsync())
			return Std.string(SaveData.displayHz());
		return Std.string(SaveData.framerate());
	}

	function aspectLabel():String
	{
		var a = SaveData.aspect();
		return a == "auto" ? Lang.t("aspect.auto") : a;
	}

	static function cycled<T>(steps:Array<T>, current:T, dir:Int):T
	{
		var i = steps.indexOf(current);
		if (i < 0)
			i = 0;
		return steps[(i + dir + steps.length) % steps.length];
	}

	function switchLanguage(dir:Int = 1):Void
	{
		Lang.cycle(dir);
		title.text = Lang.t("options.title");
		title.font = Lang.font();
		for (i in 0...ROWS)
			list.rowAt(i).font = Lang.font();
		refreshLabels();
	}

	function choose(i:Int):Void
	{
		switch (i)
		{
			case 11:
				switchLanguage();
				return;
			case 12:
				openSubState(new ControlsSubState(cam));
			case 13:
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
				refreshLabels();
			case 14:
				close();
			default:
				adjust(i, 1);
		}
	}

	function adjust(i:Int, dir:Int):Void
	{
		switch (i)
		{
			case 0:
				SaveData.setVolume(SaveData.volume() + dir * 0.1);
			case 1:
				SaveData.setDisplayMode(cycled(DISPLAYS, SaveData.displayMode(), dir));
			case 2:
				SaveData.setVsync(!SaveData.vsync());
			case 3:
				SaveData.setFramerate(cycled(FPS_STEPS, SaveData.framerate(), dir));
			case 4:
				SaveData.setAspect(cycled(ASPECTS, SaveData.aspect(), dir));
			case 5:
				SaveData.setCameraLean(SaveData.cameraLean() + dir * 0.1);
			case 6:
				SaveData.setShakeAmount(SaveData.shakeAmount() + dir * 0.1);
			case 7:
				SaveData.setFreezeAmount(SaveData.freezeAmount() + dir * 0.1);
			case 8:
				SaveData.setShowHud(!SaveData.showHud());
			case 9:
				SaveData.setSound3d(!SaveData.sound3d());
			case 10:
				SaveData.setShowFps(!SaveData.showFps());
			case 11:
				switchLanguage(dir);
				return;
			default:
				return;
		}
		SaveData.applySettings();
		refreshLabels();
	}
}
