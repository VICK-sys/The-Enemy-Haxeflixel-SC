package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import entities.HookShot;
import util.Paths;

enum HookPhase {
	Idle;
	Flying;
	Pulling;
	Holding;
	Spinning;
	Retracting;
}

class HookAttack
{
	static inline var SPAWN_DIST:Float = 40;
	static inline var RANGE:Float = 500;
	static inline var PULL_SPEED:Float = 1500;
	static inline var PULL_TIMEOUT:Float = 0.8;
	static inline var GRAB_DIST:Float = 110;
	static inline var HOLD_DIST:Float = 85;
	static inline var SPIN_TIME:Float = 0.3;
	static inline var THROW_SPEED:Float = 1400;
	static inline var THROW_TIME:Float = 0.5;
	static inline var THROW_HIT_RADIUS:Float = 60;
	static inline var WALL_PROBE:Float = 50;
	static inline var RELEASE_STUN:Float = 0.35;
	static inline var RETRACT_SPEED:Float = 2200;
	static inline var CATCH_DIST:Float = 60;
	static inline var HANDLE_LEN:Float = 62;
	static inline var ROPE_STEP:Float = 30;

	public var hook:HookShot;
	public var rope:FlxTypedGroup<FlxSprite>;
	public var busy(get, never):Bool;
	public var holding(get, never):Bool;

	private var player:Player;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var status:PlayerCombat;
	private var damageEnemy:(Enemies, Float, Float) -> Void;
	private var phase:HookPhase = Idle;
	private var victim:Enemies;
	private var pullTimer:Float = 0;
	private var spinTimer:Float = 0;
	private var spinBaseAngle:Float = 0;
	private var throwDirX:Float = 1;
	private var throwDirY:Float = 0;
	private var fireX:Float = 0;
	private var fireY:Float = 0;
	private var flightVictim:Enemies;
	private var flightTimer:Float = 0;
	private var flightDirX:Float = 1;
	private var flightDirY:Float = 0;
	private var flightHits:Array<Enemies> = [];

	public function new(player:Player, arena:Arena, director:EnemyDirector, status:PlayerCombat, damageEnemy:(Enemies, Float, Float) -> Void)
	{
		this.player = player;
		this.arena = arena;
		this.director = director;
		this.status = status;
		this.damageEnemy = damageEnemy;
		hook = new HookShot();
		hook.kill();
		rope = new FlxTypedGroup<FlxSprite>();
	}

	function get_busy():Bool
		return phase != Idle;

	function get_holding():Bool
		return phase == Holding;

	public function fire(pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		if (phase != Idle)
			return;
		fireX = pmx + dx * SPAWN_DIST;
		fireY = pmy + dy * SPAWN_DIST;
		hook.fire(fireX, fireY, dx, dy, aimDeg);
		phase = Flying;
		FlxG.sound.play(Paths.sound("scythe/throw"), 0.6);
	}

	public function throwHeld(dx:Float, dy:Float):Void
	{
		if (phase != Holding || victimGone())
			return;
		throwDirX = dx;
		throwDirY = dy;
		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		spinBaseAngle = Math.atan2(victim.y + victim.height / 2 - pmy, victim.x + victim.width / 2 - pmx) * 180 / Math.PI;
		spinTimer = SPIN_TIME;
		phase = Spinning;
	}

	public function update(elapsed:Float):Void
	{
		if (status.dead)
		{
			if (phase != Idle || flightVictim != null)
				drop();
			return;
		}

		switch (phase)
		{
			case Idle:
			case Flying: updateFlying();
			case Pulling: updatePulling(elapsed);
			case Holding: updateHolding();
			case Spinning: updateSpinning(elapsed);
			case Retracting: updateRetract();
		}

		updateFlight(elapsed);
		updateRope();
	}

	function updateFlying():Void
	{
		if (!hook.exists)
		{
			phase = Idle;
			return;
		}

		var hcx = hook.x + hook.width / 2;
		var hcy = hook.y + hook.height / 2;

		var fdx = hcx - fireX;
		var fdy = hcy - fireY;
		if (fdx * fdx + fdy * fdy >= RANGE * RANGE
			|| arena.wallAt(hcx + hook.dirX * HookShot.RADIUS, hcy + hook.dirY * HookShot.RADIUS))
		{
			beginRetract();
			return;
		}

		var hit = director.firstInCircle(hcx, hcy, HookShot.RADIUS, true);
		if (hit == null)
			return;

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var px = pmx - (hit.x + hit.width / 2);
		var py = pmy - (hit.y + hit.height / 2);
		var plen = Math.sqrt(px * px + py * py);
		if (plen <= 0)
			plen = 1;
		damageEnemy(hit, px / plen * 0.3, py / plen * 0.3);

		if (hit.isDead || !hit.exists)
		{
			beginRetract();
			return;
		}

		victim = hit;
		victim.seized = true;
		victim.drag.set(0, 0);
		hook.velocity.set(0, 0);
		pullTimer = PULL_TIMEOUT;
		phase = Pulling;
	}

	function updatePulling(elapsed:Float):Void
	{
		if (victimGone())
		{
			detachVictim();
			beginRetract();
			return;
		}

		stickHook();

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var dx = pmx - (victim.x + victim.width / 2);
		var dy = pmy - (victim.y + victim.height / 2);
		var len = Math.sqrt(dx * dx + dy * dy);

		if (len < GRAB_DIST)
		{
			victim.velocity.set(0, 0);
			phase = Holding;
			FlxG.sound.play(Paths.sound("scythe/catch"), 0.4);
			return;
		}

		pullTimer -= elapsed;
		if (pullTimer <= 0)
		{
			detachVictim();
			beginRetract();
			return;
		}

		if (len <= 0)
			len = 1;
		victim.velocity.set(dx / len * PULL_SPEED, dy / len * PULL_SPEED);
	}

	function updateHolding():Void
	{
		if (victimGone())
		{
			detachVictim();
			beginRetract();
			return;
		}

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var dx = FlxG.mouse.x - pmx;
		var dy = FlxG.mouse.y - pmy;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len < 0.001)
		{
			dx = 1;
			dy = 0;
			len = 1;
		}

		victim.velocity.set(0, 0);
		victim.setPosition(pmx + dx / len * HOLD_DIST - victim.width / 2, pmy + dy / len * HOLD_DIST - victim.height / 2);
		stickHook();
	}

	function updateSpinning(elapsed:Float):Void
	{
		if (victimGone())
		{
			detachVictim();
			beginRetract();
			return;
		}

		spinTimer -= elapsed;
		var t = 1 - spinTimer / SPIN_TIME;
		if (t > 1)
			t = 1;

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var ang = (spinBaseAngle + t * 360) * Math.PI / 180;
		victim.velocity.set(0, 0);
		victim.setPosition(pmx + Math.cos(ang) * HOLD_DIST - victim.width / 2, pmy + Math.sin(ang) * HOLD_DIST - victim.height / 2);
		stickHook();

		if (spinTimer <= 0)
			releaseThrow();
	}

	function releaseThrow():Void
	{
		flightVictim = victim;
		victim = null;
		flightDirX = throwDirX;
		flightDirY = throwDirY;
		flightHits = [];
		flightTimer = THROW_TIME;
		flightVictim.velocity.set(flightDirX * THROW_SPEED, flightDirY * THROW_SPEED);
		flightVictim.drag.set(0, 0);
		hook.kill();
		phase = Idle;
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
	}

	function updateFlight(elapsed:Float):Void
	{
		if (flightVictim == null)
			return;

		if (!flightVictim.exists || flightVictim.isDead)
		{
			flightVictim = null;
			flightHits = [];
			return;
		}

		flightVictim.velocity.set(flightDirX * THROW_SPEED, flightDirY * THROW_SPEED);

		var vcx = flightVictim.x + flightVictim.width / 2;
		var vcy = flightVictim.y + flightVictim.height / 2;

		if (arena.wallAt(vcx + flightDirX * WALL_PROBE, vcy + flightDirY * WALL_PROBE))
		{
			endFlight(true);
			return;
		}

		flightTimer -= elapsed;
		if (flightTimer <= 0)
		{
			endFlight(false);
			return;
		}

		var fv = flightVictim;
		director.eachInCircle(vcx, vcy, THROW_HIT_RADIUS, function(e)
		{
			if (e == fv || e.seized || flightHits.contains(e))
				return;
			flightHits.push(e);
			damageEnemy(e, flightDirX, flightDirY);
		});
	}

	function endFlight(hitWall:Bool):Void
	{
		var v = flightVictim;
		flightVictim = null;
		flightHits = [];
		if (v.seized)
		{
			v.seized = false;
			v.stun = RELEASE_STUN;
			v.drag.set(v.knockbackDrag, v.knockbackDrag);
		}
		if (hitWall)
			damageEnemy(v, -flightDirX * 0.4, -flightDirY * 0.4);
	}

	function updateRetract():Void
	{
		if (!hook.exists)
		{
			phase = Idle;
			return;
		}

		var dx = handX() - (hook.x + hook.width / 2);
		var dy = handY() - (hook.y + hook.height / 2);
		var len = Math.sqrt(dx * dx + dy * dy);

		if (len < CATCH_DIST)
		{
			hook.kill();
			phase = Idle;
			FlxG.sound.play(Paths.sound("scythe/catch"), 0.35);
			return;
		}

		hook.velocity.set(dx / len * RETRACT_SPEED, dy / len * RETRACT_SPEED);
		hook.angle = Math.atan2(dy, dx) * 180 / Math.PI + 270;
	}

	function beginRetract():Void
	{
		phase = Retracting;
	}

	function drop():Void
	{
		detachVictim();
		if (flightVictim != null)
		{
			if (flightVictim.seized)
			{
				flightVictim.seized = false;
				flightVictim.stun = RELEASE_STUN;
				flightVictim.drag.set(flightVictim.knockbackDrag, flightVictim.knockbackDrag);
			}
			flightVictim = null;
			flightHits = [];
		}
		hook.kill();
		clearRope();
		phase = Idle;
	}

	function detachVictim():Void
	{
		if (victim != null && victim.seized)
		{
			victim.seized = false;
			victim.stun = RELEASE_STUN;
			victim.drag.set(victim.knockbackDrag, victim.knockbackDrag);
		}
		victim = null;
	}

	function victimGone():Bool
		return victim == null || !victim.exists || victim.isDead;

	function stickHook():Void
	{
		var vcx = victim.x + victim.width / 2;
		var vcy = victim.y + victim.height / 2;
		hook.angle = Math.atan2(vcy - handY(), vcx - handX()) * 180 / Math.PI + 90;
		hook.setPosition(vcx - hook.width / 2, vcy - hook.height / 2);
	}

	function hookHandleX():Float
		return hook.x + hook.width / 2 - Math.sin(hook.angle * Math.PI / 180) * HANDLE_LEN;

	function hookHandleY():Float
		return hook.y + hook.height / 2 + Math.cos(hook.angle * Math.PI / 180) * HANDLE_LEN;

	function handX():Float
		return player.x + 30;

	function handY():Float
		return player.y + 65;

	function clearRope():Void
	{
		for (s in rope.members)
			if (s != null)
				s.kill();
	}

	function updateRope():Void
	{
		clearRope();
		if (phase == Idle || !hook.exists)
			return;

		var hx = handX();
		var hy = handY();
		var dx = hookHandleX() - hx;
		var dy = hookHandleY() - hy;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len < 8)
			return;

		var ux = dx / len;
		var uy = dy / len;
		var ang = Math.atan2(dy, dx) * 180 / Math.PI - 90;
		var count = Math.ceil(len / ROPE_STEP);
		for (i in 0...count)
		{
			var s = rope.recycle(FlxSprite);
			if (s.graphic == null)
			{
				s.loadGraphic(Paths.image("items/rope"));
				s.antialiasing = false;
			}
			var cx = hx + ux * ROPE_STEP * (i + 0.5);
			var cy = hy + uy * ROPE_STEP * (i + 0.5);
			s.setPosition(cx - s.width / 2, cy - s.height / 2);
			s.angle = ang;
		}
	}

}
