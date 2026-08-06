package systems.enemy;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import entities.enemy.Enemies;
import systems.Fx;
import systems.RenderLayers;

class DomoDeathFx
{
	static inline var SHAKE_TIME:Float = 1.0;
	static inline var SHAKE_AMPLITUDE:Float = 12;
	static inline var SHARD_COLUMNS:Int = 6;
	static inline var SHARD_ROWS:Int = 6;
	static inline var BREAK_TIME:Float = 0.9;
	static inline var FADE_TIME:Float = 0.3;
	static inline var HORIZONTAL_SPEED:Float = 180;
	static inline var HORIZONTAL_VARIANCE:Float = 55;
	static inline var UPWARD_SPEED:Float = 170;
	static inline var UPWARD_VARIANCE:Float = 65;
	static inline var GRAVITY:Float = 420;

	public var done(default, null):Bool = false;

	private var layers:RenderLayers;
	private var visual:FlxSprite;
	private var shards:Array<FlxSprite> = [];
	private var baseX:Float;
	private var baseY:Float;
	private var centerX:Float;
	private var centerY:Float;
	private var timer:Float = SHAKE_TIME;
	private var breaking:Bool = false;

	public function new(layers:RenderLayers, boss:Enemies)
	{
		this.layers = layers;
		centerX = boss.x + boss.width * 0.5;
		centerY = boss.y + boss.height * 0.5;
		visual = copyVisual(boss);
		baseX = visual.x;
		baseY = visual.y;
		makeRed(visual);
		layers.entityLayer.add(visual);
		boss.visible = false;
	}

	public function update(elapsed:Float):Bool
	{
		if (done)
			return true;

		if (!breaking)
		{
			updateShake(elapsed);
			return done;
		}

		timer -= elapsed;
		var alpha = timer < FADE_TIME ? timer / FADE_TIME : 1;
		if (alpha < 0)
			alpha = 0;
		for (shard in shards)
			shard.alpha = alpha;

		if (timer <= 0)
			finish();
		return done;
	}

	function updateShake(elapsed:Float):Void
	{
		timer -= elapsed;
		var progress = 1 - timer / SHAKE_TIME;
		var amplitude = SHAKE_AMPLITUDE * progress;
		visual.x = baseX + FlxG.random.float(-amplitude, amplitude);
		visual.y = baseY + FlxG.random.float(-amplitude, amplitude);
		if (timer <= 0)
			breakApart();
	}

	function breakApart():Void
	{
		visual.setPosition(baseX, baseY);
		var shardWidth = visual.frameWidth / SHARD_COLUMNS;
		var shardHeight = visual.frameHeight / SHARD_ROWS;

		for (row in 0...SHARD_ROWS)
			for (column in 0...SHARD_COLUMNS)
			{
				var shard = copyVisual(visual);
				shard.clipRect = new FlxRect(column * shardWidth, row * shardHeight, shardWidth, shardHeight);
				makeRed(shard);
				var displayColumn = visual.flipX ? SHARD_COLUMNS - column - 1 : column;
				var displayRow = visual.flipY ? SHARD_ROWS - row - 1 : row;
				var xDir = (displayColumn + 0.5) / SHARD_COLUMNS * 2 - 1;
				var yDir = (displayRow + 0.5) / SHARD_ROWS;
				shard.velocity.x = xDir * HORIZONTAL_SPEED + FlxG.random.float(-HORIZONTAL_VARIANCE, HORIZONTAL_VARIANCE);
				shard.velocity.y = -UPWARD_SPEED + yDir * UPWARD_SPEED * 0.5
					+ FlxG.random.float(-UPWARD_VARIANCE, UPWARD_VARIANCE);
				shard.acceleration.y = GRAVITY;
				layers.entityLayer.add(shard);
				shards.push(shard);
			}

		layers.entityLayer.remove(visual, true);
		visual.destroy();
		visual = null;
		util.Sfx.at("enemies/hit", centerX, centerY, 0.9);
		Fx.shake(0.018, 0.35);
		breaking = true;
		timer = BREAK_TIME;
	}

	function finish():Void
	{
		for (shard in shards)
		{
			layers.entityLayer.remove(shard, true);
			shard.clipRect = null;
			shard.destroy();
		}
		shards.resize(0);
		done = true;
	}

	function copyVisual(source:FlxSprite):FlxSprite
	{
		var copy = source.clone();
		copy.animation.pause();
		copy.setPosition(source.x, source.y);
		copy.scale.set(source.scale.x, source.scale.y);
		copy.width = source.width;
		copy.height = source.height;
		copy.offset.set(source.offset.x, source.offset.y);
		copy.origin.set(source.origin.x, source.origin.y);
		copy.scrollFactor.set(source.scrollFactor.x, source.scrollFactor.y);
		copy.flipX = source.flipX;
		copy.flipY = source.flipY;
		copy.angle = source.angle;
		copy.antialiasing = source.antialiasing;
		copy.solid = false;
		return copy;
	}

	inline function makeRed(sprite:FlxSprite):Void
		sprite.setColorTransform(0, 0, 0, 1, 255, 0, 0, 0);
}
