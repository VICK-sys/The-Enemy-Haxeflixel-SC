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
	headUp:Bool,
	chargeCd:Float,
	winding:Float,
	charge:Float,
	liftFrom:Float,
	face:Float,
	faceSet:Bool,
	markX:Float,
	markY:Float,
	marked:Bool,
	flank:Float
}

typedef WormPuff =
{
	sprite:FlxSprite,
	hold:Float,
	closing:Bool,
	flash:Float,
	color:Int
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
	static inline var SURFACE_MARK:Float = 0.04;
	static inline var AIM_TURN:Float = 3.5;
	static inline var COIL_PACE:Float = 0.55;
	static inline var CHARGE_RAMP:Float = 0.28;
	static inline var MIN_LENGTH:Int = 2;
	static inline var MOUND_HOLD:Float = 3.0;
	static inline var MARK_STEP:Float = 48;
	static inline var MARK_FLASH:Float = 1.0;
	static inline var MOUND_SCALE:Float = 6;
	static inline var ARC_SHAPE:Float = 2;
	static inline var SHOT_ART:String = "bullets/round_bullet_enemy";
	static inline var SHOT_SFX:String = "enemies/shoot";
	static inline var FLASH_REACH:Float = 140;

	public var done(default, null):Bool = false;
	public var lastX(default, null):Float = 0;
	public var lastY(default, null):Float = 0;

	public var floorAt:(Float, Float) -> Int;

	public function moundCount():Int
	{
		var count = 0;
		for (p in puffs)
			if (p.sprite.visible)
				count++;
		return count;
	}

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
			headUp: false,
			chargeCd: chargeCooldown() * 0.5,
			winding: 0,
			charge: 0,
			liftFrom: 0,
			face: 0,
			faceSet: false,
			markX: 0,
			markY: 0,
			marked: false,
			flank: 0
		});
	}

	inline function chargeCooldown():Float
		return cfg.chargeCooldown == null ? 6.0 : cfg.chargeCooldown;

	inline function chargeWindup():Float
		return cfg.chargeWindup == null ? 0.45 : cfg.chargeWindup;

	inline function chargeTime():Float
		return cfg.chargeTime == null ? 1.15 : cfg.chargeTime;

	inline function chargeSpeed():Float
		return cfg.chargeSpeed == null ? 1250 : cfg.chargeSpeed;

	inline function chargeRange():Float
		return cfg.chargeRange == null ? 1000 : cfg.chargeRange;

	inline function chargeTurn():Float
		return cfg.chargeTurn == null ? 0.7 : cfg.chargeTurn;

	function dropPart(s:Enemies):Void
		glow.remove(s);

	function retireAfterDeath(s:Enemies):Void
	{
		s.animation.onFinish.add(function(name:String)
		{
			if (name == "death" && s.exists)
				s.kill();
		});
		if (s.animation.name != "death")
			s.animation.play("death", true);
		if (s.animation.finished)
			s.kill();
	}

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

		var j = chains.length;
		while (j-- > 0)
			if (chains[j].segs.length < MIN_LENGTH)
			{
				collapse(chains[j]);
				chains.splice(j, 1);
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
			digLoop = FlxG.sound.create(Paths.sound("wyrm_dig")).setup(DIG_VOL, true);
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
		return cfg.underTime + (1 - Math.asin(Math.pow(r, 1 / ARC_SHAPE)) / Math.PI) * cfg.overTime;
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
				retireAfterDeath(s);

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
					headUp: !right[0].buried,
					chargeCd: chargeCooldown() * 0.4,
					winding: 0,
					charge: 0,
					liftFrom: 0,
					face: 0,
					faceSet: false,
			markX: 0,
			markY: 0,
			marked: false,
			flank: 0
				});
			}
			return;
		}
	}

	function collapse(c:WormChain):Void
	{
		for (s in c.segs)
		{
			lastX = s.x + s.width * 0.5;
			lastY = s.y + s.height * 0.5;
			fx.sparksAt(lastX, lastY);
			breach(lastX, s.feetY);
			util.Sfx.at("wyrm_surface", lastX, lastY, 0.8);
			dropPart(s);
			if (s.exists)
			{
				s.hp = 0;
				s.isDead = true;
				s.buried = false;
				s.velocity.set(0, 0);
				s.drag.set(0, 0);
				s.flashTimer = 0;
				s.color = 0xFFFFFF;
				s.alpha = 1;
				s.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
				s.animation.play("death", true);
				retireAfterDeath(s);
			}
		}
		c.segs.resize(0);
	}

	function headLift(clock:Float):Float
	{
		var cycle = cfg.underTime + cfg.overTime;
		var t = clock % cycle;
		if (t < cfg.underTime)
			return 0;
		var u = (t - cfg.underTime) / cfg.overTime;
		return Math.pow(Math.sin(u * Math.PI), ARC_SHAPE) * cfg.lift;
	}

	function advance(c:WormChain, elapsed:Float):Void
	{
		var head = c.segs[0];
		var hx = head.x + head.width * 0.5;
		var hy = head.y + head.height * 0.5;

		var rushing = c.winding > 0 || c.charge > 0;
		if (!rushing)
			c.clock += elapsed;
		c.shot -= elapsed;
		c.flank -= elapsed;
		if (c.chargeCd > 0)
			c.chargeCd -= elapsed;

		var tx = hx + 1;
		var ty = hy;
		if (head.target != null)
		{
			tx = head.target.x + head.target.width * 0.5;
			ty = head.target.y + head.target.height * 0.5;
		}

		var reach = Math.sqrt((tx - hx) * (tx - hx) + (ty - hy) * (ty - hy));
		if (!rushing && c.chargeCd <= 0 && head.target != null && reach < chargeRange())
		{
			c.winding = chargeWindup();
			c.liftFrom = headLift(c.clock);
			rushing = true;
		}

		if (c.winding > 0)
		{
			c.winding -= elapsed;
			if (c.winding <= 0)
			{
				c.winding = 0;
				c.charge = chargeTime();
				util.Sfx.at("wyrm_surface", hx, hy, 0.9);
			}
		}
		else if (c.charge > 0)
		{
			c.charge -= elapsed;
			if (c.charge <= 0)
				endCharge(c);
		}

		var sx = tx;
		var sy = ty;
		if (chains.length > 1 && !rushing)
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

		if (!rushing)
		{
			if (hx < edgeTurn)
				wx += (edgeTurn - hx) / edgeTurn * 3;
			else if (hx > roomW - edgeTurn)
				wx -= (hx - (roomW - edgeTurn)) / edgeTurn * 3;
			if (hy < edgeTurn)
				wy += (edgeTurn - hy) / edgeTurn * 3;
			else if (hy > roomH - edgeTurn)
				wy -= (hy - (roomH - edgeTurn)) / edgeTurn * 3;
		}
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
		if (rushing)
		{
			if (!c.faceSet)
			{
				c.face = heading;
				c.faceSet = true;
			}
			heading = c.face;
		}
		var turn = Math.atan2(wy, wx) - heading;
		while (turn > Math.PI)
			turn -= Math.PI * 2;
		while (turn < -Math.PI)
			turn += Math.PI * 2;
		var cap = (c.charge > 0 ? chargeTurn() : (c.winding > 0 ? cfg.turn * AIM_TURN : cfg.turn)) * elapsed;
		if (turn > cap)
			turn = cap;
		else if (turn < -cap)
			turn = -cap;
		heading += turn;
		if (rushing)
			c.face = heading;
		var dx = Math.cos(heading);
		var dy = Math.sin(heading);

		var pace = head.speed;
		if (c.winding > 0)
			pace = head.speed * COIL_PACE;
		else if (c.charge > 0)
		{
			var into = 1 - c.charge / chargeTime();
			var ramp = into < CHARGE_RAMP ? into / CHARGE_RAMP : 1;
			var from = head.speed * COIL_PACE;
			pace = from + (chargeSpeed() - from) * ramp;
		}
		hx += dx * pace * elapsed;
		hy += dy * pace * elapsed;
		var freeX = hx;
		var freeY = hy;
		hx = hx < EDGE_PAD ? EDGE_PAD : (hx > roomW - EDGE_PAD ? roomW - EDGE_PAD : hx);
		hy = hy < EDGE_PAD ? EDGE_PAD : (hy > roomH - EDGE_PAD ? roomH - EDGE_PAD : hy);
		if (c.charge > 0 && (hx != freeX || hy != freeY))
			endCharge(c);

		var lift = headLift(c.clock);
		if (c.winding > 0)
		{
			var rise = 1 - c.winding / chargeWindup();
			lift = c.liftFrom + (cfg.lift - c.liftFrom) * rise;
		}
		else if (c.charge > 0)
			lift = cfg.lift;
		var up = lift > SURFACE_MARK;
		if (up != c.headUp)
		{
			c.headUp = up;
			if (up)
			{
				util.Sfx.at("wyrm_surface", hx, hy, 0.85);
				flashMark(hx, hy + head.shadowOffY - head.height * 0.5);
				burstOut(head);
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

		if (c.flank <= 0)
		{
			c.flank = flankGap();
			flankOut(c);
		}
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
				lit = GLOW_TIME;
		}
		if (lit > 0)
			lit = lit > elapsed ? lit - elapsed : 0;
		glow.set(s, lit);

		var baseOff = s.kind == "worm" ? headOffY : bodyOffY;
		s.offset.y = baseOff + lift;
		s.lift = up ? lift : 0;
		s.shadowScaleX = up ? 8 : 0;

		s.visible = up;
		if (up)
		{
			var want = idx == 0 ? "head" : "body";
			if (s.animation.name != want)
				s.animation.play(want);
		}
		else if (idx == 0)
			layMark(c, px, s.feetY);

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
				s.setColorTransform(1, 1, 1, s.alpha, 0, 0, 0, 0);
		}

	}

	inline function flankGap():Float
		return cfg.flankGap == null ? 0 : cfg.flankGap;

	inline function flankStride():Int
		return cfg.flankStride == null || cfg.flankStride < 1 ? 1 : cfg.flankStride;

	function burstOut(from:Enemies):Void
	{
		var n = cfg.burstCount == null ? 0 : cfg.burstCount;
		for (i in 0...n)
		{
			var rad = i / n * Math.PI * 2;
			from.requestShot(Math.cos(rad), Math.sin(rad), cfg.shotDamage, cfg.shotSpeed, cfg.shotRange,
				SHOT_ART, SHOT_SFX);
		}
	}

	function flankOut(c:WormChain):Void
	{
		if (flankGap() <= 0)
			return;
		var stride = flankStride();
		var idx = stride;
		while (idx < c.segs.length)
		{
			var s = c.segs[idx];
			if (!s.buried && s.exists && !s.isDead)
			{
				var ahead = c.segs[idx - 1];
				var dx = ahead.x - s.x;
				var dy = ahead.y - s.y;
				var len = Math.sqrt(dx * dx + dy * dy);
				if (len > 0.001)
				{
					dx /= len;
					dy /= len;
					s.requestShot(-dy, dx, cfg.shotDamage, cfg.shotSpeed, cfg.shotRange, SHOT_ART, null);
					s.requestShot(dy, -dx, cfg.shotDamage, cfg.shotSpeed, cfg.shotRange, SHOT_ART, null);
				}
			}
			idx += stride;
		}
	}

	function flashMark(px:Float, py:Float):Void
	{
		var near:WormPuff = null;
		var best = FLASH_REACH * FLASH_REACH;
		for (p in puffs)
		{
			if (!p.sprite.visible)
				continue;
			var dx = p.sprite.x + p.sprite.width * 0.5 - px;
			var dy = p.sprite.y + p.sprite.height * 0.5 - py;
			var d = dx * dx + dy * dy;
			if (d < best)
			{
				best = d;
				near = p;
			}
		}
		if (near == null)
			near = moundAt(px, py);
		near.flash = MARK_FLASH;
	}

	function layMark(c:WormChain, px:Float, py:Float):Void
	{
		if (c.marked)
		{
			var dx = px - c.markX;
			var dy = py - c.markY;
			if (dx * dx + dy * dy < MARK_STEP * MARK_STEP)
				return;
		}
		for (p in puffs)
		{
			if (!p.sprite.visible || p.closing)
				continue;
			var dx = p.sprite.x + p.sprite.width * 0.5 - px;
			var dy = p.sprite.y + p.sprite.height * 0.5 - py;
			if (dx * dx + dy * dy < MARK_STEP * MARK_STEP)
			{
				c.markX = px;
				c.markY = py;
				c.marked = true;
				return;
			}
		}
		c.markX = px;
		c.markY = py;
		c.marked = true;
		moundAt(px, py);
	}

	function breach(px:Float, py:Float):Void
		moundAt(px, py);

	function closeMound(p:WormPuff):Void
	{
		p.hold = 0;
		p.closing = true;
		p.sprite.animation.play("burrow", true, true);
	}

	function moundAt(px:Float, py:Float):WormPuff
	{
		var slot:WormPuff = null;
		for (p in puffs)
			if (!p.sprite.visible)
			{
				slot = p;
				break;
			}
		if (slot == null)
		{
			var s = new FlxSprite();
			s.frames = Paths.sparrow("enemies/worm");
			s.animation.addByIndices("surface", "Mound", [0, 2, 4], "", 8, false);
			s.animation.addByPrefix("burrow", "Mound", 8, false);
			s.antialiasing = false;
			layers.shadowLayer.add(s);
			slot = {sprite: s, hold: 0, closing: false, flash: 0, color: 0xFFFFFF};
			puffs.push(slot);
		}
		slot.hold = MOUND_HOLD;
		slot.closing = false;
		slot.flash = 0;
		var s = slot.sprite;
		s.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		s.animation.play("surface", true);
		slot.color = floorAt != null ? floorAt(px, py) : 0xFFFFFF;
		s.color = slot.color;
		s.alpha = 1;
		s.scale.set(MOUND_SCALE, MOUND_SCALE);
		s.updateHitbox();
		s.setPosition(px - s.width * 0.5, py - s.height * 0.5);
		s.visible = true;
		return slot;
	}

	function updatePuffs(elapsed:Float):Void
	{
		for (p in puffs)
		{
			if (!p.sprite.visible)
				continue;
			if (p.flash > 0)
			{
				p.flash -= elapsed;
				if (p.flash <= 0)
				{
					p.flash = 0;
					p.sprite.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
					p.sprite.color = p.color;
				}
				else
				{
					var add = Std.int(255 * p.flash / MARK_FLASH);
					p.sprite.setColorTransform(1, 1, 1, 1, add, add, add, 0);
				}
			}
			if (!p.sprite.animation.finished)
				continue;
			if (p.closing)
			{
				p.sprite.visible = false;
				continue;
			}
			p.hold -= elapsed;
			if (p.hold <= 0)
				closeMound(p);
		}
	}

	function endCharge(c:WormChain):Void
	{
		c.charge = 0;
		c.winding = 0;
		c.faceSet = false;
		c.chargeCd = chargeCooldown();
		c.clock = cfg.underTime + cfg.overTime * 0.5;
	}

	function volleySize(c:WormChain):Int
	{
		var body = c.segs.length - 1;
		if (cfg.shotMinParts <= 0 || body >= cfg.shotMinParts)
			return cfg.shotCount;
		var n = Math.round(cfg.shotCount * body / cfg.shotMinParts);
		return n < 1 ? 1 : Std.int(n);
	}

	function shoot(c:WormChain, elapsed:Float, tx:Float, ty:Float):Void
	{
		var head = c.segs[0];
		var hx = head.x + head.width * 0.5;
		var hy = head.y + head.height * 0.5;

		if (c.aimHold > 0)
			c.aimHold -= elapsed;

		if (head.buried)
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
			var count = volleySize(c);
			for (i in 0...count)
			{
				var off = (i - (count - 1) * 0.5) * cfg.shotSpread;
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
