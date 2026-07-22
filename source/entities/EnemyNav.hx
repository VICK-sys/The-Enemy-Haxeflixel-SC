package entities;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;

class EnemyNav
{
	static inline var WAYPOINT_REACHED:Float = 24;

	public var map:FlxTilemap;
	public var losClear:Bool = true;
	public var moveX:Float = 0;
	public var moveY:Float = 0;

	private var pathPoints:Array<FlxPoint>;
	private var pathIndex:Int = 0;
	private var repathTimer:Float = 0;

	public function new() {}

	public function tick(elapsed:Float, fromX:Float, fromY:Float, toX:Float, toY:Float):Void
	{
		repathTimer -= elapsed;
		if (repathTimer <= 0)
		{
			repathTimer = 0.35 + FlxG.random.float() * 0.15;
			refresh(fromX, fromY, toX, toY);
		}
	}

	function refresh(fromX:Float, fromY:Float, toX:Float, toY:Float):Void
	{
		if (map == null)
		{
			losClear = true;
			return;
		}
		var from = FlxPoint.get(fromX, fromY);
		var to = FlxPoint.get(toX, toY);
		losClear = map.ray(from, to);
		if (!losClear)
		{
			clear();
			pathPoints = map.findPath(from, to);
			pathIndex = 0;
		}
		from.put();
		to.put();
	}

	public function steer(fromX:Float, fromY:Float, straightX:Float, straightY:Float):Void
	{
		moveX = straightX;
		moveY = straightY;
		if (losClear || pathPoints == null || pathIndex >= pathPoints.length)
			return;

		var wp = pathPoints[pathIndex];
		var wx:Float = wp.x - fromX;
		var wy:Float = wp.y - fromY;
		var wl:Float = Math.sqrt(wx * wx + wy * wy);
		if (wl < WAYPOINT_REACHED && pathIndex < pathPoints.length - 1)
		{
			pathIndex++;
			wp = pathPoints[pathIndex];
			wx = wp.x - fromX;
			wy = wp.y - fromY;
			wl = Math.sqrt(wx * wx + wy * wy);
		}
		if (wl > 0)
		{
			moveX = wx / wl;
			moveY = wy / wl;
		}
	}

	public function clear():Void
	{
		if (pathPoints != null)
		{
			for (p in pathPoints)
				p.put();
			pathPoints = null;
		}
	}
}
