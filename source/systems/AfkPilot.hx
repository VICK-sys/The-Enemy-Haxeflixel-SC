package systems;

import entities.Player;
import entities.enemy.Enemies;
import states.play.ReadyGate;
import systems.enemy.EnemyDirector;
import systems.weapons.Weapons;
import systems.world.Arena;
import util.Controls;

class AfkPilot
{
	static inline var ENGAGE:Float = 820;
	static inline var MELEE_STAND:Float = 150;
	static inline var YOYO_STAND:Float = 300;
	static inline var GUN_STAND:Float = 430;
	static inline var BOW_STAND:Float = 470;
	static inline var BAND:Float = 45;
	static inline var AVOID:Float = 240;
	static inline var WALL_M:Float = 170;
	static inline var CROWD_W:Float = 1.35;
	static inline var WALL_W:Float = 1.7;
	static inline var FIELD_ONLY:Float = 0.25;
	static inline var PANIC:Float = 100;
	static inline var CROWD_GAP:Float = 210;
	static inline var CROWD_N:Int = 3;
	static inline var SHOT_PANIC:Float = 150;
	static inline var LEASH:Float = 90;
	static inline var REANCHOR:Float = 900;
	static inline var HEAL_AT:Float = 0.62;
	static inline var HEAL_REACH:Float = 720;
	static inline var PEER_STOP:Float = 90;
	static inline var SWING_GAP:Float = 0.3;
	static inline var RELOAD_GAP:Float = 0.8;
	static inline var YOYO_HOLD:Float = 0.65;
	static inline var YOYO_REST:Float = 0.25;
	static inline var READY_GAP:Float = 1.0;
	static inline var STRAFE_FLIP:Float = 1.7;
	static inline var STUCK_AFTER:Float = 0.55;
	static inline var UNSTICK_FOR:Float = 0.45;
	static inline var GIGA_MIN:Float = 330;
	static inline var GIGA_FAR:Float = 620;
	static inline var THROW_MIN:Float = 380;
	static inline var THROW_MAX:Float = 680;
	static inline var THROW_GAP:Float = 6.0;
	static inline var BASH_AT:Float = 170;
	static inline var BASH_GAP:Float = 1.5;
	static inline var BIG_RANGE:Float = 700;
	static inline var BIG_GAP:Float = 2.5;
	static inline var HOOK_MIN:Float = 260;
	static inline var HOOK_MAX:Float = 560;
	static inline var HOOK_GAP:Float = 5.0;
	static inline var QUICK_DRAW:Float = 380;
	static inline var DRAW_MIN:Float = 0.45;
	static inline var CLUSTER:Float = 260;
	static inline var SUPER_PACK:Int = 3;
	static inline var SUPER_NEAR:Float = 340;
	static inline var SUPER_FAR:Float = 700;
	static inline var GUN_FIRE:Float = 840;
	static inline var BOW_FIRE:Float = 900;
	static inline var YOYO_FIRE:Float = 480;
	static inline var MELEE_REACH_PAD:Float = 40;
	static inline var AIM_IDLE:Float = 220;
	static inline var RANGED_LEAD:Float = 0.12;

	public var on(default, null):Bool = false;
	public var findPeer:(Float, Float) -> {x:Float, y:Float};

	var player:Player;
	var status:PlayerCombat;
	var combat:Weapons;
	var director:EnemyDirector;
	var pickups:Pickups;
	var gate:ReadyGate;
	var arena:Arena;

	var homeX:Float = 0;
	var homeY:Float = 0;
	var tapTimer:Float = 0;
	var holdTimer:Float = 0;
	var readyTimer:Float = 0;
	var sideTimer:Float = 0;
	var strafeTimer:Float = 0;
	var strafeSign:Float = 1;
	var stuckTimer:Float = 0;
	var unstickTimer:Float = 0;
	var lastX:Float = 0;
	var lastY:Float = 0;
	var gigaGo:Bool = false;
	var fieldX:Float = 0;
	var fieldY:Float = 0;

	public function new(player:Player, status:PlayerCombat, combat:Weapons, director:EnemyDirector, pickups:Pickups,
			gate:ReadyGate, arena:Arena)
	{
		this.player = player;
		this.status = status;
		this.combat = combat;
		this.director = director;
		this.pickups = pickups;
		this.gate = gate;
		this.arena = arena;
	}

	public function set(enabled:Bool):Void
	{
		if (on == enabled)
			return;
		on = enabled;
		Controls.setPilot(enabled);
		if (!enabled)
			return;
		homeX = px();
		homeY = py();
		lastX = player.x;
		lastY = player.y;
		tapTimer = 0;
		holdTimer = 0;
		readyTimer = 0;
		sideTimer = 0;
		strafeTimer = STRAFE_FLIP;
		stuckTimer = 0;
		unstickTimer = 0;
		gigaGo = false;
		Controls.pilotAimAt(px() + (player.flipX ? -AIM_IDLE : AIM_IDLE), py());
	}

	public function update(elapsed:Float):Void
	{
		if (!on)
			return;

		for (a in [
			Controls.UP, Controls.DOWN, Controls.LEFT, Controls.RIGHT, Controls.DASH, Controls.ATTACK, Controls.SECOND,
			Controls.SUPER, Controls.RELOAD, Controls.ACCEPT
		])
			Controls.pilotHold(a, false);

		if (tapTimer > 0)
			tapTimer -= elapsed;
		if (readyTimer > 0)
			readyTimer -= elapsed;
		if (sideTimer > 0)
			sideTimer -= elapsed;
		strafeTimer -= elapsed;
		if (strafeTimer <= 0)
		{
			strafeTimer = STRAFE_FLIP;
			strafeSign = -strafeSign;
		}

		tapReady();

		if (status.dead)
		{
			stuckTimer = 0;
			unstickTimer = 0;
			gigaGo = false;
			deadDrift();
			lastX = player.x;
			lastY = player.y;
			return;
		}

		var target = nearestFoe(ENGAGE);
		refreshField();
		var mv = plan(target);
		mv = blend(mv);

		if (mv != null)
		{
			var sdx = player.x - lastX;
			var sdy = player.y - lastY;
			if (sdx * sdx + sdy * sdy < 1.44)
				stuckTimer += elapsed;
			else
				stuckTimer = 0;
			if (stuckTimer > STUCK_AFTER)
			{
				stuckTimer = 0;
				unstickTimer = UNSTICK_FOR;
			}
			if (unstickTimer > 0)
			{
				unstickTimer -= elapsed;
				mv = {x: -mv.y * strafeSign, y: mv.x * strafeSign};
			}
			holdMove(mv.x, mv.y);
		}
		else
			stuckTimer = 0;

		aimAt(target, mv);
		if (combat.superBusy && combat.weapon == 2)
			stormAim(target);
		var superNow = target != null && !combat.superBusy && wantSuper(target, gapTo(target));
		if (!superNow)
			maybeDash(target);
		fight(target, elapsed);
		lastX = player.x;
		lastY = player.y;
	}

	function px():Float
		return player.x + player.width * 0.5;

	function py():Float
		return player.y + player.height * 0.5;

	function tcx(e:Enemies):Float
		return e.x + e.width * 0.5;

	function tcy(e:Enemies):Float
		return e.y + e.height * 0.5;

	function distTo(e:Enemies):Float
	{
		var dx = tcx(e) - px();
		var dy = tcy(e) - py();
		return Math.sqrt(dx * dx + dy * dy);
	}

	function gapTo(e:Enemies):Float
		return distTo(e) - e.hitRadius;

	function skip(e:Enemies):Bool
		return e == null || !e.exists || !e.alive || e.isDead || e.buried || e.entering;

	function nearestFoe(range:Float):Enemies
	{
		var best:Enemies = null;
		var bestD:Float = range;
		for (e in director.bodies.members)
		{
			if (skip(e))
				continue;
			var d = distTo(e);
			if (d < bestD)
			{
				bestD = d;
				best = e;
			}
		}
		return best;
	}

	function packSize(range:Float):Int
	{
		var n = 0;
		for (e in director.bodies.members)
			if (!skip(e) && distTo(e) < range)
				n++;
		return n;
	}

	function clusterAt(c:Enemies):Int
	{
		var n = 0;
		for (e in director.bodies.members)
		{
			if (skip(e))
				continue;
			var dx = tcx(e) - tcx(c);
			var dy = tcy(e) - tcy(c);
			if (dx * dx + dy * dy < CLUSTER * CLUSTER)
				n++;
		}
		return n;
	}

	function refreshField():Void
	{
		var cx:Float = 0;
		var cy:Float = 0;
		for (e in director.bodies.members)
		{
			if (skip(e))
				continue;
			var dx = px() - tcx(e);
			var dy = py() - tcy(e);
			var d = Math.sqrt(dx * dx + dy * dy);
			var gap = d - e.hitRadius;
			if (gap >= AVOID || d < 0.001)
				continue;
			var w = (AVOID - gap) / AVOID;
			cx += dx / d * w;
			cy += dy / d * w;
		}

		var wx:Float = 0;
		var wy:Float = 0;
		if (px() < WALL_M)
			wx += (WALL_M - px()) / WALL_M;
		if (px() > arena.width - WALL_M)
			wx -= (px() - (arena.width - WALL_M)) / WALL_M;
		if (py() < WALL_M)
			wy += (WALL_M - py()) / WALL_M;
		if (py() > arena.height - WALL_M)
			wy -= (py() - (arena.height - WALL_M)) / WALL_M;

		fieldX = cx * CROWD_W + wx * WALL_W;
		fieldY = cy * CROWD_W + wy * WALL_W;
	}

	function tapReady():Void
	{
		if (!gate.armed || gate.ready || status.dead || readyTimer > 0)
			return;
		readyTimer = READY_GAP;
		Controls.pilotHold(Controls.ACCEPT, true);
	}

	function deadDrift():Void
	{
		if (findPeer == null)
			return;
		var p = findPeer(px(), py());
		if (p == null)
			return;
		var dx = p.x - px();
		var dy = p.y - py();
		if (dx * dx + dy * dy < PEER_STOP * PEER_STOP)
			return;
		holdMove(dx, dy);
		Controls.pilotAimAt(p.x, p.y);
	}

	function standFor():Float
		return switch (combat.weapon)
		{
			case 1: GUN_STAND;
			case 2: BOW_STAND;
			case 3: YOYO_STAND;
			default: MELEE_STAND;
		}

	function plan(target:Enemies):{x:Float, y:Float}
	{
		if (status.health < status.healthMax * HEAL_AT)
		{
			var pick:entities.HealthPickup = null;
			var pickD:Float = HEAL_REACH;
			for (p in pickups.group.members)
			{
				if (p == null || !p.exists)
					continue;
				var dx = p.x + p.width * 0.5 - px();
				var dy = p.y + p.height * 0.5 - py();
				var d = Math.sqrt(dx * dx + dy * dy);
				if (d < pickD)
				{
					pickD = d;
					pick = p;
				}
			}
			if (pick != null)
				return {x: pick.x + pick.width * 0.5 - px(), y: pick.y + pick.height * 0.5 - py()};
		}

		if (target == null)
		{
			var hx = homeX - px();
			var hy = homeY - py();
			var hd = Math.sqrt(hx * hx + hy * hy);
			if (hd > REANCHOR)
			{
				homeX = px();
				homeY = py();
				return null;
			}
			if (hd > LEASH)
				return {x: hx, y: hy};
			return null;
		}

		var dx = tcx(target) - px();
		var dy = tcy(target) - py();
		var d = Math.sqrt(dx * dx + dy * dy) - target.hitRadius;
		var stand = standFor();
		if (d > stand + BAND)
			return {x: dx, y: dy};
		if (d < stand - BAND)
			return {x: -dx, y: -dy};

		var pxv = -dy;
		var pyv = dx;
		var along = pxv * fieldX + pyv * fieldY;
		if (along < -0.05)
		{
			pxv = -pxv;
			pyv = -pyv;
		}
		else if (along <= 0.05)
		{
			pxv *= strafeSign;
			pyv *= strafeSign;
		}
		return {x: pxv, y: pyv};
	}

	function blend(mv:{x:Float, y:Float}):{x:Float, y:Float}
	{
		var flen = Math.sqrt(fieldX * fieldX + fieldY * fieldY);
		if (mv == null)
			return flen > FIELD_ONLY ? {x: fieldX, y: fieldY} : null;
		var len = Math.sqrt(mv.x * mv.x + mv.y * mv.y);
		if (len < 0.001)
			return flen > FIELD_ONLY ? {x: fieldX, y: fieldY} : null;
		return {x: mv.x / len + fieldX, y: mv.y / len + fieldY};
	}

	function holdMove(vx:Float, vy:Float):Void
	{
		Controls.pilotHold(Controls.UP, false);
		Controls.pilotHold(Controls.DOWN, false);
		Controls.pilotHold(Controls.LEFT, false);
		Controls.pilotHold(Controls.RIGHT, false);
		var len = Math.sqrt(vx * vx + vy * vy);
		if (len < 0.1)
			return;
		vx /= len;
		vy /= len;
		if (vy < -0.42)
			Controls.pilotHold(Controls.UP, true);
		if (vy > 0.42)
			Controls.pilotHold(Controls.DOWN, true);
		if (vx < -0.42)
			Controls.pilotHold(Controls.LEFT, true);
		if (vx > 0.42)
			Controls.pilotHold(Controls.RIGHT, true);
	}

	function aimAt(target:Enemies, mv:{x:Float, y:Float}):Void
	{
		if (target != null)
		{
			var lead = combat.weapon == 1 || combat.weapon == 2 ? RANGED_LEAD : 0.0;
			Controls.pilotAimAt(tcx(target) + target.velocity.x * lead, tcy(target) + target.velocity.y * lead);
			return;
		}
		if (mv != null)
		{
			var len = Math.sqrt(mv.x * mv.x + mv.y * mv.y);
			if (len > 0.1)
				Controls.pilotAimAt(px() + mv.x / len * AIM_IDLE, py() + mv.y / len * AIM_IDLE);
		}
	}

	function stormAim(target:Enemies):Void
	{
		var best:Enemies = null;
		var bestN = 0;
		for (e in director.bodies.members)
		{
			if (skip(e))
				continue;
			var n = clusterAt(e);
			if (n > bestN)
			{
				bestN = n;
				best = e;
			}
		}
		if (best == null)
			best = target;
		if (best == null)
			return;

		var sx:Float = 0;
		var sy:Float = 0;
		var n = 0;
		for (e in director.bodies.members)
		{
			if (skip(e))
				continue;
			var dx = tcx(e) - tcx(best);
			var dy = tcy(e) - tcy(best);
			if (dx * dx + dy * dy < CLUSTER * CLUSTER)
			{
				sx += tcx(e);
				sy += tcy(e);
				n++;
			}
		}
		if (n > 0)
			Controls.pilotAimAt(sx / n, sy / n);
	}

	function escapeMove(fallback:Enemies):Bool
	{
		var ex = fieldX;
		var ey = fieldY;
		if (ex * ex + ey * ey < 0.04 && fallback != null)
		{
			ex = px() - tcx(fallback);
			ey = py() - tcy(fallback);
		}
		if (ex * ex + ey * ey < 0.04)
			return false;
		holdMove(ex, ey);
		return true;
	}

	function maybeDash(target:Enemies):Void
	{
		if (!status.dashReady || player.dashTimer > 0 || player.blockMovement)
			return;

		var panic = false;
		var crowd = 0;
		var nearest:Enemies = null;
		var nearestGap:Float = 1e9;
		for (e in director.bodies.members)
		{
			if (skip(e))
				continue;
			var gap = gapTo(e);
			if (gap < nearestGap)
			{
				nearestGap = gap;
				nearest = e;
			}
			if (gap < PANIC)
				panic = true;
			if (gap < CROWD_GAP)
				crowd++;
		}

		if ((panic || crowd >= CROWD_N) && escapeMove(nearest))
		{
			Controls.pilotHold(Controls.DASH, true);
			return;
		}

		for (s in director.shots.members)
		{
			if (s == null || !s.exists)
				continue;
			var dx = px() - (s.x + s.width * 0.5);
			var dy = py() - (s.y + s.height * 0.5);
			if (dx * dx + dy * dy > SHOT_PANIC * SHOT_PANIC)
				continue;
			if (s.dirX * dx + s.dirY * dy <= 0)
				continue;
			var pxv = -s.dirY;
			var pyv = s.dirX;
			if (pxv * fieldX + pyv * fieldY < 0)
			{
				pxv = -pxv;
				pyv = -pyv;
			}
			holdMove(pxv + fieldX, pyv + fieldY);
			Controls.pilotHold(Controls.DASH, true);
			return;
		}
	}

	function wantSuper(target:Enemies, d:Float):Bool
	{
		if (!status.canSuper() || !combat.hasSuper())
			return false;
		return switch (combat.weapon)
		{
			case 1: target.bossBody || packSize(SUPER_FAR) >= SUPER_PACK;
			case 2: target.bossBody || clusterAt(target) >= SUPER_PACK;
			default: (target.bossBody && d < SUPER_NEAR) || packSize(SUPER_NEAR) >= SUPER_PACK;
		}
	}

	function fight(target:Enemies, elapsed:Float):Void
	{
		if (target == null || combat.disabled || combat.superBusy || combat.throwAttack.airborne)
		{
			holdTimer = 0;
			gigaGo = false;
			return;
		}

		var d = gapTo(target);

		if (wantSuper(target, d))
		{
			Controls.pilotHold(Controls.SUPER, true);
			return;
		}

		switch (combat.weapon)
		{
			case 1:
				if (combat.revolver.isReloading)
					return;
				if (combat.revolver.displayRounds <= 0)
				{
					if (tapTimer <= 0)
					{
						tapTimer = RELOAD_GAP;
						Controls.pilotHold(Controls.RELOAD, true);
					}
					return;
				}
				if (sideTimer <= 0 && combat.revolver.canBig() && d < BIG_RANGE
					&& (target.bossBody || target.big || clusterAt(target) >= 2))
				{
					sideTimer = BIG_GAP;
					Controls.pilotHold(Controls.SECOND, true);
					return;
				}
				if (d < GUN_FIRE)
					Controls.pilotHold(Controls.ATTACK, true);

			case 2:
				if (d < BASH_AT && combat.bash.ready && sideTimer <= 0)
				{
					sideTimer = BASH_GAP;
					Controls.pilotHold(Controls.SECOND, true);
					return;
				}
				if (combat.bow.charging)
				{
					var full = combat.bow.charge >= 1;
					var quick = d < QUICK_DRAW && combat.bow.charge >= DRAW_MIN;
					if (!full && !quick)
						Controls.pilotHold(Controls.ATTACK, true);
				}
				else if (!combat.bow.recovering && d < BOW_FIRE)
					Controls.pilotHold(Controls.ATTACK, true);

			case 3:
				if (combat.hookAttack.holding)
				{
					var toss = nearestFoeExcept(combat.hookAttack.heldEnemy);
					if (toss != null)
						Controls.pilotAimAt(tcx(toss), tcy(toss));
					Controls.pilotHold(Controls.ATTACK, true);
					return;
				}
				if (combat.hookAttack.busy)
					return;
				if (sideTimer <= 0 && combat.hookAttack.ready && d > HOOK_MIN && d < HOOK_MAX)
				{
					sideTimer = HOOK_GAP;
					Controls.pilotHold(Controls.SECOND, true);
					return;
				}
				if (combat.yoyoJab.active)
				{
					holdTimer += elapsed;
					if (holdTimer < YOYO_HOLD)
						Controls.pilotHold(Controls.ATTACK, true);
					else
						tapTimer = YOYO_REST;
				}
				else
				{
					holdTimer = 0;
					if (combat.yoyoJab.ready && tapTimer <= 0 && d < YOYO_FIRE)
						Controls.pilotHold(Controls.ATTACK, true);
				}

			default:
				if (combat.giga.engaged)
				{
					var reach = combat.gigaSwing.reach + MELEE_REACH_PAD;
					var release = (combat.giga.shineTimed && d < reach + 80) || (combat.giga.ready && d < reach) || d < 120;
					if (!release)
						Controls.pilotHold(Controls.ATTACK, true);
					else
						gigaGo = false;
					return;
				}
				if (sideTimer <= 0 && combat.swing.ready && d > THROW_MIN && d < THROW_MAX)
				{
					gigaGo = false;
					sideTimer = THROW_GAP;
					Controls.pilotHold(Controls.SECOND, true);
					return;
				}
				if (gigaGo || (combat.swing.ready && d > GIGA_MIN && d < GIGA_FAR))
				{
					gigaGo = true;
					Controls.pilotHold(Controls.ATTACK, true);
					return;
				}
				if (d < combat.swing.reach + MELEE_REACH_PAD && tapTimer <= 0)
				{
					tapTimer = SWING_GAP;
					Controls.pilotHold(Controls.ATTACK, true);
				}
		}
	}

	function nearestFoeExcept(held:Enemies):Enemies
	{
		var best:Enemies = null;
		var bestD:Float = ENGAGE;
		for (e in director.bodies.members)
		{
			if (skip(e) || e == held)
				continue;
			var d = distTo(e);
			if (d < bestD)
			{
				bestD = d;
				best = e;
			}
		}
		return best;
	}
}
