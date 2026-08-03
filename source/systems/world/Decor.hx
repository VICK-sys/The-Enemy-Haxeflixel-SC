package systems.world;

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

		var s = new PropSprite();
		s.loadGraphic(g);
		util.PixelPerfectShader.on(s);
		var sc = p.scale <= 0 ? 1 : p.scale;
		s.scale.set(sc, sc);
		s.updateHitbox();
		s.layerMode = p.layer == null ? PropSprite.SORTED : p.layer;
		s.baseOffset = p.hitbox != null && p.hitbox.length == 4 ? p.hitbox[1] + p.hitbox[3] : g.height;
		return s;
	}

	public static function place(s:FlxSprite, x:Float, y:Float):Void
	{
		s.x = x - s.width / 2;
		s.y = y - s.height;
		if (Std.isOfType(s, PropSprite))
		{
			var p = cast(s, PropSprite);
			p.sortY = s.y + p.baseOffset * s.scale.y;
		}
	}

	public static function sortValue(s:FlxSprite):Float
	{
		if (!Std.isOfType(s, PropSprite))
			return s.y + s.height;
		var p = cast(s, PropSprite);
		if (p.layerMode == PropSprite.GROUND)
			return -999999;
		if (p.layerMode == PropSprite.OVERHEAD)
			return 999999;
		return p.sortY;
	}

	public static function solids(list:Array<PropPlace>, ?tint:Int):flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>
	{
		var group = new flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>();
		if (list == null)
			return group;

		for (pl in list)
		{
			var p = PropDataRegistry.byName(pl.n);
			if (p == null || p.hitbox == null || p.hitbox.length != 4)
				continue;
			var g = graphicFor(p);
			if (g == null)
				continue;

			var sc = p.scale <= 0 ? 1 : p.scale;
			var bx = pl.f == true ? g.width - p.hitbox[0] - p.hitbox[2] : p.hitbox[0];
			var w = Math.max(1, p.hitbox[2] * sc);
			var h = Math.max(1, p.hitbox[3] * sc);

			var s = new FlxSprite(pl.x - g.width * sc / 2 + bx * sc, pl.y - g.height * sc + p.hitbox[1] * sc);
			s.makeGraphic(1, 1, tint == null ? 0x00000000 : tint);
			s.setGraphicSize(Std.int(w), Std.int(h));
			s.updateHitbox();
			s.immovable = true;
			s.moves = false;
			s.visible = tint != null;
			s.alpha = 0.3;
			group.add(s);
		}
		return group;
	}

	public static function build(list:Array<PropPlace>, into:flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>,
			?names:Array<String>):Array<FlxSprite>
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
			if (names != null)
				names.push(pl.n);
		}
		return out;
	}
}
