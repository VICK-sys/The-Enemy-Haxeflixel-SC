package util;

import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectContainer;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

class ShotCard
{
	static inline var IDLE:Int = 0;
	static inline var FLASH_WAIT:Int = 1;
	static inline var FILE_WAIT:Int = 2;
	static inline var SLIDE_IN:Int = 3;
	static inline var HOLD:Int = 4;
	static inline var SLIDE_OUT:Int = 5;

	static inline var CARD_W:Float = 170;
	static inline var CARD_H:Float = 120;
	static inline var MARGIN:Float = 12;
	static inline var OFF_DROP:Float = 20;
	static inline var THUMB_PAD:Float = 6;
	static inline var LABEL_X:Float = 10;
	static inline var LABEL_UP:Float = 9;

	static inline var FLASH_ALPHA:Float = 160 / 255;
	static inline var FLASH_TIME:Float = 0.08;
	static inline var FLASH_FRAMES:Int = 10;
	static inline var FILE_FRAMES:Int = 5;
	static inline var IN_TIME:Float = 0.3;
	static inline var HOLD_TIME:Float = 2;
	static inline var OUT_TIME:Float = 0.25;
	static inline var BOB_RATE:Float = 4;
	static inline var BOB_AMP:Float = 1.5;

	static inline var SHUTTER:String = "camera";
	static inline var SHUTTER_VOL:Float = 0.7;

	static inline var PLATE:Int = 0xFFFFFF;
	static inline var PLATE_ALPHA:Float = 0.86;
	static inline var EDGE:Int = 0xFFFFFF;
	static inline var LABEL_COLOR:Int = 0x000000;

	static var host:DisplayObjectContainer;
	static var flash:Shape;
	static var card:Sprite;
	static var plate:Shape;
	static var thumb:Bitmap;
	static var label:TextField;

	static var state:Int = IDLE;
	static var waitFrames:Int = 0;
	static var animT:Float = 0;
	static var flashT:Float = 0;
	static var shot:BitmapData;

	public static function attach(parent:DisplayObjectContainer):Void
	{
		host = parent;
		ScreenCapture.onGrab = keepThumb;
		FlxG.signals.postUpdate.add(update);
	}

	public static function request():Void
	{
		if (host == null || state != IDLE)
			return;
		FlxG.sound.play(Paths.sound(SHUTTER), SHUTTER_VOL);
		showFlash();
		state = FLASH_WAIT;
		waitFrames = FLASH_FRAMES;
	}

	static function keepThumb(source:BitmapData):Void
	{
		clearShot();
		var box = fit(source.width, source.height);
		shot = new BitmapData(Std.int(box.x), Std.int(box.y), false, 0xFF000000);
		var mtx = new Matrix();
		mtx.scale(box.x / source.width, box.y / source.height);
		shot.draw(source, mtx, null, null, null, true);
	}

	static function fit(w:Int, h:Int):openfl.geom.Point
	{
		var maxW = (CARD_W - THUMB_PAD * 2) * scale();
		var maxH = (CARD_H - 30) * scale();
		var k = Math.min(maxW / w, maxH / h);
		return new openfl.geom.Point(Math.max(1, Math.round(w * k)), Math.max(1, Math.round(h * k)));
	}

	static function update():Void
	{
		if (flashT > 0)
		{
			flashT -= FlxG.elapsed;
			if (flash != null)
				flash.alpha = flashT <= 0 ? 0 : FLASH_ALPHA * (flashT / FLASH_TIME);
			if (flashT <= 0 && flash != null)
				flash.visible = false;
		}

		if (state == IDLE)
			return;

		var dt = FlxG.elapsed;
		switch (state)
		{
			case FLASH_WAIT:
				if (--waitFrames <= 0)
				{
					ScreenCapture.capture();
					state = FILE_WAIT;
					waitFrames = FILE_FRAMES;
				}
			case FILE_WAIT:
				if (--waitFrames <= 0)
				{
					if (shot == null)
					{
						state = IDLE;
						return;
					}
					build();
					state = SLIDE_IN;
					animT = 0;
				}
			case SLIDE_IN:
				animT += dt / IN_TIME;
				if (animT >= 1)
					animT = 1;
				var t = 1 - (1 - animT) * (1 - animT);
				place(offScreenY() + (targetY() - offScreenY()) * t);
				if (animT >= 1)
				{
					state = HOLD;
					animT = 0;
				}
			case HOLD:
				animT += dt;
				place(targetY() + Math.sin(animT * BOB_RATE) * BOB_AMP * scale());
				if (animT >= HOLD_TIME)
				{
					state = SLIDE_OUT;
					animT = 0;
				}
			case SLIDE_OUT:
				animT += dt / OUT_TIME;
				if (animT >= 1)
					animT = 1;
				var te = animT * animT;
				place(targetY() + (offScreenY() - targetY()) * te);
				if (animT >= 1)
					cleanup();
			default:
		}
	}

	static function showFlash():Void
	{
		var view = ScreenCapture.viewRect();
		if (flash == null)
		{
			flash = new Shape();
			host.addChild(flash);
		}
		flash.graphics.clear();
		flash.graphics.beginFill(0xFFFFFF);
		flash.graphics.drawRect(view.x, view.y, view.width, view.height);
		flash.graphics.endFill();
		flash.alpha = FLASH_ALPHA;
		flash.visible = true;
		flashT = FLASH_TIME;
		host.setChildIndex(flash, host.numChildren - 1);
	}

	static function build():Void
	{
		cleanupDisplay();

		var s = scale();
		var cw = CARD_W * s;
		var ch = CARD_H * s;

		card = new Sprite();

		plate = new Shape();
		plate.graphics.beginFill(EDGE);
		plate.graphics.drawRect(-2, -2, cw + 4, ch + 4);
		plate.graphics.endFill();
		plate.graphics.beginFill(PLATE);
		plate.graphics.drawRect(0, 0, cw, ch);
		plate.graphics.endFill();
		plate.alpha = PLATE_ALPHA;
		card.addChild(plate);

		thumb = new Bitmap(shot);
		thumb.smoothing = true;
		thumb.x = (cw - shot.width) * 0.5;
		thumb.y = THUMB_PAD * s;
		card.addChild(thumb);

		label = new TextField();
		label.selectable = false;
		label.mouseEnabled = false;
		label.defaultTextFormat = new TextFormat(fontName(), Std.int(16 * s), LABEL_COLOR);
		label.text = Lang.t("shot.saved");
		label.width = cw;
		var m = label.getLineMetrics(0);
		label.height = m.height + 4;
		label.x = LABEL_X * s;
		label.y = ch - LABEL_UP * s - m.ascent;
		card.addChild(label);

		host.addChild(card);
		place(offScreenY());
	}

	static function place(y:Float):Void
	{
		if (card == null)
			return;
		var view = ScreenCapture.viewRect();
		card.x = view.x + view.width - CARD_W * scale() - MARGIN * scale();
		card.y = y;
		if (host != null)
			host.setChildIndex(card, host.numChildren - 1);
	}

	static inline function targetY():Float
	{
		var view = ScreenCapture.viewRect();
		return view.y + view.height - CARD_H * scale() - MARGIN * scale();
	}

	static inline function offScreenY():Float
	{
		var view = ScreenCapture.viewRect();
		return view.y + view.height + OFF_DROP * scale();
	}

	static function scale():Float
	{
		var m = FlxG.scaleMode;
		return m != null && m.scale.x > 0 ? m.scale.x : 1;
	}

	static function fontName():String
	{
		var f = Assets.getFont(Lang.smallFont());
		return f != null ? f.fontName : "_sans";
	}

	static function cleanup():Void
	{
		cleanupDisplay();
		clearShot();
		state = IDLE;
	}

	static function cleanupDisplay():Void
	{
		if (card == null)
			return;
		if (host.contains(card))
			host.removeChild(card);
		card = null;
		plate = null;
		thumb = null;
		label = null;
	}

	static function clearShot():Void
	{
		if (shot != null)
		{
			shot.dispose();
			shot = null;
		}
	}
}
