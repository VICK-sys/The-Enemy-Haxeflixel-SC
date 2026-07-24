package states;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import systems.MenuList;

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

		var title = new FlxText(0, 190, FlxG.width, "PAUSED");
		title.setFormat(null, 48, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		title.cameras = [camUI];
		add(title);

		list = new MenuList(["RESUME", "OPTIONS", "QUIT TO MENU"], 320, 70, 32);
		list.onChoose = choose;
		list.cameras = [camUI];
		add(list);

		FlxG.mouse.visible = true;
		FlxG.sound.pause();

		super.create();
	}

	override public function close():Void
	{
		FlxG.mouse.visible = false;
		FlxG.sound.resume();
		super.close();
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
				FlxG.mouse.visible = false;
				FlxG.switchState(new MainMenuState());
		}
	}
}
