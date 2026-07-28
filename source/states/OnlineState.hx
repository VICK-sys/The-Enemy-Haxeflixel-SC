package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import net.Net;
import ui.MenuList;
import util.IrisWipe;
import util.MenuSlash;
import util.SaveData;
import util.Lang;

class OnlineState extends FlxState
{
	static inline var ACCENT:Int = 0xFFE0132D;

	private var list:MenuList;
	private var status:FlxText;
	private var ipText:FlxText;
	private var wipe:IrisWipe;
	private var ip:String = "";
	private var typing:Bool = false;
	private var nameMode:Bool = false;
	private var playerName:String = "";
	private var nameText:FlxText;
	private var weaponText:FlxText;

	static inline var NAME_MAX:Int = 12;
	private var hosting:Bool = false;
	private var waiting:Bool = false;
	private var leaving:Bool = false;
	private var busy:Bool = false;

	override public function create()
	{
		persistentUpdate = true;
		FlxG.camera.bgColor = 0xFF000000;
		FlxG.mouse.visible = true;

		var title = new FlxText(0, 90, FlxG.width, Lang.t("online.title"));
		title.setFormat(Lang.font(), 72, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, ACCENT, 4);
		add(title);

		list = new MenuList([Lang.t("online.host"), Lang.t("online.join"), Lang.t("online.weapon"), Lang.t("online.setName"), Lang.t("online.color"), Lang.t("common.back")], 236, 58, 32);
		list.onChoose = choose;
		list.onAdjust = adjust;
		add(list);
		refreshColor();

		weaponText = new FlxText(0, 514, FlxG.width, "");
		weaponText.setFormat(Lang.font(), 22, FlxColor.WHITE, CENTER);
		weaponText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(weaponText);

		nameText = new FlxText(0, 546, FlxG.width, "");
		nameText.setFormat(Lang.font(), 22, FlxColor.WHITE, CENTER);
		nameText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(nameText);

		ipText = new FlxText(0, 578, FlxG.width, "");
		ipText.setFormat(Lang.font(), 24, FlxColor.WHITE, CENTER);
		ipText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(ipText);

		status = new FlxText(0, 620, FlxG.width, "");
		status.setFormat(Lang.font(), 20, FlxColor.YELLOW, CENTER);
		status.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(status);

		var hint = new FlxText(0, FlxG.height - 32, FlxG.width, Lang.t("online.hint"));
		hint.setFormat(Lang.font(), 16, FlxColor.WHITE, CENTER);
		hint.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		hint.alpha = 0.7;
		add(hint);

		ip = SaveData.lastIp();
		playerName = SaveData.playerName();
		refreshName();
		refreshWeapon();

		subStateClosed.add(function(_)
		{
			FlxG.mouse.visible = true;
			list.enabled = !typing && !busy;
		});

		wipe = new IrisWipe(this);
		wipe.open();

		if (!OnlineHelpSubState.shown)
		{
			OnlineHelpSubState.shown = true;
			openHelp();
		}

		super.create();
	}

	function openHelp():Void
	{
		list.enabled = false;
		openSubState(new OnlineHelpSubState());
	}

	function choose(i:Int):Void
	{
		if (leaving || waiting || busy)
			return;

		busy = true;
		list.enabled = false;
		MenuSlash.play(this, list.rowAt(i), list.marker, function() commit(i));
	}

	function commit(i:Int):Void
	{
		if (leaving)
			return;

		switch (i)
		{
			case 0:
				startHost();
			case 1:
				beginTyping();
			case 2:
				openWeaponPick();
			case 3:
				beginNaming();
			case 4:
				cycleColor(1);
				releaseMenu();
			default:
				back();
		}
	}

	function adjust(i:Int, dir:Int):Void
	{
		if (leaving || waiting || busy || typing || i != 4)
			return;
		cycleColor(dir);
	}

	static var COLORS:Array<Int> = [
		0xFFFFFFFF, 0xFFFF7373, 0xFFFFB973, 0xFFFFFF73, 0xFFB9FF73, 0xFF73FF73, 0xFF73FFB9,
		0xFF73FFFF, 0xFF73B9FF, 0xFF7373FF, 0xFFB973FF, 0xFFFF73FF, 0xFFFF73B9
	];

	function cycleColor(dir:Int):Void
	{
		var idx = COLORS.indexOf(SaveData.playerColor());
		if (idx < 0)
			idx = 0;
		SaveData.setPlayerColor(COLORS[(idx + dir + COLORS.length) % COLORS.length]);
		refreshColor();
	}

	function refreshColor():Void
		list.rowAt(4).color = SaveData.playerColor();

	function releaseMenu():Void
	{
		busy = false;
		list.enabled = true;
		list.restoreRows();
	}

	function startHost():Void
	{
		typing = false;
		if (Net.host())
		{
			hosting = true;
			waiting = true;
			list.enabled = false;
			status.color = FlxColor.YELLOW;
			status.text = Net.hostPort == Net.PORT
				? Lang.t("online.hosting", [Net.PORT])
				: Lang.t("online.hostingBusy", [Net.PORT, Net.hostPort]);
		}
		else
		{
			releaseMenu();
			status.color = ACCENT;
			status.text = Lang.t("online.noPort", [Net.PORT, Net.PORT + Net.PORT_TRIES - 1]);
		}
	}

	function beginTyping():Void
	{
		typing = true;
		nameMode = false;
		list.enabled = false;
		status.color = FlxColor.YELLOW;
		status.text = Lang.t("online.typeIp");
		refreshIp();
	}

	function openWeaponPick():Void
	{
		list.enabled = false;
		var picker = new WeaponPickSubState(FlxG.camera);
		picker.closeCallback = function()
		{
			refreshWeapon();
			if (waiting || hosting)
				list.enabled = false;
			else
				releaseMenu();
		};
		openSubState(picker);
	}

	function refreshWeapon():Void
		weaponText.text = Lang.t("online.weaponLabel", [WeaponPickSubState.nameOf(WeaponPickSubState.lastPick)]);

	function beginNaming():Void
	{
		typing = true;
		nameMode = true;
		list.enabled = false;
		status.color = FlxColor.YELLOW;
		status.text = Lang.t("online.typeName");
		refreshName();
	}

	function refreshIp():Void
	{
		ipText.text = (typing && !nameMode) || ip.length > 0 ? Lang.t("online.ipLabel", [ip + (typing && !nameMode ? "_" : "")]) : "";
	}

	function refreshName():Void
	{
		var shown = playerName.length > 0 ? playerName : Lang.t("online.defaultName");
		nameText.text = Lang.t("online.nameLabel", [nameMode ? playerName + "_" : shown]);
	}

	function saveName():Void
	{
		typing = false;
		nameMode = false;
		SaveData.setPlayerName(playerName);
		releaseMenu();
		status.text = "";
		refreshName();
		refreshIp();
	}

	function tryJoin():Void
	{
		typing = false;
		refreshIp();
		status.color = FlxColor.YELLOW;
		status.text = Lang.t("online.connecting");
		if (Net.join(ip))
		{
			SaveData.setLastIp(ip);
			waiting = true;
			status.text = Lang.t("online.connected");
		}
		else
		{
			releaseMenu();
			status.color = ACCENT;
			status.text = Lang.t("online.failed", [ip]);
		}
	}

	function back():Void
	{
		if (leaving)
			return;
		leaving = true;
		Net.stop();
		wipe.close(function() FlxG.switchState(() -> new MainMenuState()));
	}


	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (leaving)
			return;

		var helpOpen = subState != null;

		for (msg in Net.poll())
		{
			if (Net.isClient && (msg.t == "start" || (msg.t == "hello" && msg.go == true)))
				launch();
		}

		if (hosting && Net.connected)
		{
			var n = Net.guestCount;
			status.text = n + (n == 1 ? " PLAYER" : " PLAYERS") + " CONNECTED - PRESS ENTER TO START\n(up to "
				+ Net.MAX_GUESTS + " can join, and more can drop in later)";
			if (!helpOpen && FlxG.keys.justPressed.ENTER)
			{
				Net.send({t: "start"});
				launch();
			}
		}

		if (Net.dropped && waiting)
		{
			waiting = false;
			hosting = false;
			Net.stop();
			releaseMenu();
			status.color = ACCENT;
			status.text = Lang.t("hud.connectionLost");
		}

		if (helpOpen)
			return;

		if (typing)
			updateTyping();

		if (FlxG.keys.justPressed.H && !typing && !busy)
			openHelp();

		if (FlxG.keys.justPressed.TAB && !typing)
			openWeaponPick();

		if (FlxG.keys.justPressed.ESCAPE)
		{
			if (typing)
				cancelTyping();
			else if (waiting)
				cancelSession();
			else
				back();
		}
	}

	function cancelTyping():Void
	{
		if (nameMode)
			playerName = SaveData.playerName();
		typing = false;
		nameMode = false;
		releaseMenu();
		status.text = "";
		refreshIp();
		refreshName();
	}

	function cancelSession():Void
	{
		waiting = false;
		hosting = false;
		Net.stop();
		releaseMenu();
		status.color = FlxColor.YELLOW;
		status.text = "";
	}

	function launch():Void
	{
		if (leaving)
			return;
		leaving = true;
		wipe.close(function()
		{
			FlxG.mouse.visible = false;
			FlxG.switchState(() -> new PlayState());
		});
	}

	function updateTyping():Void
	{
		if (nameMode)
		{
			updateNaming();
			return;
		}

		var keys:Array<FlxKey> = [FlxKey.ZERO, FlxKey.ONE, FlxKey.TWO, FlxKey.THREE, FlxKey.FOUR, FlxKey.FIVE, FlxKey.SIX, FlxKey.SEVEN, FlxKey.EIGHT, FlxKey.NINE];
		var pads:Array<FlxKey> = [FlxKey.NUMPADZERO, FlxKey.NUMPADONE, FlxKey.NUMPADTWO, FlxKey.NUMPADTHREE, FlxKey.NUMPADFOUR, FlxKey.NUMPADFIVE, FlxKey.NUMPADSIX, FlxKey.NUMPADSEVEN, FlxKey.NUMPADEIGHT, FlxKey.NUMPADNINE];
		for (n in 0...10)
		{
			if (FlxG.keys.anyJustPressed([keys[n]]) || FlxG.keys.anyJustPressed([pads[n]]))
				if (ip.length < 21)
					ip += Std.string(n);
		}
		if ((FlxG.keys.justPressed.PERIOD || FlxG.keys.justPressed.NUMPADPERIOD) && ip.length < 21)
			ip += ".";
		if (FlxG.keys.justPressed.BACKSPACE && ip.length > 0)
			ip = ip.substr(0, ip.length - 1);

		refreshIp();

		if (FlxG.keys.justPressed.ENTER && ip.length >= 7)
			tryJoin();
	}

	function updateNaming():Void
	{
		var k = FlxG.keys.firstJustPressed();
		if (playerName.length < NAME_MAX && ((k >= 65 && k <= 90) || (k >= 48 && k <= 57)))
			playerName += String.fromCharCode(k);
		else if (playerName.length < NAME_MAX && FlxG.keys.justPressed.SPACE && playerName.length > 0)
			playerName += " ";
		if (FlxG.keys.justPressed.BACKSPACE && playerName.length > 0)
			playerName = playerName.substr(0, playerName.length - 1);

		refreshName();

		if (FlxG.keys.justPressed.ENTER)
			saveName();
	}
}
