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

	private var joined:FlxText;
	private var failed:Bool = false;

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

		joined = label(rowX, py + 226, ROW_W, "", 24, FlxColor.WHITE, LEFT);

		hints(Lang.t("lobby.hostHints"), py + H - 74);
		refresh();

		super.create();
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

		if (armed()
			&& (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE
				|| util.Controls.justPressed(util.Controls.ACCEPT)
				|| util.Controls.justPressed(util.Controls.INTERACT)))
			close();
	}
}
