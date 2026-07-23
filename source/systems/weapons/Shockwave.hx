package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.enemy.Enemies;
import systems.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;

class Shockwave
{
	static inline var RING_BASE:Float = 30;

	public static inline var CRACK_TIME:Float = 2.5;

	public var rings:FlxTypedGroup<FlxSprite>;
	public var cracks:FlxTypedGroup<CrackSprite>;

	private var cfg = WeaponDataRegistry.get().shockwave;
	private var director:EnemyDirector;
	private var stunEnemy:(Enemies, Float, Float) -> Void;
	private var waves:Array<Wave> = [];

	public function new(director:EnemyDirector, stunEnemy:(Enemies, Float, Float) -> Void)
	{
		this.director = director;
		this.stunEnemy = stunEnemy;
		rings = new FlxTypedGroup<FlxSprite>();
		cracks = new FlxTypedGroup<CrackSprite>();
	}

	public function blast(cx:Float, cy:Float, stun:Bool = true):Void
	{
		cracks.recycle(CrackSprite).show(cx, cy);
		var ring = rings.recycle(FlxSprite);
		if (ring.graphic == null)
			paintRing(ring);
		ring.setPosition(cx - ring.width / 2, cy - ring.height / 2);
		ring.scale.set(0.2, 0.14);
		ring.alpha = 0.8;
		var wave = new Wave(cx, cy, ring);
		wave.stun = stun;
		waves.push(wave);
	}

	public function update(elapsed:Float):Void
	{
		var i = waves.length;
		while (i-- > 0)
		{
			var w = waves[i];
			w.t += elapsed;
			var p = w.t / cfg.waveTime;
			if (p > 1)
				p = 1;
			var ease = 1 - (1 - p) * (1 - p);
			var r = cfg.waveRadius * ease;
			var s = r / RING_BASE;
			w.ring.scale.set(s, s * 0.7);
			w.ring.alpha = 0.8 * (1 - p);

			if (w.stun)
				director.eachInCircle(w.cx, w.cy, r, function(e)
				{
					if (w.hit.contains(e))
						return;
					w.hit.push(e);
					var ex = e.x + e.width / 2 - w.cx;
					var ey = e.y + e.height / 2 - w.cy;
					var elen = Math.sqrt(ex * ex + ey * ey);
					if (elen <= 0)
						elen = 1;
					stunEnemy(e, ex / elen, ey / elen);
				});

			if (p >= 1)
			{
				w.ring.kill();
				waves.splice(i, 1);
			}
		}
	}

	function paintRing(s:FlxSprite):Void
	{
		s.makeGraphic(64, 64, 0x00000000, true);
		var bmp = s.pixels;
		for (py in 0...64)
			for (px in 0...64)
			{
				var dx = px - 31.5;
				var dy = py - 31.5;
				var d = Math.sqrt(dx * dx + dy * dy);
				if (d <= 30 && d >= 26)
					bmp.setPixel32(px, py, d >= 28 ? 0xFFEFE6D0 : 0x88EFE6D0);
			}
		s.dirty = true;
		s.antialiasing = false;
	}
}

class Wave
{
	public var cx:Float;
	public var cy:Float;
	public var t:Float = 0;
	public var stun:Bool = true;
	public var ring:FlxSprite;
	public var hit:Array<Enemies> = [];

	public function new(cx:Float, cy:Float, ring:FlxSprite)
	{
		this.cx = cx;
		this.cy = cy;
		this.ring = ring;
	}
}

class CrackSprite extends FlxSprite
{
	private var life:Float = 0;

	public function new()
	{
		super();
		paintCracks();
		antialiasing = false;
		scale.set(4, 4);
	}

	public function show(cx:Float, cy:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		angle = FlxG.random.float() * 360;
		alpha = 0.85;
		life = Shockwave.CRACK_TIME;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
		{
			kill();
			return;
		}
		if (life < 1)
			alpha = 0.85 * life;
	}

	function paintCracks():Void
	{
		makeGraphic(48, 48, 0x00000000, true);
		var bmp = pixels;
		for (i in 0...7)
		{
			var ang = i * Math.PI * 2 / 7 + FlxG.random.float() * 0.5;
			var x:Float = 23.5;
			var y:Float = 23.5;
			for (seg in 0...4)
			{
				ang += (FlxG.random.float() - 0.5) * 0.9;
				var steps = 3 + Std.random(4);
				for (st in 0...steps)
				{
					x += Math.cos(ang);
					y += Math.sin(ang);
					var xi = Std.int(x);
					var yi = Std.int(y);
					if (xi >= 0 && xi < 48 && yi >= 0 && yi < 48)
						bmp.setPixel32(xi, yi, seg < 2 ? 0xFF221C16 : 0xFF3A3028);
				}
			}
		}
		dirty = true;
	}
}
