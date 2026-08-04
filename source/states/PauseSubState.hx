package states;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.MenuList;
import util.IrisWipe;
import util.Lang;
import util.Music;

class PauseSubState extends FlxSubState
{

	private var camUI:FlxCamera;
	private var list:MenuList;
	private var leaving:Bool = false;
	private var inLobby:Bool;
	private var afk:systems.AfkPilot;

	public function new(camUI:FlxCamera, inLobby:Bool = false, afk:systems.AfkPilot = null)
	{
		super();
		this.camUI = camUI;
		this.inLobby = inLobby;
		this.afk = afk;
	}

	function exitKey():String
		return inLobby ? "pause.quit" : "pause.lobby";

	function rowKeys():Array<String>
	{
		var keys = ["pause.resume"];
		if (afk != null)
			keys.push("pause.afk");
		keys.push("pause.help");
		keys.push("pause.options");
		keys.push(exitKey());
		return keys;
	}

	function labelFor(key:String):String
	{
		if (key == "pause.afk")
			return Lang.t("pause.afk", [Lang.t(afk.on ? "common.on" : "common.off")]);
		return Lang.t(key);
	}

	override public function create():Void
	{
		var overlay = new FlxSprite(0, 0);
		overlay.makeGraphic(FlxG.width, FlxG.height, 0x99000000);
		overlay.cameras = [camUI];
		add(overlay);

		var title = new FlxText(0, 190, FlxG.width, Lang.t("pause.title"));
		title.setFormat(Lang.font(), 48, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		title.cameras = [camUI];
		add(title);

		list = new MenuList([for (k in rowKeys()) labelFor(k)], afk == null ? 300 : 272, 66, 32);
		list.onChoose = choose;
		list.cameras = [camUI];
		add(list);

		FlxG.mouse.visible = true;
		Music.hold();

		subStateClosed.add(function(_) relabel(title));

		super.create();
	}

	override public function close():Void
	{
		FlxG.mouse.visible = false;
		Music.release();
		util.Controls.resetDevices();
		super.close();
	}

	override public function destroy():Void
	{
		Music.release();
		super.destroy();
	}

	function relabel(title:FlxText):Void
	{
		title.text = Lang.t("pause.title");
		title.font = Lang.font();

		var keys = rowKeys();
		for (i in 0...keys.length)
		{
			list.rowAt(i).font = Lang.font();
			list.setLabel(i, labelFor(keys[i]));
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (util.Controls.menuBack() || util.Controls.pausePressed())
		{
			util.MenuSfx.cancel();
			close();
		}

		if (FlxG.keys.justPressed.MINUS)
			FlxG.sound.changeVolume(-0.1);

		if (FlxG.keys.justPressed.PLUS)
			FlxG.sound.changeVolume(0.1);
	}

	function choose(i:Int):Void
	{
		if (leaving)
			return;

		switch (rowKeys()[i])
		{
			case "pause.resume":
				close();
			case "pause.afk":
				afk.set(!afk.on);
				list.setLabel(i, labelFor("pause.afk"));
			case "pause.help":
				openSubState(new TutorialSubState(camUI, true));
			case "pause.options":
				openSubState(new OptionsSubState(camUI));
			default:
				leaving = true;
				list.enabled = false;
				FlxG.mouse.visible = false;
				Music.release();
				net.Net.stop();
				if (util.CustomArena.fromEditor)
					new IrisWipe(this).close(function() FlxG.switchState(() -> new EditorState()));
				else if (inLobby)
				{
					util.Lobby.leave();
					new IrisWipe(this).close(function() FlxG.switchState(() -> new MainMenuState()));
				}
				else
					new IrisWipe(this).close(function() FlxG.switchState(() -> new LobbyState()));
		}
	}
}
