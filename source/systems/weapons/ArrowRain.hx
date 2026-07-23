package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.RainArrow;
import systems.Fx;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class ArrowRain
{
	static inline var DROP_HEIGHT:Float = 450;
	static inline var LAUNCH_COUNT:Int = 3;
	static inline var LAUNCH_SPEED:Float = 1000;

	public var arrows:FlxTypedGroup<RainArrow>;
	public var markers:FlxTypedGroup<FlxSprite>;

	private var cfg = WeaponDataRegistry.get().arrowRain;
	private var fx:Fx;
	private var hits:HitPipeline;
	private var pending:Array<PendingDrop> = [];
	private var soundTimer:Float = 0;

	public function new(fx:Fx, hits:HitPipeline)
	{
		this.fx = fx;
		this.hits = hits;
		arrows = new FlxTypedGroup<RainArrow>();
		markers = new FlxTypedGroup<FlxSprite>();
	}

	public function fire(tx:Float, ty:Float, bx:Float, by:Float):Void
	{
		for (i in 0...LAUNCH_COUNT)
			arrows.recycle(RainArrow).launchUp(bx, by, -90 + (i - 1) * 14, LAUNCH_SPEED);

		for (i in 0...cfg.volley)
		{
			var r = cfg.spread * Math.sqrt(FlxG.random.float());
			var a = FlxG.random.float() * Math.PI * 2;
			rainAt(tx + Math.cos(a) * r, ty + Math.sin(a) * r * 0.6);
		}
	}

	public function rainAt(ix:Float, iy:Float):Void
	{
		var m = markers.recycle(FlxSprite);
		if (m.width != 28)
		{
			m.makeGraphic(28, 10, 0xFF221A12);
			m.antialiasing = false;
		}
		m.alpha = 0.3;
		m.setPosition(ix - 14, iy - 5);
		pending.push(new PendingDrop(cfg.delay + FlxG.random.float() * cfg.stagger, ix, iy, m));
	}

	public function update(elapsed:Float):Void
	{
		if (soundTimer > 0)
			soundTimer -= elapsed;

		var i = pending.length;
		while (i-- > 0)
		{
			var d = pending[i];
			d.time -= elapsed;
			if (d.time <= 0)
			{
				var arrow = arrows.recycle(RainArrow);
				arrow.drop(d.x, d.y, DROP_HEIGHT, cfg.fallSpeed);
				arrow.marker = d.marker;
				pending.splice(i, 1);
			}
		}

		for (a in arrows.members)
		{
			if (a == null || !a.exists || a.ascending)
				continue;
			if (a.y + a.height / 2 >= a.impactY)
				land(a);
		}
	}

	function land(a:RainArrow):Void
	{
		var ix = a.x + a.width / 2;
		var iy = a.impactY;
		if (a.marker != null)
		{
			a.marker.kill();
			a.marker = null;
		}
		a.kill();
		fx.sparksAt(ix, iy);
		if (soundTimer <= 0)
		{
			FlxG.sound.play(Paths.sound("scythe/slice"), 0.25);
			soundTimer = 0.05;
		}
		hits.blastRadial(ix, iy, cfg.hitRadius, 1, 1);
	}
}

class PendingDrop
{
	public var time:Float;
	public var x:Float;
	public var y:Float;
	public var marker:FlxSprite;

	public function new(time:Float, x:Float, y:Float, marker:FlxSprite)
	{
		this.time = time;
		this.x = x;
		this.y = y;
		this.marker = marker;
	}
}
