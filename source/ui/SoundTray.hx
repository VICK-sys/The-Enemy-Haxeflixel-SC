package ui;

import flixel.FlxG;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.ui.FlxSoundTray;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;

class SoundTray extends FlxSoundTray
{
	static inline var BAR_COUNT:Int = 10;
	static inline var BAR_W:Int = 5;
	static inline var BAR_GAP:Int = 2;
	static inline var BAR_BASE_H:Int = 3;
	static inline var PAD_TOP:Int = 5;
	static inline var PANEL_H:Int = 48;
	static inline var TEXT_BASELINE:Int = 38;
	static inline var TEXT_PAD:Int = 4;
	static inline var MIN_W:Int = 92;
	static inline var QUIET:Int = 0x5FD16A;
	static inline var MID:Int = 0xE8C860;
	static inline var LOUD:Int = 0xF04034;
	static inline var UNLIT:Int = 0x2E2E2E;
	static inline var BG:Int = 0xE0000000;
	static inline var IN_TIME:Float = 0.28;
	static inline var OUT_TIME:Float = 0.22;
	static inline var POP_TIME:Float = 0.18;
	static inline var POP_STAGGER:Float = 0.016;
	static inline var FLASH_TIME:Float = 0.3;
	static inline var DROP_TIME:Float = 0.22;
	static inline var DROP_DIP:Float = 0.45;
	static inline var SETTLED:Float = 999;
	static inline var TONE_TIME:Float = 0.3;
	static inline var BLIP_VOL:Float = 0.5;

	static inline var MASTER:Int = 0;
	static inline var SOUND:Int = 1;
	static inline var MUSIC:Int = 2;
	static inline var CHANNELS:Int = 3;
	static inline var STEP:Float = 0.1;

	static inline var HIDDEN:Int = 0;
	static inline var SLIDE_IN:Int = 1;
	static inline var HOLD:Int = 2;
	static inline var SLIDE_OUT:Int = 3;

	var panel:Bitmap;
	var accent:Bitmap;
	var text:TextField;
	var meter:Array<Bitmap> = [];
	var barClock:Array<Float> = [];
	var lit:Int = 0;
	var tone:Int = MID;
	var toneFrom:Int = MID;
	var toneClock:Float = TONE_TIME;
	var shown:Int = MID;
	var phase:Int = HIDDEN;
	var phaseClock:Float = 0;
	var inFrom:Float = 0;
	var alphaFrom:Float = 0;
	var panelW:Int = MIN_W;
	var channel:Int = MASTER;
	var fontCache:Map<String, String> = new Map();

	public function new()
	{
		super();
		removeChildren();

		volumeUpSound = util.Paths.sound("menu/scroll_up");
		volumeDownSound = util.Paths.sound("menu/scroll_down");

		panel = new Bitmap();
		addChild(panel);

		accent = new Bitmap(new BitmapData(1, 1, false, 0xFFFFFF));
		accent.height = 2;
		accent.y = PANEL_H - 2;
		addChild(accent);

		text = new TextField();
		text.selectable = false;
		text.mouseEnabled = false;
		addChild(text);

		for (i in 0...BAR_COUNT)
		{
			var bar = new Bitmap(new BitmapData(BAR_W, BAR_BASE_H + i, false, 0xFFFFFFFF));
			addChild(bar);
			meter.push(bar);
			barClock.push(SETTLED);
		}

		rebuild(word("tray.master", "MASTER") + "  100%");
		y = -height;
		visible = false;
	}

	public function listen():Void
	{
		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		FlxG.signals.postUpdate.add(readKeys);
	}

	function readKeys():Void
	{
		if (util.Controls.typing)
			return;

		if (FlxG.keys.justPressed.COMMA)
			turn(-1);
		else if (FlxG.keys.justPressed.PERIOD)
			turn(1);

		if (FlxG.keys.justPressed.PLUS || FlxG.keys.justPressed.NUMPADPLUS)
			nudge(STEP);
		else if (FlxG.keys.justPressed.MINUS || FlxG.keys.justPressed.NUMPADMINUS)
			nudge(-STEP);
	}

	function turn(dir:Int):Void
	{
		channel = (channel + dir + CHANNELS) % CHANNELS;
		showAnim(level(), volumeUpSound);
	}

	function nudge(delta:Float):Void
	{
		var v = level() + delta;
		if (v < 0)
			v = 0;
		if (v > 1)
			v = 1;
		switch (channel)
		{
			case SOUND: util.SaveData.setSfxVolume(v);
			case MUSIC: util.SaveData.setMusicVolume(v);
			default: util.SaveData.setVolume(v);
		}
		util.SaveData.applySettings();
		showAnim(v, delta > 0 ? volumeUpSound : volumeDownSound);
	}

	function level():Float
	{
		return switch (channel)
		{
			case SOUND: util.SaveData.sfxVolume();
			case MUSIC: util.SaveData.musicVolume();
			default: util.SaveData.volume();
		}
	}

	function channelName():String
	{
		return switch (channel)
		{
			case SOUND: word("tray.sound", "SOUND");
			case MUSIC: word("tray.music", "MUSIC");
			default: word("tray.master", "MASTER");
		}
	}

	override public function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, label = "VOLUME"):Void
	{
		if (sound != null)
			FlxG.sound.play(sound, BLIP_VOL);

		_timer = duration;
		var held = visible && (phase == SLIDE_IN || phase == HOLD);
		var was = held ? lit : 0;
		var muted = FlxG.sound.muted;
		lit = muted ? 0 : Math.round(volume * 10);
		var target = muted ? UNLIT : levelColor(lit / BAR_COUNT);
		toneFrom = held ? shown : target;
		tone = target;
		toneClock = 0;
		advanceTone(0);
		rebuild(muted ? word("tray.muted", "MUTED") : channelName() + "  " + Math.round(volume * 100) + "%");
		retimeBars(was);

		if (!held)
		{
			inFrom = visible ? y : -height;
			alphaFrom = visible ? alpha : 0;
			phase = SLIDE_IN;
			phaseClock = 0;
		}
		visible = true;
		active = true;
	}

	function advanceTone(dt:Float):Void
	{
		toneClock += dt;
		if (toneClock >= TONE_TIME)
		{
			shown = tone;
			return;
		}
		var u = toneClock / TONE_TIME;
		shown = mix(toneFrom, tone, u * u * (3 - 2 * u));
	}

	function retimeBars(was:Int):Void
	{
		for (i in 0...BAR_COUNT)
		{
			if (i >= was && i < lit)
				barClock[i] = -(i - was) * POP_STAGGER;
			else if (i >= lit && i < was)
				barClock[i] = -(was - 1 - i) * POP_STAGGER;
			else
				barClock[i] = SETTLED;
		}
	}

	override public function update(MS:Float):Void
	{
		var dt = MS / 1000;
		phaseClock += dt;

		switch (phase)
		{
			case SLIDE_IN:
				var u = phaseClock / IN_TIME;
				if (u >= 1)
				{
					u = 1;
					phase = HOLD;
				}
				y = inFrom + (0 - inFrom) * backOut(u);
				alpha = alphaFrom + (1 - alphaFrom) * Math.min(1, u * 3);
			case HOLD:
				_timer -= dt;
				y = 0;
				if (_timer <= 0)
				{
					phase = SLIDE_OUT;
					phaseClock = 0;
				}
			case SLIDE_OUT:
				var u = phaseClock / OUT_TIME;
				if (u >= 1)
				{
					phase = HIDDEN;
					visible = false;
					active = false;
					y = -height;
					return;
				}
				y = -height * u * u;
				alpha = 1 - u;
			default:
		}

		advanceTone(dt);
		tint(accent, shown);

		for (i in 0...BAR_COUNT)
		{
			barClock[i] += dt;
			styleBar(i);
		}
	}

	override public function screenCenter():Void
	{
		var s = _defaultScale;
		var area:Float = Lib.current.stage.stageWidth;
		if (FlxG.scaleMode != null && FlxG.scaleMode.scale.x > 0)
		{
			s = _defaultScale * FlxG.scaleMode.scale.x;
			area = FlxG.scaleMode.gameSize.x;
		}
		scaleX = s;
		scaleY = s;
		x = 0.5 * (area - panelW * s);
	}

	function styleBar(i:Int):Void
	{
		var bar = meter[i];
		var t = barClock[i];
		bar.visible = true;

		if (i < lit)
		{
			if (t < 0)
			{
				bar.visible = false;
				return;
			}
			sizeBar(bar, t >= POP_TIME ? 1.0 : backOut(t / POP_TIME));
			if (t < FLASH_TIME)
				tintLerp(bar, 0xFFFFFF, shown, t / FLASH_TIME);
			else
				tint(bar, shown);
			return;
		}

		if (t < 0)
		{
			sizeBar(bar, 1);
			tint(bar, shown);
			return;
		}
		if (t < DROP_TIME)
		{
			var u = t / DROP_TIME;
			sizeBar(bar, 1 - DROP_DIP * Math.sin(Math.PI * u));
			tintLerp(bar, shown, UNLIT, u);
			return;
		}
		sizeBar(bar, 1);
		tint(bar, UNLIT);
	}

	inline function sizeBar(bar:Bitmap, k:Float):Void
	{
		bar.scaleY = k;
		bar.y = PAD_TOP + 12 - bar.bitmapData.height * k;
	}

	function rebuild(label:String):Void
	{
		text.defaultTextFormat = format();
		text.text = word("tray.master", "MASTER") + "  100%";
		var w = Std.int(text.textWidth) + 24;
		text.text = label;
		var metrics = text.getLineMetrics(0);
		text.height = metrics.height + TEXT_PAD;
		text.y = TEXT_BASELINE - metrics.ascent;
		if (w < MIN_W)
			w = MIN_W;
		if (w != panelW || panel.bitmapData == null)
		{
			panelW = w;
			if (panel.bitmapData != null)
				panel.bitmapData.dispose();
			panel.bitmapData = new BitmapData(panelW, PANEL_H, true, BG);
			accent.width = panelW;
		}
		tint(accent, shown);
		text.width = panelW;
		text.x = 0;

		var barsW = BAR_COUNT * (BAR_W + BAR_GAP) - BAR_GAP;
		var bx = Std.int((panelW - barsW) / 2);
		for (i in 0...BAR_COUNT)
		{
			meter[i].x = bx;
			meter[i].y = PAD_TOP + 12 - meter[i].bitmapData.height;
			bx += BAR_W + BAR_GAP;
		}

		screenCenter();
	}

	function format():TextFormat
	{
		var fmt = new TextFormat(fontName(util.Lang.smallFont()), util.Lang.smallSize(), 0xFFFFFF);
		fmt.align = TextFormatAlign.CENTER;
		return fmt;
	}

	function fontName(path:String):String
	{
		var cached = fontCache.get(path);
		if (cached != null)
			return cached;
		var f = Assets.getFont(path);
		var name = f != null ? f.fontName : "_sans";
		fontCache.set(path, name);
		return name;
	}

	static function word(key:String, fallback:String):String
	{
		var s = util.Lang.t(key);
		return s == key ? fallback : s;
	}

	static function levelColor(v:Float):Int
	{
		if (v <= 0.5)
			return mix(QUIET, MID, v * 2);
		return mix(MID, LOUD, (v - 0.5) * 2);
	}

	static function mix(from:Int, to:Int, u:Float):Int
	{
		var r = Math.round(chan(from, 16) + (chan(to, 16) - chan(from, 16)) * u);
		var g = Math.round(chan(from, 8) + (chan(to, 8) - chan(from, 8)) * u);
		var b = Math.round(chan(from, 0) + (chan(to, 0) - chan(from, 0)) * u);
		return (r << 16) | (g << 8) | b;
	}

	static inline function chan(color:Int, shift:Int):Int
		return color >> shift & 0xFF;

	static function tint(bar:Bitmap, color:Int):Void
	{
		var r = (color >> 16 & 0xFF) / 255;
		var g = (color >> 8 & 0xFF) / 255;
		var b = (color & 0xFF) / 255;
		bar.transform.colorTransform = new ColorTransform(r, g, b);
	}

	static function tintLerp(bar:Bitmap, from:Int, to:Int, u:Float):Void
	{
		var r = lerpChan(from >> 16 & 0xFF, to >> 16 & 0xFF, u);
		var g = lerpChan(from >> 8 & 0xFF, to >> 8 & 0xFF, u);
		var b = lerpChan(from & 0xFF, to & 0xFF, u);
		bar.transform.colorTransform = new ColorTransform(r, g, b);
	}

	static function lerpChan(a:Int, b:Int, u:Float):Float
		return (a + (b - a) * u) / 255;

	static function backOut(u:Float):Float
	{
		var c1 = 1.70158;
		var c3 = c1 + 1;
		var v = u - 1;
		return 1 + c3 * v * v * v + c1 * v * v;
	}
}
