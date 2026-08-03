package systems;

import flixel.util.FlxColor;
import entities.Player;
import util.GhostTrail;

class DashGhost
{
	static inline var TINT:Int = 0xFFFF6A6A;
	static inline var ALPHA:Float = 0.5;
	static inline var FADE:Float = 3.4;
	static inline var INTERVAL:Float = 0.02;
	static inline var MIN_SPEED:Float = 60;

	public var trail:GhostTrail;
	public var enabled:Bool = true;

	private var player:Player;
	private var tint:FlxColor;

	public function new(player:Player)
	{
		this.player = player;
		trail = new GhostTrail(util.Skins.sheet(), ALPHA, FADE, INTERVAL);
		paint(util.SaveData.playerHue());
	}

	public function paint(hue:Float):Void
	{
		var c:FlxColor = TINT;
		c.hue = c.hue + hue * 360;
		tint = c;
	}

	public function update(elapsed:Float, guarding:Bool):Void
	{
		var cadence = trail.tick(elapsed);
		if (!enabled || !guarding || !cadence || !player.visible)
			return;
		var vx = player.velocity.x;
		var vy = player.velocity.y;
		if (vx * vx + vy * vy < MIN_SPEED * MIN_SPEED)
			return;
		trail.stampFrame(player, tint);
	}

	public function clear():Void
	{
		for (g in trail.group.members)
			if (g != null && g.exists)
				g.kill();
	}
}
