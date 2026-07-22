package;

import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.display.FPS;
import states.TitleSequence;

class Main extends Sprite
{
	public static var counter:FPS;

	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, TitleSequence));
		counter = new FPS(10, 3, 0xFFFFFF);
		addChild(counter);
	}
}
