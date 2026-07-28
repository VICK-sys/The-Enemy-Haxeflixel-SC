package systems;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.HealthPickup;
import util.Paths;

class Pickups
{
	public var group:FlxTypedGroup<HealthPickup>;
	public var onCollect:HealthPickup->Void;

	private var player:Player;
	private var status:PlayerCombat;
	private var nextId:Int = 1;

	public function new(player:Player, status:PlayerCombat)
	{
		this.player = player;
		this.status = status;
		group = new FlxTypedGroup<HealthPickup>();
	}

	public function drop(cx:Float, cy:Float):HealthPickup
	{
		var p = group.recycle(HealthPickup);
		p.drop(cx, cy);
		p.netId = nextId++;
		return p;
	}

	public function findById(id:Int):HealthPickup
	{
		for (p in group.members)
			if (p != null && p.exists && p.netId == id)
				return p;
		return null;
	}

	public function update():Void
	{
		if (status.dead)
			return;
		for (p in group.members)
		{
			if (p == null || !p.exists)
				continue;
			if (status.health >= status.healthMax)
				return;
			if (p.x + p.width <= player.x || player.x + player.width <= p.x
				|| p.y + p.height <= player.y || player.y + player.height <= p.y)
				continue;
			status.heal(HealthPickup.HEAL);
			FlxG.sound.play(Paths.sound("heal"), 0.6);
			p.kill();
			if (onCollect != null)
				onCollect(p);
		}
	}
}
