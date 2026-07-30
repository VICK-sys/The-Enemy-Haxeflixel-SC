package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.events.Event;
import states.TitleSequence;
import util.DiscordPresence;

class Main extends Sprite
{
	public static var counter:ui.Counter;

	public function new()
	{
		super();
		if (!util.DpiAware.claimed)
			return;
		DiscordPresence.init();
		addChild(new FlxGame(1280, 720, TitleSequence, 60, 60, true));
		keepPresenting();
		ui.MenuCursor.init();
		util.AspectBars.init(this);
		counter = new ui.Counter(10, 3);
		addChild(counter);
		fitCounter();
		FlxG.signals.gameResized.add(function(_, _) fitCounter());
		addEventListener(Event.ENTER_FRAME, onFrame);
	}

	static inline var IDLE_FPS:Int = 10;

	function fitCounter():Void
	{
		if (counter == null)
			return;
		var m = FlxG.scaleMode;
		var s = m != null && m.scale.x > 0 ? m.scale.x : 1;
		counter.scaleX = counter.scaleY = s;
	}

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
