package systems.enemy;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.enemy.Enemies;
import data.EnemyData.EnemyDataRegistry;
import data.EnemyData.WormData;

typedef WormChain =
{
	segs:Array<Enemies>,
	trail:Array<Float>,
	phase:Float,
	shot:Float,
	headUp:Bool
}

class WormFlock
{
	static inline var BAR_W:Int = 46;
	static inline var BAR_H:Int = 5;
	static inline var TRAIL_STEP:Float = 6;
	static inline var EMERGE:Float = 0.25;
	static inline var EDGE_PAD:Float = 120;

	public var done(default, null):Bool = false;
	public var lastX(default, null):Float = 0;
	public var lastY(default, null):Float = 0;

	public var floorAt:(Float, Float) -> Int;

	private var cfg:WormData;
	private var chains:Array<WormChain> = [];
	private var backs:Map<Enemies, FlxSprite> = new Map();
	private var fills:Map<Enemies, FlxSprite> = new Map();
	private var hpMax:Map<Enemies, Float> = new Map();
	private var tagLayer:FlxTypedGroup<FlxSprite>;
	private var fx:Fx;
	private var headOffY:Float;
	private var bodyOffY:Float;
	private var roomW:Float;
	private var roomH:Float;

	public function new(tagLayer:FlxTypedGroup<FlxSprite>, fx:Fx, roomW:Float, roomH:Float)
	{
		this.tagLayer = tagLayer;
		this.fx = fx;
		this.roomW = roomW;
		this.roomH = roomH;
		cfg = EnemyDataRegistry.get("worm").worm;
		headOffY = EnemyDataRegistry.get("worm").offsetY;
		bodyOffY = EnemyDataRegistry.get("worm_body").offsetY;
	}

	public function adopt(segs:Array<Enemies>):Void
	{
		for (s in segs)
		{
			hpMax.set(s, s.hp);
			makeBar(s);
		}
		var trail:Array<Float> = [];
		for (s in segs)
		{
			trail.push(s.x + s.width * 0.5);
			trail.push(s.y + s.height * 0.5);
		}
		var tx = segs[segs.length - 1].x + segs[segs.length - 1].width * 0.5;
		var ty = segs[segs.length - 1].y + segs[segs.length - 1].height * 0.5;
		trail.push(tx);
		trail.push(ty + cfg.spacing * 3);
		chains.push({segs: segs, trail: trail, phase: 0.4, shot: cfg.shotCooldown, headUp: false});
	}

	function makeBar(s:Enemies):Void
	{
		var back = new FlxSprite();
		back.makeGraphic(BAR_W, BAR_H, 0xC0161616);
		back.visible = false;
		tagLayer.add(back);
		backs.set(s, back);

		var fill = new FlxSprite();
		fill.makeGraphic(BAR_W - 2, BAR_H - 2, 0xFF9BE24A);
		fill.origin.set(0, 0);
		fill.visible = false;
		tagLayer.add(fill);
		fills.set(s, fill);
	}

	function dropBar(s:Enemies):Void
	{
		var back = backs.get(s);
		if (back != null)
		{
			tagLayer.remove(back, true);
			back.destroy();
		}
		var fill = fills.get(s);
		if (fill != null)
		{
			tagLayer.remove(fill, true);
			fill.destroy();
		}
		backs.remove(s);
		fills.remove(s);
		hpMax.remove(s);
	}

	public function update(elapsed:Float):Void
	{
		if (done)
			return;

		var splits:Array<WormChain> = [];
		var i = chains.length;
		while (i-- > 0)
		{
			var c = chains[i];
			reap(c, splits);
			if (c.segs.length == 0)
			{
				chains.splice(i, 1);
				continue;
			}
			advance(c, elapsed);
		}
		for (s in splits)
			chains.push(s);

		if (chains.length == 0)
			done = true;
	}

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
			dropBar(s);
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
				}
				var last = right[right.length - 1];
				trail.push(last.x + last.width * 0.5);
				trail.push(last.y + last.height * 0.5 + cfg.spacing * 2);
				splits.push({
					segs: right,
					trail: trail,
					phase: c.phase - (k + 1) * cfg.waveStep,
					shot: cfg.shotCooldown,
					headUp: false
				});
			}
			return;
		}
	}

	function advance(c:WormChain, elapsed:Float):Void
	{
		c.phase += cfg.waveSpeed * elapsed;
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

		var wx = tx - hx;
		var wy = ty - hy;
		var wl = Math.sqrt(wx * wx + wy * wy);
		if (wl > 0)
		{
			wx /= wl;
			wy /= wl;
		}

		var ox = c.trail.length >= 4 ? hx - c.trail[2] : 1;
		var oy = c.trail.length >= 4 ? hy - c.trail[3] : 0;
		var ol = Math.sqrt(ox * ox + oy * oy);
		if (ol > 0)
		{
			ox /= ol;
			oy /= ol;
		}
		var blend = Math.min(1, cfg.turn * elapsed);
		var dx = ox + (wx - ox) * blend;
		var dy = oy + (wy - oy) * blend;
		var dl = Math.sqrt(dx * dx + dy * dy);
		if (dl < 0.001)
		{
			dx = wx;
			dy = wy;
			dl = 1;
		}
		dx /= dl;
		dy /= dl;

		hx += dx * head.speed * elapsed;
		hy += dy * head.speed * elapsed;
		hx = hx < EDGE_PAD ? EDGE_PAD : (hx > roomW - EDGE_PAD ? roomW - EDGE_PAD : hx);
		hy = hy < EDGE_PAD ? EDGE_PAD : (hy > roomH - EDGE_PAD ? roomH - EDGE_PAD : hy);

		var lx = c.trail[0];
		var ly = c.trail[1];
		var moved = Math.sqrt((hx - lx) * (hx - lx) + (hy - ly) * (hy - ly));
		if (moved >= TRAIL_STEP)
		{
			c.trail.unshift(hy);
			c.trail.unshift(hx);
			var cap = Std.int((c.segs.length + 3) * cfg.spacing / TRAIL_STEP) * 2 + 8;
			if (c.trail.length > cap)
				c.trail.resize(cap);
		}

		for (idx in 0...c.segs.length)
			place(c, idx, hx, hy);

		shoot(c, tx, ty);
	}

	function place(c:WormChain, idx:Int, hx:Float, hy:Float):Void
	{
		var s = c.segs[idx];
		var px = hx;
		var py = hy;
		if (idx > 0)
		{
			var want = idx * cfg.spacing;
			var run = Math.sqrt((hx - c.trail[0]) * (hx - c.trail[0]) + (hy - c.trail[1]) * (hy - c.trail[1]));
			var ax = hx;
			var ay = hy;
			var bx = c.trail[0];
			var by = c.trail[1];
			var j = 0;
			while (run < want && j + 3 < c.trail.length)
			{
				ax = c.trail[j];
				ay = c.trail[j + 1];
				bx = c.trail[j + 2];
				by = c.trail[j + 3];
				run += Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
				j += 2;
			}
			if (run >= want)
			{
				var back = run - want;
				var segLen = Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
				var t = segLen > 0 ? back / segLen : 0;
				px = bx + (ax - bx) * t;
				py = by + (ay - by) * t;
			}
			else
			{
				px = bx;
				py = by;
			}
		}

		s.x = px - s.width * 0.5;
		s.y = py - s.height * 0.5;
		s.velocity.set(0, 0);

		var raw = Math.sin(c.phase - idx * cfg.waveStep);
		var up = raw > EMERGE;
		var lift = up ? (raw - EMERGE) / (1 - EMERGE) * cfg.lift : 0;

		if (up != !s.buried)
		{
			s.buried = !up;
			if (idx == 0)
			{
				util.Sfx.at("digging", px, py, 0.5);
				c.headUp = up;
			}
		}

		var baseOff = s.kind == "worm" ? headOffY : bodyOffY;
		s.offset.y = baseOff + lift;
		s.shadowScaleX = up ? 8 : 0;

		var want = up ? (idx == 0 ? "head" : "body") : "mound";
		if (s.animation.name != want)
			s.animation.play(want);

		if (up)
		{
			if (s.flashTimer <= 0)
				s.color = 0xFFFFFF;
			if (idx == 0 && c.trail.length >= 4)
				s.flipX = hx - c.trail[2] < 0;
		}
		else if (floorAt != null)
			s.color = floorAt(px, s.feetY);

		var back = backs.get(s);
		var fill = fills.get(s);
		if (back != null && fill != null)
		{
			back.visible = up;
			fill.visible = up;
			back.x = px - BAR_W * 0.5;
			back.y = s.y - lift - 18;
			fill.x = back.x + 1;
			fill.y = back.y + 1;
			var max = hpMax.exists(s) ? hpMax.get(s) : s.hp;
			fill.scale.x = max > 0 ? Math.max(0, s.hp / max) : 0;
		}
	}

	function shoot(c:WormChain, tx:Float, ty:Float):Void
	{
		var head = c.segs[0];
		if (c.segs.length - 1 < cfg.shotMinParts)
			return;
		if (head.buried || !head.pathing.fireClear || c.shot > 0)
			return;

		c.shot = cfg.shotCooldown;
		var hx = head.x + head.width * 0.5;
		var hy = head.y + head.height * 0.5;
		var dx = tx - hx;
		var dy = ty - hy;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len <= 0)
			return;
		head.requestShot(dx / len, dy / len, cfg.shotDamage, cfg.shotSpeed, cfg.shotRange,
			"bullets/round_bullet_enemy", "enemies/shoot");
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
