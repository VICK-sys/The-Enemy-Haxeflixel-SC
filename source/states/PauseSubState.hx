package states;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class PauseSubState extends FlxSubState
{
	private var camUI:FlxCamera;

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

		var title = new FlxText(0, 280, FlxG.width, "PAUSED");
		title.setFormat(null, 48, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		title.cameras = [camUI];
		add(title);

		var hint = new FlxText(0, 360, FlxG.width, "ESC TO RESUME");
		hint.setFormat(null, 16, FlxColor.WHITE, CENTER);
		hint.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		hint.cameras = [camUI];
		add(hint);

		FlxG.sound.pause();

		super.create();
	}

	override public function close():Void
	{
		FlxG.sound.resume();
		super.close();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
			close();

		if (FlxG.keys.justPressed.ONE)
			FlxG.sound.changeVolume(-0.1);

		if (FlxG.keys.justPressed.TWO)
			FlxG.sound.changeVolume(0.1);
	}
}
