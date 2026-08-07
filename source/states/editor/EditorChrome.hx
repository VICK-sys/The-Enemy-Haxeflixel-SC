package states.editor;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import util.Lang;

class EditorChrome
{
	static inline var PANEL:Int = 0xFF161616;
	static inline var CHIP:Int = 0xFF2A2A2A;
	static inline var CHIP_EDGE:Int = 0xFF3D3D3D;
	static inline var ROW:Int = 0xFF1E1E1E;
	static inline var ROW_ACTIVE:Int = 0xFF2E2E2E;
	static inline var EDGE_ACTIVE:Int = 0xFFEDEDED;
	static inline var TEXT_DIM:Int = 0xFFB8B8B8;
	static inline var PLAY_BG:Int = 0xFFEDEDED;
	static inline var PLAY_TEXT:Int = 0xFF141414;

	public var onSlot:Void->Void;
	public var onModeChip:Void->Void;
	public var onSheet:Void->Void;
	public var onSize:Void->Void;
	public var onMode:Int->Void;
	public var onEye:Int->Void;
	public var onUndo:Void->Void;
	public var onClear:Void->Void;
	public var onSave:Void->Void;
	public var onPlay:Void->Void;
	public var onControls:Void->Void;
	public var onLibrary:Void->Void;

	private var state:FlxState;
	private var cam:FlxCamera;
	private var sidebarW:Int;
	private var topbarH:Int;

	private var rects:Array<FlxRect> = [];
	private var actions:Array<Void->Void> = [];
	private var chipBgs:Array<FlxSprite> = [];
	private var chipEdges:Array<FlxSprite> = [];
	private var chipLabels:Array<FlxText> = [];

	private var slotChip:Int;
	private var modeChip:Int;
	private var sheetChip:Int;
	private var sizeChip:Int;
	private var saveChip:Int;

	private var rowBgs:Array<FlxSprite> = [];
	private var rowEdges:Array<FlxSprite> = [];
	private var rowLabels:Array<FlxText> = [];
	private var eyeBgs:Array<FlxSprite> = [];
	private var eyeDots:Array<FlxSprite> = [];
	private var palHint:FlxText;

	public function new(state:FlxState, cam:FlxCamera, sidebarW:Int, topbarH:Int, palX:Float, palY:Float, palW:Float, palH:Float, pad:Float)
	{
		this.state = state;
		this.cam = cam;
		this.sidebarW = sidebarW;
		this.topbarH = topbarH;

		var palBottom = palY + palH + pad;

		panel(0, 0, sidebarW, FlxG.height);
		panel(sidebarW, 0, FlxG.width - sidebarW, topbarH);
		line(sidebarW, 0, 1, FlxG.height, CHIP_EDGE);
		line(sidebarW, topbarH, FlxG.width - sidebarW, 1, CHIP_EDGE);

		var title = boxLabel(100, 0, topbarH, sidebarW - 114, "MAP EDITOR", Lang.titleSize(), FlxColor.WHITE, LEFT,
			Lang.titleFont());
		title.bold = true;

		line(palX - pad - 1, palY - pad - 1, Std.int(palW + pad * 2 + 2), Std.int(palH + pad * 2 + 2), CHIP_EDGE);
		line(palX - pad, palY - pad, Std.int(palW + pad * 2), Std.int(palH + pad * 2), 0xFF0E0E0E);
		palHint = boxLabel(palX, palY, palH, palW, "", Lang.smallSize(), TEXT_DIM, CENTER);

		var slotW = chipWidth("SLOT 1 *", 108);
		slotChip = chip(sidebarW + 12, 8, slotW, "SLOT 1", function() if (onSlot != null) onSlot());
		modeChip = chip(sidebarW + 12 + slotW + CHIP_GAP, 8, 300, "BRUSH 1X1", function() if (onModeChip != null) onModeChip());

		var playW = chipWidth("PLAY MAP", 108);
		var saveW = chipWidth("SAVE *", 90);
		var controlsW = chipWidth("CONTROLS", 110);
		var playX = FlxG.width - CHIP_EDGE_GAP - playW;
		var saveX = playX - CHIP_GAP - saveW;
		var controlsX = saveX - CHIP_GAP - controlsW;

		chip(controlsX, 8, controlsW, "CONTROLS", function() if (onControls != null) onControls());
		saveChip = chip(saveX, 8, saveW, "SAVE", function() if (onSave != null) onSave());
		var play = chip(playX, 8, playW, "PLAY MAP", function() if (onPlay != null) onPlay(), PLAY_BG);
		chipLabels[play].color = PLAY_TEXT;

		sheetChip = chip(14, Std.int(palBottom + 10), sidebarW - 28, "SHEET", function() if (onSheet != null) onSheet());
		sizeChip = chip(14, Std.int(palBottom + 10 + 34), sidebarW - 28, "SIZE", function() if (onSize != null) onSize());

		var names = ["TILES", "PROPS"];
		var rowY = palBottom + 86;
		for (i in 0...names.length)
		{
			var y = rowY + i * 46;
			var edge = new FlxSprite(12, y);
			edge.makeGraphic(sidebarW - 24, 40, EDGE_ACTIVE);
			edge.visible = false;
			ui(edge);
			rowEdges.push(edge);

			var bg = new FlxSprite(14, y + 2);
			bg.makeGraphic(sidebarW - 28, 36, ROW);
			ui(bg);
			rowBgs.push(bg);

			var eye = new FlxSprite(24, y + 11);
			eye.makeGraphic(18, 18, FlxColor.TRANSPARENT, true);
			FlxSpriteUtil.drawCircle(eye, -1, -1, -1, CHIP_EDGE, null, {smoothing: true});
			ui(eye);
			eyeBgs.push(eye);

			var dot = new FlxSprite(28, y + 15);
			dot.makeGraphic(10, 10, FlxColor.TRANSPARENT, true);
			FlxSpriteUtil.drawCircle(dot, -1, -1, -1, FlxColor.WHITE, null, {smoothing: true});
			ui(dot);
			eyeDots.push(dot);

			var l = boxLabel(54, y + 2, 36, sidebarW - 70, names[i], Lang.smallSize(), FlxColor.WHITE, LEFT);
			rowLabels.push(l);

			var mi = i;
			hit(24, y + 11, 18, 18, function() if (onEye != null) onEye(mi));
			hit(46, y, sidebarW - 58, 40, function() if (onMode != null) onMode(mi));
		}

		var by = Std.int(rowY + names.length * 46 + 14);
		chip(14, by, Std.int((sidebarW - 36) / 2), "UNDO", function() if (onUndo != null) onUndo());
		chip(Std.int(sidebarW / 2 + 4), by, Std.int((sidebarW - 36) / 2), "CLEAR", function() if (onClear != null) onClear());
		chip(14, by + 42, sidebarW - 28, "ASSETS + HITBOXES", function() if (onLibrary != null) onLibrary());
	}

	function ui(s:FlxSprite):Void
	{
		s.cameras = [cam];
		state.add(s);
	}

	function panel(x:Float, y:Float, w:Int, h:Int):Void
	{
		var s = new FlxSprite(x, y);
		s.makeGraphic(w, h, PANEL);
		ui(s);
	}

	function line(x:Float, y:Float, w:Int, h:Int, c:Int):Void
	{
		var s = new FlxSprite(x, y);
		s.makeGraphic(w, h, c);
		ui(s);
	}

	function label(x:Float, y:Float, w:Float, text:String, size:Int, color:Int, align:FlxTextAlign, ?font:String):FlxText
	{
		var t = new FlxText(x, y, w, text);
		t.setFormat(font == null ? Lang.fontFor(size) : font, size, color, align);
		t.cameras = [cam];
		state.add(t);
		return t;
	}

	function boxLabel(x:Float, boxY:Float, boxH:Float, w:Float, text:String, size:Int, color:Int, align:FlxTextAlign,
			?font:String):FlxText
	{
		var use = font == null ? Lang.fontFor(size) : font;
		return label(x, boxY + Lang.inkTop(use, size, boxH), w, text, size, color, align, use);
	}

	static inline var CHIP_PAD:Int = 14;
	static inline var CHIP_GAP:Int = 8;
	static inline var CHIP_EDGE_GAP:Int = 12;

	function chipWidth(text:String, min:Int):Int
	{
		var probe = new FlxText(0, 0, 0, text);
		probe.setFormat(Lang.smallFont(), Lang.smallSize(), FlxColor.WHITE, LEFT);
		var w = Math.ceil(probe.width) + CHIP_PAD * 2;
		probe.destroy();
		return w < min ? min : w;
	}

	function chip(x:Int, y:Int, w:Int, text:String, action:Void->Void, bgColor:Int = CHIP):Int
	{
		var edge = new FlxSprite(x - 1, y - 1);
		edge.makeGraphic(w + 2, 30, CHIP_EDGE);
		ui(edge);
		chipEdges.push(edge);

		var bg = new FlxSprite(x, y);
		bg.makeGraphic(w, 28, bgColor);
		ui(bg);
		chipBgs.push(bg);

		var l = boxLabel(x, y, 28, w, text, Lang.smallSize(), TEXT_DIM, CENTER);
		l.wordWrap = false;
		chipLabels.push(l);

		hit(x, y, w, 28, action);
		return chipBgs.length - 1;
	}

	function hit(x:Float, y:Float, w:Float, h:Float, action:Void->Void):Void
	{
		rects.push(FlxRect.get(x, y, w, h));
		actions.push(action);
	}

	public function contains():Bool
	{
		var m = FlxG.mouse.getViewPosition(cam);
		return m.x < sidebarW || m.y < topbarH;
	}

	public function update():Void
	{
		if (!FlxG.mouse.justPressed)
			return;
		var m = FlxG.mouse.getViewPosition(cam);
		for (i in 0...rects.length)
		{
			var r = rects[i];
			if (m.x >= r.x && m.x <= r.x + r.width && m.y >= r.y && m.y <= r.y + r.height)
			{
				actions[i]();
				return;
			}
		}
	}

	public function setSlot(n:Int, dirty:Bool):Void
	{
		chipLabels[slotChip].text = "SLOT " + n + (dirty ? " *" : "");
		chipLabels[saveChip].text = dirty ? "SAVE *" : "SAVE";
	}

	public function setModeChip(text:String):Void
		chipLabels[modeChip].text = text;

	public function setPaletteHint(text:String):Void
		palHint.text = text;

	public function setSize(text:String):Void
		chipLabels[sizeChip].text = text;

	public function setSheet(text:String, shown:Bool):Void
	{
		chipLabels[sheetChip].text = text;
		showChip(sheetChip, shown);
	}

	function showChip(i:Int, on:Bool):Void
	{
		chipEdges[i].visible = on;
		chipBgs[i].visible = on;
		chipLabels[i].visible = on;
	}

	public function setMode(active:Int):Void
	{
		for (i in 0...rowBgs.length)
		{
			rowEdges[i].visible = i == active;
			rowBgs[i].color = i == active ? ROW_ACTIVE : ROW;
			rowLabels[i].color = i == active ? FlxColor.WHITE : TEXT_DIM;
		}
	}

	public function setEye(i:Int, on:Bool):Void
		eyeDots[i].visible = on;

}
