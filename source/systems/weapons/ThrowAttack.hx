package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import entities.Player;
import entities.enemy.EnemyNav;
import entities.weapon.ThrownWeapon;
import systems.world.Arena;
import systems.enemy.EnemyDirector;
import systems.PlayerCombat;
import data.WeaponData.WeaponDataRegistry;
import util.GhostTrail;
import util.Paths;

class ThrowAttack
{
	static inline var SPAWN_DIST:Float = 40;
	static inline var CATCH_DIST:Float = 60;
	static inline var WALL_PROBE:Float = 60;
	static inline var TRAIL_INTERVAL:Float = 0.035;
	static inline var TRAIL_ALPHA:Float = 0.45;
	static inline var TRAIL_FADE:Float = 3;

	public var thrown:ThrownWeapon;
	public var trail:GhostTrail;
	public var airborne(get, never):Bool;

	private var player:Player;
	private var heldSprite:FlxSprite;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var status:PlayerCombat;
	private var hits:HitPipeline;
	private var cfg = WeaponDataRegistry.get().thrown;
	private var spinSound:FlxSound;
	private var nav:EnemyNav;

	public function new(player:Player, heldSprite:FlxSprite, arena:Arena, director:EnemyDirector, status:PlayerCombat, hits:HitPipeline)
	{
		this.player = player;
		this.heldSprite = heldSprite;
		this.arena = arena;
		this.director = director;
		this.status = status;
		this.hits = hits;
		thrown = new ThrownWeapon();
		trail = new GhostTrail("items/hammer", TRAIL_ALPHA, TRAIL_FADE, TRAIL_INTERVAL);
		spinSound = FlxG.sound.create(Paths.sound("weapon/spin")).setup(0.5, true);
		nav = new EnemyNav();
		nav.map = arena.map;
		nav.bodyRadius = 60;
		nav.repathInterval = 0.15;
	}

	function get_airborne():Bool
		return thrown.exists;

	public function launch(pmx:Float, pmy:Float, dx:Float, dy:Float):Void
	{
		heldSprite.visible = false;
		thrown.throwAt(pmx + dx * SPAWN_DIST, pmy + dy * SPAWN_DIST, dx, dy);
		FlxG.sound.play(Paths.sound("weapon/throw"), 0.8);
		spinSound.play(true);
	}

	public function update(elapsed:Float):Void
	{
		updateFlight(elapsed);
		updateTrail(elapsed);
	}

	function updateFlight(elapsed:Float):Void
	{
		if (!thrown.exists)
			return;

		if (status.dead)
		{
			thrown.kill();
			spinSound.stop();
			nav.clear();
			return;
		}

		var cx = thrown.x + thrown.width / 2;
		var cy = thrown.y + thrown.height / 2;
		var pmx:Float = player.x + player.width * 0.5;
		var pmy:Float = player.y + player.height * 0.5;

		var vlen = Math.sqrt(thrown.velocity.x * thrown.velocity.x + thrown.velocity.y * thrown.velocity.y);
		var vx = vlen > 0 ? thrown.velocity.x / vlen : 1;
		var vy = vlen > 0 ? thrown.velocity.y / vlen : 0;

		if (!thrown.returning)
		{
			var tdx = cx - thrown.startX;
			var tdy = cy - thrown.startY;
			if (tdx * tdx + tdy * tdy >= cfg.maxDist * cfg.maxDist
				|| arena.wallAt(cx + vx * WALL_PROBE, cy + vy * WALL_PROBE)
				|| systems.world.PropBlock.at(cx + vx * WALL_PROBE, cy + vy * WALL_PROBE))
			{
				thrown.beginReturn();
				nav.notifyBlocked();
			}
		}

		if (thrown.returning)
		{
			var rdx = pmx - cx;
			var rdy = pmy - cy;
			var rlen = Math.sqrt(rdx * rdx + rdy * rdy);
			if (rlen < CATCH_DIST)
			{
				thrown.kill();
				heldSprite.visible = true;
				spinSound.stop();
				nav.clear();
				FlxG.sound.play(Paths.sound("weapon/catch"), 0.7);
				return;
			}
			nav.tick(elapsed, cx, cy, pmx, pmy);
			nav.steer(cx, cy, rlen > 0 ? rdx / rlen : 1, rlen > 0 ? rdy / rlen : 0);
			thrown.velocity.set(nav.moveX * cfg.returnSpeed, nav.moveY * cfg.returnSpeed);
			vx = nav.moveX;
			vy = nav.moveY;
		}

		var pushX = vx;
		var pushY = vy;
		director.eachInCircle(cx, cy, ThrownWeapon.RADIUS, function(e)
		{
			if (thrown.hasHit(e))
				return;
			thrown.markHit(e);
			hits.damage(e, pushX, pushY);
		});
	}

	function updateTrail(elapsed:Float):Void
	{
		if (trail.tick(elapsed) && thrown.exists)
			trail.stamp(thrown);
	}
}
