package systems.enemy;

import flixel.FlxSprite;
import entities.enemy.Enemies;
import util.SideView;
import systems.world.Arena;
import systems.world.PropBlock;
import systems.world.FootCollide;

class EnemySpawner
{
	static inline var SPAWN_OUT:Float = 40;
	static inline var SPAWN_PAD:Float = 60;
	static inline var SPAWN_TRIM:Float = 240;
	static inline var SPAWN_SPREAD:Float = 700;
	static inline var STUCK_TIME:Float = 2.5;
	static inline var STUCK_EPS:Float = 6;
	static inline var STUCK_DRIVE:Float = 20;
	static inline var RESCUE_MIN:Float = 380;
	static inline var RESCUE_MAX:Float = 620;
	static inline var LOCAL_MIN:Float = 70;
	static inline var LOCAL_STEP:Float = 60;
	static inline var LOCAL_RINGS:Int = 4;
	static inline var LOCAL_TRIES:Int = 10;

	public var anchor:Void->FlxSprite;

	private var arena:Arena;

	public function new(arena:Arena)
	{
		this.arena = arena;
	}

	public function clearOfWalls(x:Float, y:Float, w:Float, h:Float, feetY:Float):Bool
	{
		return !arena.wallAt(x, y) && !arena.wallAt(x + w, y) && !arena.wallAt(x, y + h)
			&& !arena.wallAt(x + w, y + h) && !arena.wallAt(x + w * 0.5, y + h * 0.5)
			&& footClear(x, w, feetY);
	}

	public function footClear(x:Float, w:Float, feetY:Float):Bool
	{
		var top = feetY - FootCollide.DEPTH;
		return !PropBlock.at(x, top) && !PropBlock.at(x + w, top) && !PropBlock.at(x, feetY)
			&& !PropBlock.at(x + w, feetY) && !PropBlock.at(x + w * 0.5, feetY - FootCollide.DEPTH * 0.5);
	}

	public function spotClear(e:Enemies, x:Float, y:Float):Bool
		return clearOfWalls(x, y, e.width, e.height, y + e.shadowOffY);

	public function placeAtEdge(e:Enemies):Void
	{
		var mw = arena.width;
		var mh = arena.height;

		if (SideView.active)
		{
			e.x = Std.random(2) == 0 ? -e.width - SPAWN_OUT : mw + SPAWN_OUT;
			e.y = SideView.groundY - e.height;
		}
		else
		{
			var a = anchor();
			switch (Std.random(4))
			{
				case 0:
					e.x = -e.width - SPAWN_OUT;
					e.y = edgeCoord(a.y, mh);
				case 1:
					e.x = mw + SPAWN_OUT;
					e.y = edgeCoord(a.y, mh);
				case 2:
					e.x = edgeCoord(a.x, mw);
					e.y = -e.height - SPAWN_OUT;
				default:
					e.x = edgeCoord(a.x, mw);
					e.y = mh + SPAWN_OUT;
			}
		}

		e.entering = true;
		e.allowCollisions = NONE;
		e.aggroRange = 100000;
	}

	public function placeNear(e:Enemies):Void
	{
		var a = anchor();
		e.x = a.x + a.width * 0.5 - e.width / 2 + Math.random() * 600 - 300;
		e.y = a.y + a.height * 0.5 - e.height / 2 + Math.random() * 400 - 200;
	}

	function edgeCoord(near:Float, max:Float):Float
	{
		var v = near + (Math.random() * 2 - 1) * SPAWN_SPREAD;
		if (v < SPAWN_PAD)
			v = SPAWN_PAD;
		if (v > max - SPAWN_TRIM + SPAWN_PAD)
			v = max - SPAWN_TRIM + SPAWN_PAD;
		return v;
	}

	public function checkStuck(rig:EnemyRig, elapsed:Float):Void
	{
		var e = rig.enemy;
		var dx = e.x - rig.lastX;
		var dy = e.y - rig.lastY;
		var driven = e.velocity.x * e.velocity.x + e.velocity.y * e.velocity.y > STUCK_DRIVE * STUCK_DRIVE;

		if (!driven || dx * dx + dy * dy > STUCK_EPS * STUCK_EPS)
		{
			rig.lastX = e.x;
			rig.lastY = e.y;
			rig.stuckTimer = 0;
			return;
		}

		rig.stuckTimer += elapsed;
		if (rig.stuckTimer > STUCK_TIME)
			rescue(rig);
	}

	public function rescue(rig:EnemyRig):Void
	{
		var e = rig.enemy;

		for (ring in 0...LOCAL_RINGS)
		{
			var dist = LOCAL_MIN + ring * LOCAL_STEP;
			for (i in 0...LOCAL_TRIES)
			{
				var ang = (i / LOCAL_TRIES + Math.random() / LOCAL_TRIES) * Math.PI * 2;
				var nx = e.x + Math.cos(ang) * dist;
				var ny = e.y + Math.sin(ang) * dist;
				if (inBounds(nx, ny, e) && spotClear(e, nx, ny))
				{
					land(rig, nx, ny);
					return;
				}
			}
		}

		var a = anchor();
		var pcx = a.x + a.width * 0.5;
		var pcy = a.y + a.height * 0.5;
		var destX = pcx - e.width * 0.5;
		var destY = pcy - e.height * 0.5;

		for (i in 0...20)
		{
			var ang = Math.random() * Math.PI * 2;
			var dist = RESCUE_MIN + Math.random() * (RESCUE_MAX - RESCUE_MIN);
			var nx = pcx + Math.cos(ang) * dist - e.width * 0.5;
			var ny = pcy + Math.sin(ang) * dist - e.height * 0.5;
			if (!inBounds(nx, ny, e))
				continue;
			if (spotClear(e, nx, ny))
			{
				destX = nx;
				destY = ny;
				break;
			}
		}

		land(rig, destX, destY);
	}

	function inBounds(x:Float, y:Float, e:Enemies):Bool
	{
		return x >= SPAWN_PAD && y >= SPAWN_PAD && x + e.width <= arena.width - SPAWN_PAD
			&& y + e.height <= arena.height - SPAWN_PAD;
	}

	function land(rig:EnemyRig, x:Float, y:Float):Void
	{
		var e = rig.enemy;
		e.setPosition(x, y);
		e.velocity.set(0, 0);
		e.stun = 0;
		e.pathing.clear();
		e.entering = false;
		e.allowCollisions = ANY;
		rig.lastX = x;
		rig.lastY = y;
		rig.stuckTimer = 0;
	}
}
