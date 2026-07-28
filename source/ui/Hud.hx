package ui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.math.FlxRect;
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
	static inline var SCRAP_RIGHT:Float = 18;
	static inline var SCRAP_TOP:Float = 12;
	static inline var SCRAP_GAP:Float = 10;
	static inline var SCRAP_DROP:Float = 4;
	static inline var SCRAP_SIZE:Int = 34;
	static inline var SCRAP_ICON_SCALE:Float = 3;
	static inline var SCRAP_SHADE:Float = 0.45;

	static inline var SUPER_LEFT:Float = 3;
	static inline var SUPER_SPAN:Float = 29;
	static inline var GAUGE_LEFT:Float = 3;
	static inline var GAUGE_SPAN:Float = 29;
	static inline var BAR_Y:Float = 642;
	static inline var UI_SCALE:Float = 4;

	public var camUI:FlxCamera;

	private var state:FlxState;
	private var status:PlayerCombat;
	private var customCursor:FlxSprite;
	private var waveText:FlxText;
	private var expText:FlxText;
	private var expShade:FlxText;
	private var scrapIcon:FlxSprite;
	private var scrapIconShade:FlxSprite;
	private var expShown:Int = -1;
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
	private var gaugeBack:FlxSprite;
	private var gaugeFill:FlxSprite;
	private var gaugeClip:FlxRect;
	private var gaugeShown:Float = -1;
	private var ammoText:FlxText;
	private var ammoShown:Int = -1;
	private var ammoPop:Float = 0;
	private var superFill:FlxSprite;
	private var superClip:FlxRect;
	private var superShown:Float = -1;
	private var healthBar:FlxBar;

	public function new(state:FlxState, status:PlayerCombat)
	{
		this.state = state;
		this.status = status;

		camUI = new FlxCamera();
		FlxG.cameras.add(camUI, false);
		camUI.bgColor.alpha = 0;

		var barBackground = makeSprite(160, BAR_Y, "bar_red");
		var playerIcon = makeSprite(barBackground.x - 120, barBackground.y, "mufu_icon");

		superFill = makeSprite(barBackground.x, barBackground.y, "bar_super_fill");
		superClip = FlxRect.get(0, 0, 0, barBackground.frameHeight);

		state.add(barBackground);
		state.add(makeSprite(barBackground.x, barBackground.y, "bar_super_empty"));
		state.add(superFill);
		healthBar = makeBar(barBackground, "bar_main_empty", "bar_main_red", 'health', status.healthMax);
		state.add(healthBar);
		state.add(playerIcon);

		gaugeBack = makeSprite(barBackground.x, 0, "bar_gauge_back");
		gaugeFill = makeSprite(barBackground.x, 0, "bar_gauge_fill");
		var gaugeY = barBackground.y + (UI_SCALE + 1) * 0.5 * barBackground.frameHeight
			- (UI_SCALE - 1) * 0.5 * gaugeBack.frameHeight;
		gaugeBack.y = gaugeY;
		gaugeFill.y = gaugeY;
		gaugeClip = FlxRect.get(0, 0, 0, gaugeBack.frameHeight);
		gaugeBack.visible = false;
		gaugeFill.visible = false;
		state.add(gaugeBack);
		state.add(gaugeFill);

		ammoText = new FlxText(1000, 576, 240, "");
		ammoText.setFormat(Lang.font(), 30, FlxColor.WHITE, CENTER);
		ammoText.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		ammoText.cameras = [camUI];
		ammoText.visible = false;
		state.add(ammoText);

		timeText = new FlxText(92, 588, 0, "");
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
		scrapIconShade = makeScrapIcon(true);
		scrapIcon = makeScrapIcon(false);
		expShade = makeScrapText(true);
		expText = makeScrapText(false);
		state.add(scrapIconShade);
		state.add(expShade);
		state.add(scrapIcon);
		state.add(expText);
		setExp(0);
		bannerText = makeText(250, 48);
		deadText = makeText(380, 24);
		deadText.visible = false;

		bossHud = new BossHud(state, camUI);

		customCursor = makeSprite(0, 0, "mouse");
		state.add(customCursor);

		FlxG.mouse.visible = false;
	}

	public function setHealthRange(max:Float):Void
		healthBar.setRange(0, max);

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
		customCursor.setPosition(FlxG.mouse.viewX - 5, FlxG.mouse.viewY);

		updateSuper();

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

	function updateSuper():Void
	{
		var pct = status.superMax > 0 ? status.superMeter / status.superMax : 0;
		if (pct < 0)
			pct = 0;
		if (pct > 1)
			pct = 1;
		if (pct == superShown)
			return;
		superShown = pct;
		superClip.width = SUPER_LEFT + SUPER_SPAN * pct;
		superFill.clipRect = superClip;
	}

	function makeScrapIcon(shade:Bool):FlxSprite
	{
		var s = new FlxSprite();
		s.loadGraphic(Paths.image("items/scrap"));
		s.antialiasing = false;
		s.scale.set(SCRAP_ICON_SCALE, SCRAP_ICON_SCALE);
		s.updateHitbox();
		s.cameras = [camUI];
		if (shade)
		{
			s.color = FlxColor.BLACK;
			s.alpha = SCRAP_SHADE;
		}
		return s;
	}

	function makeScrapText(shade:Bool):FlxText
	{
		var t = new FlxText(0, 0, 0, "");
		t.setFormat(Lang.font(), SCRAP_SIZE, shade ? FlxColor.BLACK : FlxColor.WHITE, LEFT);
		if (!shade)
			t.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		if (shade)
			t.alpha = SCRAP_SHADE;
		t.cameras = [camUI];
		return t;
	}

	public function setExp(n:Int):Void
	{
		if (n == expShown)
			return;
		expShown = n;
		var label = Std.string(n);
		expText.text = label;
		expShade.text = label;
		layoutScrap();
	}

	function layoutScrap():Void
	{
		expText.x = FlxG.width - SCRAP_RIGHT - expText.width;
		expText.y = SCRAP_TOP;
		scrapIcon.x = expText.x - scrapIcon.width - SCRAP_GAP;
		scrapIcon.y = SCRAP_TOP + (expText.height - scrapIcon.height) * 0.5;
		expShade.setPosition(expText.x + SCRAP_DROP, expText.y + SCRAP_DROP);
		scrapIconShade.setPosition(scrapIcon.x + SCRAP_DROP, scrapIcon.y + SCRAP_DROP);
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
		gaugeBack.visible = shown;
		gaugeFill.visible = shown;
		if (!shown || fill == gaugeShown)
			return;
		gaugeShown = fill;
		gaugeClip.width = GAUGE_LEFT + GAUGE_SPAN * fill;
		gaugeFill.clipRect = gaugeClip;
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
		s.scale.set(UI_SCALE, UI_SCALE);
		s.cameras = [camUI];
		return s;
	}

	public function applyLanguage(wave:Int):Void
	{
		for (t in [waveText, expText, expShade, bannerText, deadText, ammoText, timeText])
			t.font = Lang.font();
		layoutScrap();
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
