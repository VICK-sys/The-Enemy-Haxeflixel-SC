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
	static inline var BOSS_BANNER_FADE:Float = 0.7;
	static inline var ALERT_W:Int = 112;
	static inline var ALERT_H:Int = 80;
	static inline var ALERT_FPS:Int = 14;
	static inline var ALERT_HOLD_FPS:Int = 10;
	static inline var ALERT_IN_FRAMES:Int = 5;
	static inline var ALERT_TIME:Float = 3.4;
	static inline var ALERT_OUT:Float = ALERT_IN_FRAMES / ALERT_FPS;
	static inline var ALERT_SCALE:Float = 3;
	static inline var ALERT_LIFT:Float = 0;
	static inline var STOP_TIMER_FADE:Float = 4;
	static inline var SCRAP_GAP:Float = 10;
	static inline var SCRAP_LEFT:Float = 5;
	static inline var SCRAP_DROP:Float = 4;
	static inline var SCRAP_ICON_SCALE:Float = UI_SCALE;
	static inline var SCRAP_SHADE:Float = 0.45;
	static inline var SUPER_GLOW_BASE:Float = 0.32;
	static inline var SUPER_GLOW_WAVE:Float = 0.28;
	static inline var SUPER_GLOW_SPEED:Float = 7.5;
	static inline var SUPER_READY_VOL:Float = 0.7;
	static inline var BAR_SLIDE:Float = 0.25;
	static inline var BAR_SETTLE:Float = 0.0005;
	static inline var HEAL_FLASH:Float = 1.0;
	static inline var HEAL_FADE:Float = 0.35;
	static inline var OCCLUDED_ALPHA:Float = 0.6;
	static inline var OCCLUSION_FADE_SPEED:Float = 5;
	static inline var OCCLUSION_PAD:Float = 12;

	static inline var UI_SCALE:Float = 4 * states.PlayState.BASE_ZOOM;
	static inline var HP_SCALE:Float = UI_SCALE;
	static inline var HP_FILL_SCALE_Y:Float = UI_SCALE * 1.1;
	static inline var SUPER_EXTRA_W:Float = 2;
	static inline var FRAME_X:Float = 16;

	static inline var HP_X:Float = 64.5;
	static inline var HP_Y:Float = 18.5;
	static inline var SUPER_X:Float = 72;
	static inline var SUPER_Y:Float = 42;

	static inline var TUBE_OFF_X:Float = 5;
	static inline var TUBE_OFF_Y:Float = -34;
	static inline var TUBE_X:Float = 4;
	static inline var TUBE_W:Float = 12;
	static inline var TUBE_TOP:Float = 12;
	static inline var TUBE_BOTTOM:Float = 54;
	static inline var ARROW_ANGLE:Float = -90;
	static inline var ARROW_TOP_OFFSET:Float = 25;
	static inline var ARROW_LEFT_OFFSET:Float = -2;

	static inline var DISPLAY_RIGHT:Float = 1280;
	static inline var DISPLAY_TOP:Float = 0;
	static inline var DISPLAY_SCALE:Float = UI_SCALE;
	static inline var DISPLAY_IN_TIME:Float = 0.65;
	static inline var DISPLAY_SOUND:String = "display_on";
	static inline var DISPLAY_VOL:Float = 0.65;
	static inline var TICK_X:Float = 13.5;
	static inline var TICK_Y:Float = 24;
	static inline var BOSS_BAR_X:Float = 11;
	static inline var BOSS_BAR_Y:Float = 15;
	static inline var BOSS_BAR_SCALE:Float = DISPLAY_SCALE;
	static inline var BOSS_BAR_EXTRA_W:Float = 2;
	static inline var WAVE_X:Float = 14;
	static inline var WAVE_Y:Float = 9;
	static inline var WAVE_W:Float = 103;
	static inline var WAVE_PAD:Float = 6;
	static inline var WAVE_SIZE_MIN:Int = 12;
	static inline var SCRAP_X:Float = 96;
	static inline var SCRAP_Y:Float = 45;
	static inline var TICK_COUNT:Int = 11;
	static inline var MAX_PIPS:Int = 12;
	static inline var WAVE_FLICKER_TIME:Float = 0.36;
	static inline var WAVE_FLICKER_BLINKS:Int = 3;
	static inline var WAVE_FLICKER_DIM:Float = 0.35;
	static inline var WAVE_FLICKER_SOUND:String = "wave_flicker";
	static inline var WAVE_FLICKER_VOLUME:Float = 0.5;
	static inline var GOOD_JOB_DELAY:Float = 0.2;
	static inline var GOOD_JOB_FPS:Int = 4;
	static inline var GOOD_JOB_X:Float = 17;
	static inline var GOOD_JOB_Y:Float = 13;
	static inline var GOOD_JOB_W:Int = 80;
	static inline var GOOD_JOB_H:Int = 16;

	static var TICK_EDGE:Array<Int> = [0, 5, 12, 19, 26, 34, 42, 51, 59, 67, 74, 82];
	static inline var AMMO_RIGHT:Float = 1264;
	static inline var AMMO_BOTTOM:Float = 704;
	static inline var AMMO_MID:Float = 34;
	static inline var PIP_GAP:Float = 4;
	static inline var CAP_GAP:Float = 6;

	public var camUI:FlxCamera;
	public var coop(default, null):CoopIcons;

	private var state:FlxState;
	private var status:PlayerCombat;
	private var customCursor:FlxSprite;
	private var waveText:FlxText;
	private var waveFlicker:Float = 0;
	private var waveLabel:String = "";
	private var expText:FlxText;
	private var expShade:FlxText;
	private var scrapIcon:FlxSprite;
	private var scrapIconShade:FlxSprite;
	private var expShown:Int = -1;
	private var bannerText:FlxText;
	private var bossWarning:FlxSprite;
	private var deadText:FlxText;
	private var bossHud:BossHud;
	private var bannerTimer:Float = 0;
	private var alertTimer:Float = 0;
	private var bannerFading:Bool = false;
	private var bannerFadeTimer:Float = 0;
	private var timeText:FlxText;
	private var stopTimerText:FlxText;
	private var stopTimerTarget:Float = 0;
	private var superFill:FlxSprite;
	private var superClip:FlxRect;
	private var superShown:Float = -1;
	private var superWidth:Int = -1;
	private var superReady:Bool = false;
	private var superGlow:Float = 0;
	private var ammoPips:Array<FlxSprite> = [];
	private var pipX:Float = 0;
	private var pipTop:Float = 0;
	private var displayPanel:FlxSprite;
	private var displayTicks:FlxSprite;
	private var goodJob:FlxSprite;
	private var goodJobDelay:Float = 0;
	private var waveCleared:Bool = false;
	private var tickClip:FlxRect;
	private var tickShown:Int = -1;
	private var bossBarBack:FlxSprite;
	private var bossBarFill:FlxSprite;
	private var bossBarClip:FlxRect;
	private var bossBarShown:Int = -1;
	private var bossBarOn:Bool = false;
	private var tubeOwner:String = null;
	private var displayRestX:Float = 0;
	private var displayStartOffset:Float = 0;
	private var displayOffset:Float = 0;
	private var displayClock:Float = 0;
	private var displayEntering:Bool = false;
	private var displayEntered:Bool = false;
	private var hpFrame:FlxSprite;
	private var ammoFrame:FlxSprite;
	private var hpBack:FlxSprite;
	private var superBack:FlxSprite;
	private var hpFill:FlxSprite;
	private var hpFlash:FlxSprite;
	private var healFlash:Float = 0;
	private var hpClip:FlxRect;
	private var hpShown:Float = -1;
	private var hpWidth:Int = -1;
	private var bulletPips:Array<FlxSprite> = [];
	private var bulletsShown:Int = -1;
	private var arrowPip:FlxSprite;
	private var arrowShown:Bool = true;
	private var capTop:FlxSprite;
	private var capBottom:FlxSprite;
	private var hpTop:Float = 0;
	private var cursorPoint:flixel.math.FlxPoint = flixel.math.FlxPoint.get();
	private var pieces:Array<flixel.FlxBasic> = [];
	private var fadingPieces:Array<FlxSprite> = [];
	private var art:Map<FlxSprite, String> = new Map();
	private var hue:Float = 0;
	private var hudOn:Bool = true;
	private var bossOccluded:Bool = false;
	private var clusterAlpha:Float = 1;

	public function new(state:FlxState, status:PlayerCombat)
	{
		this.state = state;
		this.status = status;
		hue = util.SaveData.playerHue();

		camUI = new FlxCamera();
		FlxG.cameras.add(camUI, false);
		camUI.bgColor.alpha = 0;
		camUI.pixelPerfectRender = true;

		coop = new CoopIcons(state, camUI);

		hpFrame = makeHpSprite(FRAME_X, 0, "hp_frame");
		var frameY = AMMO_BOTTOM - hpFrame.height;
		hpFrame.y = frameY;
		hpTop = frameY;

		ammoFrame = makeHpSprite(FRAME_X + TUBE_OFF_X * HP_SCALE, frameY + TUBE_OFF_Y * HP_SCALE, "ammo_tube");
		ammoFrame.visible = false;

		hpFill = makeHpSprite(FRAME_X + HP_X * HP_SCALE, frameY + HP_Y * HP_SCALE, "hp_bar");
		hpFill.scale.y = HP_FILL_SCALE_Y;
		hpFill.updateHitbox();
		hpFill.setPosition(FRAME_X + HP_X * HP_SCALE, frameY + HP_Y * HP_SCALE);
		hpClip = FlxRect.get(0, 0, 0, hpFill.frameHeight);
		hpBack = makeSlotBack(hpFill, "hp_bar");

		superFill = makeHpSprite(FRAME_X + SUPER_X * HP_SCALE, frameY + SUPER_Y * HP_SCALE, "super_bar");
		superFill.scale.x = HP_SCALE + SUPER_EXTRA_W / superFill.frameWidth;
		superFill.updateHitbox();
		superFill.setPosition(FRAME_X + SUPER_X * HP_SCALE, frameY + SUPER_Y * HP_SCALE);
		superClip = FlxRect.get(0, 0, 0, superFill.frameHeight);
		superBack = makeSlotBack(superFill, "super_bar", true);

		hpFlash = new FlxSprite(hpFill.x, hpFill.y);
		hpFlash.loadGraphic(Paths.image("ui/hp_bar"));
		hpFlash.setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);
		hpFlash.antialiasing = false;
		hpFlash.scale.set(HP_SCALE, HP_FILL_SCALE_Y);
		hpFlash.cameras = [camUI];
		hpFlash.updateHitbox();
		hpFlash.setPosition(hpFill.x, hpFill.y);
		hpFlash.visible = false;

		state.add(piece(ammoFrame));
		state.add(piece(hpFrame));
		state.add(piece(hpBack));
		state.add(piece(hpFill));
		state.add(hpFlash);
		state.add(piece(superBack));
		state.add(piece(superFill));
		for (p in [ammoFrame, hpFrame, hpBack, hpFill, superBack, superFill])
			fadingPieces.push(p);

		for (i in 0...MAX_PIPS)
		{
			var pip = makeHpSprite(0, 0, "ammo_bullet");
			pip.visible = false;
			ammoPips.push(pip);
			fadingPieces.push(pip);
			state.add(piece(pip));
		}
		layoutPips(ammoFrame.x, ammoFrame.y);

		displayPanel = makeUiSprite(0, DISPLAY_TOP, "display_panel");
		displayRestX = DISPLAY_RIGHT - displayPanel.width;
		displayPanel.x = displayRestX;
		state.add(piece(displayPanel));

		displayTicks = makeUiSprite(displayPanel.x + TICK_X * DISPLAY_SCALE,
			DISPLAY_TOP + TICK_Y * DISPLAY_SCALE, "display_ticks");
		tickClip = FlxRect.get(0, 0, 0, displayTicks.frameHeight);
		displayTicks.clipRect = tickClip;
		state.add(piece(displayTicks));

		goodJob = new FlxSprite();
		paintGoodJob();
		goodJob.cameras = [camUI];
		goodJob.visible = false;
		state.add(piece(goodJob));

		bossBarBack = makeUiSprite(displayPanel.x,
			DISPLAY_TOP + BOSS_BAR_Y * DISPLAY_SCALE, "fillEmptyBoss");
		bossBarBack.scale.set(BOSS_BAR_SCALE + BOSS_BAR_EXTRA_W / bossBarBack.frameWidth, BOSS_BAR_SCALE);
		bossBarBack.updateHitbox();
		bossBarBack.visible = false;
		state.add(piece(bossBarBack));

		bossBarFill = makeUiSprite(bossBarBack.x, bossBarBack.y, "fillBoss");
		bossBarFill.scale.set(BOSS_BAR_SCALE + BOSS_BAR_EXTRA_W / bossBarFill.frameWidth, BOSS_BAR_SCALE);
		bossBarFill.updateHitbox();
		bossBarClip = FlxRect.get(0, 0, 0, bossBarFill.frameHeight);
		bossBarFill.clipRect = bossBarClip;
		bossBarFill.visible = false;
		state.add(piece(bossBarFill));

		capTop = makeUiSprite(0, 0, "ammo_indicator");
		capTop.flipY = true;
		capBottom = makeUiSprite(0, 0, "ammo_indicator");
		capTop.visible = false;
		capBottom.visible = false;
		state.add(piece(capTop));
		state.add(piece(capBottom));

		arrowPip = makeUiSprite(0, 0, "ammo_arrow");
		arrowPip.visible = false;
		state.add(piece(arrowPip));

		timeText = new FlxText(92, 588, 0, "");
		timeText.setFormat(Lang.smallFont(), Lang.smallSize(), FlxColor.WHITE, LEFT);
		timeText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		timeText.cameras = [camUI];
		state.add(piece(timeText));
		fadingPieces.push(timeText);

		stopTimerText = makeText(120, Lang.bodySize());
		stopTimerText.font = Paths.font("digital-7");
		stopTimerText.color = 0xFFFF5A5A;
		stopTimerText.alpha = 0;
		stopTimerText.visible = false;

		waveText = new FlxText(displayPanel.x + WAVE_X * DISPLAY_SCALE,
			DISPLAY_TOP + WAVE_Y * DISPLAY_SCALE, WAVE_W * DISPLAY_SCALE, "");
		waveText.setFormat(Lang.smallFont(), Lang.smallSize(), FlxColor.WHITE, LEFT);
		waveText.wordWrap = false;
		waveText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		waveText.cameras = [camUI];
		state.add(piece(waveText));
		scrapIconShade = makeScrapIcon(true);
		scrapIcon = makeScrapIcon(false);
		expShade = makeScrapText(true);
		expText = makeScrapText(false);
		state.add(piece(scrapIconShade));
		state.add(piece(expShade));
		state.add(piece(scrapIcon));
		state.add(piece(expText));
		setExp(0);
		bossWarning = new FlxSprite();
		paintBossAlert();
		bossWarning.animation.onFinish.add(function(name)
		{
			if (name == "in")
				bossWarning.animation.play("hold");
			if (name == "out")
				bossWarning.visible = false;
		});
		bossWarning.cameras = [camUI];
		bossWarning.visible = false;
		state.add(piece(bossWarning));

		displayStartOffset = FlxG.width - displayRestX;
		displayOffset = displayStartOffset;
		layoutDisplay();
		bannerText = makeText(250, Lang.bodySize());
		deadText = makeText(380, Lang.bodySize());
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
		bossBarFill.clipRect = null;
		hpClip.put();
		hpClip = null;
		superClip.put();
		superClip = null;
		bossBarClip.put();
		bossBarClip = null;
		cursorPoint.put();
		cursorPoint = null;
	}

	public function setShown(on:Bool):Void
	{
		if (hudOn == on)
			return;
		hudOn = on;
		for (p in pieces)
			p.visible = on;
		coop.setVisible(on);
		if (on)
		{
			hideAmmo();
			stopTimerText.visible = false;
			waveText.visible = !waveCleared;
			displayTicks.visible = !waveCleared;
			goodJob.visible = waveCleared && goodJobDelay <= 0;
			bannerText.visible = bannerTimer > 0 || bannerFading;
			bossWarning.visible = alertTimer > 0;
			deadText.visible = false;
			applyDisplayMode();
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
		updateDisplay(elapsed);
		customCursor.setPosition(util.Controls.aimViewX(FlxG.camera) - customCursor.frameWidth * 0.5,
			util.Controls.aimViewY(FlxG.camera) - customCursor.frameHeight * 0.5);

		updateHealth(elapsed);
		updateHeal(elapsed);
		updateSuper(elapsed);
		updateOcclusionFade(elapsed);
		updateWaveFlicker(elapsed);
		updateGoodJob(elapsed);

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

		updateAlert(elapsed);

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
			}
			else
			{
				var age = BANNER_TIME - bannerTimer;
				if (age < BANNER_IN)
				{
					var p = age / BANNER_IN;
					bannerText.alpha = p < 0.5 ? p * 2 : 1;
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

	public function setBossOcclusion(enemies:Array<Enemies>, camera:FlxCamera):Void
	{
		bossOccluded = false;
		if (!hudOn || enemies == null || camera == null)
			return;

		var left = hpFrame.x;
		var top = hpFrame.y;
		var right = hpFrame.x + hpFrame.width;
		var bottom = hpFrame.y + hpFrame.height;
		if (ammoFrame.visible)
		{
			left = Math.min(left, ammoFrame.x);
			top = Math.min(top, ammoFrame.y);
			right = Math.max(right, ammoFrame.x + ammoFrame.width);
			bottom = Math.max(bottom, ammoFrame.y + ammoFrame.height);
		}

		for (enemy in enemies)
		{
			if (enemy == null || !enemy.exists || !enemy.visible || enemy.isDead)
				continue;
			if (!enemy.bossBody)
				continue;
			enemy.getViewPosition(camera, cursorPoint);
			var enemyLeft = cursorPoint.x - OCCLUSION_PAD;
			var enemyTop = cursorPoint.y - OCCLUSION_PAD;
			var enemyRight = cursorPoint.x + enemy.width * camera.zoom + OCCLUSION_PAD;
			var enemyBottom = cursorPoint.y + enemy.height * camera.zoom + OCCLUSION_PAD;
			if (enemyRight > left && enemyLeft < right && enemyBottom > top && enemyTop < bottom)
			{
				bossOccluded = true;
				return;
			}
		}
	}

	function updateOcclusionFade(elapsed:Float):Void
	{
		var target = bossOccluded ? OCCLUDED_ALPHA : 1;
		var step = OCCLUSION_FADE_SPEED * elapsed;
		if (clusterAlpha < target)
			clusterAlpha = Math.min(target, clusterAlpha + step);
		else if (clusterAlpha > target)
			clusterAlpha = Math.max(target, clusterAlpha - step);
		for (piece in fadingPieces)
			piece.alpha = clusterAlpha;
		if (hpFlash.visible)
			hpFlash.alpha *= clusterAlpha;
	}

	public function slideDisplayIn():Void
	{
		if (displayEntered)
			return;
		displayEntered = true;
		displayEntering = true;
		displayClock = 0;
		FlxG.sound.play(Paths.sound(DISPLAY_SOUND), DISPLAY_VOL);
	}

	function updateDisplay(elapsed:Float):Void
	{
		if (!displayEntering)
			return;
		displayClock += elapsed;
		var p = displayClock / DISPLAY_IN_TIME;
		if (p >= 1)
		{
			p = 1;
			displayEntering = false;
		}
		var left = 1 - p;
		displayOffset = displayStartOffset * left * left * left;
		layoutDisplay();
	}

	function layoutDisplay():Void
	{
		displayPanel.x = displayRestX + displayOffset;
		displayTicks.x = displayPanel.x + TICK_X * DISPLAY_SCALE;
		bossBarBack.x = displayPanel.x + BOSS_BAR_X * DISPLAY_SCALE;
		bossBarFill.x = bossBarBack.x;
		waveText.x = displayPanel.x + WAVE_X * DISPLAY_SCALE;
		goodJob.setPosition(displayPanel.x + GOOD_JOB_X * DISPLAY_SCALE,
			DISPLAY_TOP + GOOD_JOB_Y * DISPLAY_SCALE);
		layoutScrap();
	}

	static function slideTo(shown:Float, target:Float, elapsed:Float):Float
	{
		if (shown < 0)
			return target;
		var k = 1 - Math.pow(1 - BAR_SLIDE, elapsed * 60);
		var next = shown + (target - shown) * k;
		return Math.abs(target - next) < BAR_SETTLE ? target : next;
	}

	function updateHealth(elapsed:Float):Void
	{
		var pct = status.healthMax > 0 ? status.health / status.healthMax : 0;
		if (pct < 0)
			pct = 0;
		if (pct > 1)
			pct = 1;
		hpShown = slideTo(hpShown, pct, elapsed);
		var w = Math.round(hpFill.frameWidth * hpShown);
		if (w == hpWidth)
			return;
		hpWidth = w;
		hpClip.width = w;
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
		superShown = slideTo(superShown, pct, elapsed);
		var w = Math.round(superFill.frameWidth * superShown);
		if (w != superWidth)
		{
			superWidth = w;
			superClip.width = w;
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
		t.setFormat(Lang.bodyFont(), Lang.bodySize(), shade ? FlxColor.BLACK : FlxColor.WHITE, LEFT);
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
		var top = DISPLAY_TOP + SCRAP_Y * DISPLAY_SCALE;
		scrapIcon.setPosition(displayPanel.x + SCRAP_X * DISPLAY_SCALE - SCRAP_LEFT, top + (rowH - scrapIcon.height) * 0.5);
		expText.setPosition(scrapIcon.x - SCRAP_GAP - expText.width, top + (rowH - expText.height) * 0.5);
		expShade.setPosition(expText.x + SCRAP_DROP, expText.y + SCRAP_DROP);
		scrapIconShade.setPosition(scrapIcon.x + SCRAP_DROP, scrapIcon.y + SCRAP_DROP);
	}

	public function showWave(n:Int):Void
	{
		waveCleared = false;
		goodJobDelay = 0;
		goodJob.visible = false;
		waveText.visible = hudOn;
		setBossBar(false);
		applyDisplayMode();
		waveLabel = Lang.t("hud.wave", [n]);
		setDisplayLabel(waveLabel, true);
	}

	public function showWaveCleared():Void
	{
		waveCleared = true;
		goodJobDelay = GOOD_JOB_DELAY;
		goodJob.visible = false;
		waveText.visible = false;
		applyDisplayMode();
	}

	function updateGoodJob(elapsed:Float):Void
	{
		if (!waveCleared || goodJobDelay <= 0)
			return;
		goodJobDelay -= elapsed;
		if (goodJobDelay > 0)
			return;
		goodJobDelay = 0;
		goodJob.visible = hudOn;
		goodJob.animation.play("pulse", true);
	}

	public function setDisplayLabel(text:String, playSound:Bool = false):Void
	{
		if (waveText.text == text)
			return;
		waveFlicker = WAVE_FLICKER_TIME;
		waveText.text = text;
		fitDisplayLabel();
		if (playSound)
		{
			FlxG.sound.play(Paths.sound(WAVE_FLICKER_SOUND), WAVE_FLICKER_VOLUME);
		}
	}

	public function showWaveLabel():Void
	{
		setBossBar(false);
		setDisplayLabel(waveLabel);
	}

	public function showBossLabel(title:String):Void
	{
		setBossBar(true);
		setDisplayLabel(title);
	}

	function setBossBar(on:Bool):Void
	{
		if (bossBarOn == on)
			return;
		bossBarOn = on;
		tickShown = -1;
		bossBarShown = -1;
		applyDisplayMode();
	}

	function applyDisplayMode():Void
	{
		waveText.visible = hudOn && !bossBarOn && !waveCleared;
		displayTicks.visible = hudOn && !bossBarOn && !waveCleared;
		bossBarBack.visible = hudOn && bossBarOn && !waveCleared;
		bossBarFill.visible = hudOn && bossBarOn && !waveCleared;
	}

	function fitDisplayLabel():Void
	{
		var size = Lang.smallSize();
		waveText.size = size;
		var room = WAVE_W * DISPLAY_SCALE - WAVE_PAD;
		while (waveText.textField.textWidth > room && size > WAVE_SIZE_MIN)
		{
			size--;
			waveText.size = size;
		}
	}

	function updateWaveFlicker(elapsed:Float):Void
	{
		if (waveFlicker <= 0)
			return;
		waveFlicker -= elapsed;
		if (waveFlicker <= 0)
		{
			waveFlicker = 0;
			waveText.alpha = 1;
			return;
		}
		var run = (1 - waveFlicker / WAVE_FLICKER_TIME) * WAVE_FLICKER_BLINKS * 2;
		waveText.alpha = Std.int(run) % 2 == 0 ? WAVE_FLICKER_DIM : 1;
	}

	public function showBoss():Void
	{
		bossHud.beginEncounter();
		bossWarning.visible = hudOn;
		bossWarning.alpha = 1;
		bossWarning.animation.play("in", true);
		alertTimer = ALERT_TIME;
		layoutBossWarning();
		state.remove(bossWarning, true);
		state.add(bossWarning);
		raiseCursor();
		bossHud.startFlash();
	}

	function updateAlert(elapsed:Float):Void
	{
		if (alertTimer <= 0)
			return;
		alertTimer -= elapsed;
		if (alertTimer <= 0)
		{
			alertTimer = 0;
			bossWarning.visible = false;
			return;
		}
		if (alertTimer <= ALERT_OUT && bossWarning.animation.name != "out")
			bossWarning.animation.play("out", true);
		layoutBossWarning();
	}

	function layoutBossWarning():Void
	{
		bossWarning.setPosition((FlxG.width - bossWarning.width) * 0.5,
			(FlxG.height - bossWarning.height) * 0.5 + ALERT_LIFT);
	}

	public function trackBosses(pack:Array<Enemies>):Void
	{
		bossHud.track(pack);
	}

	public function bossTitle():String
		return bossHud.bossName();

	public function fadeBanner():Void
	{
		bannerTimer = 0;
		bannerFading = true;
		bannerFadeTimer = BOSS_BANNER_FADE;
	}

	public function showBanner(text:String):Void
	{
		bannerFading = false;
		bannerFadeTimer = 0;
		bannerText.y = 48;
		bannerText.text = text;
		bannerText.visible = hudOn;
		bannerText.alpha = 0;
		bannerText.scale.set(1, 1);
		bannerText.angle = 0;
		bannerTimer = BANNER_TIME;
		raiseBanner();
	}

	public function raiseCursor():Void
	{
		state.remove(customCursor, true);
		state.add(customCursor);
	}

	public function setCursorOverUi(on:Bool):Void
	{
		customCursor.visible = !on;
		FlxG.mouse.visible = on;
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
		ammoFrame.visible = false;
		tubeOwner = null;
		for (p in ammoPips)
			p.visible = false;
		capTop.visible = false;
		capBottom.visible = false;
		arrowPip.visible = false;
		for (p in bulletPips)
			p.visible = false;
		bulletsShown = -1;
	}

	public function setAmmo(cur:Int, max:Int, reloading:Bool, shown:Bool):Void
	{
		setTubeAmmo(cur, max, "ammo_bullet", shown && hudOn);
	}

	public function setBowLoaded(loaded:Bool, shown:Bool):Void
	{
		setTubeAmmo(loaded ? 1 : 0, 1, "ammo_arrow", shown && hudOn);
	}

	public function showDeath(wave:Int, best:Int):Void
	{
		deadText.text = Lang.t("hud.death", [wave, best]);
		deadText.visible = hudOn;
	}

	public function showRespawn(wave:Int):Void
	{
		deadText.text = Lang.t("hud.respawning", [wave]);
		deadText.visible = hudOn;
	}

	public function hideDeath():Void
	{
		deadText.visible = false;
	}

	static var AS_DRAWN:Array<String> = [
		"ammo_bullet", "ammo_bullet_empty", "ammo_arrow", "ammo_arrow_empty", "ammo_indicator"
	];

	function uiArt(name:String):flixel.graphics.FlxGraphic
		return util.HuePalette.graphic("ui/" + name, AS_DRAWN.indexOf(name) >= 0 ? 0 : hue);

	function skin(s:FlxSprite, name:String):Void
	{
		art.set(s, name);
		s.loadGraphic(uiArt(name));
	}

	function paintBossAlert():Void
	{
		var was = bossWarning.animation.name;
		var at = bossWarning.animation.frameIndex;
		bossWarning.loadGraphic(uiArt("boss_alert"), true, ALERT_W, ALERT_H);
		bossWarning.animation.add("in", [0, 1, 2, 3, 4], ALERT_FPS, false);
		bossWarning.animation.add("hold", [5, 6], ALERT_HOLD_FPS, true);
		bossWarning.animation.add("out", [4, 3, 2, 1, 0], ALERT_FPS, false);
		bossWarning.antialiasing = false;
		bossWarning.scale.set(ALERT_SCALE, ALERT_SCALE);
		bossWarning.updateHitbox();
		layoutBossWarning();
		if (was != null)
			bossWarning.animation.play(was, true, false, at);
	}

	function paintGoodJob():Void
	{
		var was = goodJob.animation.name;
		var at = goodJob.animation.frameIndex;
		var x = goodJob.x;
		var y = goodJob.y;
		goodJob.loadGraphic(uiArt("good_job_display"), true, GOOD_JOB_W, GOOD_JOB_H);
		goodJob.animation.add("pulse", [0, 1], GOOD_JOB_FPS, true);
		goodJob.antialiasing = false;
		goodJob.scale.set(DISPLAY_SCALE, DISPLAY_SCALE);
		goodJob.updateHitbox();
		goodJob.setPosition(x, y);
		if (was != null)
			goodJob.animation.play(was, true, false, at);
	}

	function makeSprite(x:Float, y:Float, name:String):FlxSprite
	{
		var s = new FlxSprite(x, y);
		skin(s, name);
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

	function layoutPips(frameX:Float, frameY:Float):Void
	{
		pipX = frameX + TUBE_X * HP_SCALE;
		pipTop = frameY + TUBE_TOP * HP_SCALE;
	}

	function setTubeAmmo(rounds:Int, capacity:Int, kind:String, on:Bool):Void
	{
		if (!on)
		{
			if (tubeOwner != kind)
				return;
			tubeOwner = null;
			ammoFrame.visible = false;
			rounds = 0;
			capacity = 0;
		}
		else
		{
			tubeOwner = kind;
			ammoFrame.visible = true;
		}

		var shown = capacity < 0 ? 0 : (capacity > MAX_PIPS ? MAX_PIPS : capacity);
		var arrow = kind == "ammo_arrow";
		var span = (TUBE_BOTTOM - TUBE_TOP) * HP_SCALE;
		var mid = pipX + TUBE_W * HP_SCALE * 0.5;
		for (i in 0...ammoPips.length)
		{
			var pip = ammoPips[i];
			if (i >= shown)
			{
				pip.visible = false;
				continue;
			}
			var want = i < rounds ? kind : kind + "_empty";
			if (art.get(pip) != want)
			{
				reskin(pip, want);
				pip.scale.set(HP_SCALE, HP_SCALE);
				pip.updateHitbox();
			}
			pip.angle = arrow ? ARROW_ANGLE : 0;
			var step = Math.min((arrow ? pip.width : pip.height) + PIP_GAP, span / shown);
			var base = arrow ? pipTop + ARROW_TOP_OFFSET + (pip.width - pip.height) * 0.5 : pipTop + (span - step * shown) * 0.5;
			pip.setPosition(mid - pip.width * 0.5 - (arrow ? ARROW_LEFT_OFFSET : 0), base + (shown - 1 - i) * step);
			pip.visible = true;
		}
	}

	static function ticksFor(filled:Float, keepPartial:Bool):Int
	{
		if (filled < 0)
			filled = 0;
		if (filled > 1)
			filled = 1;
		return keepPartial ? Math.ceil(filled * TICK_COUNT) : Math.round(filled * TICK_COUNT);
	}

	public function setTicks(filled:Float, keepPartial:Bool = false):Void
	{
		if (bossBarOn)
		{
			var span = filled < 0 ? 0 : (filled > 1 ? 1 : filled);
			var w = Math.round(span * bossBarFill.frameWidth);
			if (w == bossBarShown)
				return;
			bossBarShown = w;
			bossBarClip.width = w;
			bossBarFill.clipRect = bossBarClip;
			return;
		}

		var n = ticksFor(filled, keepPartial);
		if (n == tickShown)
			return;
		tickShown = n;
		tickClip.width = TICK_EDGE[tickShown];
		displayTicks.clipRect = tickClip;
	}

	public function bossFraction():Float
		return bossHud.fraction();

	function makeSlotBack(fill:FlxSprite, name:String, solid:Bool = false):FlxSprite
	{
		var s = new FlxSprite(fill.x, fill.y);
		if (solid)
			s.makeGraphic(fill.frameWidth, fill.frameHeight, FlxColor.BLACK);
		else
		{
			s.loadGraphic(Paths.image("ui/" + name));
			s.color = FlxColor.BLACK;
		}
		s.antialiasing = false;
		s.scale.set(fill.scale.x, fill.scale.y);
		s.cameras = [camUI];
		s.updateHitbox();
		s.setPosition(fill.x, fill.y);
		return s;
	}

	function makeHpSprite(x:Float, y:Float, name:String):FlxSprite
	{
		var s = makeSprite(x, y, name);
		s.scale.set(HP_SCALE, HP_SCALE);
		s.updateHitbox();
		s.setPosition(x, y);
		return s;
	}

	function reskin(s:FlxSprite, name:String):Void
	{
		skin(s, name);
		s.antialiasing = false;
		s.scale.set(UI_SCALE, UI_SCALE);
		s.updateHitbox();
	}

	public function repaint():Void
	{
		var h = util.SaveData.playerHue();
		if (h == hue)
			return;
		hue = h;
		for (s in art.keys())
		{
			var at = flixel.math.FlxPoint.get(s.x, s.y);
			s.loadGraphic(uiArt(art.get(s)));
			s.updateHitbox();
			s.setPosition(at.x, at.y);
			at.put();
		}
		paintGoodJob();
		paintBossAlert();
		hpWidth = -1;
		superWidth = -1;
		bossBarShown = -1;
	}

	public function applyLanguage(wave:Int):Void
	{
		waveText.font = Lang.smallFont();
		timeText.font = Lang.smallFont();
		for (t in [expText, expShade, bannerText, deadText])
			t.font = Lang.bodyFont();
		layoutScrap();
		waveText.text = Lang.t("hud.wave", [wave]);
	}

	function makeText(y:Float, size:Int):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, "");
		t.setFormat(Lang.fontFor(size), size, FlxColor.WHITE, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		t.cameras = [camUI];
		state.add(piece(t));
		return t;
	}

}
