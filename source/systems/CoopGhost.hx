package systems;

import flixel.FlxSprite;

class CoopGhost
{
	static inline var FRAME:Int = 32;
	static inline var FPS:Int = 8;
	static inline var SCALE:Float = 4;
	static inline var BOB_AMP:Float = 10;
	static inline var BOB_SPEED:Float = 2.2;

	public var sprite:FlxSprite;

	private var hue:Float = -1;
	private var baseY:Float = 0;
	private var clock:Float = 0;

	public function new()
	{
		sprite = new FlxSprite();
		load(0);
		util.PixelPerfectShader.on(sprite);
		sprite.scale.set(SCALE, SCALE);
		sprite.updateHitbox();
		sprite.kill();
	}

	function load(h:Float):Void
	{
		if (h == hue)
			return;
		hue = h;
		sprite.loadGraphic(util.HuePalette.graphic("characters/coop_ghost", h), true, FRAME, FRAME);
		sprite.animation.add("float", [0, 1, 2, 3], FPS, true);
	}

	public function show(cx:Float, cy:Float, h:Float):Void
	{
		load(h);
		sprite.revive();
		sprite.setPosition(cx - sprite.width * 0.5, cy - sprite.height * 0.5);
		baseY = sprite.y;
		clock = 0;
		sprite.animation.play("float", true);
	}

	public function track(cx:Float, cy:Float, flip:Bool):Void
	{
		sprite.x = cx - sprite.width * 0.5;
		baseY = cy - sprite.height * 0.5;
		sprite.flipX = flip;
	}

	public function hide():Void
		sprite.kill();

	public function update(elapsed:Float):Void
	{
		if (!sprite.exists)
			return;
		clock += elapsed;
		sprite.y = baseY + Math.sin(clock * BOB_SPEED) * BOB_AMP;
	}
}
