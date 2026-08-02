package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import net.Net;
import util.Lang;
import util.SaveData;

class JoinSubState extends LobbyPanel
{
	static inline var W:Int = 860;
	static inline var H:Int = 420;
	static inline var ROW_W:Int = 700;
	static inline var ROW_H:Int = 66;
	static inline var IP_MAX:Int = 21;
	static inline var IP_MIN:Int = 7;
	static inline var CARET_RATE:Float = 3.4;
	static inline var LOCAL:String = "127.0.0.1";

	public var onJoined:Void->Void;

	private var ipText:FlxText;
	private var ghost:FlxText;
	private var caret:FlxSprite;
	private var note:FlxText;
	private var ip:String = "";
	private var blink:Float = 0;
	private var rowX:Float = 0;
	private var rowY:Float = 0;

	public function new(camUI:FlxCamera)
	{
		super(camUI, W, H);
	}

	override public function create():Void
	{
		chrome("lobby.join");

		rowX = px + (panelW - ROW_W) * 0.5;
		rowY = py + 126;

		label(rowX, py + 96, ROW_W, Lang.t("lobby.joinAddress"), 20, LobbyPanel.DIM, LEFT);
		well(rowX, rowY, ROW_W, ROW_H);

		ghost = label(rowX + 34, rowY + 18, 0, LOCAL, 30, LobbyPanel.DIM, LEFT);
		ghost.alpha = 0.35;
		ipText = label(rowX + 18, rowY + 18, 0, "", 30, FlxColor.WHITE, LEFT);
		caret = plate(rowX + 18, rowY + 17, 3, 20, FlxColor.WHITE);

		note = label(rowX, py + 226, ROW_W, "", 22, LobbyPanel.DIM, LEFT);

		hints(Lang.t("lobby.joinHints"), py + H - 92);
		hints(Lang.t("lobby.joinHints2"), py + H - 64);

		ip = SaveData.lastIp();
		refresh();

		super.create();
	}

	function refresh():Void
	{
		ipText.text = ip;
		ghost.visible = ip == "";
		caret.x = ipText.x + (ip == "" ? 0 : ipText.width);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		tickArm(elapsed);

		blink += elapsed * CARET_RATE;
		caret.visible = Math.sin(blink) > -0.2;

		if (!armed())
			return;

		if (FlxG.keys.justPressed.ESCAPE)
		{
			close();
			return;
		}

		if (FlxG.keys.justPressed.ENTER || util.Controls.justPressed(util.Controls.ACCEPT))
		{
			connect();
			return;
		}

		typeIp(elapsed);
	}

	function paste():Void
	{
		var raw = lime.system.Clipboard.text;
		if (raw == null)
			raw = "";

		var out = "";
		var started = false;
		for (i in 0...raw.length)
		{
			if (out.length >= IP_MAX)
				break;
			var c = raw.charCodeAt(i);
			var digit = c >= 48 && c <= 57;
			var sep = c == 46 || c == 58;
			if (!started)
			{
				if (!digit)
					continue;
				started = true;
			}
			else if (!digit && !sep)
				break;
			out += raw.charAt(i);
		}
		while (out.length > 0)
		{
			var last = out.charCodeAt(out.length - 1);
			if (last != 46 && last != 58)
				break;
			out = out.substr(0, out.length - 1);
		}

		if (out == "")
		{
			note.text = Lang.t("lobby.joinPasteNone");
			note.color = LobbyPanel.BAD;
			return;
		}

		ip = out;
		note.text = "";
		refresh();
	}

	function copyOut():Void
	{
		if (ip == "")
			return;
		lime.system.Clipboard.text = ip;
		note.text = Lang.t("lobby.joinCopied");
		note.color = LobbyPanel.GOOD;
	}

	function connect():Void
	{
		if (ip.length < IP_MIN)
		{
			note.text = Lang.t("lobby.joinShort");
			note.color = LobbyPanel.BAD;
			return;
		}

		note.text = Lang.t("online.connecting");
		note.color = LobbyPanel.DIM;

		if (Net.join(ip))
		{
			SaveData.setLastIp(ip);
			Net.inGame = false;
			if (onJoined != null)
				onJoined();
			close();
			return;
		}

		note.text = Lang.t("lobby.joinFailed", [ip]);
		note.color = LobbyPanel.BAD;
	}

	function typeIp(elapsed:Float):Void
	{
		if (eraseWanted(elapsed))
		{
			if (ip.length > 0)
			{
				ip = ip.substr(0, ip.length - 1);
				refresh();
			}
			return;
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.V)
				paste();
			else if (FlxG.keys.justPressed.C)
				copyOut();
			return;
		}

		if (FlxG.keys.justPressed.L)
		{
			ip = LOCAL;
			note.text = "";
			refresh();
			return;
		}

		if (ip.length >= IP_MAX)
			return;

		for (i in 0...10)
			if (FlxG.keys.checkStatus(48 + i, JUST_PRESSED) || FlxG.keys.checkStatus(96 + i, JUST_PRESSED))
			{
				ip += Std.string(i);
				refresh();
				return;
			}

		if (FlxG.keys.justPressed.PERIOD || FlxG.keys.justPressed.NUMPADPERIOD)
		{
			ip += ".";
			refresh();
			return;
		}

		if (FlxG.keys.justPressed.SEMICOLON)
		{
			ip += ":";
			refresh();
		}
	}
}
