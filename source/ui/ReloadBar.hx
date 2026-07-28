package ui;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import util.Paths;

class ReloadBar
{
	static inline var SCALE:Float = 4;
	static inline var ART_W:Int = 28;
	static inline var ART_H:Int = 8;
	static inline var LINE_H:Int = 5;
	static inline var INSET:Float = 2;
	static inline var LIFT:Float = 40;

	public var group:FlxTypedGroup<FlxSprite>;

	private var player:Player;
	private var frame:FlxSprite;
	private var line:FlxSprite;

	public function new(player:Player)
	{
		this.player = player;
		group = new FlxTypedGroup<FlxSprite>();
		frame = make("reload_bar");
		line = make("reload_line");
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

		var span = ART_W - INSET * 2 - 1;
		line.x = frame.x + (INSET + span * progress) * SCALE;
		line.y = frame.y + (ART_H - LINE_H) * 0.5 * SCALE;
	}
}
