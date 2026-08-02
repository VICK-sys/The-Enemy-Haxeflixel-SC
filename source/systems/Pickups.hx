package systems;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.HealthPickup;
import util.Paths;

class Pickups
{
	static inline var GRAB:Float = 26;

	public var group:FlxTypedGroup<HealthPickup>;
	public var onCollect:HealthPickup->Void;

	private var player:Player;
	private var status:PlayerCombat;
	private var nextId:Int = 1;
	private var shadowLayer:FlxTypedGroup<flixel.FlxSprite>;

	public function new(player:Player, status:PlayerCombat, shadowLayer:FlxTypedGroup<flixel.FlxSprite>)
	{
		this.player = player;
		this.status = status;
		this.shadowLayer = shadowLayer;
		group = new FlxTypedGroup<HealthPickup>();
	}

	public function mount(p:HealthPickup):Void
	{
		if (p.mounted)
			return;
		p.mounted = true;
		shadowLayer.add(p.shadow);
	}

	public function drop(cx:Float, cy:Float):HealthPickup
	{
		var p = group.recycle(HealthPickup);
		mount(p);
		p.drop(cx, cy);
		p.netId = nextId++;
		p.puppet = false;
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
			if (p.x + p.width + GRAB <= player.x || player.x + player.width <= p.x - GRAB
				|| p.y + p.height + GRAB <= player.y || player.y + player.height <= p.y - GRAB)
				continue;
			status.heal(HealthPickup.HEAL);
			FlxG.sound.play(Paths.sound("heal"), 0.7);
			p.kill();
			if (onCollect != null)
				onCollect(p);
		}
	}
}
