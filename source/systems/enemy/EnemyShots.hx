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
	static inline var STEP:Float = 14;

	public var group(default, null):FlxTypedGroup<EnemyShot>;
	public var onShot:(Float, Float, Float, Float, Float, Float, Float, String) -> Void;
	public var onFriendly:EnemyShot->Bool;
	public var onShield:EnemyShot->Bool;

	private var arena:Arena;
	private var status:PlayerCombat;
	private var fx:Fx;

	public function new(arena:Arena, status:PlayerCombat, fx:Fx)
	{
		this.arena = arena;
		this.status = status;
		this.fx = fx;
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
			if (spec.useOrigin && blocked(cx, cy, sx, sy))
				continue;
			group.recycle(EnemyShot).fire(sx, sy, spec.dirX, spec.dirY, spec.damage, spec.speed, spec.range, spec.sprite);
			if (onShot != null)
				onShot(sx, sy, spec.dirX, spec.dirY, spec.damage, spec.speed, spec.range, spec.sprite);
			if (spec.sound != null && spec.sound != lastSound)
			{
				util.Sfx.at(spec.sound, sx, sy, 0.5);
				lastSound = spec.sound;
			}
		}
		e.recycleShots();
	}

	function blocked(x1:Float, y1:Float, x2:Float, y2:Float):Bool
	{
		var dx = x2 - x1;
		var dy = y2 - y1;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len <= 0)
			return solidAt(x2, y2);
		var steps = Math.ceil(len / STEP);
		for (i in 1...steps + 1)
		{
			var t = i / steps;
			if (solidAt(x1 + dx * t, y1 + dy * t))
				return true;
		}
		return false;
	}

	inline function solidAt(px:Float, py:Float):Bool
		return arena.wallAt(px, py) || PropBlock.at(px, py);

	public function update():Void
	{
		if (WorldClock.scale <= 0.05)
			return;

		for (shot in group.members)
		{
			if (shot == null || !shot.exists || shot.held)
				continue;

			var px = shot.x + shot.width / 2 + shot.dirX * PROBE;
			var py = shot.y + shot.height / 2 + shot.dirY * PROBE;
			if (blocked(shot.lastX, shot.lastY, px, py))
			{
				fx.breakAt(px, py, shot.friendly);
				shot.kill();
				continue;
			}

			var cx = shot.x + shot.width / 2;
			var cy = shot.y + shot.height / 2;

			if (shot.friendly)
			{
				if (onFriendly != null && onFriendly(shot))
				{
					fx.impactAt(cx, cy);
					shot.kill();
				}
				continue;
			}

			if (onShield != null && onShield(shot))
			{
				fx.impactAt(cx, cy);
				shot.kill();
				continue;
			}

			if (status.hurtPlayer(shot, shot.damage))
			{
				fx.impactAt(cx, cy);
				shot.kill();
			}
		}
	}
}
