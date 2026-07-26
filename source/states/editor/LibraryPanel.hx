package states.editor;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import data.PropData.PropDataRegistry;
import util.Library;
import util.Paths;

class LibraryPanel
{
	static inline var ROWS:Int = 10;
	static inline var ROW_H:Int = 30;
	static inline var PREV_W:Float = 448;
	static inline var PREV_H:Float = 300;

	static inline var PANEL:Int = 0xFA161616;
	static inline var EDGE:Int = 0xFF3D3D3D;
	static inline var CHIP:Int = 0xFF2A2A2A;
	static inline var CHIP_ON:Int = 0xFF3E3E3E;
	static inline var DIM:Int = 0xFFB8B8B8;

	static var TABS:Array<String> = ["TILESETS", "PROPS", "WALLS", "HITBOX"];
	static var TILE_SIZES:Array<Int> = [8, 16, 24, 32, 48, 64];
	static var SCALES:Array<Float> = [1, 2, 3, 4];

	public var onAdded:String->Void;

	private var state:FlxState;
	private var cam:FlxCamera;
	private var flash:String->Void;

	private var px:Float;
	private var py:Float;
	private var pw:Float = 800;
	private var ph:Float = 548;
	private var listX:Float;
	private var listY:Float;

	private var shell:Array<FlxSprite> = [];
	private var rowBgs:Array<FlxSprite> = [];
	private var rowLabels:Array<FlxText> = [];
	private var btnEdges:Array<FlxSprite> = [];
	private var btnBgs:Array<FlxSprite> = [];
	private var btnLabels:Array<FlxText> = [];
	private var rects:Array<FlxRect> = [];
	private var actions:Array<Void->Void> = [];

	private var title:FlxText;
	private var hint:FlxText;
	private var pane:PreviewPane;

	private var optBtn:Int;
	private var actBtn:Int;
	private var layerBtn:Int;
	private var baseBtn:Int;

	private var open:Bool = false;
	private var kind:Int = 0;
	private var entries:Array<String> = [];
	private var page:Int = 0;
	private var sel:Int = -1;
	private var tileIdx:Int = 2;
	private var scaleIdx:Int = 1;

	public function new(state:FlxState, cam:FlxCamera, flash:String->Void, leftInset:Float, topInset:Float, bottomInset:Float)
	{
		this.state = state;
		this.cam = cam;
		this.flash = flash;

		px = leftInset + (FlxG.width - leftInset - pw) / 2;
		py = topInset + (FlxG.height - topInset - bottomInset - ph) / 2;
		listX = px + 16;
		listY = py + 96;

		shell.push(rect(px - 2, py - 2, pw + 4, ph + 4, EDGE));
		shell.push(rect(px, py, pw, ph, PANEL));

		title = text(px, py + 14, pw, "ASSET LIBRARY", 20, FlxColor.WHITE, CENTER);

		for (i in 0...TABS.length)
			button(px + 16 + i * 186, py + 50, 178, TABS[i], tabAction(i));

		button(px + pw - 214, py + 12, 96, "RESCAN", rescan);
		button(px + pw - 110, py + 12, 96, "CLOSE", close);

		for (i in 0...ROWS)
		{
			var y = listY + i * ROW_H;
			var bg = rect(listX, y, 300, ROW_H - 2, CHIP);
			rowBgs.push(bg);
			rowLabels.push(text(listX + 10, y + 5, 284, "", 15, DIM, LEFT));
		}

		button(listX, listY + ROWS * ROW_H + 6, 142, "PREV", function() flip(-1));
		button(listX + 158, listY + ROWS * ROW_H + 6, 142, "NEXT", function() flip(1));

		var prevX = px + 336;
		var prevY = py + 96;
		pane = new PreviewPane(state, cam, prevX, prevY, PREV_W, PREV_H);
		pane.onBoxDragged = boxDragged;

		optBtn = button(prevX, prevY + PREV_H + 6, 200, "", optionAction);
		actBtn = button(prevX + 224, prevY + PREV_H + 6, 224, "", commit);
		layerBtn = button(prevX, prevY + PREV_H + 44, 296, "", cycleLayer);
		baseBtn = button(prevX + 304, prevY + PREV_H + 44, 144, "BASE BAND", baseBand);

		hint = text(px + 16, py + ph - 64, pw - 32, "", 13, DIM, CENTER);

		show(false);
	}

	function rect(x:Float, y:Float, w:Float, h:Float, c:Int):FlxSprite
	{
		var s = new FlxSprite(x, y);
		s.makeGraphic(Std.int(w), Std.int(h), c);
		s.cameras = [cam];
		state.add(s);
		return s;
	}

	function text(x:Float, y:Float, w:Float, t:String, size:Int, color:Int, align:FlxTextAlign):FlxText
	{
		var f = new FlxText(x, y, w, t);
		f.setFormat(null, size, color, align);
		f.cameras = [cam];
		state.add(f);
		return f;
	}

	function button(x:Float, y:Float, w:Float, label:String, action:Void->Void):Int
	{
		btnEdges.push(rect(x - 1, y - 1, w + 2, 30, EDGE));
		btnBgs.push(rect(x, y, w, 28, CHIP));
		btnLabels.push(text(x, y + 5, w, label, 15, DIM, CENTER));
		rects.push(FlxRect.get(x, y, w, 28));
		actions.push(action);
		return btnBgs.length - 1;
	}

	function tabAction(i:Int):Void->Void
		return function()
		{
			kind = i;
			page = 0;
			sel = -1;
			refresh();
		};

	public function isOpen():Bool
		return open;

	public function toggle():Void
	{
		show(!open);
		if (open)
			refresh();
	}

	public function close():Void
		show(false);

	public function openHitbox(propName:String):Void
	{
		show(true);
		kind = 3;
		page = 0;
		sel = -1;
		refresh();

		if (propName == null)
			return;
		var i = entries.indexOf(propName);
		if (i < 0)
			return;
		sel = i;
		page = Std.int(i / ROWS);
		refresh();
	}

	function rescan():Void
	{
		Library.rescan();
		sel = -1;
		page = 0;
		refresh();
		flash("LIBRARY RESCANNED");
		if (onAdded != null)
			onAdded("rescan");
	}

	function show(on:Bool):Void
	{
		open = on;
		for (s in shell)
			s.visible = on;
		for (s in btnEdges)
			s.visible = on;
		for (s in btnBgs)
			s.visible = on;
		for (s in btnLabels)
			s.visible = on;
		for (s in rowBgs)
			s.visible = on;
		for (s in rowLabels)
			s.visible = on;
		title.visible = on;
		hint.visible = on;
		pane.setShown(on);
	}

	function flip(d:Int):Void
	{
		var next = page + d;
		if (next < 0 || next * ROWS >= entries.length)
			return;
		page = next;
		refresh();
	}

	function refresh():Void
	{
		entries = kind == 3 ? propNames() : Library.files(TABS[kind].toLowerCase());

		for (i in 0...btnBgs.length)
			if (i < TABS.length)
			{
				btnBgs[i].color = i == kind ? CHIP_ON : CHIP;
				btnLabels[i].color = i == kind ? FlxColor.WHITE : DIM;
			}

		for (i in 0...ROWS)
		{
			var idx = page * ROWS + i;
			var has = idx < entries.length;
			rowBgs[i].visible = open && has;
			rowLabels[i].visible = open && has;
			if (!has)
				continue;
			rowBgs[i].color = idx == sel ? CHIP_ON : CHIP;
			rowLabels[i].color = idx == sel ? FlxColor.WHITE : DIM;
			rowLabels[i].text = switch (kind)
			{
				case 2: Library.displayName(entries[idx]) + (entries[idx] == Library.wallImage ? "  *" : "");
				case 3: entries[idx] + (Library.hitboxOf(entries[idx]) != null ? "  *" : "");
				default: Library.displayName(entries[idx]);
			};
		}

		btnLabels[optBtn].text = switch (kind)
		{
			case 0: "TILE " + TILE_SIZES[tileIdx];
			case 1: "SCALE " + Std.int(SCALES[scaleIdx]);
			case 2: "USE THE STOCK WALL";
			default: "FILL ART";
		};
		btnLabels[actBtn].text = switch (kind)
		{
			case 0: "ADD TILESET";
			case 1: "ADD PROP";
			case 2: "USE THIS WALL";
			default: "CLEAR BOX";
		};

		showChip(optBtn, open);

		var lm = kind == 3 && sel >= 0 && sel < entries.length ? layerModeOf(entries[sel]) : 0;
		btnLabels[layerBtn].text = "LAYER: " + switch (lm)
		{
			case 1: "GROUND - ALWAYS UNDER";
			case 2: "OVERHEAD - ALWAYS OVER";
			default: "SORTED BY ITS BASE";
		};
		showChip(layerBtn, open && kind == 3);
		showChip(baseBtn, open && kind == 3);

		hint.text = hintText();

		var src = open ? sourceBitmap() : null;
		if (src == null)
			pane.clearContent();
		else
		{
			pane.load(src, kind == 0 ? TILE_SIZES[tileIdx] : 0);
			pane.setEditable(kind == 3);
			pane.setBox(kind == 3 ? Library.hitboxOf(entries[sel]) : null);
		}
	}

	function hintText():String
	{
		if (!Library.available())
			return "IMPORTING IS DESKTOP ONLY - THIS BUILD CANNOT READ FILES";
		if (kind == 3)
			return "BASE BAND FOR BUILDINGS - BLOCK ONLY THE GROUND SO YOU CAN WALK AROUND IT\nDRAG INSIDE TO MOVE, A HANDLE TO RESIZE - THE BOTTOM EDGE IS THE DEPTH LINE";

		return (entries.length == 0 ? "NO IMAGES FOUND - DROP .PNG FILES INTO" : "DROP MORE .PNG FILES INTO") + "  library\\"
			+ TABS[kind].toLowerCase() + "  NEXT TO THE GAME\nTHEN HIT RESCAN";
	}

	function propNames():Array<String>
	{
		var out = [];
		for (p in PropDataRegistry.all())
			out.push(p.name);
		return out;
	}

	function sourceBitmap():BitmapData
	{
		if (sel < 0 || sel >= entries.length)
			return null;

		if (kind == 3)
		{
			var p = PropDataRegistry.byName(entries[sel]);
			if (p == null)
				return null;
			var g = FlxG.bitmap.add(Paths.image(p.sheet));
			if (g == null)
				return null;
			if (p.rect == null || p.rect.length != 4)
				return g.bitmap;
			var cut = new BitmapData(p.rect[2], p.rect[3], true, 0);
			cut.copyPixels(g.bitmap, new Rectangle(p.rect[0], p.rect[1], p.rect[2], p.rect[3]), new Point(0, 0));
			return cut;
		}

		var g = FlxG.bitmap.get(Paths.image(entries[sel]));
		return g == null ? null : g.bitmap;
	}

	function boxDragged(b:Array<Int>):Void
	{
		Library.setHitbox(entries[sel], b);
		flash("HITBOX " + b[2] + "x" + b[3] + " AT " + b[0] + "," + b[1]);
		refresh();
		if (onAdded != null)
			onAdded("hitbox");
	}

	function showChip(i:Int, on:Bool):Void
	{
		btnEdges[i].visible = on;
		btnBgs[i].visible = on;
		btnLabels[i].visible = on;
	}

	function layerModeOf(name:String):Int
	{
		var m = Library.layerOf(name);
		return m == null ? 0 : m;
	}

	function baseBand():Void
	{
		if (kind != 3 || sel < 0 || sel >= entries.length)
			return;
		var src = sourceBitmap();
		if (src == null)
			return;
		var b = PreviewPane.artBounds(src);
		var h = Std.int(Math.max(4, b[3] * 0.22));
		Library.setHitbox(entries[sel], [b[0], b[1] + b[3] - h, b[2], h]);
		flash("BASE BAND " + b[2] + "x" + h);
		refresh();
		if (onAdded != null)
			onAdded("hitbox");
	}

	function cycleLayer():Void
	{
		if (kind != 3 || sel < 0 || sel >= entries.length)
			return;
		Library.setLayer(entries[sel], (layerModeOf(entries[sel]) + 1) % 3);
		refresh();
		if (onAdded != null)
			onAdded("hitbox");
	}

	function optionAction():Void
	{
		switch (kind)
		{
			case 0:
				tileIdx = (tileIdx + 1) % TILE_SIZES.length;
			case 1:
				scaleIdx = (scaleIdx + 1) % SCALES.length;
			case 2:
				Library.clearWall();
				flash("BACK TO THE STOCK WALL");
				if (onAdded != null)
					onAdded("walls");
			case 3:
				var src = sourceBitmap();
				if (src != null && sel >= 0)
				{
					Library.setHitbox(entries[sel], PreviewPane.artBounds(src));
					flash("HITBOX FILLED TO THE ART");
				}
			default:
		}
		refresh();
	}

	function commit():Void
	{
		if (sel < 0 || sel >= entries.length)
		{
			flash("PICK SOMETHING FROM THE LIST FIRST");
			return;
		}

		switch (kind)
		{
			case 0:
				flash("ADDED TILESET " + Library.addTileset(entries[sel], TILE_SIZES[tileIdx], TILE_SIZES[tileIdx]));
			case 1:
				flash("ADDED PROP " + Library.addProp(entries[sel], SCALES[scaleIdx]));
			case 2:
				flash("WALLS NOW USE " + Library.setWall(entries[sel]));
			default:
				Library.setHitbox(entries[sel], null);
				flash("HITBOX CLEARED");
		}

		refresh();
		if (onAdded != null)
			onAdded(TABS[kind].toLowerCase());
	}

	public function update():Void
	{
		if (!open)
			return;

		if (FlxG.mouse.justPressed)
		{
			var m = FlxG.mouse.getScreenPosition(cam);
			for (i in 0...rects.length)
			{
				var r = rects[i];
				if (!btnBgs[i].visible)
					continue;
				if (m.x >= r.x && m.x <= r.x + r.width && m.y >= r.y && m.y <= r.y + r.height)
				{
					actions[i]();
					return;
				}
			}

			if (m.x >= listX && m.x <= listX + 300 && m.y >= listY && m.y < listY + ROWS * ROW_H)
			{
				var idx = page * ROWS + Std.int((m.y - listY) / ROW_H);
				if (idx < entries.length)
				{
					sel = idx;
					refresh();
				}
				return;
			}
		}

		pane.update();
	}
}
