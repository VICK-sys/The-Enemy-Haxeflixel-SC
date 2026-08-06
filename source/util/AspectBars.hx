package util;

import flixel.FlxG;
import flixel.system.scaleModes.BaseScaleMode;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.utils.Assets;

class AspectBars
{
	public static var bars(default, null):Int = 0;
	public static var mode(default, null):BoxedScaleMode;
	public static var resizeCount(default, null):Int = 0;

	static inline var FILL:Int = 0x0A0A0C;
	static inline var EDGE:Int = 0x2A2A30;
	static inline var ART:String = "ui/side_art";

	static var holder:Sprite;
	static var art:BitmapData;
	static var lastW:Int = -1;
	static var lastH:Int = -1;
	static var lastX:Int = -99999;
	static var lastY:Int = -99999;

	public static function init(parent:DisplayObjectContainer):Void
	{
		mode = new BoxedScaleMode();
		holder = new Sprite();
		holder.mouseEnabled = false;
		holder.mouseChildren = false;
		parent.addChild(holder);
		if (Assets.exists(Paths.image(ART)))
			art = Assets.getBitmapData(Paths.image(ART));
		Lib.current.stage.addEventListener(Event.RESIZE, function(_) apply());
		FlxG.signals.postUpdate.add(watch);
	}

	static function watch():Void
	{
		#if desktop
		var win = lime.app.Application.current.window;
		if (win.x != lastX || win.y != lastY)
		{
			lastX = win.x;
			lastY = win.y;
			resizeCount++;
		}
		#end

		var stage = Lib.current.stage;
		if (stage.stageWidth == lastW && stage.stageHeight == lastH)
			return;
		lastW = stage.stageWidth;
		lastH = stage.stageHeight;
		resizeCount++;
		apply();
	}

	public static function ratioOf(name:String):Float
	{
		return switch (name)
		{
			case "4:3": 4 / 3;
			case "16:9": 16 / 9;
			case "16:10": 16 / 10;
			case "21:9": 21 / 9;
			default: 0;
		}
	}

	public static function apply():Void
	{
		if (holder == null || FlxG.game == null || FlxG.stage == null)
			return;

		mode.ratio = ratioOf(SaveData.aspect());
		FlxG.scaleMode = mode;

		holder.graphics.clear();
		bars = 0;

		var stage = Lib.current.stage;
		var sw:Float = stage.stageWidth;
		var sh:Float = stage.stageHeight;
		var gx = mode.offset.x;
		var gy = mode.offset.y;
		var gw = mode.gameSize.x;
		var gh = mode.gameSize.y;
		if (gw <= 0 || gh <= 0)
			return;

		if (gx >= 1)
		{
			paint(0, 0, gx, sh, false);
			paint(gx + gw, 0, sw - gx - gw, sh, true);
		}
		if (gy >= 1)
		{
			paint(gx, 0, gw, gy, false);
			paint(gx, gy + gh, gw, sh - gy - gh, true);
		}
	}

	static function paint(x:Float, y:Float, w:Float, h:Float, far:Bool):Void
	{
		if (w < 1 || h < 1)
			return;
		var g = holder.graphics;
		if (art != null)
		{
			var m = new Matrix();
			var s = w > h ? h / art.height : w / art.width;
			if (s < 1)
				s = 1;
			m.scale(s, s);
			m.translate(x, y);
			g.beginBitmapFill(art, m, true, false);
		}
		else
			g.beginFill(FILL);
		g.drawRect(x, y, w, h);
		g.endFill();

		g.beginFill(EDGE);
		if (w < h)
			g.drawRect(far ? x : x + w - 2, y, 2, h);
		else
			g.drawRect(x, far ? y : y + h - 2, w, 2);
		g.endFill();

		bars++;
	}
}

class BoxedScaleMode extends BaseScaleMode
{
	public var ratio:Float = 0;

	override function updateGameSize(width:Int, height:Int):Void
	{
		var w:Float = width;
		var h:Float = height;

		if (ratio > 0)
		{
			if (w / h > ratio)
				w = h * ratio;
			else
				h = w / ratio;
		}

		var game:Float = FlxG.initialWidth / FlxG.initialHeight;
		if (w / h > game)
			w = h * game;
		else
			h = w / game;

		gameSize.set(Math.floor(w), Math.floor(h));
	}
}
