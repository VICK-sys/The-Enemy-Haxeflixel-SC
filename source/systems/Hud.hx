package systems;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import util.Paths;

class Hud
{
	public var camUI:FlxCamera;

	private var state:FlxState;
	private var status:PlayerCombat;
	private var customCursor:FlxSprite;
	private var waveText:FlxText;
	private var bannerText:FlxText;
	private var deadText:FlxText;
	private var bannerTimer:Float = 0;

	public function new(state:FlxState, status:PlayerCombat)
	{
		this.state = state;
		this.status = status;

		camUI = new FlxCamera();
		FlxG.cameras.add(camUI, false);
		camUI.bgColor.alpha = 0;

		var barBackground = makeSprite(160, 670, "bar_red");
		var activeRed = makeSprite(1060, 670, "active_red");
		var passiveRed = makeSprite(1150, 670, "pasive_red");
		var playerIcon = makeSprite(barBackground.x - 120, barBackground.y, "mufu_icon");

		state.add(barBackground);
		state.add(makeBar(barBackground, "bar_main_empty", "bar_red", 'health', status.healthMax));
		state.add(makeBar(activeRed, "active_empty", "active_red", 'itemBar', status.apMax));
		state.add(passiveRed);
		state.add(playerIcon);

		waveText = makeText(8, 16);
		bannerText = makeText(250, 48);
		deadText = makeText(380, 24);
		deadText.visible = false;

		customCursor = makeSprite(0, 0, "mouse");
		state.add(customCursor);

		FlxG.mouse.visible = false;
	}

	public function update(elapsed:Float):Void
	{
		customCursor.setPosition(FlxG.mouse.screenX - 5, FlxG.mouse.screenY);

		if (bannerTimer > 0)
		{
			bannerTimer -= elapsed;
			if (bannerTimer <= 0)
				bannerText.visible = false;
		}
	}

	public function showWave(n:Int):Void
	{
		waveText.text = "WAVE " + n;
		bannerText.text = "WAVE " + n;
		bannerText.visible = true;
		bannerTimer = 2;
	}

	public function showDeath(wave:Int, best:Int):Void
	{
		deadText.text = "WAVE " + wave + "  -  BEST " + best + "\nPRESS R TO RESTART";
		deadText.visible = true;
	}

	public function hideDeath():Void
	{
		deadText.visible = false;
	}

	function makeSprite(x:Float, y:Float, name:String):FlxSprite
	{
		var s = new FlxSprite(x, y, Paths.image("ui/" + name));
		s.antialiasing = false;
		s.scale.set(4, 4);
		s.cameras = [camUI];
		return s;
	}

	function makeText(y:Float, size:Int):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, "");
		t.setFormat(null, size, FlxColor.WHITE, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		t.cameras = [camUI];
		state.add(t);
		return t;
	}

	function makeBar(anchor:FlxSprite, emptyName:String, fillName:String, valueField:String, max:Float):FlxBar
	{
		var b = new FlxBar(anchor.x, anchor.y, LEFT_TO_RIGHT, Std.int(anchor.width), Std.int(anchor.height), status, valueField, 0, max);
		b.createImageBar(Paths.image("ui/" + emptyName), Paths.image("ui/" + fillName), FlxColor.TRANSPARENT, FlxColor.TRANSPARENT);
		b.updateBar();
		b.antialiasing = false;
		b.scale.set(4, 4);
		b.cameras = [camUI];
		return b;
	}
}
