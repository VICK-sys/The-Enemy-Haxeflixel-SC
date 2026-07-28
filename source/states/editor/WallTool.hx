package states.editor;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;

class WallTool
{
	public var map(default, null):FlxTilemap;
	public var hover(default, null):FlxSprite;
	public var rectPreview(default, null):FlxSprite;
	public var brush(default, null):Int = 1;

	private var doc:EditorMap;
	private var tilesPath:String;
	private var themeColor:Int = 0xFFFFFFFF;
	private var stroke:Bool = false;
	private var strokePaint:Bool = true;
	private var rectMode:Bool = false;
	private var anchorC:Int = 0;
	private var anchorR:Int = 0;
	private var lastC:Int = -1;
	private var lastR:Int = -1;

	public function new(doc:EditorMap, tilesPath:String)
	{
		this.doc = doc;
		this.tilesPath = tilesPath;

		map = new FlxTilemap();

		hover = new FlxSprite();
		hover.makeGraphic(doc.cell, doc.cell, 0xFFFFFFFF);
		hover.alpha = 0.3;

		rectPreview = new FlxSprite();
		rectPreview.makeGraphic(doc.cell, doc.cell, 0xFFFFFFFF);
		rectPreview.origin.set(0, 0);
		rectPreview.alpha = 0.3;
		rectPreview.visible = false;
	}

	public function rebuild():Void
	{
		map.loadMapFromCSV(doc.wallCsv(), tilesPath, doc.cell, doc.cell, AUTO);
		map.color = themeColor;
	}

	public function setThemeColor(c:Int):Void
	{
		themeColor = c;
		map.color = c;
	}

	public function setCell(c:Int, r:Int, on:Bool):Void
	{
		if (doc.setWall(c, r, on))
			map.setTileIndex(r * doc.cols + c, on ? 1 : 0, true);
	}

	public function hideCursor():Void
	{
		hover.visible = false;
		rectPreview.visible = false;
		stroke = false;
	}

	public function cycleBrush(max:Int):String
	{
		brush = brush >= max ? 1 : brush + 1;
		return "BRUSH " + brush + "X" + brush;
	}

	public function update(c:Int, r:Int, blocked:Bool):Void
	{
		if (blocked)
		{
			hideCursor();
			return;
		}
		updateHover(c, r);
		updateStroke(c, r);
	}

	function updateHover(c:Int, r:Int):Void
	{
		var half = Math.floor((brush - 1) / 2);
		hover.visible = !stroke && doc.inside(c, r);
		hover.scale.set(brush, brush);
		hover.x = ((c - half) + brush * 0.5) * doc.cell - hover.width / 2;
		hover.y = ((r - half) + brush * 0.5) * doc.cell - hover.height / 2;
	}

	function updateStroke(c:Int, r:Int):Void
	{
		if (!stroke)
		{
			var left = FlxG.mouse.justPressed;
			var right = FlxG.mouse.justPressedRight;
			if (!left && !right)
				return;
			stroke = true;
			strokePaint = left;
			rectMode = FlxG.keys.pressed.SHIFT;
			doc.pushUndo();
			doc.dirty = true;
			if (rectMode)
			{
				anchorC = c;
				anchorR = r;
				rectPreview.visible = true;
				rectPreview.color = strokePaint ? FlxColor.WHITE : 0xFFE0132D;
			}
			else
				paintCell(c, r, strokePaint);
			lastC = c;
			lastR = r;
			return;
		}

		var held = strokePaint ? FlxG.mouse.pressed : FlxG.mouse.pressedRight;
		if (held)
		{
			if (rectMode)
			{
				rectPreview.x = Math.min(anchorC, c) * doc.cell;
				rectPreview.y = Math.min(anchorR, r) * doc.cell;
				rectPreview.scale.set(Math.abs(c - anchorC) + 1, Math.abs(r - anchorR) + 1);
			}
			else if (c != lastC || r != lastR)
			{
				paintLine(lastC, lastR, c, r, strokePaint);
				lastC = c;
				lastR = r;
			}
			return;
		}

		stroke = false;
		if (rectMode)
		{
			rectPreview.visible = false;
			applyRect(anchorC, anchorR, c, r, strokePaint);
		}
		else
			rebuild();
	}

	function paintCell(c:Int, r:Int, on:Bool):Void
	{
		var half = Math.floor((brush - 1) / 2);
		for (rr in (r - half)...(r - half + brush))
			for (cc in (c - half)...(c - half + brush))
				setCell(cc, rr, on);
	}

	function paintLine(c0:Int, r0:Int, c1:Int, r1:Int, on:Bool):Void
	{
		var steps = Std.int(Math.max(Math.abs(c1 - c0), Math.abs(r1 - r0)));
		if (steps == 0)
		{
			paintCell(c1, r1, on);
			return;
		}
		for (i in 0...steps + 1)
		{
			var t = i / steps;
			paintCell(Math.round(c0 + (c1 - c0) * t), Math.round(r0 + (r1 - r0) * t), on);
		}
	}

	function applyRect(c0:Int, r0:Int, c1:Int, r1:Int, on:Bool):Void
	{
		var cMin = Std.int(Math.min(c0, c1));
		var cMax = Std.int(Math.max(c0, c1));
		var rMin = Std.int(Math.min(r0, r1));
		var rMax = Std.int(Math.max(r0, r1));
		for (r in rMin...rMax + 1)
			for (c in cMin...cMax + 1)
				doc.setWall(c, r, on);
		rebuild();
	}
}
