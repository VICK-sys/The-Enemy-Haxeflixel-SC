package states;

import flixel.FlxG;
import flixel.FlxSprite;
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
	static inline var SPLASH_COUNT:Int = 9;
	static inline var SPLASH_SIZE:Int = 30;
	static inline var SPLASH_SIZE_MIN:Int = 14;
	static inline var SPLASH_MAX_W:Float = 360;

	static inline var TITLE_SCALE:Float = 0.5;
	static inline var TITLE_Y:Float = 72;
	static inline var SHADOW_OFF_X:Float = 14;
	static inline var SHADOW_OFF_Y:Float = 16;
	static inline var SHADOW_TINT:Int = 0x4A0A14;
	static inline var BOB_AMP:Float = 10;
	static inline var BOB_SPEED:Float = 1.9;

	static inline var SHUT_FLATTEN:Float = 0.3;
	static inline var SHUT_PINCH:Float = 0.17;
	static inline var SHUT_FADE:Float = 0.08;
	static inline var SHUT_MIN:Int = 24;

	private var list:MenuList;
	private var best:FlxText;
	private var wipe:IrisWipe;
	private var splash:FlxText;
	private var splashTime:Float = 0;
	private var titleArt:FlxSprite;
	private var titleShade:FlxSprite;
	private var titleBaseY:Float = 0;
	private var bobTime:Float = 0;
	private var leaving:Bool = false;
	private var typed:String = "";
	private var scare:FlxSprite;
	private var scareTimer:Float = 0;
	private var scareSound:flixel.sound.FlxSound;
	private var busy:Bool = false;
	private var shutX:Int = 0;
	private var shutY:Int = 0;
	private var shutW:Int = 0;
	private var shutH:Int = 0;
	private var maps:Array<Int>;
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

		addTitle();

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
				FlxG.switchState(() -> new MainMenuState());
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

	function addTitle():Void
	{
		titleShade = makeTitleArt();
		titleShade.setColorTransform(0, 0, 0, 1, (SHADOW_TINT >> 16) & 0xFF, (SHADOW_TINT >> 8) & 0xFF, SHADOW_TINT & 0xFF, 0);
		add(titleShade);

		titleArt = makeTitleArt();
		add(titleArt);

		titleBaseY = titleArt.y;
		titleShade.setPosition(titleArt.x + SHADOW_OFF_X, titleBaseY + SHADOW_OFF_Y);

		addSplash(titleArt.x + titleArt.width, titleBaseY + titleArt.height);
	}

	function makeTitleArt():FlxSprite
	{
		var s = new FlxSprite();
		s.loadGraphic(util.Paths.image("ui/title"));
		s.antialiasing = false;
		s.scale.set(TITLE_SCALE, TITLE_SCALE);
		s.updateHitbox();
		s.setPosition((FlxG.width - s.width) * 0.5, TITLE_Y);
		return s;
	}

	function addSplash(titleRight:Float, titleBottom:Float):Void
	{
		splash = new FlxText(0, 0, 0, Lang.t("menu.splash." + FlxG.random.int(0, SPLASH_COUNT - 1)));
		splash.setFormat(Lang.font(), SPLASH_SIZE, FlxColor.YELLOW, LEFT);
		splash.updateHitbox();

		if (splash.width > SPLASH_MAX_W)
		{
			var fit = Std.int(SPLASH_SIZE * SPLASH_MAX_W / splash.width);
			splash.setFormat(Lang.font(), fit < SPLASH_SIZE_MIN ? SPLASH_SIZE_MIN : fit, FlxColor.YELLOW, LEFT);
		}

		splash.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		splash.updateHitbox();
		splash.angle = SPLASH_ANGLE;
		splash.x = titleRight - splash.width * 0.5 - 24;
		splash.y = titleBottom - splash.height * 0.5 - 26;
		add(splash);
	}

	static inline var CODE:String = "1987";
	static inline var SCARE_QUIT:Float = 2;

	function readCode():Void
	{
		var hit = -1;
		if (FlxG.keys.justPressed.ZERO || FlxG.keys.justPressed.NUMPADZERO)
			hit = 0;
		else if (FlxG.keys.justPressed.ONE || FlxG.keys.justPressed.NUMPADONE)
			hit = 1;
		else if (FlxG.keys.justPressed.TWO || FlxG.keys.justPressed.NUMPADTWO)
			hit = 2;
		else if (FlxG.keys.justPressed.THREE || FlxG.keys.justPressed.NUMPADTHREE)
			hit = 3;
		else if (FlxG.keys.justPressed.FOUR || FlxG.keys.justPressed.NUMPADFOUR)
			hit = 4;
		else if (FlxG.keys.justPressed.FIVE || FlxG.keys.justPressed.NUMPADFIVE)
			hit = 5;
		else if (FlxG.keys.justPressed.SIX || FlxG.keys.justPressed.NUMPADSIX)
			hit = 6;
		else if (FlxG.keys.justPressed.SEVEN || FlxG.keys.justPressed.NUMPADSEVEN)
			hit = 7;
		else if (FlxG.keys.justPressed.EIGHT || FlxG.keys.justPressed.NUMPADEIGHT)
			hit = 8;
		else if (FlxG.keys.justPressed.NINE || FlxG.keys.justPressed.NUMPADNINE)
			hit = 9;

		if (hit < 0)
			return;

		typed += hit;
		if (typed.length > CODE.length)
			typed = typed.substr(typed.length - CODE.length);
		if (typed == CODE)
		{
			typed = "";
			startScare();
		}
	}

	function startScare():Void
	{
		list.enabled = false;
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.pause();
		}

		scare = new FlxSprite();
		scare.loadGraphic(util.Paths.image("fun/golden_freddy"));
		scare.antialiasing = false;
		scare.scrollFactor.set();
		scare.setGraphicSize(FlxG.width, FlxG.height);
		scare.updateHitbox();
		scare.setPosition(0, 0);
		add(scare);

		scareSound = FlxG.sound.play(util.Paths.sound("fun/goldie_scare"), 1);
		scareTimer = SCARE_QUIT;
	}

	function updateScare(elapsed:Float):Void
	{
		scareTimer -= elapsed;
		if (scareTimer > 0)
			return;
		scareTimer = 0;
		DiscordPresence.shutdown();
		lime.system.System.exit(0);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (leaving)
			return;

		if (scareTimer > 0)
		{
			updateScare(elapsed);
			return;
		}

		if (subState == null && !busy)
			readCode();

		if (FlxG.keys.justPressed.F7 && !busy && subState == null)
		{
			leaving = true;
			list.enabled = false;
			wipe.close(function() FlxG.switchState(() -> new EditorState()));
			return;
		}

		splashTime += elapsed;
		var s = 1 - SPLASH_THROB * Math.abs(Math.sin(splashTime * SPLASH_SPEED));
		splash.scale.set(s, s);

		bobTime += elapsed;
		var lift = Math.sin(bobTime * BOB_SPEED) * BOB_AMP;
		titleArt.y = titleBaseY + lift;
		titleShade.y = titleBaseY + SHADOW_OFF_Y + lift;
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
				wipe.close(function() FlxG.switchState(() -> new OnlineState()));
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
			FlxG.switchState(() -> new PlayState());
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
