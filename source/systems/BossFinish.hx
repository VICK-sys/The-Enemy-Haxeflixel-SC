package systems;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import entities.Player;
import util.Paths;

class BossFinish
{
	static inline var SLOW:Float = 0.3;
	static inline var ZOOM_IN:Float = 1.75;
	static inline var PULL:Float = 0.62;
	static inline var EASE_IN:Float = 0.25;
	static inline var HOLD:Float = 1.6;
	static inline var EASE_OUT:Float = 1.15;
	static inline var VOLUME:Float = 0.8;
	static inline var FADE:Float = 0.35;

	public var active(get, never):Bool;
	public var baseZoom:Void->Float;

	private var player:Player;
	private var fx:Fx;
	private var running:Bool = false;
	private var clock:Float = 0;
	private var atX:Float = 0;
	private var atY:Float = 0;
	private var fromZoom:Float = 1;
	private var whoosh:FlxSound;

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
			if (whoosh == null)
				whoosh = FlxG.sound.create(Paths.sound("slowmo")).setup(VOLUME);
			whoosh.volume = VOLUME;
			whoosh.play(true);
		}
	}

	public function cancel():Void
	{
		if (!running)
			return;
		running = false;
		clock = 0;
		hush();
		fx.slowFactor = 1;
		FlxG.camera.zoom = baseZoom != null ? baseZoom() : fromZoom;
		FlxG.camera.targetOffset.set(0, 0);
	}

	function hush():Void
	{
		if (whoosh == null || !whoosh.playing)
			return;
		whoosh.fadeOut(FADE, 0, function(_) whoosh.stop());
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

		var base = baseZoom != null ? baseZoom() : fromZoom;
		fx.slowFactor = 1 + (SLOW - 1) * reach;
		FlxG.camera.zoom = base + (base * ZOOM_IN - base) * reach;

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		FlxG.camera.targetOffset.set((atX - pmx) * PULL * reach, (atY - pmy) * PULL * reach);
		FlxG.camera.snapToTarget();
	}
}
