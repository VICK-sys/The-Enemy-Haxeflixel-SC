package states.editor;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import data.PropData.PropDataRegistry;
import systems.Decor;

class PropPalette extends PalettePanel
{
	public var index(default, null):Int = 0;
	public var highlight(default, null):Bool = true;

	private var contact:BitmapData;
	private var cell:Int;
	private var cols:Int = 1;
	private var scrollY:Float = 0;

	public function new(state:FlxState, cam:FlxCamera, px:Float, py:Float, w:Float, h:Float, pad:Float, cell:Int)
	{
		super(state, cam, px, py, w, h, pad);
		this.cell = cell;
	}

	public function build():Void
	{
		var n = PropDataRegistry.count();
		if (n == 0)
			return;
		frame();

		cols = Std.int(width / cell);
		if (cols < 1)
			cols = 1;
		var rows = Math.ceil(n / cols);

		if (contact != null)
			contact.dispose();
		contact = new BitmapData(cols * cell, rows * cell, true, 0);

		for (i in 0...n)
		{
			var s = Decor.make(PropDataRegistry.get(i).name);
			if (s == null)
				continue;
			var src = s.graphic.bitmap;
			var k = Math.min((cell - 10) / src.width, (cell - 10) / src.height);
			var m = new Matrix();
			m.scale(k, k);
			m.translate((i % cols) * cell + (cell - src.width * k) * 0.5,
				Math.floor(i / cols) * cell + (cell - src.height * k) * 0.5);
			contact.draw(src, m, null, null, null, false);
			s.destroy();
		}

		scrollY = 0;
		redraw();
	}

	public function redraw():Void
	{
		if (contact == null)
			return;
		frame();
		scrollY = PalettePanel.clamp(scrollY, 0, Math.max(0, contact.height - height));

		var view = new BitmapData(Std.int(width), Std.int(height), true, 0xFF120C14);
		view.copyPixels(contact, new Rectangle(0, scrollY, width, height), new Point(0, 0));
		setWindow(view, 1);

		sel.setGraphicSize(cell, cell);
		sel.updateHitbox();
		sel.x = x + (index % cols) * cell;
		sel.y = y + Math.floor(index / cols) * cell - scrollY;
		sel.visible = highlight && bg.visible && sel.y >= y - 1 && sel.y + cell <= y + height + 1;
	}

	public function setHighlight(on:Bool):Void
	{
		highlight = on;
		redraw();
	}

	override public function show(on:Bool):Void
	{
		super.show(on);
		if (on)
			redraw();
	}

	public function pick():Bool
	{
		var col = Math.floor(localX() / cell);
		var row = Math.floor((localY() + scrollY) / cell);
		if (col < 0 || col >= cols || row < 0)
			return false;
		var i = row * cols + col;
		if (i < 0 || i >= PropDataRegistry.count())
			return false;
		index = i;
		redraw();
		return true;
	}

	public function scroll(dy:Float):Void
	{
		scrollY -= dy;
		redraw();
	}

	public function select(i:Int):Void
	{
		index = i;
		var top = Math.floor(index / cols) * cell;
		if (top < scrollY)
			scrollY = top;
		else if (top + cell > scrollY + height)
			scrollY = top + cell - height;
		redraw();
	}

	public function scrollStep():Float
		return cell * 0.5;
}
