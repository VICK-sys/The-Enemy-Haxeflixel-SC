package systems;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.ScrapPickup;
import util.Paths;
import util.WorldClock;

class Scraps
{
	static inline var MAGNET:Float = 170;
	static inline var PULL_MIN:Float = 90;
	static inline var PULL_MAX:Float = 620;
	static inline var PICK_GAP:Float = 0.09;

	public var group:FlxTypedGroup<ScrapPickup>;

	private var player:Player;
	private var status:PlayerCombat;
	private var pickTimer:Float = 0;

	public function new(player:Player, status:PlayerCombat)
	{
		this.player = player;
		this.status = status;
		group = new FlxTypedGroup<ScrapPickup>();
	}

	public function drop(cx:Float, cy:Float):Void
	{
		var s = group.recycle(ScrapPickup);
		s.drop(cx, cy);
	}

	public function clear():Void
	{
		for (s in group.members)
			if (s != null && s.exists)
				s.kill();
	}

	public function update(elapsed:Float):Void
	{
		if (status.dead)
			return;

		var px = player.x + player.width / 2;
		var py = player.feetY - player.height / 2;
		var step = elapsed * WorldClock.scale;

		if (pickTimer > 0)
			pickTimer -= step;

		var take:ScrapPickup = null;
		var takeLen:Float = 0;

		for (s in group.members)
		{
			if (s == null || !s.exists)
				continue;

			var dx = px - (s.x + s.width / 2);
			var dy = py - (s.y + s.height / 2);
			var len = Math.sqrt(dx * dx + dy * dy);

			if (len < MAGNET)
			{
				var near = 1 - len / MAGNET;
				s.pullTo(px, py, PULL_MIN + (PULL_MAX - PULL_MIN) * near * near, step);
			}

			if (s.x + s.width <= player.x || player.x + player.width <= s.x
				|| s.y + s.height <= player.y || player.y + player.height <= s.y)
				continue;

			if (take == null || len < takeLen)
			{
				take = s;
				takeLen = len;
			}
		}

		if (take == null || pickTimer > 0)
			return;

		pickTimer = PICK_GAP;
		util.Levels.award(util.Levels.scrapValue());
		FlxG.sound.play(Paths.sound("bulletLoad"), 0.5);
		take.kill();
	}
}
