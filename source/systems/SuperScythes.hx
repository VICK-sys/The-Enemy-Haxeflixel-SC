package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import entities.SuperBlade;
import util.Paths;

class SuperScythes
{
	static inline var COUNT:Int = 10;
	static inline var RING_RX:Float = 130;
	static inline var RING_RY:Float = 45;
	static inline var ROT_SPEED:Float = 120;
	static inline var DEPTH_SCALE:Float = 0.4;
	static inline var HOVER_HEIGHT:Float = 40;
	static inline var HOVER_EASE:Float = 6;
	static inline var HOVER_BOB:Float = 5;
	static inline var HOVER_BOB_SPEED:Float = 3;
	static inline var FALL_GRAVITY:Float = 900;
	static inline var SQUASH_TIME:Float = 0.22;
	static inline var ASCEND_TIME:Float = 0.45;
	static inline var APEX_HEIGHT:Float = 90;
	static inline var DEPLOY_TIME:Float = 0.35;
	static inline var FIRE_GATE:Float = 0.08;
	static inline var TRAIL_INTERVAL:Float = 0.05;
	static inline var TRAIL_ALPHA:Float = 0.3;
	static inline var TRAIL_FADE:Float = 4;

	public var backLayer:FlxTypedGroup<SuperBlade>;
	public var frontLayer:FlxTypedGroup<SuperBlade>;
	public var trail:FlxTypedGroup<FlxSprite>;

	private var player:Player;
	private var scythe:FlxSprite;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var status:PlayerCombat;
	private var damageEnemy:(Enemies, Float, Float) -> Void;
	private var spinSound:FlxSound;
	private var pool:Array<SuperBlade> = [];
	private var ringAngle:Float = 0;
	private var fireGate:Float = 0;
	private var trailTimer:Float = 0;
	private var fx:Fx;
	private var baseOffsetY:Float = 0;
	private var baseScaleX:Float = 1;
	private var baseScaleY:Float = 1;
	private var hover:Float = 0;
	private var hoverTime:Float = 0;
	private var fallSpeed:Float = 0;
	private var squashTimer:Float = 0;
	private var wasActive:Bool = false;
	private var ascendTimer:Float = 0;
	private var deployTimer:Float = 0;
	private var scytheStartX:Float = 0;
	private var scytheStartY:Float = 0;
	private var scytheStartAngle:Float = 0;

	public var activating(get, never):Bool;

	function get_activating():Bool
	{
		return ascendTimer > 0;
	}

	public function new(player:Player, scythe:FlxSprite, arena:Arena, director:EnemyDirector, status:PlayerCombat, fx:Fx, damageEnemy:(Enemies, Float, Float) -> Void)
	{
		this.player = player;
		this.scythe = scythe;
		this.arena = arena;
		this.director = director;
		this.status = status;
		this.fx = fx;
		this.damageEnemy = damageEnemy;
		baseOffsetY = player.offset.y;
		baseScaleX = player.scale.x;
		baseScaleY = player.scale.y;
		backLayer = new FlxTypedGroup<SuperBlade>();
		frontLayer = new FlxTypedGroup<SuperBlade>();
		trail = new FlxTypedGroup<FlxSprite>();
		spinSound = FlxG.sound.load(Paths.sound("scythe/spin"), 0.35, true);
	}

	public function orbiterCount():Int
	{
		var n = 0;
		for (b in pool)
			if (b.exists && !b.launched)
				n++;
		return n;
	}

	public function active():Bool
	{
		return orbiterCount() > 0;
	}

	public function activate():Void
	{
		ascendTimer = ASCEND_TIME;
		scytheStartX = scythe.x;
		scytheStartY = scythe.y;
		scytheStartAngle = scythe.angle;
		FlxG.sound.play(Paths.sound("scythe/ascend"), 0.7);
	}

	function deployBlades():Void
	{
		var pmx = player.x + player.width * 0.5;
		var apexY = player.y + player.height * 0.5 - APEX_HEIGHT;
		for (i in 0...COUNT)
		{
			var b = obtainBlade();
			b.spawnInFormation(i);
			b.x = pmx - b.width / 2;
			b.y = apexY - b.height / 2;
		}
		ringAngle = 0;
		deployTimer = DEPLOY_TIME;
		scythe.visible = false;
		FlxG.sound.play(Paths.sound("scythe/split"), 0.7);
		spinSound.play(true);
	}

	function obtainBlade():SuperBlade
	{
		for (b in pool)
			if (!b.exists)
				return b;
		var b = new SuperBlade();
		pool.push(b);
		frontLayer.add(b);
		return b;
	}

	function setLayer(b:SuperBlade, front:Bool):Void
	{
		var to = front ? frontLayer : backLayer;
		if (to.members.indexOf(b) >= 0)
			return;
		backLayer.remove(b, true);
		frontLayer.remove(b, true);
		to.add(b);
	}

	public function tryLaunch(tx:Float, ty:Float):Void
	{
		if (fireGate > 0)
			return;

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var adx = tx - pmx;
		var ady = ty - pmy;
		var alen = Math.sqrt(adx * adx + ady * ady);
		if (alen < 0.001)
		{
			adx = 1;
			ady = 0;
			alen = 1;
		}
		adx /= alen;
		ady /= alen;

		var best:SuperBlade = null;
		var bestDot:Float = -999;
		for (b in pool)
		{
			if (!b.exists || b.launched)
				continue;
			var bdx = b.x + b.width / 2 - pmx;
			var bdy = b.y + b.height / 2 - pmy;
			var blen = Math.sqrt(bdx * bdx + bdy * bdy);
			var dot = blen > 0 ? (bdx * adx + bdy * ady) / blen : -1;
			if (dot > bestDot)
			{
				bestDot = dot;
				best = b;
			}
		}
		if (best == null)
			return;

		best.launch(tx, ty);
		setLayer(best, true);
		fireGate = FIRE_GATE;
		if (orbiterCount() == 0)
			spinSound.stop();
	}

	public function update(elapsed:Float):Void
	{
		fireGate -= elapsed;

		updateTrail(elapsed);

		if (ascendTimer > 0)
		{
			if (status.dead)
			{
				ascendTimer = 0;
			}
			else
			{
				ascendTimer -= elapsed;
				var p = 1 - Math.max(0, ascendTimer) / ASCEND_TIME;
				var ease = 1 - (1 - p) * (1 - p) * (1 - p);
				var apexX = player.x + player.width * 0.5 - scythe.width / 2;
				var apexY = player.y + player.height * 0.5 - APEX_HEIGHT - scythe.height / 2;
				scythe.x = scytheStartX + (apexX - scytheStartX) * ease;
				scythe.y = scytheStartY + (apexY - scytheStartY) * ease;
				var delta = ((0 - scytheStartAngle) % 360 + 540) % 360 - 180;
				scythe.angle = scytheStartAngle + delta * ease;
				if (ascendTimer <= 0)
					deployBlades();
			}
		}

		if (status.dead && active())
		{
			for (b in pool)
				if (b.exists && !b.launched)
					b.kill();
			spinSound.stop();
		}

		var isActive = active();
		if (wasActive && !isActive && !status.dead)
			scythe.visible = true;
		wasActive = isActive;

		hoverTime += elapsed;
		if (isActive)
		{
			hover += (HOVER_HEIGHT - hover) * (1 - Math.exp(-HOVER_EASE * elapsed));
			fallSpeed = 0;
		}
		else if (hover > 0)
		{
			fallSpeed += FALL_GRAVITY * elapsed;
			hover -= fallSpeed * elapsed;
			if (hover <= 0)
			{
				hover = 0;
				fallSpeed = 0;
				if (!status.dead)
				{
					squashTimer = SQUASH_TIME;
					FlxG.sound.play(Paths.sound("scythe/catch"), 0.45);
					fx.sparksAt(player.x + player.width * 0.5, player.y + player.height);
				}
			}
		}

		var bob = isActive ? Math.sin(hoverTime * HOVER_BOB_SPEED) * HOVER_BOB * (hover / HOVER_HEIGHT) : 0;
		var lift = hover + bob;
		player.offset.y = baseOffsetY + lift;
		player.floating = hover > 2;

		if (squashTimer > 0)
		{
			squashTimer -= elapsed;
			var q = squashTimer > 0 ? squashTimer / SQUASH_TIME : 0;
			player.scale.set(baseScaleX * (1 + 0.15 * q), baseScaleY * (1 - 0.25 * q));
		}

		ringAngle += ROT_SPEED * elapsed;
		if (deployTimer > 0)
			deployTimer -= elapsed;

		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5 - lift;
		var apexY = player.y + player.height * 0.5 - APEX_HEIGHT;

		for (b in pool)
		{
			if (!b.exists)
				continue;

			if (!b.launched)
			{
				var phase = (ringAngle + b.slot * (360 / COUNT)) * Math.PI / 180;
				var depth = Math.sin(phase);
				var rx = pmx + Math.cos(phase) * RING_RX;
				var ry = pmy + depth * RING_RY;
				if (deployTimer > 0)
				{
					var dp = 1 - deployTimer / DEPLOY_TIME;
					var de = 1 - (1 - dp) * (1 - dp) * (1 - dp);
					rx = pmx + (rx - pmx) * de;
					ry = apexY + (ry - apexY) * de;
				}
				b.x = rx - b.width / 2;
				b.y = ry - b.height / 2;
				var s = 3 + depth * DEPTH_SCALE;
				b.scale.set(s, s);
				b.alpha = 0.85 + 0.15 * depth;
				setLayer(b, depth > 0);
			}
			else if (b.inFlight() && !b.fading)
			{
				var cx = b.x + b.width / 2;
				var cy = b.y + b.height / 2;
				if (arena.wallAt(cx + b.dirX * SuperBlade.RADIUS, cy + b.dirY * SuperBlade.RADIUS))
				{
					b.velocity.set(0, 0);
					b.fading = true;
					continue;
				}
				var blade = b;
				director.eachInCircle(cx, cy, SuperBlade.RADIUS, function(e)
				{
					if (blade.hasHit(e))
						return;
					blade.markHit(e);
					damageEnemy(e, blade.dirX, blade.dirY);
				});
			}
		}
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

		var any = false;
		for (b in pool)
			if (b.exists)
			{
				any = true;
				break;
			}
		if (!any)
			return;

		trailTimer -= elapsed;
		if (trailTimer > 0)
			return;
		trailTimer = TRAIL_INTERVAL;

		for (b in pool)
		{
			if (!b.exists || b.fading)
				continue;
			var g = trail.recycle(FlxSprite);
			if (g.graphic == null)
			{
				g.loadGraphic(Paths.image("items/mufu_scythe"));
				g.antialiasing = false;
			}
			g.setPosition(b.x, b.y);
			g.angle = b.angle;
			g.scale.set(b.scale.x, b.scale.y);
			g.alpha = TRAIL_ALPHA;
		}
	}
}
