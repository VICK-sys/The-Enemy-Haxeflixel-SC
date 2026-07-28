package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import util.Paths;

class ReloadBar
{
	static inline var SCALE:Float = 4;
	static inline var LIFT:Float = 40;
	static inline var FALLBACK_INSET:Float = 3;

	public var group:FlxTypedGroup<FlxSprite>;

	private var player:Player;
	private var frame:FlxSprite;
	private var line:FlxSprite;
	private var trackLo:Float = 0;
	private var trackHi:Float = 0;

	public function new(player:Player)
	{
		this.player = player;
		group = new FlxTypedGroup<FlxSprite>();
		frame = make("reload_bar");
		line = make("reload_line");
		traceTrack();
		group.add(frame);
		group.add(line);
		group.visible = false;
	}

	function make(name:String):FlxSprite
	{
		var s = new FlxSprite();
		s.loadGraphic(Paths.image("ui/" + name));
		s.antialiasing = false;
		s.scale.set(SCALE, SCALE);
		s.updateHitbox();
		return s;
	}

	function traceTrack():Void
	{
		trackLo = FALLBACK_INSET;
		trackHi = frame.frameWidth - FALLBACK_INSET - line.frameWidth;

		var g = FlxG.bitmap.add(Paths.image("ui/reload_bar"));
		if (g == null || g.bitmap == null)
			return;

		var row = Std.int(g.bitmap.height / 2);
		var bestLo = -1;
		var bestLen = 0;
		var runLo = -1;
		var x = 0;
		while (x <= g.bitmap.width)
		{
			var white = x < g.bitmap.width && g.bitmap.getPixel32(x, row) == 0xFFFFFFFF;
			if (white && runLo < 0)
				runLo = x;
			if (!white && runLo >= 0)
			{
				if (x - runLo > bestLen)
				{
					bestLen = x - runLo;
					bestLo = runLo;
				}
				runLo = -1;
			}
			x++;
		}

		if (bestLen >= 2)
		{
			trackLo = bestLo;
			trackHi = bestLo + bestLen - line.frameWidth;
		}
	}

	public function update(shown:Bool, progress:Float):Void
	{
		group.visible = shown;
		if (!shown)
			return;

		if (progress < 0)
			progress = 0;
		if (progress > 1)
			progress = 1;

		frame.x = player.x + player.width * 0.5 - frame.width * 0.5;
		frame.y = player.y - LIFT * player.sizeScale;

		line.x = frame.x + (trackLo + (trackHi - trackLo) * progress) * SCALE;
		line.y = frame.y + (frame.frameHeight - line.frameHeight) * 0.5 * SCALE;
	}
}
