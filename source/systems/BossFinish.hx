package systems;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import entities.Player;

class BossFinish
{
	static inline var SLOW:Float = 0.3;
	static inline var ZOOM_IN:Float = 1.75;
	static inline var PULL:Float = 0.62;
	static inline var EASE_IN:Float = 0.25;
	static inline var HOLD:Float = 1.6;
	static inline var EASE_OUT:Float = 1.15;

	public var active(get, never):Bool;

	private var player:Player;
	private var fx:Fx;
	private var running:Bool = false;
	private var clock:Float = 0;
	private var atX:Float = 0;
	private var atY:Float = 0;
	private var fromZoom:Float = 1;
	private var toZoom:Float = 1;

	public function new(player:Player, fx:Fx)
	{
		this.player = player;
		this.fx = fx;
	}

	function get_active():Bool
		return running;

	public function trigger(cx:Float, cy:Float):Void
	{
		atX = cx;
		atY = cy;
		clock = 0;
		if (!running)
		{
			running = true;
			fromZoom = FlxG.camera.zoom;
			toZoom = fromZoom * ZOOM_IN;
		}
	}

	public function cancel():Void
	{
		if (!running)
			return;
		running = false;
		clock = 0;
		fx.slowFactor = 1;
		FlxG.camera.zoom = fromZoom;
		FlxG.camera.targetOffset.set(0, 0);
	}

	public function update(elapsed:Float):Void
	{
		if (!running)
			return;

		clock += FlxG.timeScale > 0.001 ? elapsed / FlxG.timeScale : elapsed;

		var reach:Float = 0;
		if (clock < EASE_IN)
			reach = FlxEase.quadOut(clock / EASE_IN);
		else if (clock < EASE_IN + HOLD)
			reach = 1;
		else
		{
			var out = (clock - EASE_IN - HOLD) / EASE_OUT;
			if (out >= 1)
			{
				cancel();
				return;
			}
			reach = 1 - FlxEase.quadInOut(out);
		}

		fx.slowFactor = 1 + (SLOW - 1) * reach;
		FlxG.camera.zoom = fromZoom + (toZoom - fromZoom) * reach;

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		FlxG.camera.targetOffset.set((atX - pmx) * PULL * reach, (atY - pmy) * PULL * reach);
	}
}
