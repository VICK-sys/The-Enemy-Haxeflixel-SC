package entities.enemy;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;

class EnemyNav
{
	static inline var WAYPOINT_REACHED:Float = 32;
	static inline var BUDGET_PER_FRAME:Int = 2;
	static inline var RETRY_DELAY:Float = 0.06;
	static inline var FAR_DIST:Float = 950;
	static inline var FAR_MULT:Float = 3;
	static inline var MIN_PATH_AGE:Float = 0.4;

	static var pathBudget:Int = BUDGET_PER_FRAME;

	public var map:FlxTilemap;
	public var losClear:Bool = true;
	public var bodyRadius:Float = 40;
	public var repathInterval:Float = 0.35;
	public var moveX:Float = 0;
	public var moveY:Float = 0;

	private var pathPoints:Array<FlxPoint>;
	private var pathIndex:Int = 0;
	private var repathTimer:Float = 0;
	private var pathAge:Float = 999;

	public function new()
	{
		repathTimer = Math.random() * 0.3;
	}

	public static function resetBudget():Void
	{
		pathBudget = BUDGET_PER_FRAME;
	}

	public static function usedBudget():Int
	{
		return BUDGET_PER_FRAME - pathBudget;
	}

	public function tick(elapsed:Float, fromX:Float, fromY:Float, toX:Float, toY:Float):Void
	{
		pathAge += elapsed;
		repathTimer -= elapsed;
		if (repathTimer > 0)
			return;
		if (refresh(fromX, fromY, toX, toY))
		{
			var dx = toX - fromX;
			var dy = toY - fromY;
			var far = dx * dx + dy * dy > FAR_DIST * FAR_DIST;
			repathTimer = repathInterval * (1 + FlxG.random.float() * 0.4) * (far ? FAR_MULT : 1);
		}
		else
		{
			repathTimer = RETRY_DELAY;
		}
	}

	function refresh(fromX:Float, fromY:Float, toX:Float, toY:Float):Bool
	{
		if (map == null)
		{
			losClear = true;
			return true;
		}
		losClear = corridorClear(fromX, fromY, toX, toY);
		if (losClear)
			return true;

		if (pathPoints != null && pathAge < MIN_PATH_AGE)
			return true;

		if (pathBudget <= 0)
			return false;
		pathBudget--;

		clear();
		var from = FlxPoint.get(fromX, fromY);
		var to = FlxPoint.get(toX, toY);
		pathPoints = map.findPath(from, to, RAY_BOX(bodyRadius * 2, bodyRadius * 2));
		pathIndex = 0;
		pathAge = 0;
		from.put();
		to.put();
		return true;
	}

	function corridorClear(fromX:Float, fromY:Float, toX:Float, toY:Float):Bool
	{
		var dx = toX - fromX;
		var dy = toY - fromY;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len <= 0)
			return true;
		var px = -dy / len * bodyRadius;
		var py = dx / len * bodyRadius;
		return rayClear(fromX + px, fromY + py, toX + px, toY + py)
			&& rayClear(fromX - px, fromY - py, toX - px, toY - py);
	}

	function rayClear(x1:Float, y1:Float, x2:Float, y2:Float):Bool
	{
		var a = FlxPoint.get(x1, y1);
		var b = FlxPoint.get(x2, y2);
		var clear = map.ray(a, b);
		a.put();
		b.put();
		return clear;
	}

	public function notifyBlocked():Void
	{
		losClear = false;
		repathTimer = 0;
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
