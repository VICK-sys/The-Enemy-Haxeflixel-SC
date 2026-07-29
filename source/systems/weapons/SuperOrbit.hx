package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.weapon.Orbiter;
import systems.world.Arena;
import systems.enemy.EnemyDirector;
import systems.PlayerCombat;
import systems.Fx;
import data.WeaponData.WeaponDataRegistry;
import util.GhostTrail;
import util.Paths;

class SuperOrbit
{
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
	static inline var TRAIL_INTERVAL:Float = 0.05;
	static inline var TRAIL_ALPHA:Float = 0.3;
	static inline var TRAIL_FADE:Float = 4;

	public var backLayer:FlxTypedGroup<Orbiter>;
	public var frontLayer:FlxTypedGroup<Orbiter>;
	public var trail:GhostTrail;

	public var cosmetic:Bool = false;

	private var player:FlxSprite;
	private var owner:Player;
	private var heldSprite:FlxSprite;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var status:PlayerCombat;
	private var hits:HitPipeline;
	private var spinSound:FlxSound;
	private var cfg = WeaponDataRegistry.get().superOrbit;
	private var pool:Array<Orbiter> = [];
	private var ringAngle:Float = 0;
	private var fireGate:Float = 0;
	private var fx:Fx;
	private var baseScaleX:Float = 1;
	private var baseScaleY:Float = 1;
	private var hover:Float = 0;
	private var hoverTime:Float = 0;
	private var fallSpeed:Float = 0;
	private var squashTimer:Float = 0;
	private var wasActive:Bool = false;
	private var ascendTimer:Float = 0;
	private var deployTimer:Float = 0;
	private var heldStartX:Float = 0;
	private var heldStartY:Float = 0;
	private var heldStartAngle:Float = 0;

	public var activating(get, never):Bool;

	function get_activating():Bool
	{
		return ascendTimer > 0;
	}

	public static function decoration(body:FlxSprite, fx:Fx):SuperOrbit
	{
		var s = new SuperOrbit(body, null, null, null, null, fx, null);
		s.cosmetic = true;
		return s;
	}

	public function new(player:FlxSprite, heldSprite:FlxSprite, arena:Arena, director:EnemyDirector, status:PlayerCombat, fx:Fx, hits:HitPipeline)
	{
		this.player = player;
		this.owner = Std.isOfType(player, Player) ? cast player : null;
		this.heldSprite = heldSprite;
		this.arena = arena;
		this.director = director;
		this.status = status;
		this.fx = fx;
		this.hits = hits;
		baseScaleX = player.scale.x;
		baseScaleY = player.scale.y;
		backLayer = new FlxTypedGroup<Orbiter>();
		frontLayer = new FlxTypedGroup<Orbiter>();
		trail = new GhostTrail("items/hammer", TRAIL_ALPHA, TRAIL_FADE, TRAIL_INTERVAL);
		spinSound = FlxG.sound.create(Paths.sound("weapon/spin")).setup(0.35, true);
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

	public function clear():Void
	{
		for (b in pool)
			if (b.exists && !b.launched)
				b.kill();
		spinSound.stop();
		ascendTimer = 0;
	}

	public var hue:Float = 0;

	public function activate():Void
	{
		ascendTimer = ASCEND_TIME;
		if (heldSprite != null)
		{
			heldStartX = heldSprite.x;
			heldStartY = heldSprite.y;
			heldStartAngle = heldSprite.angle;
		}
		FlxG.sound.play(Paths.sound("weapon/ascend"), 0.7);
	}

	function deployBlades():Void
	{
		var pmx = player.x + player.width * 0.5;
		var apexY = player.y + player.height * 0.5 - APEX_HEIGHT;
		for (i in 0...cfg.count)
		{
			var b = obtainBlade();
			b.paint(hue);
			b.spawnInFormation(i);
			b.x = pmx - b.width / 2;
			b.y = apexY - b.height / 2;
		}
		ringAngle = 0;
		deployTimer = DEPLOY_TIME;
		if (heldSprite != null)
			heldSprite.visible = false;
		FlxG.sound.play(Paths.sound("weapon/split"), 0.7);
		spinSound.play(true);
	}

	function obtainBlade():Orbiter
	{
		for (b in pool)
			if (!b.exists)
				return b;
		var b = new Orbiter();
		pool.push(b);
		frontLayer.add(b);
		return b;
	}

	function setLayer(b:Orbiter, front:Bool):Void
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

		var best:Orbiter = null;
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
		fireGate = cfg.fireGate;
		if (orbiterCount() == 0)
			spinSound.stop();
	}

	public function update(elapsed:Float):Void
	{
		fireGate -= elapsed;

		updateTrail(elapsed);

		if (ascendTimer > 0)
		{
			if (!cosmetic && status.dead)
			{
				ascendTimer = 0;
			}
			else
			{
				ascendTimer -= elapsed;

				if (heldSprite != null)
				{
					var p = 1 - Math.max(0, ascendTimer) / ASCEND_TIME;
					var ease = 1 - (1 - p) * (1 - p) * (1 - p);
					var apexX = player.x + player.width * 0.5 - heldSprite.width / 2;
					var apexY = player.y + player.height * 0.5 - APEX_HEIGHT - heldSprite.height / 2;
					heldSprite.x = heldStartX + (apexX - heldStartX) * ease;
					heldSprite.y = heldStartY + (apexY - heldStartY) * ease;
					var delta = ((0 - heldStartAngle) % 360 + 540) % 360 - 180;
					heldSprite.angle = heldStartAngle + delta * ease;
				}
				if (ascendTimer <= 0)
					deployBlades();
			}
		}

		if (!cosmetic && status.dead && active())
		{
			for (b in pool)
				if (b.exists && !b.launched)
					b.kill();
			spinSound.stop();
		}

		var isActive = active();
		if (!cosmetic && wasActive && !isActive && !status.dead)
			heldSprite.visible = true;
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
				if (cosmetic || !status.dead)
				{
					squashTimer = SQUASH_TIME;
					FlxG.sound.play(Paths.sound("weapon/catch"), 0.45);
					fx.sparksAt(player.x + player.width * 0.5, player.y + player.height);
				}
			}
		}

		var bob = isActive ? Math.sin(hoverTime * HOVER_BOB_SPEED) * HOVER_BOB * (hover / HOVER_HEIGHT) : 0;
		var lift = hover + bob;

		if (owner != null)
		{
			owner.offset.y = owner.baseOffsetY + lift;
			owner.floating = hover > 2;
		}

		if (squashTimer > 0)
		{
			squashTimer -= elapsed;
			var q = squashTimer > 0 ? squashTimer / SQUASH_TIME : 0;
			if (owner != null)
				owner.scale.set(baseScaleX * (1 + 0.15 * q), baseScaleY * (1 - 0.25 * q));
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
				var phase = (ringAngle + b.slot * (360 / cfg.count)) * Math.PI / 180;
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
			else if (!cosmetic && b.inFlight() && !b.fading)
			{
				var cx = b.x + b.width / 2;
				var cy = b.y + b.height / 2;
				if (arena.wallAt(cx + b.dirX * Orbiter.RADIUS, cy + b.dirY * Orbiter.RADIUS)
					|| systems.world.PropBlock.at(cx + b.dirX * Orbiter.RADIUS, cy + b.dirY * Orbiter.RADIUS))
				{
					b.velocity.set(0, 0);
					b.fading = true;
					continue;
				}
				var blade = b;
				director.eachInCircle(cx, cy, Orbiter.RADIUS, function(e)
				{
					if (blade.hasHit(e))
						return;
					blade.markHit(e);
					hits.damage(e, blade.dirX, blade.dirY);
				});
			}
		}
	}

	function updateTrail(elapsed:Float):Void
	{
		if (!trail.tick(elapsed))
			return;
		for (b in pool)
			if (b.exists && !b.fading)
				trail.stamp(b);
	}
}
