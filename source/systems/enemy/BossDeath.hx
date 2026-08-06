package systems.enemy;

import flixel.FlxSprite;
import entities.enemy.Enemies;

class BossFall
{
	public var boss:Enemies;
	public var dying:Bool = false;
	public var phase:Int = 0;
	public var timer:Float = 0;
	public var baseX:Float = 0;
	public var baseY:Float = 0;
	public var explosion:FlxSprite;
	public var domo:DomoDeathFx;

	public function new(boss:Enemies)
		this.boss = boss;
}

class BossDeath
{
	static inline var SHAKE_DUR:Float = 1.0;
	static inline var SHAKE_AMP:Float = 12;

	public var onDrops:(Float, Float) -> Void;
	public var onFall:(Float, Float, Bool) -> Void;
	public var onKill:(Float, Float) -> Void;

	private var layers:RenderLayers;
	private var watched:Array<BossFall> = [];

	public function new(layers:RenderLayers)
	{
		this.layers = layers;
	}

	public function watch(e:Enemies):Void
		watched.push(new BossFall(e));

	public function update(elapsed:Float):Void
	{
		var i = watched.length;
		while (i-- > 0)
		{
			var w = watched[i];
			if (!w.dying)
			{
				if (w.boss.isDead)
					begin(w);
				continue;
			}

			if (w.domo != null)
			{
				if (w.domo.update(elapsed))
					finish(w);
			}
			else if (w.phase == 0)
				updateShake(w, elapsed);
			else if (w.explosion != null && w.explosion.animation.finished)
				finish(w);
		}
	}

	function begin(w:BossFall):Void
	{
		w.dying = true;
		w.phase = 0;
		w.timer = SHAKE_DUR;
		w.baseX = w.boss.x;
		w.baseY = w.boss.y;
		w.boss.velocity.set(0, 0);
		w.boss.allowCollisions = NONE;
		if (w.boss.kind == "domo")
			w.domo = new DomoDeathFx(layers, w.boss);
		if (onKill != null)
			onKill(w.baseX + w.boss.width * 0.5, w.baseY + w.boss.height * 0.5);
	}

	function updateShake(w:BossFall, elapsed:Float):Void
	{
		w.timer -= elapsed;
		var amp = SHAKE_AMP * (1 - w.timer / SHAKE_DUR);
		w.boss.x = w.baseX + (Math.random() * 2 - 1) * amp;
		w.boss.y = w.baseY + (Math.random() * 2 - 1) * amp;
		w.boss.velocity.set(0, 0);

		if (w.timer > 0)
			return;

		w.boss.x = w.baseX;
		w.boss.y = w.baseY;
		w.boss.visible = false;
		w.explosion = Fx.bossBlast(w.boss.x + w.boss.width / 2, w.boss.y + w.boss.height / 2);
		layers.entityLayer.add(w.explosion);
		w.phase = 1;
	}

	function finish(w:BossFall):Void
	{
		if (w.explosion != null)
		{
			layers.entityLayer.remove(w.explosion, true);
			w.explosion.destroy();
			w.explosion = null;
		}
		var cx = w.boss.x + w.boss.width / 2;
		var cy = w.boss.y + w.boss.height / 2;
		if (onDrops != null)
			onDrops(cx, cy);
		w.boss.kill();
		watched.remove(w);
		if (onFall != null)
			onFall(cx, cy, w.boss.kind == "domo");
	}
}
