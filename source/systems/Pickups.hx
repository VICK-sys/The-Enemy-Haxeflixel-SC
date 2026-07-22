package systems;

import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.HealthPickup;

class Pickups
{
	public var group:FlxTypedGroup<HealthPickup>;

	private var player:Player;
	private var status:PlayerCombat;

	public function new(player:Player, status:PlayerCombat)
	{
		this.player = player;
		this.status = status;
		group = new FlxTypedGroup<HealthPickup>();
	}

	public function drop(cx:Float, cy:Float):Void
	{
		group.recycle(HealthPickup).drop(cx, cy);
	}

	public function update():Void
	{
		if (status.dead || status.health >= status.healthMax)
			return;
		for (p in group.members)
		{
			if (p == null || !p.exists)
				continue;
			if (p.x + p.width <= player.x || player.x + player.width <= p.x
				|| p.y + p.height <= player.y || player.y + player.height <= p.y)
				continue;
			status.heal(HealthPickup.HEAL);
			p.kill();
		}
	}
}
