package states;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.MenuList;
import util.SaveData;
import util.Lang;

class OptionsSubState extends FlxSubState
{
	static inline var RESET_WINDOW:Float = 3.0;
	static inline var HUE_STEP:Float = 1 / 360.0;
	static inline var VOICE_STEP:Float = 0.05;
	static inline var TOP:Float = 150;
	static inline var STEP:Float = 34;
	static inline var TAB_GAP:Float = 22;
	static inline var TAIL_GAP:Float = 18;
	static inline var ROW_SIZE:Int = 22;
	static inline var TAB_SIZE:Int = 20;
	static inline var TAB_COLOR:Int = 0xFFE8C860;
	static inline var DIM:Int = 0xFF9A9A9A;
	static inline var PREVIEW_SCALE:Float = 6;
	static inline var PREVIEW_IN:Float = 260;
	static inline var PREVIEW_Y:Float = 330;
	static inline var WEAPON_SCALE:Float = 4;
	static inline var WEAPON_TILT:Float = -35;
	static inline var HAND_X:Float = 0.19;
	static inline var HAND_Y:Float = 0.64;
	static inline var SKIN_GAP:Float = 0.05;
	static inline var SETTLE_GAP:Float = 0.3;

	static var HELD_ART:Array<String> = ["items/hammer", "items/revolver", "items/crossbow", "items/yoyo"];

	static inline var VOLUME:Int = 0;
	static inline var DISPLAY:Int = 1;
	static inline var VSYNC:Int = 2;
	static inline var FRAMERATE:Int = 3;
	static inline var ASPECT:Int = 4;
	static inline var CAMERA:Int = 5;
	static inline var SHAKE:Int = 6;
	static inline var FREEZE:Int = 7;
	static inline var COLOR:Int = 8;
	static inline var HUD:Int = 9;
	static inline var SOUND3D:Int = 10;
	static inline var FPS:Int = 11;
	static inline var LANGUAGE:Int = 12;
	static inline var CONTROLS:Int = 13;
	static inline var RESET:Int = 14;
	static inline var VOICE:Int = 15;
	static inline var RESOLUTION:Int = 16;

	static inline var TAB:Int = -1;
	static inline var BACK:Int = -2;
	static inline var BLANK:Int = -3;

	static var PAGES:Array<{key:String, items:Array<Int>}> = [
		{key: "options.page.graphics", items: [DISPLAY, RESOLUTION, ASPECT, VSYNC, FRAMERATE]},
		{key: "options.page.visual", items: [CAMERA, SHAKE, FREEZE, HUD, FPS]},
		{key: "options.page.sounds", items: [VOLUME, SOUND3D]},
		{key: "options.page.custom", items: [COLOR, VOICE, LANGUAGE, CONTROLS, RESET]}
	];

	static var FPS_STEPS:Array<Int> = [60, 120, 144, 165, 240];
	static var ASPECTS:Array<String> = ["auto", "4:3", "16:9", "16:10", "21:9"];
	static var DISPLAYS:Array<String> = ["windowed", "borderless", "fullscreen"];

	private var cam:FlxCamera;
	private var list:MenuList;
	private var title:FlxText;
	private var resetArmed:Bool = false;
	private var resetTimer:Float = 0;
	private var shownVolume:Float = -1;
	private var page:Int = 0;
	private var ids:Array<Int> = [];
	private var rows:Int = 0;
	private var preview:FlxSprite;
	private var previewWeapon:FlxSprite;
	private var hueDirty:Bool = false;
	private var huePending:Bool = false;
	private var skinClock:Float = 0;
	private var settleClock:Float = 0;
	private var sample:FlxSound;

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

		var widest = 0;
		for (p in PAGES)
			if (p.items.length > widest)
				widest = p.items.length;
		rows = widest + 2;

		list = new MenuList([for (i in 0...rows) ""], TOP, STEP, ROW_SIZE);
		list.onChoose = choose;
		list.onAdjust = adjust;
		list.repeatFor = canRepeat;
		list.marker.scale.set(1.6, 1.6);
		list.marker.updateHitbox();
		list.rowAt(0).size = TAB_SIZE;
		add(list);

		preview = new FlxSprite();
		preview.antialiasing = false;
		preview.visible = false;
		add(preview);

		previewWeapon = new FlxSprite();
		previewWeapon.antialiasing = false;
		previewWeapon.visible = false;
		add(previewWeapon);

		if (cam != null)
		{
			shade.cameras = [cam];
			title.cameras = [cam];
			list.cameras = [cam];
			preview.cameras = [cam];
			previewWeapon.cameras = [cam];
		}

		buildPreview();
		refreshWeapon();
		buildPage();

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

		updateSkin(elapsed);
		showPreview(ids[list.index] == COLOR);

		if (util.Controls.menuBack())
		{
			util.MenuSfx.cancel();
			close();
		}
	}

	function buildPage():Void
	{
		var items = PAGES[page].items;

		ids = [TAB];
		for (item in items)
			ids.push(item);
		while (ids.length < rows - 1)
			ids.push(BLANK);
		ids.push(BACK);

		var y = TOP;
		for (i in 0...rows)
		{
			var row = list.rowAt(i);
			var kind = ids[i];
			row.visible = kind != BLANK;
			list.setSkip(i, kind == BLANK);

			if (kind == BLANK)
				continue;

			if (i == 1)
				y += TAB_GAP;
			if (kind == BACK)
				y += TAIL_GAP;
			list.place(i, y);
			y += STEP;
		}

		refreshLabels();
		list.settle();
	}

	function showPreview(on:Bool):Void
	{
		if (preview.visible == on)
			return;
		preview.visible = on;
		previewWeapon.visible = on;
	}

	function updateSkin(elapsed:Float):Void
	{
		if (skinClock > 0)
			skinClock -= elapsed;

		if (hueDirty && skinClock <= 0)
		{
			hueDirty = false;
			skinClock = SKIN_GAP;
			util.HuePalette.live("characters/mufu", SaveData.playerHue());
			refreshWeapon();
		}

		if (huePending)
		{
			settleClock -= elapsed;
			if (settleClock <= 0)
			{
				huePending = false;
				SaveData.commit();
			}
		}
	}

	function buildPreview():Void
	{
		preview.frames = util.HuePalette.liveFrames("characters/mufu", SaveData.playerHue());
		preview.animation.addByPrefix("idle", "Idle", 9, true);
		preview.animation.play("idle");
		preview.scale.set(PREVIEW_SCALE, PREVIEW_SCALE);
		preview.updateHitbox();
		preview.setPosition(FlxG.width - PREVIEW_IN - preview.width * 0.5, PREVIEW_Y - preview.height * 0.5);
	}

	function refreshWeapon():Void
	{
		var pick = WeaponPickSubState.lastPick;
		if (pick < 0 || pick >= HELD_ART.length)
			pick = 0;
		previewWeapon.loadGraphic(util.HuePalette.graphic(HELD_ART[pick], SaveData.playerHue()));
		previewWeapon.antialiasing = false;
		previewWeapon.scale.set(WEAPON_SCALE, WEAPON_SCALE);
		previewWeapon.updateHitbox();
		previewWeapon.angle = WEAPON_TILT;
		if (preview.width > 0)
		{
			previewWeapon.x = preview.x + preview.width * HAND_X - previewWeapon.width * 0.5;
			previewWeapon.y = preview.y + preview.height * HAND_Y - previewWeapon.height * 0.5;
		}
	}

	static function swatch(h:Float):Int
		return FlxColor.fromHSB(((0.98 + h) % 1.0) * 360, 0.72, 1);

	function turnPage(dir:Int):Void
	{
		page = (page + dir + PAGES.length) % PAGES.length;
		buildPage();
	}

	function refreshLabels():Void
	{
		shownVolume = SaveData.volume();
		for (i in 0...rows)
			refreshRow(i);
	}

	function refreshRow(i:Int):Void
	{
		var id = ids[i];
		if (id == VOLUME)
			shownVolume = SaveData.volume();
		list.setLabel(i, labelFor(id));
		list.rowAt(i).color = switch (id)
		{
			case TAB: TAB_COLOR;
			case COLOR: swatch(SaveData.playerHue());
			case RESOLUTION: windowed() ? FlxColor.WHITE : DIM;
			default: FlxColor.WHITE;
		}
	}

	function canRepeat(row:Int):Bool
	{
		return switch (ids[row])
		{
			case COLOR, VOLUME, CAMERA, SHAKE, FREEZE, VOICE: true;
			default: false;
		}
	}

	function labelFor(id:Int):String
	{
		return switch (id)
		{
			case TAB: Lang.t("options.page", [Lang.t(PAGES[page].key), page + 1, PAGES.length]);
			case BACK: Lang.t("common.back");
			case VOLUME: Lang.t("options.volume", [Math.round(shownVolume * 100)]);
			case DISPLAY: Lang.t("options.display", [Lang.t("display." + SaveData.displayMode())]);
			case RESOLUTION: Lang.t("options.resolution", [SaveData.windowFill()]);
			case VSYNC: Lang.t("options.vsync", [onOff(SaveData.vsync())]);
			case FRAMERATE: Lang.t("options.framerate", [fpsLabel()]);
			case ASPECT: Lang.t("options.aspect", [aspectLabel()]);
			case CAMERA: Lang.t("options.camera", [Math.round(SaveData.cameraLean() * 100)]);
			case SHAKE: Lang.t("options.shake", [Math.round(SaveData.shakeAmount() * 100)]);
			case FREEZE: Lang.t("options.freeze", [Math.round(SaveData.freezeAmount() * 100)]);
			case COLOR: Lang.t("options.color", [Math.round(SaveData.playerHue() * 360)]);
			case VOICE: Lang.t("options.voice", [pitchLabel()]);
			case HUD: Lang.t("options.hud", [onOff(SaveData.showHud())]);
			case SOUND3D: Lang.t("options.sound3d", [onOff(SaveData.sound3d())]);
			case FPS: Lang.t("options.fps", [onOff(SaveData.showFps())]);
			case LANGUAGE: Lang.t("options.language", [Lang.t("lang.name")]);
			case CONTROLS: Lang.t("options.controls");
			case RESET: Lang.t(resetArmed ? "options.resetBestConfirm" : "options.resetBest");
			default: "";
		}
	}

	function hearVoice():Void
	{
		if (sample != null && sample.playing)
			sample.stop();
		var line = "voice/hurt" + (1 + Std.random(systems.PlayerCombat.HURT_LINES));
		sample = FlxG.sound.play(util.Paths.sound(line), systems.PlayerCombat.VOICE);
		if (sample != null)
			sample.pitch = SaveData.voicePitch();
	}

	function onOff(b:Bool):String
		return Lang.t(b ? "common.on" : "common.off");

	function pitchLabel():String
	{
		var v = Math.round(SaveData.voicePitch() * 100);
		var frac = v % 100;
		return Std.int(v / 100) + "." + (frac < 10 ? "0" + frac : "" + frac);
	}

	static function windowed():Bool
		return SaveData.displayMode() == "windowed";

	function stepResolution(dir:Int):Void
		SaveData.setWindowFill(cycled(SaveData.WINDOW_STEPS, SaveData.windowFill(), dir));

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
		for (i in 0...rows)
			list.rowAt(i).font = Lang.font();
		refreshLabels();
	}

	function choose(row:Int):Void
	{
		switch (ids[row])
		{
			case LANGUAGE:
				switchLanguage();
				return;
			case VOICE:
				hearVoice();
			case CONTROLS:
				openSubState(new ControlsSubState(cam));
			case RESET:
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
			case BACK:
				close();
			default:
				adjust(row, 1);
		}
	}

	function adjust(row:Int, dir:Int):Void
	{
		switch (ids[row])
		{
			case TAB:
				turnPage(dir);
				return;
			case VOLUME:
				SaveData.setVolume(SaveData.volume() + dir * 0.1);
			case DISPLAY:
				SaveData.setDisplayMode(cycled(DISPLAYS, SaveData.displayMode(), dir));
			case RESOLUTION:
				if (!windowed())
					return;
				stepResolution(dir);
			case VSYNC:
				SaveData.setVsync(!SaveData.vsync());
			case FRAMERATE:
				SaveData.setFramerate(cycled(FPS_STEPS, SaveData.framerate(), dir));
			case ASPECT:
				SaveData.setAspect(cycled(ASPECTS, SaveData.aspect(), dir));
			case CAMERA:
				SaveData.setCameraLean(SaveData.cameraLean() + dir * 0.1);
			case SHAKE:
				SaveData.setShakeAmount(SaveData.shakeAmount() + dir * 0.1);
			case FREEZE:
				SaveData.setFreezeAmount(SaveData.freezeAmount() + dir * 0.1);
			case COLOR:
				SaveData.setPlayerHue(SaveData.playerHue() + dir * HUE_STEP, false);
				hueDirty = true;
				huePending = true;
				settleClock = SETTLE_GAP;
			case VOICE:
				SaveData.setVoicePitch(SaveData.voicePitch() + dir * VOICE_STEP);
			case HUD:
				SaveData.setShowHud(!SaveData.showHud());
			case SOUND3D:
				SaveData.setSound3d(!SaveData.sound3d());
			case FPS:
				SaveData.setShowFps(!SaveData.showFps());
			case LANGUAGE:
				switchLanguage(dir);
				return;
			default:
				return;
		}
		SaveData.applySettings();
		if (ids[row] == VSYNC || ids[row] == DISPLAY)
			refreshLabels();
		else
			refreshRow(row);
	}
}
