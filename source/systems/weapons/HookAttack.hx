package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import entities.weapon.HookShot;
import systems.Arena;
import systems.EnemyDirector;
import systems.PlayerCombat;
import flixel.util.FlxDirectionFlags;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

enum HookPhase {
	Idle;
	Flying;
	Pulling;
	Holding;
	Spinning;
	Whirling;
	Retracting;
	GrappleFly;
	GrapplePull;
}

class HookAttack
{
	static inline var SPAWN_DIST:Float = 40;
	static inline var WALL_PROBE:Float = 50;
	static inline var RETRACT_SPEED:Float = 2200;
	static inline var CATCH_DIST:Float = 60;
	static inline var HANDLE_LEN:Float = 62;

	public var hook:HookShot;
	public var rope:FlxTypedGroup<FlxSprite>;
	public var busy(get, never):Bool;
	public var holding(get, never):Bool;

	private var cfg = WeaponDataRegistry.get().hook;
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
	private var whirlTimer:Float = 0;
	private var whirlBase:Float = 0;
	private var whirlHits:Array<Enemies> = [];
	private var anchorX:Float = 0;
	private var anchorY:Float = 0;
	private var grappleTimer:Float = 0;
	private var grappleHits:Array<Enemies> = [];
	private var grappleTarget:Enemies;

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

	public function whirl(aimDeg:Float):Void
	{
		if (phase != Idle)
			return;
		whirlBase = aimDeg;
		whirlTimer = cfg.whirlTime;
		whirlHits = [];
		hook.revive();
		hook.velocity.set(0, 0);
		phase = Whirling;
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
	}

	public function grapple(pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		if (phase != Idle)
			return;
		fireX = pmx + dx * SPAWN_DIST;
		fireY = pmy + dy * SPAWN_DIST;
		hook.fire(fireX, fireY, dx, dy, aimDeg);
		grappleHits = [];
		player.blockMovement = true;
		phase = GrappleFly;
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
		spinTimer = cfg.spinTime;
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
			case Whirling: updateWhirling(elapsed);
			case Retracting: updateRetract();
			case GrappleFly: updateGrappleFly();
			case GrapplePull: updateGrapplePull(elapsed);
		}

		updateFlight(elapsed);
		updateRope();
	}

	function updateGrappleFly():Void
	{
		if (!hook.exists)
		{
			endGrapple();
			return;
		}

		player.velocity.set(0, 0);

		var hcx = hook.x + hook.width / 2;
		var hcy = hook.y + hook.height / 2;

		var hit = director.firstInCircle(hcx, hcy, HookShot.RADIUS, true);
		if (hit != null)
		{
			grappleTarget = hit;
			anchorX = hit.x + hit.width * 0.5;
			anchorY = hit.y + hit.height * 0.5;
			hook.velocity.set(0, 0);
			grappleTimer = cfg.grappleTimeout;
			grappleHits = [];
			status.invincible = true;
			phase = GrapplePull;
			return;
		}

		var fdx = hcx - fireX;
		var fdy = hcy - fireY;
		if (fdx * fdx + fdy * fdy >= cfg.grappleRange * cfg.grappleRange
			|| arena.wallAt(hcx + hook.dirX * HookShot.RADIUS, hcy + hook.dirY * HookShot.RADIUS))
		{
			endGrapple();
		}
	}

	function updateGrapplePull(elapsed:Float):Void
	{
		if (grappleTarget != null && grappleTarget.exists && !grappleTarget.isDead)
		{
			anchorX = grappleTarget.x + grappleTarget.width * 0.5;
			anchorY = grappleTarget.y + grappleTarget.height * 0.5;
		}

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var dx = anchorX - pmx;
		var dy = anchorY - pmy;
		var dist = Math.sqrt(dx * dx + dy * dy);

		grappleTimer -= elapsed;
		if (dist < cfg.grappleCatch || grappleTimer <= 0 || player.wasTouching != FlxDirectionFlags.NONE)
		{
			endGrapple();
			return;
		}

		var ux = dx / dist;
		var uy = dy / dist;
		player.velocity.set(ux * cfg.grapplePullSpeed, uy * cfg.grapplePullSpeed);
		player.flipX = ux < 0;
		hook.setPosition(anchorX - hook.width / 2, anchorY - hook.height / 2);

		director.eachInCircle(pmx, pmy, cfg.grappleRadius, function(e)
		{
			if (grappleHits.contains(e))
				return;
			grappleHits.push(e);
			damageEnemy(e, ux * cfg.grappleFling, uy * cfg.grappleFling);
		});
	}

	function endGrapple():Void
	{
		player.velocity.set(0, 0);
		player.blockMovement = false;
		status.invincible = false;
		grappleTarget = null;
		grappleHits = [];
		hook.kill();
		Rope.clear(rope);
		phase = Idle;
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
		if (fdx * fdx + fdy * fdy >= cfg.range * cfg.range
			|| arena.wallAt(hcx + hook.dirX * HookShot.RADIUS, hcy + hook.dirY * HookShot.RADIUS))
		{
			beginRetract();
			return;
		}

		var hit = director.firstInCircle(hcx, hcy, HookShot.RADIUS, true);
		if (hit == null)
			return;

		if (!hit.grabbable)
		{
			damageEnemy(hit, hook.dirX, hook.dirY);
			beginRetract();
			return;
		}

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
		pullTimer = cfg.pullTimeout;
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

		if (len < cfg.grabDist)
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
		victim.velocity.set(dx / len * cfg.pullSpeed, dy / len * cfg.pullSpeed);
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
		victim.setPosition(pmx + dx / len * cfg.holdDist - victim.width / 2, pmy + dy / len * cfg.holdDist - victim.height / 2);
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
		var t = 1 - spinTimer / cfg.spinTime;
		if (t > 1)
			t = 1;

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var ang = (spinBaseAngle + t * 360) * Math.PI / 180;
		victim.velocity.set(0, 0);
		victim.setPosition(pmx + Math.cos(ang) * cfg.holdDist - victim.width / 2, pmy + Math.sin(ang) * cfg.holdDist - victim.height / 2);
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
		flightTimer = cfg.throwTime;
		flightVictim.velocity.set(flightDirX * cfg.throwSpeed, flightDirY * cfg.throwSpeed);
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

		flightVictim.velocity.set(flightDirX * cfg.throwSpeed, flightDirY * cfg.throwSpeed);

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
		director.eachInCircle(vcx, vcy, cfg.throwHitRadius, function(e)
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
		v.unseize(cfg.releaseStun);
		if (hitWall)
			damageEnemy(v, -flightDirX * 0.4, -flightDirY * 0.4);
	}

	function updateWhirling(elapsed:Float):Void
	{
		whirlTimer -= elapsed;
		var p = 1 - whirlTimer / cfg.whirlTime;
		if (p > 1)
			p = 1;

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var ang = (whirlBase + 360 * p) * Math.PI / 180;
		var hx = pmx + Math.cos(ang) * cfg.whirlRadius;
		var hy = pmy + Math.sin(ang) * cfg.whirlRadius;
		hook.velocity.set(0, 0);
		hook.setPosition(hx - hook.width / 2, hy - hook.height / 2);
		hook.angle = ang * 180 / Math.PI + 90;

		director.eachInCircle(hx, hy, cfg.whirlHitRadius, function(e)
		{
			if (e.seized || whirlHits.contains(e))
				return;
			whirlHits.push(e);
			damageEnemy(e, Math.cos(ang), Math.sin(ang));
		});

		if (whirlTimer <= 0)
		{
			whirlHits = [];
			hook.kill();
			phase = Idle;
		}
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
			flightVictim.unseize(cfg.releaseStun);
			flightVictim = null;
			flightHits = [];
		}
		whirlHits = [];
		grappleHits = [];
		grappleTarget = null;
		status.invincible = false;
		player.blockMovement = false;
		hook.kill();
		Rope.clear(rope);
		phase = Idle;
	}

	function detachVictim():Void
	{
		if (victim != null)
			victim.unseize(cfg.releaseStun);
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

	function updateRope():Void
	{
		if (phase == Idle || !hook.exists)
		{
			Rope.clear(rope);
			return;
		}
		Rope.line(rope, handX(), handY(), hookHandleX(), hookHandleY());
	}
}
