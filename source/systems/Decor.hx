package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import data.PropData.PropData;
import data.PropData.PropPlace;
import data.PropData.PropDataRegistry;
import util.Paths;

class Decor
{
	static function graphicFor(p:PropData):FlxGraphic
	{
		var key = "prop:" + p.name;
		var g = FlxG.bitmap.get(key);
		if (g != null)
			return g;

		var src = FlxG.bitmap.add(Paths.image(p.sheet));
		if (src == null)
			return null;

		var full = p.rect == null || p.rect.length != 4;
		var w = full ? src.bitmap.width : p.rect[2];
		var h = full ? src.bitmap.height : p.rect[3];
		if (w <= 0 || h <= 0)
			return null;

		var cut = new BitmapData(w, h, true, 0);
		cut.copyPixels(src.bitmap, full ? new Rectangle(0, 0, w, h) : new Rectangle(p.rect[0], p.rect[1], w, h), new Point(0, 0));

		g = FlxG.bitmap.add(cut, false, key);
		g.persist = true;
		g.destroyOnNoUse = false;
		return g;
	}

	public static function make(name:String):FlxSprite
	{
		var p = PropDataRegistry.byName(name);
		if (p == null)
			return null;
		var g = graphicFor(p);
		if (g == null)
			return null;

		var s = new FlxSprite();
		s.loadGraphic(g);
		s.antialiasing = false;
		var sc = p.scale <= 0 ? 1 : p.scale;
		s.scale.set(sc, sc);
		s.updateHitbox();
		return s;
	}

	public static function place(s:FlxSprite, x:Float, y:Float):Void
	{
		s.x = x - s.width / 2;
		s.y = y - s.height;
	}

	public static function build(list:Array<PropPlace>, into:flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>):Array<FlxSprite>
	{
		var out:Array<FlxSprite> = [];
		if (list == null)
			return out;
		for (pl in list)
		{
			var s = make(pl.n);
			if (s == null)
				continue;
			s.flipX = pl.f == true;
			place(s, pl.x, pl.y);
			into.add(s);
			out.push(s);
		}
		return out;
	}
}
