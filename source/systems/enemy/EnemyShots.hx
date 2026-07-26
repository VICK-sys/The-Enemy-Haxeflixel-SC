package systems.enemy;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.enemy.Enemies;
import entities.enemy.EnemyShot;
import util.Paths;
import util.WorldClock;
import systems.world.Arena;
import systems.world.PropBlock;

class EnemyShots
{
	static inline var PROBE:Float = 10;

	public var group(default, null):FlxTypedGroup<EnemyShot>;
	public var onShot:(Float, Float, Float, Float, Float, Float, Float, String) -> Void;

	private var arena:Arena;
	private var status:PlayerCombat;

	public function new(arena:Arena, status:PlayerCombat)
	{
		this.arena = arena;
		this.status = status;
		group = new FlxTypedGroup<EnemyShot>();
	}

	public function emit(e:Enemies):Void
	{
		if (e.pendingShots.length == 0)
			return;

		var cx = e.x + e.width / 2;
		var cy = e.y + e.height / 2;
		var lastSound:String = null;

		for (spec in e.pendingShots)
		{
			var sx = spec.useOrigin ? spec.originX : cx;
			var sy = spec.useOrigin ? spec.originY : cy;
			group.recycle(EnemyShot).fire(sx, sy, spec.dirX, spec.dirY, spec.damage, spec.speed, spec.range, spec.sprite);
			if (onShot != null)
				onShot(sx, sy, spec.dirX, spec.dirY, spec.damage, spec.speed, spec.range, spec.sprite);
			if (spec.sound != null && spec.sound != lastSound)
			{
				FlxG.sound.play(Paths.sound(spec.sound), 0.5);
				lastSound = spec.sound;
			}
		}
		e.recycleShots();
	}

	public function update():Void
	{
		if (WorldClock.scale <= 0.05)
			return;

		for (shot in group.members)
		{
			if (shot == null || !shot.exists)
				continue;

			var px = shot.x + shot.width / 2 + shot.dirX * PROBE;
			var py = shot.y + shot.height / 2 + shot.dirY * PROBE;
			if (arena.wallAt(px, py) || PropBlock.at(px, py))
			{
				shot.kill();
				continue;
			}

			if (status.hurtPlayer(shot, shot.damage))
				shot.kill();
		}
	}
}
