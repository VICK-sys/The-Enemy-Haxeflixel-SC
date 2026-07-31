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
	static inline var PANEL_H:Int = 40;
	static inline var MIN_W:Int = 92;
	static inline var FONT_SIZE:Int = 16;
	static inline var GOLD:Int = 0xE8C860;
	static inline var UNLIT:Int = 0x2E2E2E;
	static inline var BG:Int = 0xE0000000;
	static inline var IN_TIME:Float = 0.28;
	static inline var OUT_TIME:Float = 0.22;
	static inline var POP_TIME:Float = 0.18;
	static inline var POP_STAGGER:Float = 0.016;
	static inline var FLASH_TIME:Float = 0.3;
	static inline var BLIP_VOL:Float = 0.5;

	static inline var HIDDEN:Int = 0;
	static inline var SLIDE_IN:Int = 1;
	static inline var HOLD:Int = 2;
	static inline var SLIDE_OUT:Int = 3;

	var panel:Bitmap;
	var text:TextField;
	var meter:Array<Bitmap> = [];
	var barClock:Array<Float> = [];
	var lit:Int = 0;
	var flashClock:Float = 999;
	var phase:Int = HIDDEN;
	var phaseClock:Float = 0;
	var inFrom:Float = 0;
	var panelW:Int = MIN_W;
	var fontCache:Map<String, String> = new Map();

	public function new()
	{
		super();
		removeChildren();

		volumeUpSound = util.Paths.sound("menu/scroll_up");
		volumeDownSound = util.Paths.sound("menu/scroll_down");

		panel = new Bitmap();
		addChild(panel);

		text = new TextField();
		text.selectable = false;
		text.mouseEnabled = false;
		text.y = PAD_TOP + 14;
		text.height = 22;
		addChild(text);

		for (i in 0...BAR_COUNT)
		{
			var bar = new Bitmap(new BitmapData(BAR_W, BAR_BASE_H + i, false, 0xFFFFFFFF));
			addChild(bar);
			meter.push(bar);
			barClock.push(999);
		}

		rebuild("MASTER  100%");
		y = -height;
		visible = false;
	}

	override public function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, label = "VOLUME"):Void
	{
		if (sound != null)
			FlxG.sound.play(sound, BLIP_VOL);

		_timer = duration;
		var muted = FlxG.sound.muted;
		lit = muted ? 0 : Math.round(volume * 10);
		rebuild(muted ? word("tray.muted", "MUTED") : word("tray.master", "MASTER") + "  " + Math.round(volume * 100) + "%");

		for (i in 0...BAR_COUNT)
			barClock[i] = i < lit ? -i * POP_STAGGER : 999;
		flashClock = 0;

		inFrom = visible ? y : -height;
		phase = SLIDE_IN;
		phaseClock = 0;
		visible = true;
		active = true;
		alpha = 1;
	}

	override public function update(MS:Float):Void
	{
		var dt = MS / 1000;
		phaseClock += dt;
		flashClock += dt;

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
				alpha = Math.min(1, u * 3);
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
		if (i >= lit)
		{
			bar.visible = true;
			bar.scaleY = 1;
			bar.y = PAD_TOP + 12 - bar.bitmapData.height;
			tint(bar, UNLIT);
			return;
		}
		if (t < 0)
		{
			bar.visible = false;
			return;
		}
		bar.visible = true;
		var k = t >= POP_TIME ? 1.0 : backOut(t / POP_TIME);
		bar.scaleY = k;
		bar.y = PAD_TOP + 12 - bar.bitmapData.height * k;
		if (i == lit - 1 && flashClock < FLASH_TIME)
			tintLerp(bar, 0xFFFFFF, GOLD, flashClock / FLASH_TIME);
		else
			tint(bar, GOLD);
	}

	function rebuild(label:String):Void
	{
		text.defaultTextFormat = format();
		text.text = label;

		var w = Std.int(text.textWidth) + 24;
		if (w < MIN_W)
			w = MIN_W;
		if (w != panelW || panel.bitmapData == null)
		{
			panelW = w;
			if (panel.bitmapData != null)
				panel.bitmapData.dispose();
			var bd = new BitmapData(panelW, PANEL_H, true, BG);
			bd.fillRect(new openfl.geom.Rectangle(0, PANEL_H - 2, panelW, 2), 0xFF000000 | GOLD);
			panel.bitmapData = bd;
		}
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
		var fmt = new TextFormat(fontName(util.Lang.display()), FONT_SIZE, 0xFFFFFF);
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
