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

	static inline var W:Int = 380;
	static inline var HEADER_H:Int = 20;
	static inline var LIST_H:Int = 168;
	static inline var INPUT_H:Int = 24;
	static inline var H:Int = HEADER_H + LIST_H + INPUT_H;
	static inline var PAD:Int = 6;
	static inline var LINE_H:Int = 17;
	static inline var QUOTE_H:Int = 14;
	static inline var GAP:Int = 3;
	static inline var EMO:Int = 16;
	static inline var BODY_SIZE:Int = 14;
	static inline var META_SIZE:Int = 12;
	static inline var STRIP_H:Int = 16;
	static inline var PALETTE_H:Int = 24;
	static inline var CHIP_W:Int = 16;

	static inline var BG:Int = 0xD2131019;
	static inline var HEAD_BG:Int = 0xFF262231;
	static inline var EDGE:Int = 0xFF3C4356;
	static inline var DIM:Int = 0xFF8A90A0;
	static inline var INPUT_BG:Int = 0xFF0B0A10;

	var cam:FlxCamera;
	var bg:FlxSprite;
	var header:FlxSprite;
	var title:FlxText;
	var inputBg:FlxSprite;
	var input:FlxInputText;
	var hint:FlxText;
	var stripBg:FlxSprite;
	var stripText:FlxText;
	var paletteBg:FlxSprite;
	var paletteIcons:Array<FlxSprite> = [];
	var emojiBtn:FlxSprite;
	var emojiBtnIcon:FlxSprite;
	var rows:Array<FlxSprite> = [];
	var rowHits:Array<{key:String, own:Bool, ry:Float, rh:Float}> = [];
	var chipR:FlxText;
	var chipE:FlxText;
	var chipX:FlxText;
	var chipPlate:FlxSprite;

	var scroll:Int = 0;
	var lastVer:Int = -1;
	var lastScroll:Int = -1;
	var lastListH:Int = -1;
	var replyKey:String = null;
	var editKey:String = null;
	var paletteOpen:Bool = false;
	var dragging:Bool = false;
	var dragDX:Float = 0;
	var dragDY:Float = 0;
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

		bg = plate(0, 0, W, H, BG);
		header = plate(0, 0, W, HEADER_H, HEAD_BG);
		plate(0, HEADER_H - 1, W, 1, EDGE);
		title = label(PAD, 3, W - PAD * 2, Lang.t("chat.title"), META_SIZE, DIM, LEFT);

		inputBg = plate(0, H - INPUT_H, W - INPUT_H, INPUT_H, INPUT_BG);
		plate(0, H - INPUT_H - 1, W, 1, EDGE);

		input = new FlxInputText(PAD, H - INPUT_H + 3, W - INPUT_H - PAD * 2, "", BODY_SIZE, FlxColor.WHITE, FlxColor.TRANSPARENT);
		input.setFormat(Lang.font(), BODY_SIZE, FlxColor.WHITE, LEFT);
		input.fieldBorderThickness = 0;
		input.maxChars = ChatLog.MAX_LEN;
		input.caretColor = FlxColor.WHITE;
		input.onEnter.add(function(_) submit());
		add(input);

		hint = label(PAD + 2, H - INPUT_H + 5, W - INPUT_H - PAD * 2, Lang.t("chat.typeHint"), META_SIZE, DIM, LEFT);

		emojiBtn = plate(W - INPUT_H, H - INPUT_H, INPUT_H, INPUT_H, HEAD_BG);
		emojiBtnIcon = emoji(0);
		emojiBtnIcon.setPosition(x + W - INPUT_H + 4, y + H - INPUT_H + 4);
		add(emojiBtnIcon);

		stripBg = plate(0, H - INPUT_H - STRIP_H, W, STRIP_H, HEAD_BG);
		stripText = label(PAD, H - INPUT_H - STRIP_H + 2, W - PAD * 2, "", META_SIZE, DIM, LEFT);
		stripBg.visible = false;
		stripText.visible = false;

		paletteBg = plate(0, H - INPUT_H - PALETTE_H, W, PALETTE_H, HEAD_BG);
		paletteBg.visible = false;
		for (i in 0...EMOJI.length)
		{
			var e = emoji(i);
			e.setPosition(x + PAD + i * (EMO + 6), y + H - INPUT_H - PALETTE_H + 4);
			e.visible = false;
			add(e);
			paletteIcons.push(e);
		}

		chipPlate = plate(0, 0, CHIP_W * 3 + 8, 15, 0xF0262231);
		chipPlate.visible = false;
		chipR = label(0, 0, CHIP_W, "R", META_SIZE, 0xFFB8D8FF, CENTER);
		chipE = label(0, 0, CHIP_W, "E", META_SIZE, 0xFFFFE28A, CENTER);
		chipX = label(0, 0, CHIP_W, "X", META_SIZE, 0xFFFF9A9A, CENTER);
		chipR.visible = chipE.visible = chipX.visible = false;

		cameras = [cam];

		var sx = util.SaveData.chatX();
		var sy = util.SaveData.chatY();
		if (sx < 0 || sy < 0)
		{
			sx = 8;
			sy = FlxG.height - H - 8;
		}
		setPosition(clampX(sx), clampY(sy));
	}

	function plate(px:Float, py:Float, w:Int, h:Int, color:Int):FlxSprite
	{
		var s = new FlxSprite(x + px, y + py);
		s.makeGraphic(w, h, color);
		add(s);
		return s;
	}

	function label(px:Float, py:Float, w:Float, text:String, size:Int, color:Int, align:flixel.text.FlxTextAlign):FlxText
	{
		var t = new FlxText(x + px, y + py, w, text);
		t.setFormat(Lang.font(), size, color, align);
		add(t);
		return t;
	}

	function emoji(frame:Int):FlxSprite
	{
		var e = new FlxSprite();
		e.loadGraphic(Paths.image("ui/chat_emoji"), true, EMO, EMO);
		e.animation.frameIndex = frame;
		e.antialiasing = false;
		return e;
	}

	static function measure(s:String, size:Int):Float
	{
		if (scratch == null)
		{
			scratch = new FlxText(0, 0, 0, "");
			scratch.setFormat(Lang.font(), size, FlxColor.WHITE, LEFT);
		}
		if (scratch.size != size)
			scratch.size = size;
		scratch.text = s;
		return scratch.textField.textWidth + 4;
	}

	inline function clampX(v:Float):Float
		return v < 0 ? 0 : (v > FlxG.width - W ? FlxG.width - W : v);

	inline function clampY(v:Float):Float
		return v < 0 ? 0 : (v > FlxG.height - H ? FlxG.height - H : v);

	public function show(on:Bool):Void
	{
		showing = on;
		visible = on;
		if (!on)
		{
			wantFocus = false;
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
		var over = mx >= x && mx < x + W && my >= y && my < y + H;

		if (dragging)
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
		else if (FlxG.mouse.justPressed && mx >= x && mx < x + W && my >= y && my < y + HEADER_H)
		{
			dragging = true;
			dragDX = mx - x;
			dragDY = my - y;
		}

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
		if (FlxG.mouse.justPressed && over && my >= y + H - INPUT_H && mx < x + W - INPUT_H)
			wantFocus = true;

		if (wantFocus)
			typingHold = 2;
		else if (typingHold > 0)
			typingHold--;
		util.Controls.typing = typingHold > 0;
		util.Controls.uiMouse = over;

		hint.visible = !wantFocus && input.text == "";

		if (over && FlxG.mouse.justPressed && mx >= x + W - INPUT_H && my >= y + H - INPUT_H)
			setPalette(!paletteOpen);
		if (paletteOpen && FlxG.mouse.justPressed)
			for (i in 0...paletteIcons.length)
			{
				var e = paletteIcons[i];
				if (mx >= e.x - 2 && mx < e.x + EMO + 4 && my >= e.y - 4 && my < e.y + EMO + 4)
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
		paletteBg.visible = paletteOpen;
		for (e in paletteIcons)
			e.visible = paletteOpen;

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
		var h = LIST_H;
		if (paletteOpen)
			h -= PALETTE_H;
		if (replyKey != null || editKey != null)
			h -= STRIP_H;
		return h;
	}

	function setPalette(on:Bool):Void
	{
		paletteOpen = on;
		paletteBg.visible = on;
		for (e in paletteIcons)
			e.visible = on;
	}

	function refreshStrip():Void
	{
		var want = replyKey != null || editKey != null;
		var off = (paletteOpen ? PALETTE_H : 0);
		stripBg.y = y + H - INPUT_H - off - STRIP_H;
		stripText.y = stripBg.y + 2;
		paletteBg.y = y + H - INPUT_H - PALETTE_H;
		for (i in 0...paletteIcons.length)
			paletteIcons[i].y = y + H - INPUT_H - PALETTE_H + 4;
		stripBg.visible = want;
		stripText.visible = want;
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

	function addRow(s:FlxSprite):Void
	{
		add(s);
		rows.push(s);
	}

	function rowText(px:Float, py:Float, text:String, size:Int, color:Int):FlxText
	{
		var t = new FlxText(px, py, 0, text);
		t.setFormat(Lang.font(), size, color, LEFT);
		addRow(t);
		return t;
	}

	function buildRows(listH:Int):Void
	{
		clearRows();

		var maxW = W - PAD * 2 - CHIP_W * 3 - 10;
		var bottom = HEADER_H + listH - GAP;
		var idx = ChatLog.messages.length - 1 - scroll;

		while (idx >= 0 && bottom > HEADER_H + LINE_H)
		{
			var m = ChatLog.messages[idx];
			idx--;

			var lines = layout(m, maxW);
			var quote = m.reply != null && !m.deleted ? QUOTE_H : 0;
			var blockH = quote + lines.length * LINE_H;
			var top = bottom - blockH;
			if (top < HEADER_H + 2)
				break;

			if (quote > 0)
			{
				var q = ChatLog.get(m.reply);
				var qs = q == null || q.deleted ? Lang.t("chat.deleted") : q.name + ": " + stripTokens(q.text);
				if (qs.length > 46)
					qs = qs.substr(0, 46) + "..";
				rowText(PAD + 8, top, "> " + qs, META_SIZE, DIM);
			}

			for (li in 0...lines.length)
			{
				var ly = top + quote + li * LINE_H;
				for (seg in lines[li])
				{
					if (seg.emoji >= 0)
					{
						var e = emoji(seg.emoji);
						e.setPosition(PAD + seg.sx, ly);
						addRow(e);
					}
					else
						rowText(PAD + seg.sx, ly, seg.text, BODY_SIZE, seg.color);
				}
			}

			rowHits.push({key: m.key, own: m.sender == net.Net.selfId, ry: top, rh: blockH});
			bottom = top - GAP;
		}
	}

	function stripTokens(s:String):String
	{
		for (n in EMOJI)
			s = StringTools.replace(s, ":" + n + ":", "");
		return s;
	}

	function layout(m:ChatMsg, maxW:Float):Array<Array<{sx:Float, text:String, color:Int, emoji:Int}>>
	{
		var lines:Array<Array<{sx:Float, text:String, color:Int, emoji:Int}>> = [[]];
		var cx:Float = 0;

		function put(text:String, color:Int, emojiIdx:Int, w:Float):Void
		{
			if (cx + w > maxW && cx > 0)
			{
				lines.push([]);
				cx = 0;
				if (text == " ")
					return;
			}
			lines[lines.length - 1].push({sx: cx, text: text, color: color, emoji: emojiIdx});
			cx += w;
		}

		var nm = m.name + ":";
		put(nm, nameColor(m.hue), -1, measure(nm, BODY_SIZE) + 4);

		if (m.deleted)
		{
			put(Lang.t("chat.deleted"), DIM, -1, measure(Lang.t("chat.deleted"), BODY_SIZE));
			return merge(lines);
		}

		for (tok in tokenize(m.text))
		{
			if (tok.emoji >= 0)
				put("", 0, tok.emoji, EMO + 1);
			else if (tok.text == " ")
				put(" ", FlxColor.WHITE, -1, measure(" ", BODY_SIZE) - 3);
			else
				put(tok.text, FlxColor.WHITE, -1, measure(tok.text, BODY_SIZE) - 2);
		}

		if (m.edited)
			put(Lang.t("chat.edited"), DIM, -1, measure(Lang.t("chat.edited"), META_SIZE));

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

	function tokenize(s:String):Array<{text:String, emoji:Int}>
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

		while (i < s.length)
		{
			var ch = s.charAt(i);
			if (ch == " ")
			{
				flush();
				out.push({text: " ", emoji: -1});
				i++;
				continue;
			}
			if (ch == ":")
			{
				var close = s.indexOf(":", i + 1);
				if (close > i)
				{
					var name = s.substring(i + 1, close);
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
		if (over && !dragging)
			for (h in rowHits)
				if (my >= y + h.ry && my < y + h.ry + h.rh)
				{
					hoverKey = h.key;
					hoverOwn = h.own;
					chipPlate.setPosition(x + W - (CHIP_W * 3 + 10), y + h.ry);
					break;
				}

		var showChips = hoverKey != null;
		chipPlate.visible = showChips;
		chipR.visible = showChips;
		chipE.visible = showChips && hoverOwn;
		chipX.visible = showChips && hoverOwn;
		if (!showChips)
			return;

		chipR.setPosition(chipPlate.x + 2, chipPlate.y + 1);
		chipE.setPosition(chipPlate.x + 2 + CHIP_W, chipPlate.y + 1);
		chipX.setPosition(chipPlate.x + 2 + CHIP_W * 2, chipPlate.y + 1);

		if (!FlxG.mouse.justPressed)
			return;
		if (my < chipPlate.y || my >= chipPlate.y + 15 || mx < chipPlate.x)
			return;

		var slot = Std.int((mx - chipPlate.x - 2) / CHIP_W);
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
