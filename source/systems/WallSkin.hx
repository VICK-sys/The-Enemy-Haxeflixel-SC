package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import data.ThemeData.ThemeDataRegistry;
import data.TilesetData.TilesetData;
import data.TilesetData.TilesetDataRegistry;
import util.CustomArena;
import util.Paths;

class WallSkin
{
	public var background(default, null):String;

	private var color:Int = 0xFF1C1010;
	private var tex:BitmapData;
	private var texRect:Rectangle;
	private var tileSet:TilesetData;
	private var tileGrid:Array<Int>;
	private var tileSheet:BitmapData;

	public function new()
	{
		if (!CustomArena.active)
			return;

		var t = ThemeDataRegistry.get(0);
		background = t.background;
		color = ThemeDataRegistry.colorOf(t);

		if (t.wall != null && t.wall != "")
		{
			var g = FlxG.bitmap.add(Paths.image(t.wall));
			if (g != null)
			{
				tex = g.bitmap;
				texRect = t.wallRect != null && t.wallRect.length == 4
					? new Rectangle(t.wallRect[0], t.wallRect[1], t.wallRect[2], t.wallRect[3])
					: new Rectangle(0, 0, tex.width, tex.height);
			}
		}

		tileSet = TilesetDataRegistry.byName(CustomArena.tileset);
		if (tileSet != null)
		{
			tileGrid = DecorTiles.parse(CustomArena.tiles, tileSet);
			var tg = FlxG.bitmap.add(Paths.image(tileSet.image));
			tileSheet = tg == null ? null : tg.bitmap;
		}
	}

	public function paint(s:FlxSprite, wx:Float, wy:Float, w:Int, h:Int):Void
	{
		var painted = tileSheet != null && tileGrid != null;
		if (tex == null && !painted)
		{
			s.makeGraphic(w, h, color);
			return;
		}

		s.makeGraphic(w, h, color, true);

		if (tex != null)
		{
			var step = new Point();
			var y:Float = 0;
			while (y < h)
			{
				var x:Float = 0;
				while (x < w)
				{
					step.setTo(x, y);
					s.pixels.copyPixels(tex, texRect, step, null, null, true);
					x += texRect.width;
				}
				y += texRect.height;
			}
		}

		if (painted)
			stampTiles(s, wx, wy, w, h);

		s.dirty = true;
	}

	function stampTiles(s:FlxSprite, wx:Float, wy:Float, w:Int, h:Int):Void
	{
		var tw = tileSet.tileW;
		var th = tileSet.tileH;
		var per = Std.int(tileSheet.width / tw);
		var gridCols = DecorTiles.cols(tileSet);
		var gridRows = DecorTiles.rows(tileSet);

		var c0 = Math.floor(wx / tw);
		var c1 = Math.floor((wx + w - 1) / tw);
		var r0 = Math.floor(wy / th);
		var r1 = Math.floor((wy + h - 1) / th);

		for (r in r0...r1 + 1)
		{
			if (r < 0 || r >= gridRows)
				continue;
			for (c in c0...c1 + 1)
			{
				if (c < 0 || c >= gridCols)
					continue;
				var v = tileGrid[r * gridCols + c];
				if (v <= 0)
					continue;

				var x0 = Math.max(wx, c * tw);
				var y0 = Math.max(wy, r * th);
				var x1 = Math.min(wx + w, (c + 1) * tw);
				var y1 = Math.min(wy + h, (r + 1) * th);
				if (x1 <= x0 || y1 <= y0)
					continue;

				var srcX = ((v - 1) % per) * tw + (x0 - c * tw);
				var srcY = Math.floor((v - 1) / per) * th + (y0 - r * th);
				s.pixels.copyPixels(tileSheet, new Rectangle(srcX, srcY, x1 - x0, y1 - y0),
					new Point(x0 - wx, y0 - wy), null, null, true);
			}
		}
	}
}
