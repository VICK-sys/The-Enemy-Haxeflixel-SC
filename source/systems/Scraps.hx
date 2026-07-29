package systems;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.ScrapPickup;
import util.Paths;
import util.WorldClock;

class Scraps
{
	public static inline var BOSS_SCRAP:Int = 5;

	static inline var MAGNET:Float = 260;
	static inline var PULL_MIN:Float = 200;
	static inline var PULL_MAX:Float = 900;
	static inline var PICK_GAP:Float = 0.1;
	static inline var HOLD:Float = 20;

	public var group:FlxTypedGroup<ScrapPickup>;

	private var player:Player;
	private var status:PlayerCombat;
	private var shadowLayer:FlxTypedGroup<flixel.FlxSprite>;
	private var pickTimer:Float = 0;

	public function new(player:Player, status:PlayerCombat, shadowLayer:FlxTypedGroup<flixel.FlxSprite>)
	{
		this.player = player;
		this.status = status;
		this.shadowLayer = shadowLayer;
		group = new FlxTypedGroup<ScrapPickup>();
	}

	public function drop(cx:Float, cy:Float):Void
	{
		var s = group.recycle(ScrapPickup);
		if (!s.mounted)
		{
			s.mounted = true;
			shadowLayer.add(s.shadow);
		}
		s.drop(cx, cy);
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

			if (len < MAGNET && len > HOLD)
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
