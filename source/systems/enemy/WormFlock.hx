package systems.enemy;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.enemy.Enemies;
import data.EnemyData.EnemyDataRegistry;
import data.EnemyData.WormData;
import util.Paths;

typedef WormChain =
{
	segs:Array<Enemies>,
	trail:Array<Float>,
	clock:Float,
	bearing:Float,
	shot:Float,
	aiming:Float,
	aimDeg:Float,
	aimHold:Float,
	headUp:Bool
}

typedef WormPuff =
{
	sprite:FlxSprite,
	life:Float
}

class WormFlock
{
	static inline var TRAIL_STEP:Float = 6;
	static inline var STRIDE:Int = 3;
	static inline var TRAIL_SLACK:Float = 1.5;
	static inline var EDGE_PAD:Float = 120;
	static inline var EDGE_TURN:Float = 600;
	static inline var EDGE_SHARE:Float = 0.22;
	static inline var TRACK:Float = 1.4;
	static inline var JOSTLE:Float = 2.2;
	static inline var AIM_TIME:Float = 0.35;
	static inline var AIM_HOLD:Float = 0.45;
	static inline var DIG_VOL:Float = 0.55;
	static inline var GLOW_TIME:Float = 0.35;
	static inline var GLOW_HOLD:Float = 0.6;
	static inline var PUFF_LIFE:Float = 0.4;
	static inline var PUFF_GROW:Float = 2.2;
	static inline var SURFACE_MARK:Float = 0.04;

	public var done(default, null):Bool = false;
	public var lastX(default, null):Float = 0;
	public var lastY(default, null):Float = 0;

	public var floorAt:(Float, Float) -> Int;

	private var cfg:WormData;
	private var chains:Array<WormChain> = [];
	private var glow:Map<Enemies, Float> = new Map();
	private var puffs:Array<WormPuff> = [];
	private var volleyGap:Float = 0;
	private var digLoop:flixel.sound.FlxSound;
	private var layers:RenderLayers;
	private var fx:Fx;
	private var headOffY:Float;
	private var bodyOffY:Float;
	private var roomW:Float;
	private var roomH:Float;
	private var edgeTurn:Float;

	public function new(layers:RenderLayers, fx:Fx, roomW:Float, roomH:Float)
	{
		this.layers = layers;
		this.fx = fx;
		this.roomW = roomW;
		this.roomH = roomH;
		edgeTurn = Math.min(EDGE_TURN, Math.min(roomW, roomH) * EDGE_SHARE);
		cfg = EnemyDataRegistry.get("worm").worm;
		headOffY = EnemyDataRegistry.get("worm").offsetY;
		bodyOffY = EnemyDataRegistry.get("worm_body").offsetY;
	}

	public function adopt(segs:Array<Enemies>):Void
	{
		var trail:Array<Float> = [];
		for (s in segs)
		{
			trail.push(s.x + s.width * 0.5);
			trail.push(s.y + s.height * 0.5);
			trail.push(0);
		}
		var last = segs[segs.length - 1];
		trail.push(last.x + last.width * 0.5);
		trail.push(last.y + last.height * 0.5 + cfg.spacing * 3);
		trail.push(0);
		chains.push({
			segs: segs,
			trail: trail,
			clock: 0,
			bearing: 0,
			shot: cfg.shotCooldown,
			aiming: 0,
			aimDeg: 0,
			aimHold: 0,
			headUp: false
		});
	}

	function dropPart(s:Enemies):Void
		glow.remove(s);

	public function update(elapsed:Float):Void
	{
		updatePuffs(elapsed);

		if (done)
			return;

		if (volleyGap > 0)
			volleyGap -= elapsed;

		var splits:Array<WormChain> = [];
		var i = chains.length;
		while (i-- > 0)
		{
			var c = chains[i];
			reap(c, splits);
			if (c.segs.length == 0)
				chains.splice(i, 1);
		}
		for (s in splits)
		{
			s.bearing = angleOf(s);
			chains.push(s);
		}

		if (chains.length == 0)
		{
			done = true;
			retire();
			return;
		}

		jostle(elapsed);
		for (c in chains)
			advance(c, elapsed);
		tunnelHum();
	}

	public function hush():Void
	{
		if (digLoop != null && digLoop.playing)
			digLoop.stop();
	}

	public function retire():Void
	{
		hush();
		for (p in puffs)
		{
			p.life = 0;
			p.sprite.visible = false;
			layers.shadowLayer.remove(p.sprite, true);
			p.sprite.destroy();
		}
		puffs.resize(0);
	}

	function tunnelHum():Void
	{
		var bx:Float = 0;
		var by:Float = 0;
		var best:Float = -1;
		for (c in chains)
		{
			var h = c.segs[0];
			if (!h.buried)
				continue;
			var hx = h.x + h.width * 0.5;
			var hy = h.y + h.height * 0.5;
			var d = h.target == null ? 0 : Math.pow(hx - h.target.x, 2) + Math.pow(hy - h.target.y, 2);
			if (best < 0 || d < best)
			{
				best = d;
				bx = hx;
				by = hy;
			}
		}

		if (best < 0)
		{
			hush();
			return;
		}

		if (digLoop == null)
			digLoop = FlxG.sound.load(Paths.sound("wyrm_dig"), DIG_VOL, true, FlxG.sound.defaultSoundGroup);
		if (!digLoop.playing)
			digLoop.play(true);
		util.Sfx.tune(digLoop, bx, by, DIG_VOL);
	}

	function angleOf(c:WormChain):Float
	{
		var h = c.segs[0];
		var hx = h.x + h.width * 0.5;
		var hy = h.y + h.height * 0.5;
		if (h.target == null)
			return 0;
		return Math.atan2(hy - (h.target.y + h.target.height * 0.5), hx - (h.target.x + h.target.width * 0.5));
	}

	function jostle(elapsed:Float):Void
	{
		if (chains.length < 2)
			return;

		for (c in chains)
		{
			var d = angleOf(c) - c.bearing;
			while (d > Math.PI)
				d -= Math.PI * 2;
			while (d < -Math.PI)
				d += Math.PI * 2;
			c.bearing += d * Math.min(1, TRACK * elapsed) + cfg.orbit * elapsed;
		}

		var arc = Math.PI * 2 / chains.length;
		for (i in 0...chains.length)
			for (j in i + 1...chains.length)
			{
				var d = chains[j].bearing - chains[i].bearing;
				while (d > Math.PI)
					d -= Math.PI * 2;
				while (d < -Math.PI)
					d += Math.PI * 2;
				var gap = d < 0 ? -d : d;
				if (gap >= arc)
					continue;
				var push = (arc - gap) * JOSTLE * elapsed;
				if (d >= 0)
				{
					chains[j].bearing += push;
					chains[i].bearing -= push;
				}
				else
				{
					chains[j].bearing -= push;
					chains[i].bearing += push;
				}
			}
	}

	function clockFor(lift:Float):Float
	{
		if (lift <= SURFACE_MARK)
			return cfg.underTime * 0.5;
		var r = lift / cfg.lift;
		if (r > 1)
			r = 1;
		return cfg.underTime + (1 - Math.asin(r) / Math.PI) * cfg.overTime;
	}

	inline function liftOf(s:Enemies):Float
		return s.offset.y - (s.kind == "worm" ? headOffY : bodyOffY);

	function reap(c:WormChain, splits:Array<WormChain>):Void
	{
		var k = 0;
		while (k < c.segs.length)
		{
			var s = c.segs[k];
			if (s.exists && !s.isDead)
			{
				k++;
				continue;
			}

			lastX = s.x + s.width * 0.5;
			lastY = s.y + s.height * 0.5;
			fx.sparksAt(lastX, lastY);
			dropPart(s);
			if (s.exists)
				s.kill();

			var right = c.segs.splice(k + 1, c.segs.length);
			c.segs.pop();

			if (right.length > 0)
			{
				var trail:Array<Float> = [];
				for (r in right)
				{
					trail.push(r.x + r.width * 0.5);
					trail.push(r.y + r.height * 0.5);
					trail.push(liftOf(r));
				}
				var last = right[right.length - 1];
				trail.push(last.x + last.width * 0.5);
				trail.push(last.y + last.height * 0.5 + cfg.spacing * 2);
				trail.push(0);
				splits.push({
					segs: right,
					trail: trail,
					clock: clockFor(liftOf(right[0])),
					bearing: 0,
					shot: cfg.shotCooldown,
					aiming: 0,
					aimDeg: 0,
					aimHold: 0,
					headUp: !right[0].buried
				});
			}
			return;
		}
	}

	function headLift(clock:Float):Float
	{
		var cycle = cfg.underTime + cfg.overTime;
		var t = clock % cycle;
		if (t < cfg.underTime)
			return 0;
		var u = (t - cfg.underTime) / cfg.overTime;
		return Math.sin(u * Math.PI) * cfg.lift;
	}

	function advance(c:WormChain, elapsed:Float):Void
	{
		c.clock += elapsed;
		c.shot -= elapsed;

		var head = c.segs[0];
		var hx = head.x + head.width * 0.5;
		var hy = head.y + head.height * 0.5;

		var tx = hx + 1;
		var ty = hy;
		if (head.target != null)
		{
			tx = head.target.x + head.target.width * 0.5;
			ty = head.target.y + head.target.height * 0.5;
		}

		var sx = tx;
		var sy = ty;
		if (chains.length > 1)
		{
			sx += Math.cos(c.bearing) * cfg.flankDist;
			sy += Math.sin(c.bearing) * cfg.flankDist;
		}

		var wx = sx - hx;
		var wy = sy - hy;
		var wl = Math.sqrt(wx * wx + wy * wy);
		if (wl > 0)
		{
			wx /= wl;
			wy /= wl;
		}

		if (hx < edgeTurn)
			wx += (edgeTurn - hx) / edgeTurn * 3;
		else if (hx > roomW - edgeTurn)
			wx -= (hx - (roomW - edgeTurn)) / edgeTurn * 3;
		if (hy < edgeTurn)
			wy += (edgeTurn - hy) / edgeTurn * 3;
		else if (hy > roomH - edgeTurn)
			wy -= (hy - (roomH - edgeTurn)) / edgeTurn * 3;
		var el = Math.sqrt(wx * wx + wy * wy);
		if (el > 0)
		{
			wx /= el;
			wy /= el;
		}

		var ox = c.trail.length >= STRIDE * 2 ? hx - c.trail[STRIDE] : 1;
		var oy = c.trail.length >= STRIDE * 2 ? hy - c.trail[STRIDE + 1] : 0;
		var ol = Math.sqrt(ox * ox + oy * oy);
		if (ol > 0)
		{
			ox /= ol;
			oy /= ol;
		}
		var heading = ol > 0 ? Math.atan2(oy, ox) : Math.atan2(wy, wx);
		var turn = Math.atan2(wy, wx) - heading;
		while (turn > Math.PI)
			turn -= Math.PI * 2;
		while (turn < -Math.PI)
			turn += Math.PI * 2;
		var cap = cfg.turn * elapsed;
		if (turn > cap)
			turn = cap;
		else if (turn < -cap)
			turn = -cap;
		heading += turn;
		var dx = Math.cos(heading);
		var dy = Math.sin(heading);

		hx += dx * head.speed * elapsed;
		hy += dy * head.speed * elapsed;
		hx = hx < EDGE_PAD ? EDGE_PAD : (hx > roomW - EDGE_PAD ? roomW - EDGE_PAD : hx);
		hy = hy < EDGE_PAD ? EDGE_PAD : (hy > roomH - EDGE_PAD ? roomH - EDGE_PAD : hy);

		var lift = headLift(c.clock);
		var up = lift > SURFACE_MARK;
		if (up != c.headUp)
		{
			c.headUp = up;
			if (up)
			{
				util.Sfx.at("wyrm_surface", hx, hy, 0.85);
				breach(hx, hy + head.shadowOffY - head.height * 0.5);
			}
			else
				util.Sfx.at("digging", hx, hy, 0.5);
		}

		var lx = c.trail[0];
		var ly = c.trail[1];
		var moved = Math.sqrt((hx - lx) * (hx - lx) + (hy - ly) * (hy - ly));
		if (moved >= TRAIL_STEP)
		{
			c.trail.unshift(lift);
			c.trail.unshift(hy);
			c.trail.unshift(hx);
			var cap = Std.int(c.segs.length * cfg.spacing * TRAIL_SLACK / TRAIL_STEP) * STRIDE + STRIDE * 4;
			if (c.trail.length > cap)
				c.trail.resize(cap);
		}
		else
		{
			c.trail[2] = lift;
		}

		shoot(c, elapsed, tx, ty);

		for (idx in 0...c.segs.length)
			place(c, idx, elapsed, hx, hy, lift);
	}

	function place(c:WormChain, idx:Int, elapsed:Float, hx:Float, hy:Float, headHigh:Float):Void
	{
		var s = c.segs[idx];
		var px = hx;
		var py = hy;
		var lift = headHigh;

		if (idx > 0)
		{
			var want = idx * cfg.spacing;
			var run = Math.sqrt((hx - c.trail[0]) * (hx - c.trail[0]) + (hy - c.trail[1]) * (hy - c.trail[1]));
			var ax = hx;
			var ay = hy;
			var aLift = headHigh;
			var bx = c.trail[0];
			var by = c.trail[1];
			var bLift = c.trail[2];
			var j = 0;
			while (run < want && j + STRIDE + 2 < c.trail.length)
			{
				ax = c.trail[j];
				ay = c.trail[j + 1];
				aLift = c.trail[j + 2];
				bx = c.trail[j + STRIDE];
				by = c.trail[j + STRIDE + 1];
				bLift = c.trail[j + STRIDE + 2];
				run += Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
				j += STRIDE;
			}
			if (run >= want)
			{
				var back = run - want;
				var segLen = Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
				var t = segLen > 0 ? back / segLen : 0;
				px = bx + (ax - bx) * t;
				py = by + (ay - by) * t;
				lift = bLift + (aLift - bLift) * t;
			}
			else
			{
				px = bx;
				py = by;
				lift = bLift;
			}
		}

		s.x = px - s.width * 0.5;
		s.y = py - s.height * 0.5;
		s.velocity.set(0, 0);

		var up = lift > SURFACE_MARK;
		var lit = glow.exists(s) ? glow.get(s) : 0;
		if (up != !s.buried)
		{
			s.buried = !up;
			if (up)
			{
				lit = GLOW_TIME;
				if (idx > 0)
					breach(px, s.feetY);
			}
		}
		if (lit > 0)
			lit = lit > elapsed ? lit - elapsed : 0;
		glow.set(s, lit);

		var baseOff = s.kind == "worm" ? headOffY : bodyOffY;
		s.offset.y = baseOff + lift;
		s.shadowScaleX = up ? 8 : 0;

		var want = up ? (idx == 0 ? "head" : "body") : "mound";
		if (s.animation.name != want)
			s.animation.play(want);

		if (up)
		{
			if (s.flashTimer <= 0)
			{
				s.color = 0xFFFFFF;
				var t = lit / GLOW_TIME;
				var add = t >= GLOW_HOLD ? 255 : Std.int(t / GLOW_HOLD * 255);
				s.setColorTransform(1, 1, 1, s.alpha, add, add, add, 0);
			}
			if (idx == 0)
			{
				var deg = c.aimHold > 0 ? c.aimDeg : Math.atan2(py - c.trail[STRIDE + 1], px - c.trail[STRIDE]) * 180 / Math.PI;
				if (deg > 90 || deg < -90)
				{
					s.flipX = true;
					deg = deg > 0 ? deg - 180 : deg + 180;
				}
				else
					s.flipX = false;
				s.angle = deg;
			}
		}
		else
		{
			if (idx == 0)
				s.angle = 0;
			if (s.flashTimer <= 0)
			{
				s.setColorTransform(1, 1, 1, s.alpha, 0, 0, 0, 0);
				if (floorAt != null)
					s.color = floorAt(px, s.feetY);
			}
		}

	}

	function breach(px:Float, py:Float):Void
	{
		var s:FlxSprite = null;
		for (p in puffs)
			if (p.life <= 0 && !p.sprite.visible)
			{
				s = p.sprite;
				p.life = PUFF_LIFE;
				break;
			}
		if (s == null)
		{
			s = new FlxSprite();
			s.frames = Paths.sparrow("enemies/worm");
			s.animation.addByPrefix("puff", "Mound", 8, false);
			s.antialiasing = false;
			layers.shadowLayer.add(s);
			puffs.push({sprite: s, life: PUFF_LIFE});
		}
		s.animation.play("puff", true);
		s.color = 0xFFFFFF;
		s.alpha = 0.85;
		s.scale.set(4, 4);
		s.updateHitbox();
		s.setPosition(px - s.width * 0.5, py - s.height * 0.5);
		s.visible = true;
	}

	function updatePuffs(elapsed:Float):Void
	{
		for (p in puffs)
		{
			if (p.life <= 0)
				continue;
			p.life -= elapsed;
			var t = p.life / PUFF_LIFE;
			if (t <= 0)
			{
				p.sprite.visible = false;
				p.life = 0;
				continue;
			}
			p.sprite.alpha = t * 0.85;
			var k = 4 + (1 - t) * PUFF_GROW;
			var cx = p.sprite.x + p.sprite.width * 0.5;
			var cy = p.sprite.y + p.sprite.height * 0.5;
			p.sprite.scale.set(k, k);
			p.sprite.updateHitbox();
			p.sprite.setPosition(cx - p.sprite.width * 0.5, cy - p.sprite.height * 0.5);
		}
	}

	function shoot(c:WormChain, elapsed:Float, tx:Float, ty:Float):Void
	{
		var head = c.segs[0];
		var hx = head.x + head.width * 0.5;
		var hy = head.y + head.height * 0.5;

		if (c.aimHold > 0)
			c.aimHold -= elapsed;

		if (head.buried || c.segs.length - 1 < cfg.shotMinParts)
		{
			c.aiming = 0;
			return;
		}

		c.aimDeg = Math.atan2(ty - hy, tx - hx) * 180 / Math.PI;

		if (c.aiming > 0)
		{
			c.aimHold = AIM_HOLD;
			c.aiming -= elapsed;
			if (c.aiming > 0)
				return;
			c.shot = cfg.shotCooldown;
			for (i in 0...cfg.shotCount)
			{
				var off = (i - (cfg.shotCount - 1) * 0.5) * cfg.shotSpread;
				var rad = (c.aimDeg + off) * Math.PI / 180;
				head.requestShot(Math.cos(rad), Math.sin(rad), cfg.shotDamage, cfg.shotSpeed, cfg.shotRange,
					"bullets/round_bullet_enemy", "enemies/shoot");
			}
			return;
		}

		if (c.shot > 0 || !head.pathing.fireClear)
			return;
		if (chains.length > 1)
		{
			if (volleyGap > 0)
				return;
			volleyGap = cfg.volleyGap;
		}
		c.aiming = AIM_TIME;
		c.aimHold = AIM_HOLD;
	}

	public function chainCount():Int
		return chains.length;

	public function segmentCount():Int
	{
		var n = 0;
		for (c in chains)
			n += c.segs.length;
		return n;
	}
}
