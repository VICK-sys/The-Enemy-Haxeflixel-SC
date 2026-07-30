package;

import flixel.FlxG;
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
		addChild(new FlxGame(0, 0, TitleSequence, 60, 60, true));
		keepPresenting();
		ui.MenuCursor.init();
		util.AspectBars.init(this);
		counter = new FPS(10, 3, 0xFFFFFF);
		addChild(counter);
		addEventListener(Event.ENTER_FRAME, onFrame);
	}

	static inline var IDLE_FPS:Int = 10;

	function keepPresenting():Void
	{
		FlxG.autoPause = false;
		FlxG.signals.postGameReset.add(function() FlxG.autoPause = false);
		FlxG.signals.postStateSwitch.add(snapPixels);
		snapPixels();
		FlxG.signals.focusLost.add(function() FlxG.drawFramerate = IDLE_FPS);
		FlxG.signals.focusGained.add(function() FlxG.drawFramerate = FlxG.updateFramerate);
	}

	function snapPixels():Void
	{
		if (FlxG.camera != null)
			FlxG.camera.pixelPerfectRender = true;
	}

	function onFrame(_:Event):Void
		DiscordPresence.tick();
}
