package states;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.MenuList;
import util.Controls;
import util.Lang;

class ControlsSubState extends FlxSubState
{
	static inline var ROWS:Int = 14;
	static inline var ARM_TIME:Float = 0.15;

	static var ACTION_KEYS:Array<String> = [
		"up", "down", "left", "right", "dash", "attack", "second", "super", "reload", "accept", "pause"
	];
	static var ACTIONS:Array<Int> = [
		Controls.UP, Controls.DOWN, Controls.LEFT, Controls.RIGHT, Controls.DASH, Controls.ATTACK, Controls.SECOND,
		Controls.SUPER, Controls.RELOAD, Controls.ACCEPT, Controls.PAUSE
	];

	private var cam:FlxCamera;
	private var list:MenuList;
	private var title:FlxText;
	private var note:FlxText;
	private var prompt:FlxText;
	private var device:Int = 0;
	private var capturing:Int = -1;
	private var arm:Float = 0;

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

		title = new FlxText(0, 34, FlxG.width, Lang.t("controls.title"));
		title.setFormat(Lang.font(), 40, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		add(title);

		list = new MenuList([for (i in 0...ROWS) ""], 104, 38, 22);
		list.onChoose = choose;
		list.onAdjust = adjust;
		list.marker.scale.set(1.6, 1.6);
		list.marker.updateHitbox();
		add(list);

		prompt = new FlxText(0, 654, FlxG.width, "");
		prompt.setFormat(Lang.font(), 18, FlxColor.YELLOW, CENTER);
		prompt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(prompt);

		note = new FlxText(0, 684, FlxG.width, "");
		note.setFormat(Lang.font(), 14, FlxColor.WHITE, CENTER);
		note.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		note.alpha = 0.7;
		add(note);

		if (cam != null)
		{
			shade.cameras = [cam];
			title.cameras = [cam];
			list.cameras = [cam];
			prompt.cameras = [cam];
			note.cameras = [cam];
		}

		refreshLabels();
		super.create();
	}

	function deviceName():String
		return Lang.t(device == 0 ? "controls.keyboard" : "controls.gamepad");

	function bindLabel(i:Int):String
	{
		var action = ACTIONS[i];
		if (device == 0)
			return Controls.keyName(Controls.keyOf(action));
		return Controls.padName(Controls.padOf(action));
	}

	function refreshLabels():Void
	{
		list.setLabel(0, Lang.t("controls.device", [deviceName()]));
		for (i in 0...ACTIONS.length)
			list.setLabel(1 + i, Lang.t("controls." + ACTION_KEYS[i]) + "   -   " + bindLabel(i));
		list.setLabel(12, Lang.t("controls.reset"));
		list.setLabel(13, Lang.t("common.back"));
		note.text = Lang.t(device == 0 ? "controls.mouseNote" : "controls.stickNote");
	}

	function choose(i:Int):Void
	{
		if (capturing >= 0)
			return;
		if (i == 0)
		{
			adjust(0, 1);
			return;
		}
		if (i == 12)
		{
			Controls.resetBinds();
			refreshLabels();
			return;
		}
		if (i == 13)
		{
			close();
			return;
		}
		capturing = i - 1;
		arm = ARM_TIME;
		list.enabled = false;
		prompt.text = Lang.t(device == 0 ? "controls.pressKey" : "controls.pressPad");
	}

	function adjust(i:Int, dir:Int):Void
	{
		if (capturing >= 0 || i != 0)
			return;
		device = device == 0 ? 1 : 0;
		refreshLabels();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (capturing < 0)
		{
			if (Controls.menuBack())
			{
				util.MenuSfx.cancel();
				close();
			}
			return;
		}

		if (arm > 0)
		{
			arm -= elapsed;
			return;
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			util.MenuSfx.cancel();
			endCapture();
			return;
		}

		if (device == 0)
		{
			var k = Controls.capturedKey();
			if (k != FlxKey.NONE)
			{
				Controls.bindKey(ACTIONS[capturing], k);
				endCapture();
			}
		}
		else
		{
			var id = Controls.capturedPad();
			if (id >= 0)
			{
				Controls.bindPad(ACTIONS[capturing], id);
				endCapture();
			}
		}
	}

	function endCapture():Void
	{
		capturing = -1;
		prompt.text = "";
		list.enabled = true;
		refreshLabels();
	}
}
