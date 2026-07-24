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
import states.tutorial.WeaponsDemo;
import states.tutorial.ModesDemo;
import states.tutorial.SuperDemo;
import states.tutorial.AbilitiesDemo;
import states.tutorial.HealthDemo;
import util.Paths;

class TutorialSubState extends FlxSubState
{
	public static var shown:Bool = false;

	static inline var PAGES:Int = 7;
	static inline var FADE_TIME:Float = 0.35;
	static inline var OPEN_TIME:Float = 0.2;

	static var TITLES:Array<String> = ["MOVE", "ATTACK", "WEAPONS", "MODES", "SUPER", "ABILITIES", "HEALTH"];
	static var DESCS:Array<String> = [
		"WASD - move        SPACE - dash (2s cooldown)",
		"Aim with the mouse        LEFT CLICK - attack",
		"1-4 or SCROLL WHEEL - switch weapon",
		"RIGHT CLICK - cycle the equipped weapon's mode",
		"Q - super at full AP (scythe only)\nLEFT CLICK - launch the blades",
		"E - TIME STOP: the arena freezes for 10s (30s cooldown)\nYou keep moving and attacking - press E again to end it early",
		"Enemies drop hearts - walk into them to heal"
	];

	private var camUI:FlxCamera;
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

	public function new(camUI:FlxCamera)
	{
		super();
		this.camUI = camUI;
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
		t.setFormat(null, size, FlxColor.WHITE, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		t.cameras = [camUI];
		add(t);
		return t;
	}

	function buildPage():Void
	{
		if (demo != null)
		{
			remove(demo);
			demo.destroy();
		}

		titleText.text = TITLES[page];
		descText.text = DESCS[page];
		pageText.text = "A/<- <   " + (page + 1) + " / " + PAGES + "   > D/->        ENTER - PLAY";

		demo = switch (page)
		{
			case 0: new MoveDemo(camUI);
			case 1: new AttackDemo(camUI);
			case 2: new WeaponsDemo(camUI);
			case 3: new ModesDemo(camUI);
			case 4: new SuperDemo(camUI);
			case 5: new AbilitiesDemo(camUI);
			default: new HealthDemo(camUI);
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
			return;
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

		if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT)
			flip(1);
		if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT)
			flip(-1);
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE)
			beginClose();
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
		FlxG.sound.play(Paths.sound("scythe/slice"), 0.3);
	}
}
