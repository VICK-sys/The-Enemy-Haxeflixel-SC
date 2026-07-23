package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import entities.enemy.EnemyNav;
import entities.ThrownScythe;
import util.Paths;

class ThrowAttack
{
	static inline var SPAWN_DIST:Float = 40;
	static inline var MAX_DIST:Float = 500;
	static inline var RETURN_SPEED:Float = 1250;
	static inline var CATCH_DIST:Float = 60;
	static inline var WALL_PROBE:Float = 60;
	static inline var TRAIL_INTERVAL:Float = 0.035;
	static inline var TRAIL_ALPHA:Float = 0.45;
	static inline var TRAIL_FADE:Float = 3;

	public var thrown:ThrownScythe;
	public var trail:FlxTypedGroup<FlxSprite>;
	public var airborne(get, never):Bool;

	private var player:Player;
	private var scythe:FlxSprite;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var status:PlayerCombat;
	private var damageEnemy:(Enemies, Float, Float) -> Void;
	private var spinSound:FlxSound;
	private var nav:EnemyNav;
	private var trailTimer:Float = 0;

	public function new(player:Player, scythe:FlxSprite, arena:Arena, director:EnemyDirector, status:PlayerCombat, damageEnemy:(Enemies, Float, Float) -> Void)
	{
		this.player = player;
		this.scythe = scythe;
		this.arena = arena;
		this.director = director;
		this.status = status;
		this.damageEnemy = damageEnemy;
		thrown = new ThrownScythe();
		trail = new FlxTypedGroup<FlxSprite>();
		spinSound = FlxG.sound.load(Paths.sound("scythe/spin"), 0.5, true);
		nav = new EnemyNav();
		nav.map = arena.map;
		nav.bodyRadius = 60;
		nav.repathInterval = 0.15;
	}

	function get_airborne():Bool
		return thrown.exists;

	public function launch(pmx:Float, pmy:Float, dx:Float, dy:Float):Void
	{
		scythe.visible = false;
		thrown.throwAt(pmx + dx * SPAWN_DIST, pmy + dy * SPAWN_DIST, dx, dy);
		FlxG.sound.play(Paths.sound("scythe/throw"), 0.8);
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
			if (tdx * tdx + tdy * tdy >= MAX_DIST * MAX_DIST
				|| arena.wallAt(cx + vx * WALL_PROBE, cy + vy * WALL_PROBE))
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
				scythe.visible = true;
				spinSound.stop();
				nav.clear();
				FlxG.sound.play(Paths.sound("scythe/catch"), 0.7);
				return;
			}
			nav.tick(elapsed, cx, cy, pmx, pmy);
			nav.steer(cx, cy, rlen > 0 ? rdx / rlen : 1, rlen > 0 ? rdy / rlen : 0);
			thrown.velocity.set(nav.moveX * RETURN_SPEED, nav.moveY * RETURN_SPEED);
			vx = nav.moveX;
			vy = nav.moveY;
		}

		var pushX = vx;
		var pushY = vy;
		director.eachInCircle(cx, cy, ThrownScythe.RADIUS, function(e)
		{
			if (thrown.hasHit(e))
				return;
			thrown.markHit(e);
			damageEnemy(e, pushX, pushY);
		});
	}

	function updateTrail(elapsed:Float):Void
	{
		for (g in trail.members)
		{
			if (g == null || !g.exists)
				continue;
			g.alpha -= TRAIL_FADE * elapsed;
			if (g.alpha <= 0)
				g.kill();
		}

		if (!thrown.exists)
			return;

		trailTimer -= elapsed;
		if (trailTimer > 0)
			return;
		trailTimer = TRAIL_INTERVAL;

		var g = trail.recycle(FlxSprite);
		if (g.graphic == null)
		{
			g.loadGraphic(Paths.image("items/mufu_scythe"));
			g.antialiasing = false;
		}
		g.setPosition(thrown.x, thrown.y);
		g.angle = thrown.angle;
		g.scale.set(thrown.scale.x, thrown.scale.y);
		g.alpha = TRAIL_ALPHA;
	}
}
