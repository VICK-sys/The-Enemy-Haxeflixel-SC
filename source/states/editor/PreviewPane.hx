package states.editor;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

class PreviewPane
{
	static inline var HANDLE:Int = 10;
	static inline var EDGE:Int = 0xFF3D3D3D;

	static var HANDLE_FLAGS:Array<Array<Bool>> = [
		[true, false, true, false], [false, true, true, false], [true, false, false, true], [false, true, false, true],
		[false, false, true, false], [false, false, false, true], [true, false, false, false], [false, true, false, false]
	];

	public var onBoxDragged:Array<Int>->Void;

	private var cam:FlxCamera;
	private var x:Float;
	private var y:Float;
	private var w:Float;
	private var h:Float;

	private var frame:Array<FlxSprite> = [];
	private var view:FlxSprite;
	private var hitRect:FlxSprite;
	private var handles:Array<FlxSprite> = [];

	private var scale:Float = 1;
	private var ok:Bool = false;
	private var editable:Bool = false;
	private var box:Array<Int>;

	private var dragMode:Int = 0;
	private var dragAX:Float = 0;
	private var dragAY:Float = 0;
	private var grabIX:Float = 0;
	private var grabIY:Float = 0;
	private var boxStart:Array<Int>;
	private var workBox:Array<Int>;
	private var eL:Bool = false;
	private var eR:Bool = false;
	private var eT:Bool = false;
	private var eB:Bool = false;

	public function new(state:FlxState, cam:FlxCamera, x:Float, y:Float, w:Float, h:Float)
	{
		this.cam = cam;
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;

		frame.push(sprite(state, x - 2, y - 2, Std.int(w + 4), Std.int(h + 4), EDGE));
		frame.push(sprite(state, x, y, Std.int(w), Std.int(h), 0xFF0E0E0E));

		view = new FlxSprite();
		view.antialiasing = false;
		view.cameras = [cam];
		state.add(view);

		hitRect = new FlxSprite();
		hitRect.makeGraphic(1, 1, 0xFF7CFC00);
		hitRect.origin.set(0, 0);
		hitRect.alpha = 0.4;
		hitRect.cameras = [cam];
		state.add(hitRect);

		for (i in 0...HANDLE_FLAGS.length)
		{
			var hs = new FlxSprite();
			hs.makeGraphic(HANDLE, HANDLE, FlxColor.WHITE);
			hs.visible = false;
			hs.cameras = [cam];
			state.add(hs);
			handles.push(hs);
		}
	}

	function sprite(state:FlxState, sx:Float, sy:Float, sw:Int, sh:Int, c:Int):FlxSprite
	{
		var s = new FlxSprite(sx, sy);
		s.makeGraphic(sw, sh, c);
		s.cameras = [cam];
		state.add(s);
		return s;
	}

	public function setShown(on:Bool):Void
	{
		for (s in frame)
			s.visible = on;
		if (!on)
			clearContent();
	}

	public function clearContent():Void
	{
		ok = false;
		editable = false;
		box = null;
		view.visible = false;
		hideBox();
		dragMode = 0;
	}

	public function load(src:BitmapData, gridStep:Int):Void
	{
		ok = false;
		view.visible = false;
		hideBox();

		if (src == null)
			return;

		var s = Math.min(w / src.width, h / src.height);
		if (s > 6)
			s = 6;
		var dw = Std.int(src.width * s);
		var dh = Std.int(src.height * s);
		if (dw < 1 || dh < 1)
			return;

		var out = new BitmapData(dw, dh, true, 0xFF0E0E0E);
		var m = new Matrix();
		m.scale(s, s);
		out.draw(src, m);

		if (gridStep > 0)
			drawGrid(out, gridStep * s);

		var old = view.graphic;
		view.loadGraphic(out);
		if (old != null && old != view.graphic)
			FlxG.bitmap.remove(old);

		view.x = x + (w - dw) / 2;
		view.y = y + (h - dh) / 2;
		view.visible = true;
		scale = s;
		ok = true;
	}

	static function drawGrid(out:BitmapData, step:Float):Void
	{
		if (step < 3)
			return;
		var gx = step;
		while (gx < out.width)
		{
			out.fillRect(new Rectangle(Math.round(gx), 0, 1, out.height), 0x66FFFFFF);
			gx += step;
		}
		var gy = step;
		while (gy < out.height)
		{
			out.fillRect(new Rectangle(0, Math.round(gy), out.width, 1), 0x66FFFFFF);
			gy += step;
		}
	}

	public function setEditable(on:Bool):Void
	{
		editable = on;
		if (!on)
			dragMode = 0;
	}

	public function setBox(b:Array<Int>):Void
	{
		box = b;
		drawBox(b);
	}

	function hideBox():Void
	{
		hitRect.visible = false;
		for (hs in handles)
			hs.visible = false;
	}

	function drawBox(b:Array<Int>):Void
	{
		if (!ok || b == null)
		{
			hideBox();
			return;
		}

		hitRect.x = view.x + b[0] * scale;
		hitRect.y = view.y + b[1] * scale;
		hitRect.scale.set(b[2] * scale, b[3] * scale);
		hitRect.visible = true;

		var x0 = hitRect.x;
		var y0 = hitRect.y;
		var x1 = x0 + b[2] * scale;
		var y1 = y0 + b[3] * scale;
		var mx = (x0 + x1) / 2;
		var my = (y0 + y1) / 2;
		var pts = [
			[x0, y0], [x1, y0], [x0, y1], [x1, y1],
			[mx, y0], [mx, y1], [x0, my], [x1, my]
		];

		for (i in 0...handles.length)
		{
			handles[i].x = pts[i][0] - HANDLE / 2;
			handles[i].y = pts[i][1] - HANDLE / 2;
			handles[i].visible = true;
		}
	}

	function handleAt(mx:Float, my:Float):Int
	{
		for (i in 0...handles.length)
		{
			var hs = handles[i];
			if (!hs.visible)
				continue;
			if (mx >= hs.x - 2 && mx <= hs.x + HANDLE + 2 && my >= hs.y - 2 && my <= hs.y + HANDLE + 2)
				return i;
		}
		return -1;
	}

	function beginDrag(mx:Float, my:Float):Void
	{
		dragMode = 0;
		if (mx < view.x || mx > view.x + view.width || my < view.y || my > view.y + view.height)
			return;

		grabIX = imgXf(mx);
		grabIY = imgYf(my);

		if (box != null)
		{
			var hIdx = handleAt(mx, my);
			if (hIdx >= 0)
			{
				dragMode = 3;
				eL = HANDLE_FLAGS[hIdx][0];
				eR = HANDLE_FLAGS[hIdx][1];
				eT = HANDLE_FLAGS[hIdx][2];
				eB = HANDLE_FLAGS[hIdx][3];
				boxStart = box.copy();
				return;
			}
			if (grabIX >= box[0] && grabIX <= box[0] + box[2] && grabIY >= box[1] && grabIY <= box[1] + box[3])
			{
				dragMode = 2;
				boxStart = box.copy();
				return;
			}
		}

		dragMode = 1;
		dragAX = grabIX;
		dragAY = grabIY;
	}

	public function update():Void
	{
		if (!editable || !ok)
			return;

		var m = FlxG.mouse.getViewPosition(cam);

		if (FlxG.mouse.justPressed)
			beginDrag(m.x, m.y);

		if (dragMode == 0)
			return;

		var ix = imgXf(m.x);
		var iy = imgYf(m.y);
		var iw = view.width / scale;
		var ih = view.height / scale;

		switch (dragMode)
		{
			case 2:
				var nx = PalettePanel.clamp(boxStart[0] + (ix - grabIX), 0, iw - boxStart[2]);
				var ny = PalettePanel.clamp(boxStart[1] + (iy - grabIY), 0, ih - boxStart[3]);
				workBox = [Math.round(nx), Math.round(ny), boxStart[2], boxStart[3]];

			case 3:
				var x0 = boxStart[0] * 1.0;
				var y0 = boxStart[1] * 1.0;
				var x1 = x0 + boxStart[2];
				var y1 = y0 + boxStart[3];
				if (eL)
					x0 = ix;
				if (eR)
					x1 = ix;
				if (eT)
					y0 = iy;
				if (eB)
					y1 = iy;
				workBox = [
					Math.round(Math.min(x0, x1)), Math.round(Math.min(y0, y1)),
					Math.round(Math.abs(x1 - x0)), Math.round(Math.abs(y1 - y0))
				];

			default:
				workBox = [
					Math.round(Math.min(dragAX, ix)), Math.round(Math.min(dragAY, iy)),
					Math.round(Math.abs(ix - dragAX)), Math.round(Math.abs(iy - dragAY))
				];
		}

		drawBox(workBox);

		if (!FlxG.mouse.pressed)
		{
			dragMode = 0;
			if (workBox[2] >= 2 && workBox[3] >= 2 && onBoxDragged != null)
				onBoxDragged(workBox);
			else
				drawBox(box);
		}
	}

	function imgXf(sx:Float):Float
		return PalettePanel.clamp((sx - view.x) / scale, 0, view.width / scale);

	function imgYf(sy:Float):Float
		return PalettePanel.clamp((sy - view.y) / scale, 0, view.height / scale);

	public static function artBounds(src:BitmapData):Array<Int>
	{
		var minX = src.width;
		var minY = src.height;
		var maxX = -1;
		var maxY = -1;

		for (py in 0...src.height)
			for (px in 0...src.width)
				if ((src.getPixel32(px, py) >>> 24) > 8)
				{
					if (px < minX)
						minX = px;
					if (py < minY)
						minY = py;
					if (px > maxX)
						maxX = px;
					if (py > maxY)
						maxY = py;
				}

		if (maxX < 0)
			return [0, 0, src.width, src.height];
		return [minX, minY, maxX - minX + 1, maxY - minY + 1];
	}
}
