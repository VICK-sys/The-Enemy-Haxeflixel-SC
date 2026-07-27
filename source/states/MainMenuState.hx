package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.MenuList;
import util.DiscordPresence;
import util.IrisWipe;
import util.JaggedBand;
import util.MenuSlash;
import util.Music;
import util.SaveData;
import util.Lang;

class MainMenuState extends FlxState
{
	static inline var ACCENT:Int = 0xFFE0132D;
	static inline var SPLASH_ANGLE:Float = -18;
	static inline var SPLASH_THROB:Float = 0.09;
	static inline var SPLASH_SPEED:Float = 3.4;

	static inline var SHUT_FLATTEN:Float = 0.3;
	static inline var SHUT_PINCH:Float = 0.17;
	static inline var SHUT_FADE:Float = 0.08;
	static inline var SHUT_MIN:Int = 24;

	private var list:MenuList;
	private var best:FlxText;
	private var wipe:IrisWipe;
	private var splash:FlxText;
	private var splashTime:Float = 0;
	private var leaving:Bool = false;
	private var busy:Bool = false;
	private var shutX:Int = 0;
	private var shutY:Int = 0;
	private var shutW:Int = 0;
	private var shutH:Int = 0;
	private var maps:Array<Int> = [0];
	private var mapPick:Int = 0;
	private var shutCurW:Int = 0;
	private var shutCurH:Int = 0;
	private var actions:Array<String> = [];

	override public function create()
	{
		persistentUpdate = true;
		FlxG.camera.bgColor = 0xFF000000;
		FlxG.mouse.visible = true;
		DiscordPresence.menu();
		util.CustomArena.clear();
		util.Detour.reset();

		addBands();

		var title = new FlxText(0, 110, FlxG.width, "THE ENEMY");
		title.setFormat(null, 96, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, ACCENT, 4);
		add(title);

		addSplash(title);

		findMaps();

		var labels = [playLabel()];
		actions = ["play"];
		#if desktop
		labels.push(Lang.t("menu.online"));
		actions.push("online");
		#end
		labels.push(Lang.t("menu.options"));
		actions.push("options");
		#if !html5
		labels.push(Lang.t("menu.quit"));
		actions.push("quit");
		#end
		list = new MenuList(labels, 360, 72, 44);
		list.onChoose = choose;
		list.onAdjust = adjustMap;
		add(list);

		best = new FlxText(16, FlxG.height - 30, 0, "");
		best.setFormat(Lang.font(), 16, FlxColor.WHITE, LEFT);
		best.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(best);
		refreshBest();

		subStateClosed.add(function(_)
		{
			if (Lang.consumeChanged())
			{
				FlxG.switchState(new MainMenuState());
				return;
			}
			busy = false;
			list.enabled = true;
			list.restoreRows();
			refreshBest();
		});

		Music.play("stage/gloomDoomWoods", 0.3);

		wipe = new IrisWipe(this);
		wipe.open();

		super.create();
	}

	function addBands():Void
	{
		add(new JaggedBand(true, 40, 84, 26, 0xFF4A0A14, 16));
		add(new JaggedBand(false, 40, 84, 26, 0xFF4A0A14, -16));
		add(new JaggedBand(true, 40, 84, 30, ACCENT, 30));
		add(new JaggedBand(false, 40, 84, 30, ACCENT, -30));
	}

	function addSplash(title:FlxText):Void
	{
		var probe = new FlxText(0, 0, 0, title.text);
		probe.setFormat(null, 96, FlxColor.WHITE, LEFT);
		var titleRight = FlxG.width * 0.5 + probe.width * 0.5;
		var titleBottom = title.y + probe.height;
		probe.destroy();

		splash = new FlxText(0, 0, 0, Lang.t("menu.splash"));
		splash.setFormat(Lang.font(), 26, FlxColor.YELLOW, LEFT);
		splash.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		splash.updateHitbox();
		splash.angle = SPLASH_ANGLE;
		splash.x = titleRight - splash.width * 0.5 - 24;
		splash.y = titleBottom - splash.height * 0.5 - 26;
		add(splash);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (leaving)
			return;

		if (FlxG.keys.justPressed.F7 && !busy && subState == null)
		{
			leaving = true;
			list.enabled = false;
			wipe.close(function() FlxG.switchState(new EditorState()));
			return;
		}

		splashTime += elapsed;
		var s = 1 - SPLASH_THROB * Math.abs(Math.sin(splashTime * SPLASH_SPEED));
		splash.scale.set(s, s);

	}

	function refreshBest():Void
	{
		var n = SaveData.bestWave();
		best.text = n > 0 ? Lang.t("menu.best", [n]) : "";
	}

	function choose(i:Int):Void
	{
		if (leaving || busy)
			return;

		busy = true;
		list.enabled = false;
		MenuSlash.play(this, list.rowAt(i), list.marker, function() commit(i));
	}

	function commit(i:Int):Void
	{
		switch (actions[i])
		{
			case "play":
				startGame();
			case "online":
				leaving = true;
				wipe.close(function() FlxG.switchState(new OnlineState()));
			case "options":
				FlxG.inputs.reset();
				openSubState(new OptionsSubState());
			default:
				quit();
		}
	}


	function findMaps():Void
	{
		maps = [0];
		for (s in 1...util.MapStore.SLOTS + 1)
			if (util.MapStore.load(s) != null)
				maps.push(s);

		mapPick = 0;
	}

	function playLabel():String
		return maps[mapPick] == 0 ? Lang.t("menu.play") : Lang.t("menu.playSlot", [maps[mapPick]]);

	function adjustMap(i:Int, dir:Int):Void
	{
		if (i != 0 || maps.length <= 1)
			return;
		mapPick = (mapPick + dir + maps.length) % maps.length;
		list.setLabel(0, playLabel());
	}

	function loadPick():Void
	{
		util.CustomArena.clear();
		if (maps[mapPick] == 0)
			return;

		var m = util.MapStore.load(maps[mapPick]);
		if (m != null)
			util.CustomArena.fromStored(m, maps[mapPick]);
	}

	function startGame():Void
	{
		leaving = true;
		list.enabled = false;
		loadPick();
		wipe.close(function()
		{
			FlxG.mouse.visible = false;
			FlxG.switchState(new PlayState());
		});
	}

	function quit():Void
	{
		leaving = true;
		list.enabled = false;

		#if desktop
		var win = lime.app.Application.current.window;
		win.borderless = true;
		shutX = win.x;
		shutY = win.y;
		shutW = shutCurW = win.width;
		shutH = shutCurH = win.height;

		FlxG.camera.fade(FlxColor.BLACK, SHUT_FLATTEN + SHUT_PINCH, false);
		FlxTween.num(shutH, SHUT_MIN, SHUT_FLATTEN, {ease: FlxEase.quadIn, onComplete: pinchWindow}, setShutHeight);
		#else
		FlxG.camera.fade(FlxColor.BLACK, 0.25, false, function()
		{
			DiscordPresence.shutdown();
			lime.system.System.exit(0);
		});
		#end
	}

	#if desktop
	function setShutHeight(v:Float):Void
	{
		shutCurH = Std.int(v);
		applyShutSize();
	}

	function setShutWidth(v:Float):Void
	{
		shutCurW = Std.int(v);
		applyShutSize();
	}

	function applyShutSize():Void
	{
		var win = lime.app.Application.current.window;
		win.resize(shutCurW, shutCurH);
		win.move(shutX + Std.int((shutW - shutCurW) / 2), shutY + Std.int((shutH - shutCurH) / 2));
	}

	function pinchWindow(_:FlxTween):Void
	{
		FlxTween.num(shutW, SHUT_MIN, SHUT_PINCH, {ease: FlxEase.quadIn, onComplete: fadeWindow}, setShutWidth);
	}

	function fadeWindow(_:FlxTween):Void
	{
		FlxTween.num(1, 0, SHUT_FADE, {onComplete: function(_)
		{
			DiscordPresence.shutdown();
			lime.system.System.exit(0);
		}}, function(v) lime.app.Application.current.window.opacity = v);
	}
	#end
}
