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

class PauseSubState extends FlxSubState
{
	private var camUI:FlxCamera;
	private var list:MenuList;
	private var leaving:Bool = false;

	public function new(camUI:FlxCamera)
	{
		super();
		this.camUI = camUI;
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

		list = new MenuList([Lang.t("pause.resume"), Lang.t("pause.options"), Lang.t("pause.quit")], 320, 70, 32);
		list.onChoose = choose;
		list.cameras = [camUI];
		add(list);

		FlxG.mouse.visible = true;
		FlxG.sound.pause();

		subStateClosed.add(function(_) relabel(title));

		super.create();
	}

	override public function close():Void
	{
		FlxG.mouse.visible = false;
		FlxG.sound.resume();
		super.close();
	}

	function relabel(title:FlxText):Void
	{
		title.text = Lang.t("pause.title");
		title.font = Lang.font();

		var keys = ["pause.resume", "pause.options", "pause.quit"];
		for (i in 0...keys.length)
		{
			list.rowAt(i).font = Lang.font();
			list.setLabel(i, Lang.t(keys[i]));
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
			close();

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
				openSubState(new OptionsSubState(camUI));
			default:
				leaving = true;
				list.enabled = false;
				FlxG.mouse.visible = false;
				FlxG.sound.resume();
				net.Net.stop();
				if (util.CustomArena.fromEditor)
					new IrisWipe(this).close(function() FlxG.switchState(() -> new EditorState()));
				else
					new IrisWipe(this).close(function() FlxG.switchState(() -> new MainMenuState()));
		}
	}
}
