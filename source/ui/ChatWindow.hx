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

	static inline var INSET:Int = 8;
	static inline var WRAP_RATIO:Float = 0.68;
	static inline var INPUT0:Int = 32;
	static inline var PAD0:Int = 6;
	static inline var LINE0:Int = 30;
	static inline var QUOTE0:Int = 26;
	static inline var GAP0:Int = 4;
	static inline var EMO0:Int = 16;
	static inline var STRIP0:Int = 28;
	static inline var PALETTE0:Int = 28;
	static inline var CHIP0:Int = 24;
	static inline var LOG_HOLD:Float = 5;
	static inline var LOG_FADE:Float = 1;

	static inline var DIM:Int = 0xFF8A90A0;

	public static var liveChat(default, null):ChatWindow;
	public var hovering(default, null):Bool = false;

	var cam:FlxCamera;
	var input:FlxInputText;
	var inputView:FlxText;
	var hint:FlxText;
	var stripText:FlxText;
	var paletteIcons:Array<FlxSprite> = [];
	var emojiBtnIcon:FlxSprite;
	var rows:Array<FlxSprite> = [];
	var rowHits:Array<{key:String, own:Bool, ry:Float, rh:Float}> = [];
	var chipR:FlxText;
	var chipE:FlxText;
	var chipX:FlxText;

	var s:Float = 1;
	var w:Int = 0;
	var h:Int = 0;
	var inputH:Int = INPUT0;
	var pad:Int = PAD0;
	var lineH:Int = LINE0;
	var quoteH:Int = QUOTE0;
	var gap:Int = GAP0;
	var emo:Int = EMO0;
	var bodySize:Int = 0;
	var metaSize:Int = 0;
	var stripH:Int = STRIP0;
	var paletteH:Int = PALETTE0;
	var chipW:Int = CHIP0;
	var composerY:Int = GAP0;

	var scroll:Int = 0;
	var lastVer:Int = -1;
	var lastScroll:Int = -1;
	var lastListH:Int = -1;
	var replyKey:String = null;
	var editKey:String = null;
	var paletteOpen:Bool = false;
	var typingHold:Int = 0;
	var wantFocus:Bool = false;
	var hoverKey:String = null;
	var hoverOwn:Bool = false;
	var showing:Bool = true;
	var idleAge:Float = 0;
	var logAlpha:Float = 1;
	var wasFocused:Bool = false;

	static var scratch:FlxText = null;

	public function new(cam:FlxCamera)
	{
		super();
		this.cam = cam;
		liveChat = this;
		scrollFactor.set(0, 0);

		s = util.SaveData.chatScale();
		metrics();

		input = new FlxInputText(0, 0, w, "", bodySize, FlxColor.WHITE, FlxColor.TRANSPARENT);
		input.setFormat(Lang.smallFont(), bodySize, FlxColor.WHITE, LEFT);
		input.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		input.fieldBorderThickness = 0;
		input.maxChars = ChatLog.MAX_LEN;
		input.caretColor = FlxColor.WHITE;
		input.onEnter.add(function(_) submit());
		input.alpha = 0;
		add(input);

		inputView = label("", FlxColor.WHITE, LEFT);
		hint = label("", DIM, LEFT);
		emojiBtnIcon = emoji(0);
		add(emojiBtnIcon);

		stripText = label("", DIM, LEFT);
		for (i in 0...EMOJI.length)
		{
			var e = emoji(i);
			add(e);
			paletteIcons.push(e);
		}

		chipR = label("R", 0xFFB8D8FF, CENTER);
		chipE = label("E", 0xFFFFE28A, CENTER);
		chipX = label("X", 0xFFFF9A9A, CENTER);

		cameras = [cam];
		setPosition(INSET, INSET);
		relayout();
	}

	inline function px(v:Float):Int
		return Std.int(v * s + 0.5);

	function metrics():Void
	{
		w = Std.int(FlxG.width * WRAP_RATIO) - INSET * 2;
		if (w < 1)
			w = 1;
		h = FlxG.height - INSET * 2;
		inputH = px(INPUT0);
		pad = px(PAD0);
		lineH = px(LINE0);
		quoteH = px(QUOTE0);
		gap = px(GAP0);
		emo = px(EMO0);
		bodySize = Lang.chatSize(s);
		metaSize = Lang.chatSize(s);
		stripH = px(STRIP0);
		paletteH = px(PALETTE0);
		chipW = px(CHIP0);
	}

	function label(text:String, color:Int, align:flixel.text.FlxTextAlign):FlxText
	{
		var t = new FlxText(0, 0, 0, text);
		t.setFormat(Lang.smallFont(), metaSize, color, align);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
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
			scratch.setFormat(Lang.smallFont(), size, FlxColor.WHITE, LEFT);
		}
		scratch.font = Lang.smallFont();
		if (scratch.size != size)
			scratch.size = size;
		scratch.text = str;
		return scratch.textField.textWidth + 4;
	}

	function relayout():Void
	{
		metrics();
		setPosition(INSET, INSET);

		input.font = Lang.smallFont();
		input.size = bodySize;
		input.fieldWidth = w - emo - pad * 3;
		inputH = Std.int(input.height + lineH + 0.5);
		inputView.font = Lang.smallFont();
		inputView.size = bodySize;
		inputView.fieldWidth = w - emo - pad * 3;

		hint.font = Lang.smallFont();
		hint.size = metaSize;
		hint.fieldWidth = w - emo - pad * 3;
		hint.text = Lang.t("chat.typeHint");

		emojiBtnIcon.scale.set(s, s);
		emojiBtnIcon.updateHitbox();

		stripText.font = Lang.smallFont();
		stripText.size = metaSize;
		stripText.fieldWidth = w - pad * 2;

		for (e in paletteIcons)
		{
			e.scale.set(s, s);
			e.updateHitbox();
		}

		for (chip in [chipR, chipE, chipX])
		{
			chip.font = Lang.smallFont();
			chip.size = metaSize;
			chip.fieldWidth = chipW;
		}
		composerY = gap;
		placeComposer();

		lastVer = -1;
		lastListH = -1;
	}

	function placeComposer():Void
	{
		var cy = y + composerY;
		if (wantFocus && (replyKey != null || editKey != null))
		{
			stripText.setPosition(x + pad, cy + px(2));
			cy += stripH;
		}
		if (wantFocus && paletteOpen)
		{
			for (i in 0...paletteIcons.length)
				paletteIcons[i].setPosition(x + pad + i * (emo + px(6)), cy + px(4));
			cy += paletteH;
		}
		input.setPosition(x + pad, cy);
		inputView.setPosition(x + pad, cy);
		hint.setPosition(x + pad + px(2), cy + px(2));
		emojiBtnIcon.setPosition(x + w - emo - pad, cy + lineH + pad);
	}

	public static function refreshScale():Void
	{
		if (liveChat == null)
			return;
		liveChat.s = util.SaveData.chatScale();
		liveChat.relayout();
	}

	public function show(on:Bool):Void
	{
		if (on && !showing)
		{
			idleAge = 0;
			setLogAlpha(1);
		}
		showing = on;
		visible = on;
		if (!on)
		{
			wantFocus = false;
			wasFocused = false;
			hovering = false;
			paletteOpen = false;
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
		paletteOpen = false;
		if (input.hasFocus)
			input.endFocus();
	}

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
		if (!wantFocus)
			paletteOpen = false;
		if (wantFocus && !input.hasFocus)
			input.startFocus();
		else if (!wantFocus && input.hasFocus)
			input.endFocus();

		var mp = FlxG.mouse.getViewPosition(cam);
		var mx = mp.x;
		var my = mp.y;
		mp.put();
		var inside = mx >= x && mx < x + w && my >= y && my < y + h;
		var onRow = false;
		if (inside)
			for (hit in rowHits)
				if (my >= y + hit.ry && my < y + hit.ry + hit.rh)
				{
					onRow = true;
					break;
				}
		var onInput = inside && my >= input.y && my < input.y + inputH;
		var onPalette = inside && paletteOpen && my >= input.y - paletteH && my < input.y;
		var over = !panelOpen && wantFocus && (onRow || onInput || onPalette);

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

		if (FlxG.mouse.justPressed && wantFocus && !inside)
			blurInput();

		if (wantFocus)
			typingHold = 2;
		else if (typingHold > 0)
			typingHold--;
		util.Controls.typing = typingHold > 0;
		util.Controls.uiMouse = over;
		hovering = over;

		input.visible = wantFocus;
		var caret = input.caretIndex;
		if (caret < 0 || caret > input.text.length)
			caret = input.text.length;
		inputView.text = input.text.substr(0, caret) + "|" + input.text.substr(caret);
		inputView.visible = wantFocus;
		hint.visible = wantFocus && input.text == "";
		emojiBtnIcon.visible = wantFocus;

		if (wantFocus && FlxG.mouse.justPressed && mx >= emojiBtnIcon.x && mx < emojiBtnIcon.x + emo
			&& my >= emojiBtnIcon.y && my < emojiBtnIcon.y + emo)
			paletteOpen = !paletteOpen;
		if (paletteOpen && FlxG.mouse.justPressed)
			for (i in 0...paletteIcons.length)
			{
				var e = paletteIcons[i];
				if (mx >= e.x - 2 && mx < e.x + emo + 4 && my >= e.y - 4 && my < e.y + emo + 4)
				{
					input.text += ":" + EMOJI[i] + ":";
					input.caretIndex = input.text.length;
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

		var changed = ChatLog.version != lastVer;
		updateLogFade(elapsed, changed);

		var listH = listHeight();
		if (changed || scroll != lastScroll || listH != lastListH)
		{
			lastVer = ChatLog.version;
			lastScroll = scroll;
			lastListH = listH;
			buildRows(listH);
		}

		updateHover(mx, my, over);
	}

	function setLogAlpha(value:Float):Void
	{
		if (value == logAlpha)
			return;
		logAlpha = value;
		for (row in rows)
			row.alpha = value;
	}

	function updateLogFade(elapsed:Float, changed:Bool):Void
	{
		if (wantFocus || changed || wasFocused)
			idleAge = 0;
		else
			idleAge += elapsed;

		var value:Float = 1;
		if (!wantFocus && idleAge > LOG_HOLD)
			value = Math.max(0, 1 - (idleAge - LOG_HOLD) / LOG_FADE);
		setLogAlpha(value);
		wasFocused = wantFocus;
	}

	function listHeight():Int
	{
		var lh = h;
		if (wantFocus)
			lh -= inputH;
		if (wantFocus && paletteOpen)
			lh -= paletteH;
		if (wantFocus && (replyKey != null || editKey != null))
			lh -= stripH;
		return lh;
	}

	function refreshStrip():Void
	{
		var want = wantFocus && (replyKey != null || editKey != null);

		stripText.visible = want;
		for (e in paletteIcons)
			e.visible = wantFocus && paletteOpen;

		if (editKey != null)
			stripText.text = Lang.t("chat.editing");
		else if (replyKey != null)
		{
			var m = ChatLog.get(replyKey);
			stripText.text = Lang.t("chat.replyTo", [m == null ? "?" : m.name]);
		}
		placeComposer();
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
		sp.alpha = logAlpha;
		add(sp);
		rows.push(sp);
	}

	function rowText(lx:Float, ly:Float, text:String, size:Int, color:Int):FlxText
	{
		var t = new FlxText(lx, ly, 0, text);
		t.setFormat(Lang.smallFont(), size, color, LEFT);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		addRow(t);
		return t;
	}

	function buildRows(listH:Int):Void
	{
		clearRows();

		var actionW = wantFocus ? chipW * 3 + px(10) : 0;
		var maxW = w - pad * 2 - actionW;
		var idx = ChatLog.messages.length - 1 - scroll;
		var used = gap;
		var blocks:Array<{
			message:ChatMsg,
			lines:Array<Array<{sx:Float, text:String, color:Int, emoji:Int}>>,
			quote:Int,
			height:Int
		}> = [];

		while (idx >= 0)
		{
			var m = ChatLog.messages[idx];
			idx--;

			var lines = layout(m, maxW);
			var quote = m.reply != null && !m.deleted ? quoteH : 0;
			var blockH = quote + lines.length * lineH;
			if (used + blockH > listH - gap)
				break;
			blocks.unshift({message: m, lines: lines, quote: quote, height: blockH});
			used += blockH + gap;
		}

		var top = gap;
		for (block in blocks)
		{
			var m = block.message;
			var lines = block.lines;
			var quote = block.quote;
			var blockH = block.height;

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
			top += blockH + gap;
		}
		composerY = top;
		placeComposer();
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
		put(nm, util.HuePalette.nameTint(m.hue), -1, measure(nm, bodySize) + px(4));

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
			{
				var rest = tok.text;
				while (rest.length > 0)
				{
					var take = rest.length;
					while (take > 1 && measure(rest.substr(0, take), bodySize) - px(2) > maxW)
						take--;
					var part = rest.substr(0, take);
					put(part, FlxColor.WHITE, -1, measure(part, bodySize) - px(2));
					rest = rest.substr(take);
				}
			}
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
		hoverOwn = false;
		if (over)
			for (hit in rowHits)
				if (my >= y + hit.ry && my < y + hit.ry + hit.rh)
				{
					hoverKey = hit.key;
					hoverOwn = hit.own;
					break;
				}

		var showChips = wantFocus && hoverKey != null;
		chipR.visible = showChips;
		chipE.visible = showChips && hoverOwn;
		chipX.visible = showChips && hoverOwn;
		if (!showChips)
			return;

		var chipLeft = x + w - (chipW * 3 + px(8));
		var chipTop = y;
		for (hit in rowHits)
			if (hit.key == hoverKey)
			{
				chipTop += hit.ry;
				break;
			}
		chipR.setPosition(chipLeft, chipTop);
		chipE.setPosition(chipLeft + chipW, chipTop);
		chipX.setPosition(chipLeft + chipW * 2, chipTop);

		if (!FlxG.mouse.justPressed)
			return;
		if (my < chipTop || my >= chipTop + lineH || mx < chipLeft || mx >= chipLeft + chipW * 3)
			return;

		var slot = Std.int((mx - chipLeft) / chipW);
		if (slot == 0)
		{
			replyKey = hoverKey;
			editKey = null;
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
				wantFocus = true;
			}
		}
		else if (slot == 2 && hoverOwn)
			ChatLog.remove(hoverKey);
	}

	override public function destroy():Void
	{
		if (liveChat == this)
			liveChat = null;
		super.destroy();
	}
}
