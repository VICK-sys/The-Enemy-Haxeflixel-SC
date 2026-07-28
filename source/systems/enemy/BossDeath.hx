package systems.enemy;

import flixel.FlxSprite;
import entities.enemy.Enemies;

class BossDeath
{
	static inline var SHAKE_DUR:Float = 1.0;
	static inline var SHAKE_AMP:Float = 12;

	public var onDefeated:Void->Void;
	public var onDrops:(Float, Float) -> Void;

	private var layers:RenderLayers;
	private var boss:Enemies;
	private var dying:Bool = false;
	private var phase:Int = 0;
	private var timer:Float = 0;
	private var baseX:Float = 0;
	private var baseY:Float = 0;
	private var explosion:FlxSprite;

	public function new(layers:RenderLayers)
	{
		this.layers = layers;
	}

	public function watch(e:Enemies):Void
	{
		boss = e;
		dying = false;
	}

	public function update(elapsed:Float):Void
	{
		if (boss == null)
			return;

		if (!dying)
		{
			if (boss.isDead)
				begin();
			return;
		}

		if (phase == 0)
			updateShake(elapsed);
		else if (explosion != null && explosion.animation.finished)
			finish();
	}

	function begin():Void
	{
		dying = true;
		phase = 0;
		timer = SHAKE_DUR;
		baseX = boss.x;
		baseY = boss.y;
		boss.velocity.set(0, 0);
		boss.allowCollisions = NONE;
	}

	function updateShake(elapsed:Float):Void
	{
		timer -= elapsed;
		var amp = SHAKE_AMP * (1 - timer / SHAKE_DUR);
		boss.x = baseX + (Math.random() * 2 - 1) * amp;
		boss.y = baseY + (Math.random() * 2 - 1) * amp;
		boss.velocity.set(0, 0);

		if (timer > 0)
			return;

		boss.x = baseX;
		boss.y = baseY;
		boss.visible = false;
		explosion = Fx.bossBlast(boss.x + boss.width / 2, boss.y + boss.height / 2);
		layers.entityLayer.add(explosion);
		phase = 1;
	}

	function finish():Void
	{
		layers.entityLayer.remove(explosion, true);
		explosion.destroy();
		explosion = null;
		if (onDrops != null)
			onDrops(boss.x + boss.width / 2, boss.y + boss.height / 2);
		boss.kill();
		boss = null;
		dying = false;
		if (onDefeated != null)
			onDefeated();
	}
}
