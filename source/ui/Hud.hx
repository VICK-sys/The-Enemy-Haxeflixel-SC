package ui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
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
	static inline var SCRAP_GAP:Float = 10;
	static inline var SCRAP_LIFT:Float = 6;
	static inline var SCRAP_DROP:Float = 4;
	static inline var SCRAP_SIZE:Int = 34;
	static inline var SCRAP_ICON_SCALE:Float = UI_SCALE;
	static inline var SCRAP_SHADE:Float = 0.45;
	static inline var SUPER_GLOW_BASE:Float = 0.32;
	static inline var SUPER_GLOW_WAVE:Float = 0.28;
	static inline var SUPER_GLOW_SPEED:Float = 7.5;
	static inline var SUPER_READY_VOL:Float = 0.7;
	static inline var HEAL_FLASH:Float = 1.0;
	static inline var HEAL_HUE:Float = 1 / 3;
	static inline var HEAL_FADE:Float = 0.35;

	static inline var UI_SCALE:Float = 4 * states.PlayState.BASE_ZOOM;
	static inline var FRAME_X:Float = 16;

	static inline var HP_X:Float = 28;
	static inline var HP_Y:Float = 8;
	static inline var SUPER_X:Float = 27;
	static inline var SUPER_Y:Float = 17;
	static inline var AMMO_RIGHT:Float = 1264;
	static inline var AMMO_BOTTOM:Float = 704;
	static inline var AMMO_MID:Float = 34;
	static inline var PIP_GAP:Float = 4;
	static inline var CAP_GAP:Float = 6;

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
	private var superFill:FlxSprite;
	private var superClip:FlxRect;
	private var superShown:Float = -1;
	private var superReady:Bool = false;
	private var superGlow:Float = 0;
	private var hpFill:FlxSprite;
	private var hpFlash:FlxSprite;
	private var healFlash:Float = 0;
	private var hpClip:FlxRect;
	private var hpShown:Float = -1;
	private var bulletPips:Array<FlxSprite> = [];
	private var bulletsShown:Int = -1;
	private var twinPips:Array<FlxSprite> = [];
	private var twinShown:Int = -1;
	private var arrowPip:FlxSprite;
	private var arrowShown:Bool = true;
	private var capTop:FlxSprite;
	private var capBottom:FlxSprite;
	private var twinCapTop:FlxSprite;
	private var twinCapBottom:FlxSprite;
	private var hpTop:Float = 0;
	private var cursorPoint:flixel.math.FlxPoint = flixel.math.FlxPoint.get();
	private var pieces:Array<flixel.FlxBasic> = [];
	private var hudOn:Bool = true;

	public function new(state:FlxState, status:PlayerCombat)
	{
		this.state = state;
		this.status = status;

		camUI = new FlxCamera();
		FlxG.cameras.add(camUI, false);
		camUI.bgColor.alpha = 0;
		camUI.pixelPerfectRender = true;

		var frame = makeUiSprite(FRAME_X, 0, "hp_thing");
		var frameY = AMMO_BOTTOM - frame.height;
		frame.y = frameY;
		hpTop = frameY;

		hpFill = makeUiSprite(FRAME_X + HP_X * UI_SCALE, frameY + HP_Y * UI_SCALE, "hp_bar");
		hpClip = FlxRect.get(0, 0, 0, hpFill.frameHeight);

		superFill = makeUiSprite(FRAME_X + SUPER_X * UI_SCALE, frameY + SUPER_Y * UI_SCALE, "super_bar");
		superClip = FlxRect.get(0, 0, 0, superFill.frameHeight);

		hpFlash = new FlxSprite(hpFill.x, hpFill.y);
		hpFlash.loadGraphic(util.HuePalette.graphic("ui/hp_bar", HEAL_HUE));
		hpFlash.antialiasing = false;
		hpFlash.scale.set(UI_SCALE, UI_SCALE);
		hpFlash.cameras = [camUI];
		hpFlash.updateHitbox();
		hpFlash.setPosition(hpFill.x, hpFill.y);
		hpFlash.visible = false;

		state.add(piece(frame));
		state.add(piece(hpFill));
		state.add(hpFlash);
		state.add(piece(superFill));

		capTop = makeUiSprite(0, 0, "ammo_indicator");
		capTop.flipY = true;
		capBottom = makeUiSprite(0, 0, "ammo_indicator");
		capTop.visible = false;
		capBottom.visible = false;
		state.add(piece(capTop));
		state.add(piece(capBottom));

		twinCapTop = makeUiSprite(0, 0, "ammo_indicator");
		twinCapTop.flipY = true;
		twinCapBottom = makeUiSprite(0, 0, "ammo_indicator");
		twinCapTop.visible = false;
		twinCapBottom.visible = false;
		state.add(piece(twinCapTop));
		state.add(piece(twinCapBottom));

		arrowPip = makeUiSprite(0, 0, "ammo_arrow");
		arrowPip.visible = false;
		state.add(piece(arrowPip));

		timeText = new FlxText(92, 588, 0, "");
		timeText.setFormat(Lang.font(), 14, FlxColor.WHITE, LEFT);
		timeText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		timeText.cameras = [camUI];
		state.add(piece(timeText));

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
		state.add(piece(scrapIconShade));
		state.add(piece(expShade));
		state.add(piece(scrapIcon));
		state.add(piece(expText));
		setExp(0);
		bannerText = makeText(250, 48);
		deadText = makeText(380, 24);
		deadText.visible = false;

		bossHud = new BossHud(state, camUI);

		customCursor = makeSprite(0, 0, "mouse");
		state.add(customCursor);

		FlxG.mouse.visible = false;
	}

	function piece<T:flixel.FlxBasic>(o:T):T
	{
		pieces.push(o);
		return o;
	}

	public function dispose():Void
	{
		hpFill.clipRect = null;
		hpFlash.clipRect = null;
		superFill.clipRect = null;
		hpClip.put();
		hpClip = null;
		superClip.put();
		superClip = null;
		bossHud.dispose();
	}

	public function setShown(on:Bool):Void
	{
		if (hudOn == on)
			return;
		hudOn = on;
		for (p in pieces)
			p.visible = on;
		bossHud.setShown(on);
		if (on)
		{
			hideAmmo();
			stopTimerText.visible = false;
			bannerText.visible = bannerTimer > 0 || bannerFading;
			deadText.visible = false;
		}
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
		customCursor.setPosition(util.Controls.aimViewX(FlxG.camera) - customCursor.frameWidth * 0.5,
			util.Controls.aimViewY(FlxG.camera) - customCursor.frameHeight * 0.5);

		updateHealth();
		updateHeal(elapsed);
		updateSuper(elapsed);

		if (stopTimerText.alpha != stopTimerTarget)
		{
			var a = stopTimerText.alpha;
			if (a < stopTimerTarget)
				a = Math.min(stopTimerTarget, a + STOP_TIMER_FADE * elapsed);
			else
				a = Math.max(stopTimerTarget, a - STOP_TIMER_FADE * elapsed);
			stopTimerText.alpha = a;
			stopTimerText.visible = a > 0 && hudOn;
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

	function updateHealth():Void
	{
		var pct = status.healthMax > 0 ? status.health / status.healthMax : 0;
		if (pct < 0)
			pct = 0;
		if (pct > 1)
			pct = 1;
		if (pct == hpShown)
			return;
		hpShown = pct;
		hpClip.width = hpFill.frameWidth * pct;
		hpFill.clipRect = hpClip;
	}

	public function flashHeal():Void
		healFlash = HEAL_FLASH;

	function updateHeal(elapsed:Float):Void
	{
		if (healFlash <= 0)
			return;

		healFlash -= elapsed;
		if (healFlash <= 0)
		{
			healFlash = 0;
			hpFlash.visible = false;
			hpFlash.alpha = 1;
			return;
		}

		var u = 1 - healFlash / HEAL_FLASH;
		hpFlash.clipRect = hpClip;
		hpFlash.visible = hudOn;
		hpFlash.alpha = u > 1 - HEAL_FADE ? flixel.tweens.FlxEase.quadOut((1 - u) / HEAL_FADE) : 1;
	}

	function updateSuper(elapsed:Float):Void
	{
		var pct = status.superMax > 0 ? status.superMeter / status.superMax : 0;
		if (pct < 0)
			pct = 0;
		if (pct > 1)
			pct = 1;
		if (pct != superShown)
		{
			superShown = pct;
			superClip.width = superFill.frameWidth * pct;
			superFill.clipRect = superClip;
		}

		var ready = status.canSuper() && !status.dead;
		if (ready != superReady)
		{
			superReady = ready;
			superGlow = 0;
			if (ready)
				FlxG.sound.play(Paths.sound("super_ready"), SUPER_READY_VOL);
			else
				superFill.setColorTransform(1, 1, 1, superFill.alpha, 0, 0, 0, 0);
		}

		if (!superReady)
			return;

		superGlow += elapsed * SUPER_GLOW_SPEED;
		var lit = SUPER_GLOW_BASE + SUPER_GLOW_WAVE * (0.5 + 0.5 * Math.sin(superGlow));
		var keep = 1 - lit;
		var add = 255 * lit;
		superFill.setColorTransform(keep, keep, keep, superFill.alpha, add, add, add, 0);
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
		var rowH = scrapIcon.height > expText.height ? scrapIcon.height : expText.height;
		var top = hpTop - SCRAP_LIFT - rowH;
		scrapIcon.setPosition(FRAME_X, top + (rowH - scrapIcon.height) * 0.5);
		expText.setPosition(scrapIcon.x + scrapIcon.width + SCRAP_GAP, top + (rowH - expText.height) * 0.5);
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
		bannerText.visible = hudOn;
		bannerText.alpha = 0;
		bannerText.scale.set(1, 1);
		bannerText.angle = 0;
		bannerText.y = BOSS_BANNER_TOP;
		bossSlide = true;
		bannerTimer = BOSS_BANNER_TIME;
		bossHud.startFlash();
		raiseBanner();
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

	public function showBossBar(pack:Array<Enemies>):Void
	{
		bossHud.showBar(pack);
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
		bannerText.visible = hudOn;
		bannerText.alpha = 0;
		bannerText.scale.set(3, 3);
		bannerText.angle = -10;
		bannerTimer = BANNER_TIME;
		raiseBanner();
	}

	function raiseBanner():Void
	{
		state.remove(bannerText, true);
		state.add(bannerText);
		state.remove(customCursor, true);
		state.add(customCursor);
	}

	function stackCaps(rows:Int, rowH:Float):Float
		return stackColumn(AMMO_RIGHT - AMMO_MID, rows, rowH, capTop, capBottom);

	function stackColumn(midX:Float, rows:Int, rowH:Float, top:FlxSprite, bottom:FlxSprite):Float
	{
		var span = rows * rowH + (rows - 1) * PIP_GAP;
		var topY = AMMO_BOTTOM - top.height - bottom.height - CAP_GAP * 2 - span;
		top.setPosition(midX - top.width * 0.5, topY);
		bottom.setPosition(midX - bottom.width * 0.5, AMMO_BOTTOM - bottom.height);
		top.visible = true;
		bottom.visible = true;
		return topY + top.height + CAP_GAP;
	}

	function hideAmmo():Void
	{
		capTop.visible = false;
		capBottom.visible = false;
		arrowPip.visible = false;
		for (p in bulletPips)
			p.visible = false;
		bulletsShown = -1;
		hideTwinAmmo();
	}

	function hideTwinAmmo():Void
	{
		twinCapTop.visible = false;
		twinCapBottom.visible = false;
		for (p in twinPips)
			p.visible = false;
		twinShown = -1;
	}

	public function setAmmo(cur:Int, max:Int, reloading:Bool, shown:Bool):Void
	{
		while (bulletPips.length < max)
		{
			var p = makeUiSprite(0, 0, "ammo_bullet");
			p.visible = false;
			state.add(piece(p));
			bulletPips.push(p);
		}

		if (!shown || !hudOn)
		{
			if (bulletsShown != -1)
			{
				for (p in bulletPips)
					p.visible = false;
				bulletsShown = -1;
				if (!arrowPip.visible)
				{
					capTop.visible = false;
					capBottom.visible = false;
				}
			}
			return;
		}

		if (cur == bulletsShown)
			return;
		bulletsShown = cur;

		var pipH = bulletPips[0].height;
		var y = stackCaps(max, pipH);
		var midX = AMMO_RIGHT - AMMO_MID;
		for (i in 0...bulletPips.length)
		{
			var p = bulletPips[i];
			var full = i >= max - cur;
			reskin(p, full ? "ammo_bullet" : "ammo_bullet_empty");
			p.setPosition(midX - p.width * 0.5, y + i * (pipH + PIP_GAP));
			p.visible = i < max;
		}
	}

	public function setTwinAmmo(cur:Int, max:Int, shown:Bool):Void
	{
		while (twinPips.length < max)
		{
			var p = makeUiSprite(0, 0, "ammo_bullet");
			p.visible = false;
			state.add(piece(p));
			twinPips.push(p);
		}

		if (!shown || !hudOn)
		{
			if (twinShown != -1)
				hideTwinAmmo();
			return;
		}

		if (cur == twinShown)
			return;
		twinShown = cur;

		var pipH = twinPips[0].height;
		var midX = AMMO_RIGHT - AMMO_MID - twinCapTop.width - PIP_GAP * 2;
		var y = stackColumn(midX, max, pipH, twinCapTop, twinCapBottom);
		for (i in 0...twinPips.length)
		{
			var p = twinPips[i];
			var full = i >= max - cur;
			reskin(p, full ? "ammo_bullet" : "ammo_bullet_empty");
			p.setPosition(midX - p.width * 0.5, y + i * (pipH + PIP_GAP));
			p.visible = i < max;
		}
	}

	public function setBowLoaded(loaded:Bool, shown:Bool):Void
	{
		if (!shown || !hudOn)
		{
			if (arrowPip.visible)
			{
				arrowPip.visible = false;
				if (bulletsShown == -1)
				{
					capTop.visible = false;
					capBottom.visible = false;
				}
			}
			return;
		}

		if (!arrowPip.visible || loaded != arrowShown)
		{
			arrowShown = loaded;
			reskin(arrowPip, loaded ? "ammo_arrow" : "ammo_arrow_empty");
			var y = stackCaps(1, arrowPip.height);
			arrowPip.setPosition(AMMO_RIGHT - AMMO_MID - arrowPip.width * 0.5, y);
			arrowPip.visible = true;
		}
	}

	public function showDeath(wave:Int, best:Int):Void
	{
		deadText.text = Lang.t("hud.death", [wave, best]);
		deadText.visible = hudOn;
	}

	public function showRespawn():Void
	{
		deadText.text = Lang.t("hud.respawning");
		deadText.visible = hudOn;
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

	function makeUiSprite(x:Float, y:Float, name:String):FlxSprite
	{
		var s = makeSprite(x, y, name);
		s.updateHitbox();
		s.setPosition(x, y);
		return s;
	}

	function reskin(s:FlxSprite, name:String):Void
	{
		s.loadGraphic(Paths.image("ui/" + name));
		s.antialiasing = false;
		s.scale.set(UI_SCALE, UI_SCALE);
		s.updateHitbox();
	}

	public function applyLanguage(wave:Int):Void
	{
		for (t in [waveText, expText, expShade, bannerText, deadText, timeText])
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
		state.add(piece(t));
		return t;
	}

}
