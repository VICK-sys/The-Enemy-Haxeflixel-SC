package ui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import entities.enemy.Enemies;
import util.Paths;
import systems.PlayerCombat;
import util.Lang;

class Hud
{
	static inline var BANNER_TIME:Float = 2;
	static inline var BANNER_IN:Float = 0.35;
	static inline var BANNER_OUT:Float = 0.3;
	static inline var BOSS_BANNER_TIME:Float = 3.4;
	static inline var BOSS_BANNER_DESC:Float = 2.5;
	static inline var BOSS_BANNER_FADE:Float = 0.7;
	static inline var BOSS_BANNER_TOP:Float = -70;
	static inline var BOSS_BANNER_REST:Float = 250;
	static inline var STOP_TIMER_FADE:Float = 4;
	static inline var RELOAD_TINT:Int = 0xFFFF7A7A;
	static inline var AMMO_POP_TIME:Float = 0.14;
	static inline var AMMO_POP_AMP:Float = 0.4;

	public var camUI:FlxCamera;

	private var state:FlxState;
	private var status:PlayerCombat;
	private var customCursor:FlxSprite;
	private var waveText:FlxText;
	private var bannerText:FlxText;
	private var deadText:FlxText;
	private var bossHud:BossHud;
	private var bannerTimer:Float = 0;
	private var bossSlide:Bool = false;
	private var bannerFading:Bool = false;
	private var bannerFadeTimer:Float = 0;
	private var timeText:FlxText;
	private var stopTimerText:FlxText;
	private var stopTimerTarget:Float = 0;
	private var gaugeBar:FlxBar;
	private var ammoText:FlxText;
	private var ammoShown:Int = -1;
	private var ammoPop:Float = 0;

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

		var gaugeAnchor = makeSprite(1060, 578, "active_blue");
		gaugeBar = new FlxBar(gaugeAnchor.x, gaugeAnchor.y, LEFT_TO_RIGHT, Std.int(gaugeAnchor.width), Std.int(gaugeAnchor.height), null, "", 0, 1);
		gaugeBar.createImageBar(Paths.image("ui/active_empty"), Paths.image("ui/active_blue"), FlxColor.TRANSPARENT, FlxColor.TRANSPARENT);
		gaugeBar.antialiasing = false;
		gaugeBar.scale.set(4, 4);
		gaugeBar.cameras = [camUI];
		gaugeBar.visible = false;
		state.add(gaugeBar);

		ammoText = new FlxText(1000, 576, 240, "");
		ammoText.setFormat(Lang.font(), 30, FlxColor.WHITE, CENTER);
		ammoText.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		ammoText.cameras = [camUI];
		ammoText.visible = false;
		state.add(ammoText);

		timeText = new FlxText(92, 616, 0, "");
		timeText.setFormat(Lang.font(), 14, FlxColor.WHITE, LEFT);
		timeText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		timeText.cameras = [camUI];
		state.add(timeText);

		stopTimerText = makeText(120, 32);
		stopTimerText.font = Paths.font("digital-7");
		stopTimerText.color = 0xFFFF5A5A;
		stopTimerText.alpha = 0;
		stopTimerText.visible = false;

		waveText = makeText(8, 16);
		bannerText = makeText(250, 48);
		deadText = makeText(380, 24);
		deadText.visible = false;

		bossHud = new BossHud(state, camUI);

		customCursor = makeSprite(0, 0, "mouse");
		state.add(customCursor);

		FlxG.mouse.visible = false;
	}

	public function setTimeStop(label:String):Void
	{
		if (timeText.text != label)
			timeText.text = label;
	}

	public function setStopTimer(label:String):Void
	{
		if (label != "")
		{
			if (stopTimerText.text != label)
				stopTimerText.text = label;
			stopTimerTarget = 1;
		}
		else
			stopTimerTarget = 0;
	}

	public function update(elapsed:Float):Void
	{
		customCursor.setPosition(FlxG.mouse.screenX - 5, FlxG.mouse.screenY);

		if (ammoPop > 0)
		{
			ammoPop -= elapsed;
			var t = ammoPop > 0 ? ammoPop / AMMO_POP_TIME : 0;
			var s = 1 + AMMO_POP_AMP * t;
			ammoText.scale.set(s, s);
		}

		if (stopTimerText.alpha != stopTimerTarget)
		{
			var a = stopTimerText.alpha;
			if (a < stopTimerTarget)
				a = Math.min(stopTimerTarget, a + STOP_TIMER_FADE * elapsed);
			else
				a = Math.max(stopTimerTarget, a - STOP_TIMER_FADE * elapsed);
			stopTimerText.alpha = a;
			stopTimerText.visible = a > 0;
		}

		bossHud.update(elapsed);

		if (bannerFading)
		{
			bannerFadeTimer -= elapsed;
			bannerText.alpha = bannerFadeTimer > 0 ? bannerFadeTimer / BOSS_BANNER_FADE : 0;
			if (bannerFadeTimer <= 0)
			{
				bannerFading = false;
				bannerText.visible = false;
				bannerText.alpha = 1;
				bannerText.scale.set(1, 1);
				bannerText.angle = 0;
				bannerText.y = 48;
				bossSlide = false;
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
				bannerText.y = 48;
				bossSlide = false;
			}
			else if (bossSlide)
			{
				updateBossBanner();
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
		waveText.text = Lang.t("hud.wave", [n]);
		bannerText.color = FlxColor.WHITE;
		showBanner(Lang.t("hud.wave", [n]));
	}

	public function showBoss():Void
	{
		bannerText.color = 0xFFE0132D;
		bannerText.text = Lang.t("hud.bossApproaching");
		bannerText.visible = true;
		bannerText.alpha = 0;
		bannerText.scale.set(1, 1);
		bannerText.angle = 0;
		bannerText.y = BOSS_BANNER_TOP;
		bossSlide = true;
		bannerTimer = BOSS_BANNER_TIME;
		bossHud.startFlash();
	}

	function updateBossBanner():Void
	{
		var age = BOSS_BANNER_TIME - bannerTimer;
		var p = age < BOSS_BANNER_DESC ? age / BOSS_BANNER_DESC : 1;
		var ease = 1 - Math.pow(1 - p, 3);
		bannerText.y = BOSS_BANNER_TOP + (BOSS_BANNER_REST - BOSS_BANNER_TOP) * ease;
		bannerText.scale.set(1, 1);
		bannerText.angle = 0;
		bannerText.alpha = age < 0.4 ? age / 0.4 : 1;
	}

	public function showBossBar(bossEnemy:Enemies):Void
	{
		bossHud.showBar(bossEnemy);
	}

	public function fadeBanner():Void
	{
		bannerTimer = 0;
		bannerFading = true;
		bannerFadeTimer = BOSS_BANNER_FADE;
	}

	public function showBanner(text:String):Void
	{
		bossSlide = false;
		bannerText.y = 48;
		bannerText.text = text;
		bannerText.visible = true;
		bannerText.alpha = 0;
		bannerText.scale.set(3, 3);
		bannerText.angle = -10;
		bannerTimer = BANNER_TIME;
	}

	public function setGauge(fill:Float, shown:Bool):Void
	{
		gaugeBar.visible = shown;
		if (shown)
			gaugeBar.percent = fill * 100;
	}

	public function setAmmo(cur:Int, max:Int, reloading:Bool, shown:Bool):Void
	{
		ammoText.visible = shown;
		if (!shown)
			return;
		if (cur != ammoShown)
		{
			ammoShown = cur;
			ammoText.text = cur + " / " + max;
			ammoPop = AMMO_POP_TIME;
		}
		ammoText.color = reloading ? RELOAD_TINT : FlxColor.WHITE;
	}

	public function showDeath(wave:Int, best:Int):Void
	{
		deadText.text = Lang.t("hud.death", [wave, best]);
		deadText.visible = true;
	}

	public function showRespawn():Void
	{
		deadText.text = Lang.t("hud.respawning");
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

	public function applyLanguage(wave:Int):Void
	{
		for (t in [waveText, bannerText, deadText, ammoText, timeText])
			t.font = Lang.font();
		waveText.text = Lang.t("hud.wave", [wave]);
	}

	function makeText(y:Float, size:Int):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, "");
		t.setFormat(Lang.font(), size, FlxColor.WHITE, CENTER);
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
