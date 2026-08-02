package states;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import states.tutorial.TutorialDemo;
import states.tutorial.MoveDemo;
import states.tutorial.AttackDemo;
import states.tutorial.SuperDemo;
import states.tutorial.ScrapDemo;
import states.tutorial.HealthDemo;
import states.tutorial.ReadyDemo;
import util.Lang;

class TutorialSubState extends FlxSubState
{
	public static var shown:Bool = false;

	static inline var PAGES:Int = 6;
	static inline var FADE_TIME:Float = 0.35;
	static inline var OPEN_TIME:Float = 0.2;

	static var KEYS:Array<String> = ["move", "attack", "super", "scrap", "health", "ready"];

	private var camUI:FlxCamera;
	private var closeNav:Bool;
	private var titleText:FlxText;
	private var descText:FlxText;
	private var pageText:FlxText;
	private var page:Int = 0;
	private var demo:TutorialDemo;
	private var fadeSprites:Array<FlxSprite> = [];
	private var fadeBase:Array<Float> = [];
	private var fade:Float = 1;
	private var closing:Bool = false;
	private var opening:Bool = false;

	public function new(camUI:FlxCamera, closeNav:Bool = false)
	{
		super();
		this.camUI = camUI;
		this.closeNav = closeNav;
	}

	override public function create():Void
	{
		var overlay = new FlxSprite(0, 0);
		overlay.makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
		overlay.cameras = [camUI];
		add(overlay);

		var border = new FlxSprite(236, 76);
		border.makeGraphic(808, 568, 0xFFB2273A);
		border.cameras = [camUI];
		add(border);

		var panel = new FlxSprite(240, 80);
		panel.makeGraphic(800, 560, 0xFF4A4550);
		panel.cameras = [camUI];
		add(panel);

		titleText = uiText(100, 36);
		descText = uiText(524, 16);
		pageText = uiText(596, 16);

		buildPage();
		beginOpen();

		super.create();
	}

	function uiText(y:Float, size:Int):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, "");
		t.setFormat(Lang.font(), size, FlxColor.WHITE, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		t.cameras = [camUI];
		add(t);
		return t;
	}

	function bind(action:Int):String
		return util.Controls.bindName(action);

	function moveKeys():String
	{
		var n = [
			bind(util.Controls.UP), bind(util.Controls.LEFT),
			bind(util.Controls.DOWN), bind(util.Controls.RIGHT)
		];
		for (s in n)
			if (s.length != 1)
				return n.join("/");
		return n.join("");
	}

	function descArgs():Array<Dynamic>
	{
		return switch (page)
		{
			case 0: [moveKeys(), bind(util.Controls.DASH)];
			case 1: [bind(util.Controls.ATTACK), bind(util.Controls.SECOND)];
			case 2: [bind(util.Controls.SUPER)];
			default: null;
		}
	}

	function buildPage():Void
	{
		if (demo != null)
		{
			remove(demo);
			demo.destroy();
		}

		titleText.text = Lang.t("tutorial." + KEYS[page] + ".title");
		descText.text = Lang.t("tutorial." + KEYS[page] + ".desc", descArgs());
		pageText.text = Lang.t(closeNav ? "lobbyHelp.nav" : "tutorial.nav", [page + 1, PAGES]);

		demo = switch (page)
		{
			case 0: new MoveDemo(camUI);
			case 1: new AttackDemo(camUI);
			case 2: new SuperDemo(camUI);
			case 3: new ScrapDemo(camUI);
			case 4: new HealthDemo(camUI);
			default: new ReadyDemo(camUI);
		}
		add(demo);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (opening)
		{
			fade += elapsed / OPEN_TIME;
			if (fade >= 1)
			{
				fade = 1;
				opening = false;
				applyFade(1);
				fadeSprites = [];
				fadeBase = [];
				demo.active = true;
			}
			else
				applyFade(1 - (1 - fade) * (1 - fade));
		}

		if (closing)
		{
			fade -= elapsed / FADE_TIME;
			if (fade < 0)
				fade = 0;
			applyFade(fade * fade);
			if (fade <= 0)
				close();
			return;
		}

		if (util.Controls.menuRightJust())
			flip(1);
		if (util.Controls.menuLeftJust())
			flip(-1);
		if (util.Controls.menuAccept())
		{
			util.MenuSfx.click();
			beginClose();
		}
		else if (util.Controls.menuBack())
		{
			util.MenuSfx.cancel();
			beginClose();
		}
	}

	function beginOpen():Void
	{
		opening = true;
		fade = 0;
		demo.active = false;
		snapshot(members);
		snapshot(demo.members);
		applyFade(0);
	}

	function beginClose():Void
	{
		closing = true;
		demo.active = false;
		snapshot(members);
		snapshot(demo.members);
	}

	function applyFade(f:Float):Void
	{
		for (i in 0...fadeSprites.length)
			fadeSprites[i].alpha = fadeBase[i] * f;
	}

	function snapshot(list:Array<FlxBasic>):Void
	{
		for (m in list)
		{
			if (m == null || !Std.isOfType(m, FlxSprite))
				continue;
			var s:FlxSprite = cast m;
			fadeSprites.push(s);
			fadeBase.push(s.alpha);
		}
	}

	function flip(dir:Int):Void
	{
		page = (page + dir + PAGES) % PAGES;
		buildPage();
		util.MenuSfx.hover();
	}
}
