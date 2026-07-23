package;

import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.display.FPS;
import openfl.events.Event;
import states.TitleSequence;
import util.DiscordPresence;

class Main extends Sprite
{
	public static var counter:FPS;

	public function new()
	{
		super();
		DiscordPresence.init();
		addChild(new FlxGame(0, 0, TitleSequence));
		counter = new FPS(10, 3, 0xFFFFFF);
		addChild(counter);
		addEventListener(Event.ENTER_FRAME, onFrame);
	}

	function onFrame(_:Event):Void
		DiscordPresence.tick();
}
