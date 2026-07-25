package states;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import net.Net;
import util.Paths;

class OnlineHelpSubState extends FlxSubState
{
	public static var shown:Bool = false;

	static inline var PAGES:Int = 3;
	static inline var FADE_TIME:Float = 0.3;
	static inline var OPEN_TIME:Float = 0.2;

	static var TITLES:Array<String> = ["ONLINE CO-OP", "SETTING IT UP", "WHAT CHANGES"];

	private var titleText:FlxText;
	private var bodyText:FlxText;
	private var pageText:FlxText;
	private var page:Int = 0;
	private var fadeSprites:Array<FlxSprite> = [];
	private var fadeBase:Array<Float> = [];
	private var fade:Float = 1;
	private var closing:Bool = false;
	private var opening:Bool = false;

	override public function create():Void
	{
		var overlay = new FlxSprite(0, 0);
		overlay.makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
		add(overlay);

		var border = new FlxSprite(236, 76);
		border.makeGraphic(808, 568, 0xFFB2273A);
		add(border);

		var panel = new FlxSprite(240, 80);
		panel.makeGraphic(800, 560, 0xFF4A4550);
		add(panel);

		titleText = uiText(110, 36);
		bodyText = uiText(200, 20);
		pageText = uiText(596, 16);

		buildPage();
		beginOpen();

		super.create();
	}

	function uiText(y:Float, size:Int):FlxText
	{
		var t = new FlxText(260, y, 760, "");
		t.setFormat(null, size, FlxColor.WHITE, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(t);
		return t;
	}

	function body(i:Int):String
	{
		return switch (i)
		{
			case 0:
				"Fight the waves together - up to " + (Net.MAX_GUESTS + 1) + " of you.\n\n"
					+ "One of you HOSTS and runs the game.\n"
					+ "Everyone else JOINS and fights alongside.\n\n"
					+ "You share the wave counter and the boss,\n"
					+ "but you each keep your own health and AP.\n\n"
					+ "Friends can drop in after the run has begun.";

			case 1:
				"HOST - pick HOST GAME, then send your friends\n"
					+ "your IP address. Over the internet you must\n"
					+ "forward TCP port " + Net.PORT + " on your router first.\n\n"
					+ "JOIN - pick JOIN GAME, type the host's IP,\n"
					+ "then press ENTER.\n\n"
					+ "If the host reports a different port because\n"
					+ Net.PORT + " was busy, join with   IP:PORT\n\n"
					+ "On the same house network, use the host's\n"
					+ "local IP and skip the port forwarding.";

			default:
				"Dying does not end the run. You drop out for\n"
					+ "a few seconds, then respawn with half health.\n"
					+ "The enemies turn on whoever is still standing,\n"
					+ "so the run only ends if EVERYONE is down.\n\n"
					+ "TIME STOP and the TOTEM are switched off\n"
					+ "online - both rewrite the whole world, which\n"
					+ "only works when one player owns it.\n\n"
					+ "You will see everything your friend throws\n"
					+ "out - arrows, slashes, shockwaves, the hook,\n"
					+ "the thrown scythe and all four SUPERS.";
		}
	}

	function buildPage():Void
	{
		titleText.text = TITLES[page];
		bodyText.text = body(page);
		pageText.text = "A/<- <   " + (page + 1) + " / " + PAGES + "   > D/->        ENTER - CLOSE";
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
		snapshot(members);
		applyFade(0);
	}

	function beginClose():Void
	{
		closing = true;
		snapshot(members);
	}

	function applyFade(f:Float):Void
	{
		for (i in 0...fadeSprites.length)
			fadeSprites[i].alpha = fadeBase[i] * f;
	}

	function snapshot(list:Array<FlxBasic>):Void
	{
		fadeSprites = [];
		fadeBase = [];
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
