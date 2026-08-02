package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import net.Net;
import util.Lang;

class HostSubState extends LobbyPanel
{
	static inline var W:Int = 860;
	static inline var H:Int = 348;
	static inline var ROW_W:Int = 700;
	static inline var ROW_H:Int = 66;

	static inline var CONFIRM:Float = 3;

	public var onStopped:Void->Void;

	private var joined:FlxText;
	private var note:FlxText;
	private var failed:Bool = false;
	private var confirm:Float = 0;

	public function new(camUI:FlxCamera)
	{
		super(camUI, W, H);
	}

	override public function create():Void
	{
		if (Net.mode == Off)
		{
			if (Net.host())
				Net.inGame = false;
			else
				failed = true;
		}

		chrome("lobby.host");

		if (failed)
		{
			label(px, py + 150, panelW, Lang.t("lobby.hostFailed"), 26, LobbyPanel.BAD, CENTER);
			hints(Lang.t("lobby.backHint"), py + H - 74);
			super.create();
			return;
		}

		var rowX = px + (panelW - ROW_W) * 0.5;

		label(rowX, py + 96, ROW_W, Lang.t("lobby.hostAddress"), 20, LobbyPanel.DIM, LEFT);
		well(rowX, py + 126, ROW_W, ROW_H);
		var shown = Net.localAddress();
		label(rowX + 18, py + 126 + 18, ROW_W - 36,
			shown == "" ? Lang.t("lobby.hostNoAddress") : shown + ":" + Net.hostPort,
			30, shown == "" ? LobbyPanel.DIM : LobbyPanel.GOOD, LEFT);

		joined = label(rowX, py + 216, ROW_W, "", 24, FlxColor.WHITE, LEFT);
		note = label(rowX, py + 250, ROW_W, "", 20, LobbyPanel.BAD, LEFT);

		hints(Lang.t("lobby.hostHints"), py + H - 74);
		refresh();

		super.create();
	}

	function stopHosting():Void
	{
		Net.stop();
		if (onStopped != null)
			onStopped();
		close();
	}

	function refresh():Void
	{
		if (joined == null)
			return;
		joined.text = Lang.t("lobby.hostJoined", [Net.guestCount, Net.MAX_GUESTS]);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		tickArm(elapsed);
		refresh();

		if (confirm > 0)
		{
			confirm -= elapsed;
			if (confirm <= 0)
				note.text = "";
		}

		if (!failed && armed() && FlxG.keys.justPressed.X)
		{
			if (confirm > 0)
				stopHosting();
			else
			{
				confirm = CONFIRM;
				note.text = Lang.t("lobby.hostStopAgain");
			}
			return;
		}

		if (armed()
			&& (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE
				|| util.Controls.justPressed(util.Controls.ACCEPT)
				|| util.Controls.justPressed(util.Controls.INTERACT)))
			close();
	}
}
