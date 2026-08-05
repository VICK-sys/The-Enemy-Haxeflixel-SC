package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.events.Event;
import states.TitleSequence;
import util.DiscordPresence;

class Main extends Sprite
{
	static inline var COUNTER_RIGHT:Float = 10;
	static inline var COUNTER_TOP:Float = 3;

	public static var counter:ui.Counter;

	public function new()
	{
		super();
		if (!util.DpiAware.claimed)
			return;
		DiscordPresence.init();
		counter = new ui.Counter(0, 0);
		var game = new FlxGame(1280, 720, TitleSequence, 60, 60, true);
		@:privateAccess game._customSoundTray = ui.SoundTray;
		FlxG.signals.postGameStart.add(function() {
			var tray = cast(FlxG.game.soundTray, ui.SoundTray);
			if (tray != null)
				tray.listen();
		});
		addChild(game);
		keepPresenting();
		ui.MenuCursor.init();
		util.ScreenCapture.init();
		util.AspectBars.init(this);
		util.ShotCard.attach(this);
		addChild(counter);
		fitCounter();
		FlxG.signals.gameResized.add(function(_, _) fitCounter());
		addEventListener(Event.ENTER_FRAME, onFrame);
	}

	function fitCounter():Void
	{
		if (counter == null)
			return;
		var m = FlxG.scaleMode;
		var s = m != null && m.scale.x > 0 ? m.scale.x : 1;
		counter.scaleX = counter.scaleY = s;
		var right:Float = FlxG.stage.stageWidth;
		var top:Float = 0;
		if (m != null && m.gameSize.x > 0)
		{
			right = m.offset.x + m.gameSize.x;
			top = m.offset.y;
		}
		counter.x = Math.floor(right - counter.width - COUNTER_RIGHT);
		counter.y = Math.floor(top + COUNTER_TOP);
	}

	function keepPresenting():Void
	{
		FlxG.autoPause = false;
		FlxG.signals.postGameReset.add(function() FlxG.autoPause = false);
		FlxG.signals.postStateSwitch.add(snapPixels);
		snapPixels();
		FlxG.signals.focusLost.add(function() FlxG.drawFramerate = util.SaveData.idleFramerate());
		FlxG.signals.focusGained.add(function() FlxG.drawFramerate = FlxG.updateFramerate);
	}

	function snapPixels():Void
	{
		if (FlxG.camera != null)
			FlxG.camera.pixelPerfectRender = true;
	}

	function onFrame(_:Event):Void
	{
		DiscordPresence.tick();
		fitCounter();
	}
}

