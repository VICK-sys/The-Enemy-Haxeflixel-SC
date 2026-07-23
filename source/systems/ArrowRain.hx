package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.enemy.Enemies;
import entities.RainArrow;
import util.Paths;

class ArrowRain
{
	static inline var VOLLEY:Int = 8;
	static inline var DELAY:Float = 0.55;
	static inline var STAGGER:Float = 0.35;
	static inline var SPREAD:Float = 130;
	static inline var DROP_HEIGHT:Float = 450;
	static inline var FALL_SPEED:Float = 1600;
	static inline var HIT_RADIUS:Float = 80;
	static inline var LAUNCH_COUNT:Int = 3;
	static inline var LAUNCH_SPEED:Float = 1000;

	public var arrows:FlxTypedGroup<RainArrow>;
	public var markers:FlxTypedGroup<FlxSprite>;

	private var director:EnemyDirector;
	private var fx:Fx;
	private var damageEnemy:(Enemies, Float, Float) -> Void;
	private var pending:Array<PendingDrop> = [];

	public function new(director:EnemyDirector, fx:Fx, damageEnemy:(Enemies, Float, Float) -> Void)
	{
		this.director = director;
		this.fx = fx;
		this.damageEnemy = damageEnemy;
		arrows = new FlxTypedGroup<RainArrow>();
		markers = new FlxTypedGroup<FlxSprite>();
	}

	public function fire(tx:Float, ty:Float, bx:Float, by:Float):Void
	{
		for (i in 0...LAUNCH_COUNT)
			arrows.recycle(RainArrow).launchUp(bx, by, -90 + (i - 1) * 14, LAUNCH_SPEED);

		for (i in 0...VOLLEY)
		{
			var r = SPREAD * Math.sqrt(FlxG.random.float());
			var a = FlxG.random.float() * Math.PI * 2;
			var ix = tx + Math.cos(a) * r;
			var iy = ty + Math.sin(a) * r * 0.6;
			var m = markers.recycle(FlxSprite);
			if (m.width != 28)
			{
				m.makeGraphic(28, 10, 0xFF221A12);
				m.antialiasing = false;
			}
			m.alpha = 0.3;
			m.setPosition(ix - 14, iy - 5);
			pending.push(new PendingDrop(DELAY + FlxG.random.float() * STAGGER, ix, iy, m));
		}
	}

	public function update(elapsed:Float):Void
	{
		var i = pending.length;
		while (i-- > 0)
		{
			var d = pending[i];
			d.time -= elapsed;
			if (d.time <= 0)
			{
				var arrow = arrows.recycle(RainArrow);
				arrow.drop(d.x, d.y, DROP_HEIGHT, FALL_SPEED);
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
		FlxG.sound.play(Paths.sound("scythe/slice"), 0.25);
		director.eachInCircle(ix, iy, HIT_RADIUS, function(e)
		{
			var ex = e.x + e.width / 2 - ix;
			var ey = e.y + e.height / 2 - iy;
			var elen = Math.sqrt(ex * ex + ey * ey);
			if (elen <= 0)
				elen = 1;
			damageEnemy(e, ex / elen, ey / elen);
		});
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
