package ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxInputText;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import systems.chat.ChatLog;
import systems.chat.ChatLog.ChatMsg;
import util.Lang;
import util.Paths;

class ChatWindow extends FlxSpriteGroup
{
	public static var EMOJI:Array<String> = [
		"smile", "joy", "sob", "heart", "up", "fire", "skull", "mad", "sweat", "sword"
	];

	public static inline var MIN_SCALE:Float = 0.7;
	public static inline var MAX_SCALE:Float = 2.0;

	static inline var W0:Int = 380;
	static inline var HEADER0:Int = 20;
	static inline var LIST0:Int = 168;
	static inline var INPUT0:Int = 24;
	static inline var PAD0:Int = 6;
	static inline var LINE0:Int = 17;
	static inline var QUOTE0:Int = 14;
	static inline var GAP0:Int = 3;
	static inline var EMO0:Int = 16;
	static inline var BODY0:Int = 14;
	static inline var META0:Int = 12;
	static inline var STRIP0:Int = 16;
	static inline var PALETTE0:Int = 24;
	static inline var CHIP0:Int = 16;
	static inline var GRIP0:Int = 12;
	static inline var GRAB:Float = 220;

	static inline var BG:Int = 0xD2131019;
	static inline var HEAD_BG:Int = 0xFF262231;
	static inline var EDGE:Int = 0xFF3C4356;
	static inline var DIM:Int = 0xFF8A90A0;
	static inline var INPUT_BG:Int = 0xFF0B0A10;
	static inline var GRIP_BG:Int = 0xFF5A6480;

	public var hovering(default, null):Bool = false;

	var cam:FlxCamera;
	var bg:FlxSprite;
	var header:FlxSprite;
	var headEdge:FlxSprite;
	var title:FlxText;
	var inputBg:FlxSprite;
	var inputEdge:FlxSprite;
	var input:FlxInputText;
	var hint:FlxText;
	var stripBg:FlxSprite;
	var stripText:FlxText;
	var paletteBg:FlxSprite;
	var paletteIcons:Array<FlxSprite> = [];
	var emojiBtn:FlxSprite;
	var emojiBtnIcon:FlxSprite;
	var grip:FlxSprite;
	var rows:Array<FlxSprite> = [];
	var rowHits:Array<{key:String, own:Bool, ry:Float, rh:Float}> = [];
	var chipR:FlxText;
	var chipE:FlxText;
	var chipX:FlxText;
	var chipPlate:FlxSprite;

	var s:Float = 1;
	var w:Int = W0;
	var h:Int = HEADER0 + LIST0 + INPUT0;
	var headerH:Int = HEADER0;
	var inputH:Int = INPUT0;
	var pad:Int = PAD0;
	var lineH:Int = LINE0;
	var quoteH:Int = QUOTE0;
	var gap:Int = GAP0;
	var emo:Int = EMO0;
	var bodySize:Int = BODY0;
	var metaSize:Int = META0;
	var stripH:Int = STRIP0;
	var paletteH:Int = PALETTE0;
	var chipW:Int = CHIP0;
	var gripW:Int = GRIP0;

	var scroll:Int = 0;
	var lastVer:Int = -1;
	var lastScroll:Int = -1;
	var lastListH:Int = -1;
	var lastScale:Float = -1;
	var replyKey:String = null;
	var editKey:String = null;
	var paletteOpen:Bool = false;
	var dragging:Bool = false;
	var sizing:Bool = false;
	var dragDX:Float = 0;
	var dragDY:Float = 0;
	var gripFromX:Float = 0;
	var gripFromY:Float = 0;
	var gripFromScale:Float = 1;
	var typingHold:Int = 0;
	var wantFocus:Bool = false;
	var hoverKey:String = null;
	var hoverOwn:Bool = false;
	var showing:Bool = true;

	static var scratch:FlxText = null;

	public function new(cam:FlxCamera)
	{
		super();
		this.cam = cam;
		scrollFactor.set(0, 0);

		s = util.SaveData.chatScale();
		metrics();

		bg = plate(BG);
		header = plate(HEAD_BG);
		headEdge = plate(EDGE);
		title = label("", DIM, LEFT);
		inputBg = plate(INPUT_BG);
		inputEdge = plate(EDGE);

		input = new FlxInputText(0, 0, w, "", bodySize, FlxColor.WHITE, FlxColor.TRANSPARENT);
		input.setFormat(Lang.font(), bodySize, FlxColor.WHITE, LEFT);
		input.fieldBorderThickness = 0;
		input.maxChars = ChatLog.MAX_LEN;
		input.caretColor = FlxColor.WHITE;
		input.onEnter.add(function(_) submit());
		add(input);

		hint = label("", DIM, LEFT);
		emojiBtn = plate(HEAD_BG);
		emojiBtnIcon = emoji(0);
		add(emojiBtnIcon);

		stripBg = plate(HEAD_BG);
		stripText = label("", DIM, LEFT);
		paletteBg = plate(HEAD_BG);
		for (i in 0...EMOJI.length)
		{
			var e = emoji(i);
			add(e);
			paletteIcons.push(e);
		}
		grip = plate(GRIP_BG);

		chipPlate = plate(0xF0262231);
		chipR = label("R", 0xFFB8D8FF, CENTER);
		chipE = label("E", 0xFFFFE28A, CENTER);
		chipX = label("X", 0xFFFF9A9A, CENTER);

		cameras = [cam];

		var sx = util.SaveData.chatX();
		var sy = util.SaveData.chatY();
		if (sx < 0 || sy < 0)
		{
			sx = 8;
			sy = FlxG.height - h - 8;
		}
		setPosition(clampX(sx), clampY(sy));
		relayout();
	}

	inline function px(v:Float):Int
		return Std.int(v * s + 0.5);

	function metrics():Void
	{
		w = px(W0);
		headerH = px(HEADER0);
		inputH = px(INPUT0);
		h = headerH + px(LIST0) + inputH;
		pad = px(PAD0);
		lineH = px(LINE0);
		quoteH = px(QUOTE0);
		gap = px(GAP0);
		emo = px(EMO0);
		bodySize = px(BODY0);
		metaSize = px(META0);
		stripH = px(STRIP0);
		paletteH = px(PALETTE0);
		chipW = px(CHIP0);
		gripW = px(GRIP0);
	}

	function plate(color:Int):FlxSprite
	{
		var sp = new FlxSprite();
		sp.makeGraphic(1, 1, color);
		add(sp);
		return sp;
	}

	inline function sized(sp:FlxSprite, lx:Float, ly:Float, sw:Int, sh:Int):Void
	{
		sp.setGraphicSize(sw < 1 ? 1 : sw, sh < 1 ? 1 : sh);
		sp.updateHitbox();
		sp.setPosition(x + lx, y + ly);
	}

	function label(text:String, color:Int, align:flixel.text.FlxTextAlign):FlxText
	{
		var t = new FlxText(0, 0, 0, text);
		t.setFormat(Lang.font(), metaSize, color, align);
		add(t);
		return t;
	}

	function emoji(frame:Int):FlxSprite
	{
		var e = new FlxSprite();
		e.loadGraphic(Paths.image("ui/chat_emoji"), true, EMO0, EMO0);
		e.animation.frameIndex = frame;
		e.antialiasing = false;
		return e;
	}

	static function measure(str:String, size:Int):Float
	{
		if (scratch == null)
		{
			scratch = new FlxText(0, 0, 0, "");
			scratch.setFormat(Lang.font(), size, FlxColor.WHITE, LEFT);
		}
		if (scratch.size != size)
			scratch.size = size;
		scratch.text = str;
		return scratch.textField.textWidth + 4;
	}

	inline function clampX(v:Float):Float
		return v < 0 ? 0 : (v > FlxG.width - w ? FlxG.width - w : v);

	inline function clampY(v:Float):Float
		return v < 0 ? 0 : (v > FlxG.height - h ? FlxG.height - h : v);

	function relayout():Void
	{
		metrics();

		sized(bg, 0, 0, w, h);
		sized(header, 0, 0, w, headerH);
		sized(headEdge, 0, headerH - 1, w, 1);
		title.size = metaSize;
		title.fieldWidth = w - pad * 2;
		title.text = Lang.t("chat.title");
		title.setPosition(x + pad, y + px(3));

		sized(inputBg, 0, h - inputH, w - inputH, inputH);
		sized(inputEdge, 0, h - inputH - 1, w, 1);

		input.size = bodySize;
		input.fieldWidth = w - inputH - pad * 2;
		input.setPosition(x + pad, y + h - inputH + px(3));

		hint.size = metaSize;
		hint.fieldWidth = w - inputH - pad * 2;
		hint.text = Lang.t("chat.typeHint");
		hint.setPosition(x + pad + px(2), y + h - inputH + px(5));

		sized(emojiBtn, w - inputH, h - inputH, inputH, inputH);
		emojiBtnIcon.scale.set(s, s);
		emojiBtnIcon.updateHitbox();
		emojiBtnIcon.setPosition(x + w - inputH + px(4), y + h - inputH + px(4));

		sized(grip, w - gripW, h - inputH - gripW, gripW, gripW);

		sized(stripBg, 0, 0, w, stripH);
		stripText.size = metaSize;
		stripText.fieldWidth = w - pad * 2;

		sized(paletteBg, 0, 0, w, paletteH);
		for (i in 0...paletteIcons.length)
		{
			var e = paletteIcons[i];
			e.scale.set(s, s);
			e.updateHitbox();
		}

		sized(chipPlate, 0, 0, chipW * 3 + px(8), px(15));
		chipR.size = metaSize;
		chipE.size = metaSize;
		chipX.size = metaSize;
		chipR.fieldWidth = chipW;
		chipE.fieldWidth = chipW;
		chipX.fieldWidth = chipW;

		lastScale = s;
		lastVer = -1;
		setPosition(clampX(x), clampY(y));
	}

	public function show(on:Bool):Void
	{
		showing = on;
		visible = on;
		if (!on)
		{
			wantFocus = false;
			hovering = false;
			if (input.hasFocus)
				input.endFocus();
			util.Controls.typing = false;
			util.Controls.uiMouse = false;
		}
	}

	public function focusInput():Void
		wantFocus = true;

	public function blurInput():Void
	{
		wantFocus = false;
		if (input.hasFocus)
			input.endFocus();
	}

	function nameColor(hue:Float):Int
		return FlxColor.fromHSB(hue * 360, 0.82, 0.98);

	function submit():Void
	{
		var text = input.text;
		if (editKey != null)
			ChatLog.edit(editKey, text);
		else
			ChatLog.send(text, replyKey);
		input.text = "";
		replyKey = null;
		editKey = null;
		scroll = 0;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!showing)
			return;

		var panelOpen = FlxG.state.subState != null;
		if (panelOpen)
			wantFocus = false;
		if (wantFocus && !input.hasFocus)
			input.startFocus();
		else if (!wantFocus && input.hasFocus)
			input.endFocus();

		var mp = FlxG.mouse.getViewPosition(cam);
		var mx = mp.x;
		var my = mp.y;
		mp.put();
		var over = !panelOpen && mx >= x && mx < x + w && my >= y && my < y + h;

		if (sizing)
		{
			over = true;
			if (FlxG.mouse.pressed)
			{
				var step = ((mx - gripFromX) + (my - gripFromY)) * 0.5;
				var want = gripFromScale + step / GRAB;
				want = want < MIN_SCALE ? MIN_SCALE : (want > MAX_SCALE ? MAX_SCALE : want);
				if (Math.abs(want - s) > 0.01)
				{
					s = want;
					relayout();
				}
			}
			else
			{
				sizing = false;
				util.SaveData.setChatScale(s);
				util.SaveData.setChatPos(x, y);
			}
		}
		else if (dragging)
		{
			over = true;
			if (FlxG.mouse.pressed)
				setPosition(clampX(mx - dragDX), clampY(my - dragDY));
			else
			{
				dragging = false;
				util.SaveData.setChatPos(x, y);
			}
		}
		else if (over && FlxG.mouse.justPressed && mx >= grip.x && my >= grip.y
			&& mx < grip.x + gripW && my < grip.y + gripW)
		{
			sizing = true;
			gripFromX = mx;
			gripFromY = my;
			gripFromScale = s;
		}
		else if (FlxG.mouse.justPressed && !panelOpen && mx >= x && mx < x + w && my >= y && my < y + headerH)
		{
			dragging = true;
			dragDX = mx - x;
			dragDY = my - y;
		}

		hovering = over;

		if (!panelOpen && !wantFocus && FlxG.keys.justPressed.T)
			wantFocus = true;

		if (FlxG.keys.justPressed.ESCAPE)
		{
			if (replyKey != null || editKey != null)
			{
				if (editKey != null)
					input.text = "";
				replyKey = null;
				editKey = null;
				typingHold = 2;
			}
			else if (wantFocus)
				blurInput();
		}

		if (FlxG.mouse.justPressed && !over && wantFocus)
			blurInput();
		if (FlxG.mouse.justPressed && over && my >= y + h - inputH && mx < x + w - inputH)
			wantFocus = true;

		if (wantFocus)
			typingHold = 2;
		else if (typingHold > 0)
			typingHold--;
		util.Controls.typing = typingHold > 0;
		util.Controls.uiMouse = over;

		hint.visible = !wantFocus && input.text == "";

		if (over && FlxG.mouse.justPressed && mx >= x + w - inputH && my >= y + h - inputH)
			paletteOpen = !paletteOpen;
		if (paletteOpen && over && FlxG.mouse.justPressed)
			for (i in 0...paletteIcons.length)
			{
				var e = paletteIcons[i];
				if (mx >= e.x - 2 && mx < e.x + emo + 4 && my >= e.y - 4 && my < e.y + emo + 4)
				{
					input.text += ":" + EMOJI[i] + ":";
					input.caretIndex = input.text.length;
					if (!panelOpen)
						wantFocus = true;
					break;
				}
			}

		if (over && FlxG.mouse.wheel != 0)
		{
			scroll += FlxG.mouse.wheel > 0 ? 1 : -1;
			var top = ChatLog.messages.length - 1;
			scroll = scroll < 0 ? 0 : (scroll > top ? (top < 0 ? 0 : top) : scroll);
		}

		refreshStrip();

		var listH = listHeight();
		if (ChatLog.version != lastVer || scroll != lastScroll || listH != lastListH)
		{
			lastVer = ChatLog.version;
			lastScroll = scroll;
			lastListH = listH;
			buildRows(listH);
		}

		updateHover(mx, my, over);
	}

	function listHeight():Int
	{
		var lh = h - headerH - inputH;
		if (paletteOpen)
			lh -= paletteH;
		if (replyKey != null || editKey != null)
			lh -= stripH;
		return lh;
	}

	function refreshStrip():Void
	{
		var want = replyKey != null || editKey != null;
		var off = paletteOpen ? paletteH : 0;
		stripBg.setPosition(x, y + h - inputH - off - stripH);
		stripText.setPosition(x + pad, stripBg.y + px(2));
		paletteBg.setPosition(x, y + h - inputH - paletteH);
		for (i in 0...paletteIcons.length)
			paletteIcons[i].setPosition(x + pad + i * (emo + px(6)), y + h - inputH - paletteH + px(4));

		stripBg.visible = want;
		stripText.visible = want;
		paletteBg.visible = paletteOpen;
		for (e in paletteIcons)
			e.visible = paletteOpen;

		if (editKey != null)
			stripText.text = Lang.t("chat.editing");
		else if (replyKey != null)
		{
			var m = ChatLog.get(replyKey);
			stripText.text = Lang.t("chat.replyTo", [m == null ? "?" : m.name]);
		}
	}

	function clearRows():Void
	{
		for (r in rows)
		{
			remove(r, true);
			r.destroy();
		}
		rows = [];
		rowHits = [];
	}

	function addRow(sp:FlxSprite):Void
	{
		add(sp);
		rows.push(sp);
	}

	function rowText(lx:Float, ly:Float, text:String, size:Int, color:Int):FlxText
	{
		var t = new FlxText(lx, ly, 0, text);
		t.setFormat(Lang.font(), size, color, LEFT);
		addRow(t);
		return t;
	}

	function buildRows(listH:Int):Void
	{
		clearRows();

		var maxW = w - pad * 2 - chipW * 3 - px(10);
		var bottom = headerH + listH - gap;
		var idx = ChatLog.messages.length - 1 - scroll;

		while (idx >= 0 && bottom > headerH + lineH)
		{
			var m = ChatLog.messages[idx];
			idx--;

			var lines = layout(m, maxW);
			var quote = m.reply != null && !m.deleted ? quoteH : 0;
			var blockH = quote + lines.length * lineH;
			var top = bottom - blockH;
			if (top < headerH + 2)
				break;

			if (quote > 0)
			{
				var q = ChatLog.get(m.reply);
				var qs = q == null || q.deleted ? Lang.t("chat.deleted") : q.name + ": " + stripTokens(q.text);
				if (qs.length > 46)
					qs = qs.substr(0, 46) + "..";
				rowText(pad + px(8), top, "> " + qs, metaSize, DIM);
			}

			for (li in 0...lines.length)
			{
				var ly = top + quote + li * lineH;
				for (seg in lines[li])
				{
					if (seg.emoji >= 0)
					{
						var e = emoji(seg.emoji);
						e.scale.set(s, s);
						e.updateHitbox();
						e.setPosition(pad + seg.sx, ly);
						addRow(e);
					}
					else
						rowText(pad + seg.sx, ly, seg.text, bodySize, seg.color);
				}
			}

			rowHits.push({key: m.key, own: m.sender == net.Net.selfId, ry: top, rh: blockH});
			bottom = top - gap;
		}
	}

	function stripTokens(str:String):String
	{
		for (n in EMOJI)
			str = StringTools.replace(str, ":" + n + ":", "");
		return str;
	}

	function layout(m:ChatMsg, maxW:Float):Array<Array<{sx:Float, text:String, color:Int, emoji:Int}>>
	{
		var lines:Array<Array<{sx:Float, text:String, color:Int, emoji:Int}>> = [[]];
		var cx:Float = 0;

		function put(text:String, color:Int, emojiIdx:Int, tw:Float):Void
		{
			if (cx + tw > maxW && cx > 0)
			{
				lines.push([]);
				cx = 0;
				if (text == " ")
					return;
			}
			lines[lines.length - 1].push({sx: cx, text: text, color: color, emoji: emojiIdx});
			cx += tw;
		}

		var nm = m.name + ":";
		put(nm, nameColor(m.hue), -1, measure(nm, bodySize) + px(4));

		if (m.deleted)
		{
			put(Lang.t("chat.deleted"), DIM, -1, measure(Lang.t("chat.deleted"), bodySize));
			return merge(lines);
		}

		for (tok in tokenize(m.text))
		{
			if (tok.emoji >= 0)
				put("", 0, tok.emoji, emo + 1);
			else if (tok.text == " ")
				put(" ", FlxColor.WHITE, -1, measure(" ", bodySize) - px(3));
			else
				put(tok.text, FlxColor.WHITE, -1, measure(tok.text, bodySize) - px(2));
		}

		if (m.edited)
			put(Lang.t("chat.edited"), DIM, -1, measure(Lang.t("chat.edited"), metaSize));

		return merge(lines);
	}

	function merge(lines:Array<Array<{sx:Float, text:String, color:Int, emoji:Int}>>):Array<Array<{sx:Float, text:String, color:Int, emoji:Int}>>
	{
		var out:Array<Array<{sx:Float, text:String, color:Int, emoji:Int}>> = [];
		for (line in lines)
		{
			var packed:Array<{sx:Float, text:String, color:Int, emoji:Int}> = [];
			for (seg in line)
			{
				var last = packed.length > 0 ? packed[packed.length - 1] : null;
				if (seg.emoji < 0 && last != null && last.emoji < 0 && last.color == seg.color)
					last.text += seg.text;
				else
					packed.push(seg);
			}
			out.push(packed);
		}
		return out;
	}

	function tokenize(str:String):Array<{text:String, emoji:Int}>
	{
		var out:Array<{text:String, emoji:Int}> = [];
		var i = 0;
		var word = "";

		function flush():Void
		{
			if (word != "")
			{
				out.push({text: word, emoji: -1});
				word = "";
			}
		}

		while (i < str.length)
		{
			var ch = str.charAt(i);
			if (ch == " ")
			{
				flush();
				out.push({text: " ", emoji: -1});
				i++;
				continue;
			}
			if (ch == ":")
			{
				var close = str.indexOf(":", i + 1);
				if (close > i)
				{
					var name = str.substring(i + 1, close);
					var e = EMOJI.indexOf(name);
					if (e >= 0)
					{
						flush();
						out.push({text: "", emoji: e});
						i = close + 1;
						continue;
					}
				}
			}
			word += ch;
			i++;
		}
		flush();
		return out;
	}

	function updateHover(mx:Float, my:Float, over:Bool):Void
	{
		hoverKey = null;
		if (over && !dragging && !sizing)
			for (hit in rowHits)
				if (my >= y + hit.ry && my < y + hit.ry + hit.rh)
				{
					hoverKey = hit.key;
					hoverOwn = hit.own;
					chipPlate.setPosition(x + w - (chipW * 3 + px(10)), y + hit.ry);
					break;
				}

		var showChips = hoverKey != null;
		chipPlate.visible = showChips;
		chipR.visible = showChips;
		chipE.visible = showChips && hoverOwn;
		chipX.visible = showChips && hoverOwn;
		if (!showChips)
			return;

		chipR.setPosition(chipPlate.x + px(2), chipPlate.y + px(1));
		chipE.setPosition(chipPlate.x + px(2) + chipW, chipPlate.y + px(1));
		chipX.setPosition(chipPlate.x + px(2) + chipW * 2, chipPlate.y + px(1));

		if (!FlxG.mouse.justPressed)
			return;
		if (my < chipPlate.y || my >= chipPlate.y + px(15) || mx < chipPlate.x)
			return;

		var slot = Std.int((mx - chipPlate.x - px(2)) / chipW);
		var panelOpen = FlxG.state.subState != null;
		if (slot == 0)
		{
			replyKey = hoverKey;
			editKey = null;
			if (!panelOpen)
				wantFocus = true;
		}
		else if (slot == 1 && hoverOwn)
		{
			var m = ChatLog.get(hoverKey);
			if (m != null && !m.deleted)
			{
				editKey = hoverKey;
				replyKey = null;
				input.text = m.text;
				input.caretIndex = input.text.length;
				if (!panelOpen)
					wantFocus = true;
			}
		}
		else if (slot == 2 && hoverOwn)
			ChatLog.remove(hoverKey);
	}
}
