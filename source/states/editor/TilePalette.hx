package states.editor;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import data.TilesetData.TilesetData;
import systems.world.DecorTiles;
import util.Paths;

class TilePalette extends PalettePanel
{
	public var selCol(default, null):Int = 0;
	public var selRow(default, null):Int = 0;
	public var selCols(default, null):Int = 1;
	public var selRows(default, null):Int = 1;

	private var set:TilesetData;
	private var viewX:Float = 0;
	private var viewY:Float = 0;
	private var scale:Float = 1;
	private var fit:Float = 1;
	private var maxZoom:Float;
	private var dragCol:Int = 0;
	private var dragRow:Int = 0;

	public function new(state:FlxState, cam:FlxCamera, px:Float, py:Float, w:Float, h:Float, pad:Float, maxZoom:Float)
	{
		super(state, cam, px, py, w, h, pad);
		this.maxZoom = maxZoom;
	}

	public function build(t:TilesetData):Void
	{
		set = t;
		if (set == null)
			return;
		frame();
		resetSelection();

		var cells = DecorTiles.contentCells(set);
		fit = Math.min(width / (cells[2] * set.tileW), height / (cells[3] * set.tileH));
		scale = fit;
		viewX = cells[0] * set.tileW;
		viewY = cells[1] * set.tileH;
		redraw();
	}

	public function resetSelection():Void
	{
		selCol = 0;
		selRow = 0;
		selCols = 1;
		selRows = 1;
	}

	function bitmap():BitmapData
	{
		if (set == null)
			return null;
		var g = FlxG.bitmap.add(Paths.image(set.image));
		return g == null ? null : g.bitmap;
	}

	public function perRow():Int
	{
		var b = bitmap();
		var n = b == null ? 1 : Std.int(b.width / set.tileW);
		return n < 1 ? 1 : n;
	}

	public function count():Int
	{
		var b = bitmap();
		return b == null ? 0 : Std.int(b.width / set.tileW) * Std.int(b.height / set.tileH);
	}

	public function index():Int
		return selRow * perRow() + selCol + 1;

	public function indexAt(dx:Int, dy:Int):Int
		return (selRow + dy) * perRow() + (selCol + dx) + 1;

	public function redraw():Void
	{
		var b = bitmap();
		if (b == null)
			return;

		var viewW = Std.int(width / scale);
		var viewH = Std.int(height / scale);
		if (viewW < 1) viewW = 1;
		if (viewH < 1) viewH = 1;

		viewX = PalettePanel.clamp(viewX, 0, Math.max(0, b.width - viewW));
		viewY = PalettePanel.clamp(viewY, 0, Math.max(0, b.height - viewH));

		var view = new BitmapData(viewW, viewH, true, 0xFF120C14);
		view.copyPixels(b, new Rectangle(viewX, viewY, viewW, viewH), new Point(0, 0));

		var gx = Math.ceil(viewX / set.tileW) * set.tileW;
		while (gx < viewX + viewW)
		{
			view.fillRect(new Rectangle(gx - viewX, 0, 1, viewH), 0x55FFFFFF);
			gx += set.tileW;
		}
		var gy = Math.ceil(viewY / set.tileH) * set.tileH;
		while (gy < viewY + viewH)
		{
			view.fillRect(new Rectangle(0, gy - viewY, viewW, 1), 0x55FFFFFF);
			gy += set.tileH;
		}

		setWindow(view, scale);
		placeSelection();
	}

	function placeSelection():Void
	{
		if (set == null)
			return;
		sel.setGraphicSize(Std.int(set.tileW * selCols * scale), Std.int(set.tileH * selRows * scale));
		sel.updateHitbox();
		sel.x = x + (selCol * set.tileW - viewX) * scale;
		sel.y = y + (selRow * set.tileH - viewY) * scale;
		sel.visible = bg.visible
			&& sel.x >= x - 1 && sel.y >= y - 1
			&& sel.x + sel.width <= x + width + 1
			&& sel.y + sel.height <= y + height + 1;
	}

	public function pick(anchor:Bool):Void
	{
		if (set == null)
			return;
		var sheetX = viewX + localX() / scale;
		var sheetY = viewY + localY() / scale;
		var col = Math.floor(sheetX / set.tileW);
		var row = Math.floor(sheetY / set.tileH);
		var per = perRow();
		var down = Std.int(count() / per);
		col = Std.int(PalettePanel.clamp(col, 0, per - 1));
		row = Std.int(PalettePanel.clamp(row, 0, down - 1));

		if (anchor)
		{
			dragCol = col;
			dragRow = row;
		}
		selCol = col < dragCol ? col : dragCol;
		selRow = row < dragRow ? row : dragRow;
		selCols = Std.int(Math.abs(col - dragCol)) + 1;
		selRows = Std.int(Math.abs(row - dragRow)) + 1;
		placeSelection();
	}

	public function step(dir:Int):Void
	{
		var n = count();
		if (n == 0)
			return;
		var i = index() - 1 + dir;
		if (i < 0)
			i = n - 1;
		if (i >= n)
			i = 0;
		selCol = i % perRow();
		selRow = Std.int(i / perRow());
		selCols = 1;
		selRows = 1;
		placeSelection();
	}

	public function drag():Void
	{
		var dx = FlxG.mouse.deltaScreenX;
		var dy = FlxG.mouse.deltaScreenY;
		if (dx == 0 && dy == 0)
			return;
		viewX -= dx / scale;
		viewY -= dy / scale;
		redraw();
	}

	public function zoom(dir:Int):Void
	{
		var before = scale;
		scale = PalettePanel.clamp(scale * (dir > 0 ? 1.25 : 0.8), fit * 0.5, maxZoom);
		var cx = viewX + (width / before) * 0.5;
		var cy = viewY + (height / before) * 0.5;
		viewX = cx - (width / scale) * 0.5;
		viewY = cy - (height / scale) * 0.5;
		redraw();
	}

	public function renderIndices(idx:Array<Int>, w:Int, h:Int):BitmapData
	{
		var b = bitmap();
		if (b == null || set == null || w <= 0 || h <= 0)
			return null;
		var per = perRow();
		var out = new BitmapData(w * set.tileW, h * set.tileH, true, 0);
		for (r in 0...h)
			for (c in 0...w)
			{
				var v = idx[r * w + c];
				if (v <= 0)
					continue;
				var sc = (v - 1) % per;
				var sr = Std.int((v - 1) / per);
				out.copyPixels(b, new Rectangle(sc * set.tileW, sr * set.tileH, set.tileW, set.tileH),
					new Point(c * set.tileW, r * set.tileH));
			}
		return out;
	}

	public function patchBitmap():BitmapData
	{
		var b = bitmap();
		if (b == null)
			return null;
		var w = selCols * set.tileW;
		var h = selRows * set.tileH;
		var cut = new BitmapData(w, h, true, 0);
		cut.copyPixels(b, new Rectangle(selCol * set.tileW, selRow * set.tileH, w, h), new Point(0, 0));
		return cut;
	}
}
