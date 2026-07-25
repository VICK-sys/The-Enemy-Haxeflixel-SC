package systems.perspective;

import flixel.FlxSprite;
import systems.RenderLayers;
import util.Paths;

class Totem
{
	public static inline var W:Int = 128;
	public static inline var H:Int = 128;

	static inline var GLOW_PAD:Int = 26;
	static inline var FLASH_TIME:Float = 0.12;

	public var sprite:FlxSprite;
	public var glow:FlxSprite;
	public var shadow:FlxSprite;
	public var homeX:Float = 0;
	public var homeY:Float = 0;

	private var pulse:Float = 0;
	private var flashTimer:Float = 0;

	public function new(layers:RenderLayers)
	{
		glow = new FlxSprite(0, 0);
		glow.blend = ADD;
		glow.alpha = 0.14;
		glow.visible = false;
		layers.entityLayer.add(glow);

		sprite = new FlxSprite(0, 0);
		sprite.visible = false;
		layers.entityLayer.add(sprite);

		applyFace(false);

		shadow = new FlxSprite(0, 0, Paths.image("effects/shadow"));
		shadow.scale.set(7, 5);
		shadow.visible = false;
		layers.shadowLayer.add(shadow);
	}

	public function applyFace(side:Bool):Void
	{
		var img = Paths.image(side ? "stage/totem_side" : "stage/totem_top");
		var keepX = sprite.x;
		var keepY = sprite.y;

		sprite.loadGraphic(img);
		sprite.antialiasing = false;
		sprite.setGraphicSize(W, H);
		sprite.updateHitbox();
		sprite.setPosition(keepX, keepY);

		glow.loadGraphic(img);
		glow.antialiasing = false;
		glow.setGraphicSize(W + GLOW_PAD, H + GLOW_PAD);
		glow.updateHitbox();
	}

	public function flash(mult:Float = 1):Void
	{
		flashTimer = FLASH_TIME * mult;
		sprite.setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);
	}

	public function show():Void
	{
		sprite.visible = true;
		glow.visible = true;
		shadow.visible = true;
	}

	public function hide():Void
	{
		sprite.visible = false;
		glow.visible = false;
		shadow.visible = false;
	}

	public function hitTest(cx:Float, cy:Float, radius:Float):Bool
	{
		var nx = Math.max(sprite.x, Math.min(cx, sprite.x + sprite.width));
		var ny = Math.max(sprite.y, Math.min(cy, sprite.y + sprite.height));
		var dx = cx - nx;
		var dy = cy - ny;
		return dx * dx + dy * dy <= radius * radius;
	}

	public function update(elapsed:Float, hot:Bool):Void
	{
		pulse += elapsed;

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
				sprite.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		}

		glow.alpha = 0.12 + 0.10 * Math.sin(pulse * 3) + (hot ? 0.18 : 0);
		glow.x = sprite.x + sprite.width / 2 - glow.width / 2;
		glow.y = sprite.y + sprite.height / 2 - glow.height / 2;
		shadow.x = sprite.x + sprite.width / 2 - shadow.width / 2;
		shadow.y = sprite.y + sprite.height - shadow.height / 2;
	}
}
