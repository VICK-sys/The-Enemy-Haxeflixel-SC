package util;

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

	static inline var FILL:Int = 0x0A0A0C;
	static inline var EDGE:Int = 0x2A2A30;
	static inline var ART:String = "assets/images/ui/side_art.png";

	static var holder:Sprite;
	static var art:BitmapData;

	public static function init(parent:DisplayObjectContainer):Void
	{
		holder = new Sprite();
		holder.mouseEnabled = false;
		holder.mouseChildren = false;
		parent.addChild(holder);
		if (Assets.exists(ART))
			art = Assets.getBitmapData(ART);
		Lib.current.stage.addEventListener(Event.RESIZE, function(_) apply());
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
		if (holder == null)
			return;
		holder.graphics.clear();
		bars = 0;

		var r = ratioOf(SaveData.aspect());
		if (r <= 0)
			return;

		var gm = flixel.FlxG.scaleMode;
		var gx = gm.offset.x;
		var gy = gm.offset.y;
		var gw = gm.gameSize.x;
		var gh = gm.gameSize.y;
		if (gw <= 0 || gh <= 0)
			return;

		var cw = gw;
		var ch = gh;
		if (gw / gh > r)
			cw = gh * r;
		else
			ch = gw / r;

		var barW = (gw - cw) / 2;
		var barH = (gh - ch) / 2;

		if (barW >= 1)
		{
			paint(gx, gy, barW, gh, false);
			paint(gx + gw - barW, gy, barW, gh, true);
		}
		if (barH >= 1)
		{
			paint(gx, gy, gw, barH, false);
			paint(gx, gy + gh - barH, gw, barH, true);
		}
	}

	static function paint(x:Float, y:Float, w:Float, h:Float, far:Bool):Void
	{
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
