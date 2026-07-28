package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import entities.weapon.HookShot;
import systems.world.Arena;
import systems.enemy.EnemyDirector;
import systems.PlayerCombat;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;
import systems.world.PropBlock;

enum HookPhase
{
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
	static inline var RETRACT_SPEED:Float = 2200;
	static inline var CATCH_DIST:Float = 60;
	static inline var HANDLE_LEN:Float = 62;

	public var hook:HookShot;
	public var rope:FlxTypedGroup<FlxSprite>;
	public var busy(get, never):Bool;
	public var holding(get, never):Bool;
	public var onGrab:(Enemies, Bool) -> Void;

	private var cfg = WeaponDataRegistry.get().hook;
	private var player:Player;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var status:PlayerCombat;
	private var hits:HitPipeline;

	private var flight:HookFlight;

	private var phase:HookPhase = Idle;
	private var victim:Enemies;
	private var pullTimer:Float = 0;
	private var spinTimer:Float = 0;
	private var spinBaseAngle:Float = 0;
	private var throwDirX:Float = 1;
	private var throwDirY:Float = 0;
	private var fireX:Float = 0;
	private var fireY:Float = 0;

	public function new(player:Player, arena:Arena, director:EnemyDirector, status:PlayerCombat, hits:HitPipeline)
	{
		this.player = player;
		this.arena = arena;
		this.director = director;
		this.status = status;
		this.hits = hits;

		hook = new HookShot();
		hook.kill();
		rope = new FlxTypedGroup<FlxSprite>();

		flight = new HookFlight(arena, director, hits);
		flight.onRelease = function(e)
		{
			if (onGrab != null)
				onGrab(e, false);
		};
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
		FlxG.sound.play(Paths.sound("weapon/throw"), 0.6);
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
			if (phase != Idle || flight.active)
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

		flight.update(elapsed);
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
		var px = hcx + hook.dirX * HookShot.RADIUS;
		var py = hcy + hook.dirY * HookShot.RADIUS;
		if (fdx * fdx + fdy * fdy >= cfg.range * cfg.range || arena.wallAt(px, py) || PropBlock.at(px, py))
		{
			beginRetract();
			return;
		}

		var hit = director.firstInCircle(hcx, hcy, HookShot.RADIUS, true);
		if (hit == null)
			return;

		if (!hit.grabbable)
		{
			hits.damageN(hit, hook.dirX, hook.dirY, cfg.snagDamage);
			beginRetract();
			return;
		}

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var ptx = pmx - (hit.x + hit.width / 2);
		var pty = pmy - (hit.y + hit.height / 2);
		var plen = Math.sqrt(ptx * ptx + pty * pty);
		if (plen <= 0)
			plen = 1;
		hits.damage(hit, ptx / plen * 0.3, pty / plen * 0.3);

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
		if (onGrab != null)
			onGrab(victim, true);
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
			FlxG.sound.play(Paths.sound("weapon/catch"), 0.4);
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
		flight.launch(victim, throwDirX, throwDirY);
		victim = null;
		hook.kill();
		phase = Idle;
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
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
			FlxG.sound.play(Paths.sound("weapon/catch"), 0.35);
			return;
		}

		hook.velocity.set(dx / len * RETRACT_SPEED, dy / len * RETRACT_SPEED);
		hook.angle = Math.atan2(dy, dx) * 180 / Math.PI + 270;
	}

	function beginRetract():Void
		phase = Retracting;

	public function drop():Void
	{
		detachVictim();
		flight.stop();
		hook.kill();
		Rope.clear(rope);
		phase = Idle;
	}

	function detachVictim():Void
	{
		if (victim != null)
		{
			victim.unseize(cfg.releaseStun);
			if (onGrab != null)
				onGrab(victim, false);
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
