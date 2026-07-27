package ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.Lang;
import util.Paths;

class DialogueBox
{
	static inline var SIDE:Float = 60;
	static inline var HEIGHT:Float = 210;
	static inline var BOTTOM:Float = 40;
	static inline var EDGE:Int = 6;
	static inline var PAD:Float = 26;
	static inline var CHAR_TIME:Float = 0.024;
	static inline var BLIP_EVERY:Int = 3;
	static inline var BLINK:Float = 0.5;

	public var open(default, null):Bool = false;
	public var onClosed:Void->Void;

	private var edge:FlxSprite;
	private var panel:FlxSprite;
	private var body:FlxText;
	private var more:FlxText;

	private var pages:Array<String> = [];
	private var page:Int = 0;
	private var shown:Int = 0;
	private var timer:Float = 0;
	private var blink:Float = 0;
	private var full:String = "";

	public function new(state:FlxState, cam:FlxCamera)
	{
		var w = FlxG.width - SIDE * 2;
		var y = FlxG.height - BOTTOM - HEIGHT;

		edge = new FlxSprite(SIDE - EDGE, y - EDGE);
		edge.makeGraphic(Std.int(w + EDGE * 2), Std.int(HEIGHT + EDGE * 2), FlxColor.WHITE);

		panel = new FlxSprite(SIDE, y);
		panel.makeGraphic(Std.int(w), Std.int(HEIGHT), FlxColor.BLACK);

		body = new FlxText(SIDE + PAD, y + PAD, w - PAD * 2, "");
		body.setFormat(Lang.font(), 24, FlxColor.WHITE, LEFT);

		more = new FlxText(0, y + HEIGHT - 40, FlxG.width - SIDE - PAD, "");
		more.setFormat(Lang.font(), 18, FlxColor.WHITE, RIGHT);

		for (s in [edge, panel, (cast body : FlxSprite), (cast more : FlxSprite)])
		{
			s.cameras = [cam];
			s.scrollFactor.set();
			s.visible = false;
			state.add(s);
		}
	}

	public function start(lines:Array<String>):Void
	{
		if (lines == null || lines.length == 0)
			return;
		pages = lines;
		page = 0;
		open = true;
		show(true);
		loadPage();
	}

	function show(on:Bool):Void
	{
		edge.visible = on;
		panel.visible = on;
		body.visible = on;
		more.visible = on;
	}

	function loadPage():Void
	{
		full = pages[page];
		shown = 0;
		timer = 0;
		blink = 0;
		body.text = "";
		more.text = "";
	}

	public function update(elapsed:Float):Void
	{
		if (!open)
			return;

		var typing = shown < full.length;
		if (typing)
		{
			timer += elapsed;
			while (timer >= CHAR_TIME && shown < full.length)
			{
				timer -= CHAR_TIME;
				shown++;
				if (shown % BLIP_EVERY == 0 && full.charAt(shown - 1) != " ")
					FlxG.sound.play(Paths.sound("tick"), 0.18);
			}
			body.text = full.substr(0, shown);
		}
		else
		{
			blink += elapsed;
			more.text = (blink % (BLINK * 2)) < BLINK ? Lang.t("talk.more") : "";
		}

		if (!advancePressed())
			return;

		if (typing)
		{
			shown = full.length;
			body.text = full;
			return;
		}

		page++;
		if (page < pages.length)
		{
			loadPage();
			return;
		}

		open = false;
		show(false);
		if (onClosed != null)
			onClosed();
	}

	function advancePressed():Bool
		return FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z;
}
