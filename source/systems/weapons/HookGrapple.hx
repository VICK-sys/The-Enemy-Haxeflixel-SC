package systems.weapons;

import flixel.FlxG;
import flixel.util.FlxDirectionFlags;
import entities.Player;
import entities.enemy.Enemies;
import entities.weapon.HookShot;
import systems.world.Arena;
import systems.enemy.EnemyDirector;
import systems.PlayerCombat;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;
import systems.world.PropBlock;

class HookGrapple
{
	static inline var NONE:Int = 0;
	static inline var FLYING:Int = 1;
	static inline var PULLING:Int = 2;

	private var cfg = WeaponDataRegistry.get().hook;
	private var player:Player;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var status:PlayerCombat;
	private var hits:HitPipeline;
	private var hook:HookShot;

	private var stage:Int = NONE;
	private var fireX:Float = 0;
	private var fireY:Float = 0;
	private var anchorX:Float = 0;
	private var anchorY:Float = 0;
	private var timer:Float = 0;
	private var hitList:Array<Enemies> = [];
	private var target:Enemies;

	public function new(player:Player, arena:Arena, director:EnemyDirector, status:PlayerCombat, hits:HitPipeline, hook:HookShot)
	{
		this.player = player;
		this.arena = arena;
		this.director = director;
		this.status = status;
		this.hits = hits;
		this.hook = hook;
	}

	public function begin(x:Float, y:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		fireX = x;
		fireY = y;
		hook.fire(x, y, dx, dy, aimDeg);
		hitList = [];
		player.blockMovement = true;
		stage = FLYING;
		FlxG.sound.play(Paths.sound("scythe/throw"), 0.6);
	}

	public function update(elapsed:Float):Bool
	{
		return switch (stage)
		{
			case FLYING: updateFly();
			case PULLING: updatePull(elapsed);
			default: false;
		};
	}

	function updateFly():Bool
	{
		if (!hook.exists)
			return false;

		player.velocity.set(0, 0);

		var hcx = hook.x + hook.width / 2;
		var hcy = hook.y + hook.height / 2;

		var hit = director.firstInCircle(hcx, hcy, HookShot.RADIUS, true);
		if (hit != null)
		{
			target = hit;
			anchorX = hit.x + hit.width * 0.5;
			anchorY = hit.y + hit.height * 0.5;
			hook.velocity.set(0, 0);
			timer = cfg.grappleTimeout;
			hitList = [];
			status.invincible = true;
			stage = PULLING;
			return true;
		}

		var fdx = hcx - fireX;
		var fdy = hcy - fireY;
		var px = hcx + hook.dirX * HookShot.RADIUS;
		var py = hcy + hook.dirY * HookShot.RADIUS;
		return fdx * fdx + fdy * fdy < cfg.grappleRange * cfg.grappleRange && !arena.wallAt(px, py) && !PropBlock.at(px, py);
	}

	function updatePull(elapsed:Float):Bool
	{
		if (target != null && target.exists && !target.isDead)
		{
			anchorX = target.x + target.width * 0.5;
			anchorY = target.y + target.height * 0.5;
		}

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var dx = anchorX - pmx;
		var dy = anchorY - pmy;
		var dist = Math.sqrt(dx * dx + dy * dy);

		timer -= elapsed;
		if (dist < cfg.grappleCatch || timer <= 0 || player.wasTouching != FlxDirectionFlags.NONE)
			return false;

		var ux = dx / dist;
		var uy = dy / dist;
		player.velocity.set(ux * cfg.grapplePullSpeed, uy * cfg.grapplePullSpeed);
		player.flipX = ux < 0;
		hook.setPosition(anchorX - hook.width / 2, anchorY - hook.height / 2);

		director.eachInCircle(pmx, pmy, cfg.grappleRadius, function(e)
		{
			if (hitList.contains(e))
				return;
			hitList.push(e);
			hits.damage(e, ux * cfg.grappleFling, uy * cfg.grappleFling);
		});
		return true;
	}

	public function stop():Void
	{
		target = null;
		hitList = [];
		if (stage == NONE)
			return;

		stage = NONE;
		player.velocity.set(0, 0);
		status.invincible = false;
		if (!status.dead)
			player.blockMovement = false;
	}
}
