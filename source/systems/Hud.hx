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
	static inline var BANNER_TIME:Float = 2;
	static inline var BANNER_IN:Float = 0.35;
	static inline var BANNER_OUT:Float = 0.3;
	static inline var MODE_SWITCH_TIME:Float = 0.3;
	static inline var ICON_X:Float = 560;
	static inline var ICON_Y:Float = 652;

	public var camUI:FlxCamera;

	private var state:FlxState;
	private var status:PlayerCombat;
	private var customCursor:FlxSprite;
	private var waveText:FlxText;
	private var bannerText:FlxText;
	private var deadText:FlxText;
	private var modeText:FlxText;
	private var modeIcon:FlxSprite;
	private var bannerTimer:Float = 0;
	private var currentMode:String = "";
	private var modeSwitchTimer:Float = 0;
	private var iconBaseAngle:Float = 0;
	private var iconScaleX:Float = 1;
	private var iconScaleY:Float = 1;

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
		modeText = makeText(645, 12);

		modeIcon = new FlxSprite();
		modeIcon.antialiasing = false;
		modeIcon.cameras = [camUI];
		state.add(modeIcon);

		customCursor = makeSprite(0, 0, "mouse");
		state.add(customCursor);

		FlxG.mouse.visible = false;
	}

	public function update(elapsed:Float):Void
	{
		customCursor.setPosition(FlxG.mouse.screenX - 5, FlxG.mouse.screenY);

		if (modeSwitchTimer > 0)
		{
			modeSwitchTimer -= elapsed;
			var p = 1 - modeSwitchTimer / MODE_SWITCH_TIME;
			if (p > 1)
				p = 1;
			var ease = 1 - (1 - p) * (1 - p) * (1 - p);
			var mult = 1 + (1 - ease) * 1.2;
			modeIcon.scale.set(iconScaleX * mult, iconScaleY * mult);
			modeIcon.angle = iconBaseAngle - 180 * (1 - ease);
			modeIcon.alpha = ease;
			modeText.scale.set(1 + (1 - ease) * 0.6, 1 + (1 - ease) * 0.6);
			modeText.alpha = 0.3 + 0.7 * ease;
			if (modeSwitchTimer <= 0)
			{
				modeIcon.scale.set(iconScaleX, iconScaleY);
				modeIcon.angle = iconBaseAngle;
				modeIcon.alpha = 1;
				modeText.scale.set(1, 1);
				modeText.alpha = 1;
			}
		}

		if (bannerTimer > 0)
		{
			bannerTimer -= elapsed;
			if (bannerTimer <= 0)
			{
				bannerText.visible = false;
				bannerText.scale.set(1, 1);
				bannerText.alpha = 1;
				bannerText.angle = 0;
			}
			else
			{
				var age = BANNER_TIME - bannerTimer;
				if (age < BANNER_IN)
				{
					var p = age / BANNER_IN;
					var ease = 1 - (1 - p) * (1 - p) * (1 - p);
					var s = 3 - 2 * ease;
					bannerText.scale.set(s, s);
					bannerText.alpha = p < 0.5 ? p * 2 : 1;
					bannerText.angle = -10 * (1 - ease);
				}
				else if (bannerTimer < BANNER_OUT)
				{
					var q = bannerTimer / BANNER_OUT;
					var s = 1 + (1 - q) * 0.6;
					bannerText.scale.set(s, s);
					bannerText.alpha = q;
					bannerText.angle = 0;
				}
				else
				{
					var s = 1 + 0.05 * Math.sin(age * 10);
					bannerText.scale.set(s, s);
					bannerText.alpha = 1;
					bannerText.angle = Math.sin(age * 6) * 1.2;
				}
			}
		}
	}

	public function showWave(n:Int):Void
	{
		waveText.text = "WAVE " + n;
		bannerText.text = "WAVE " + n;
		bannerText.visible = true;
		bannerText.alpha = 0;
		bannerText.scale.set(3, 3);
		bannerText.angle = -10;
		bannerTimer = BANNER_TIME;
	}

	public function setMode(name:String):Void
	{
		if (name == currentMode)
			return;
		currentMode = name;
		modeText.text = "MODE: " + name;
		applyModeIcon(name);
		modeSwitchTimer = MODE_SWITCH_TIME;
	}

	function applyModeIcon(name:String):Void
	{
		if (name == "HAMMER")
		{
			modeIcon.loadGraphic(Paths.image("items/mufu_hammer"));
			iconBaseAngle = 15;
		}
		else if (name == "SHOCKWAVE")
		{
			modeIcon.loadGraphic(Paths.image("items/mufu_hammer"));
			iconBaseAngle = -30;
		}
		else if (name == "BOW")
		{
			modeIcon.loadGraphic(Paths.image("items/mufu_bow"));
			iconBaseAngle = 0;
		}
		else if (name == "ARROW RAIN")
		{
			modeIcon.loadGraphic(Paths.image("items/mufu_bow"));
			iconBaseAngle = -45;
		}
		else if (name == "HOOK")
		{
			modeIcon.loadGraphic(Paths.image("items/mufu_hook"));
			iconBaseAngle = 30;
		}
		else if (name == "THROW" || name.indexOf("SUPER") == 0)
		{
			modeIcon.loadGraphic(Paths.image("items/mufu_scythe"));
			iconBaseAngle = 30;
		}
		else
		{
			modeIcon.frames = Paths.sparrow("effects/attacks_gfx");
			if (modeIcon.animation.getByName("slash") == null)
				modeIcon.animation.addByPrefix("slash", "Sword", 0, false);
			var slashAnim = modeIcon.animation.getByName("slash");
			var frame = name == "AIR SLICE" && slashAnim.numFrames > 3 ? slashAnim.numFrames - 3 : 0;
			modeIcon.animation.play("slash", true, false, frame);
			modeIcon.animation.pause();
			iconBaseAngle = name == "AIR SLICE" ? -35 : 0;
		}
		modeIcon.setGraphicSize(34, 0);
		modeIcon.updateHitbox();
		iconScaleX = modeIcon.scale.x;
		iconScaleY = modeIcon.scale.y;
		modeIcon.x = ICON_X - modeIcon.width / 2;
		modeIcon.y = ICON_Y - modeIcon.height / 2;
		modeIcon.angle = iconBaseAngle;
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
