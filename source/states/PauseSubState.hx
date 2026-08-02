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
	static inline var ARM_TIME:Float = 0.12;

	private var camUI:FlxCamera;
	private var list:MenuList;
	private var leaving:Bool = false;
	private var arm:Float = ARM_TIME;
	private var inLobby:Bool;

	public function new(camUI:FlxCamera, inLobby:Bool = false)
	{
		super();
		this.camUI = camUI;
		this.inLobby = inLobby;
	}

	function exitKey():String
		return inLobby ? "pause.quit" : "pause.lobby";

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

		list = new MenuList([Lang.t("pause.resume"), Lang.t("pause.help"), Lang.t("pause.options"), Lang.t(exitKey())], 300, 66, 32);
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

		var keys = ["pause.resume", "pause.help", "pause.options", exitKey()];
		for (i in 0...keys.length)
		{
			list.rowAt(i).font = Lang.font();
			list.setLabel(i, Lang.t(keys[i]));
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (arm > 0)
		{
			arm -= elapsed;
			return;
		}

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

		switch (i)
		{
			case 0:
				close();
			case 1:
				openSubState(new TutorialSubState(camUI, true));
			case 2:
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
