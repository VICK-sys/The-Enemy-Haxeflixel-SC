package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import util.Paths;

class MenuList extends FlxGroup
{
	static inline var SELECTOR_GAP:Float = 26;
	static inline var EASE:Float = 16;
	static inline var BOB:Float = 4;
	static inline var BOB_SPEED:Float = 5;

	public var index(default, null):Int = 0;
	public var onChoose:Int->Void;
	public var onAdjust:(Int, Int) -> Void;
	public var enabled:Bool = true;

	private var rows:Array<FlxText> = [];
	private var selector:FlxSprite;
	private var bobTime:Float = 0;
	private var lastMouseX:Float = 0;
	private var lastMouseY:Float = 0;

	public function new(labels:Array<String>, startY:Float, spacing:Float, size:Int)
	{
		super();
		for (i in 0...labels.length)
		{
			var t = new FlxText(0, startY + i * spacing, 0, labels[i]);
			t.setFormat(null, size, FlxColor.WHITE, CENTER);
			t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			t.screenCenter(X);
			rows.push(t);
			add(t);
		}

		selector = new FlxSprite();
		selector.loadGraphic(selectorGraphic());
		selector.antialiasing = false;
		selector.scale.set(3, 3);
		selector.updateHitbox();
		selector.angle = -35;
		add(selector);

		lastMouseX = FlxG.mouse.x;
		lastMouseY = FlxG.mouse.y;
		snapSelector();
	}

	public function setLabel(i:Int, text:String):Void
	{
		rows[i].text = text;
		rows[i].screenCenter(X);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		bobTime += elapsed;

		if (!enabled)
			return;

		if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.UP)
			move(-1);
		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.DOWN)
			move(1);

		if (FlxG.mouse.x != lastMouseX || FlxG.mouse.y != lastMouseY)
		{
			lastMouseX = FlxG.mouse.x;
			lastMouseY = FlxG.mouse.y;
			for (i in 0...rows.length)
			{
				if (i != index && FlxG.mouse.overlaps(rows[i], rowCamera(i)))
				{
					index = i;
					blip();
				}
			}
		}

		if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT)
			adjust(-1);
		if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT)
			adjust(1);

		var clicked = FlxG.mouse.justPressed && FlxG.mouse.overlaps(rows[index], rowCamera(index));
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || clicked)
		{
			FlxG.sound.play(Paths.sound("scythe/catch"), 0.5);
			if (onChoose != null)
				onChoose(index);
		}

		positionSelector(elapsed);
	}

	static function selectorGraphic():FlxGraphic
	{
		var key = "menuScytheOutline";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var src = FlxG.bitmap.add(Paths.image("items/mufu_scythe")).bitmap;
		var sil = new BitmapData(src.width, src.height, true, 0);
		for (y in 0...src.height)
			for (x in 0...src.width)
				if (src.getPixel32(x, y) >>> 24 != 0)
					sil.setPixel32(x, y, 0xFFFFFFFF);

		var outlined = new BitmapData(src.width + 2, src.height + 2, true, 0);
		for (oy in 0...3)
			for (ox in 0...3)
				if (ox != 1 || oy != 1)
					outlined.copyPixels(sil, sil.rect, new Point(ox, oy), null, null, true);
		outlined.copyPixels(src, src.rect, new Point(1, 1), null, null, true);
		sil.dispose();

		return FlxG.bitmap.add(outlined, false, key);
	}

	function move(dir:Int):Void
	{
		index = (index + dir + rows.length) % rows.length;
		blip();
	}

	function adjust(dir:Int):Void
	{
		if (onAdjust == null)
			return;
		FlxG.sound.play(Paths.sound("scythe/slice"), 0.2);
		onAdjust(index, dir);
	}

	function rowCamera(i:Int):flixel.FlxCamera
	{
		var cams = rows[i].cameras;
		return cams != null && cams.length > 0 ? cams[0] : FlxG.camera;
	}

	function blip():Void
	{
		FlxG.sound.play(Paths.sound("scythe/slice"), 0.25);
	}

	function positionSelector(elapsed:Float):Void
	{
		var k = Math.min(1, EASE * elapsed);
		selector.x += (targetX() - selector.x) * k;
		selector.y += (targetY() - selector.y) * k;
	}

	function snapSelector():Void
	{
		selector.x = targetX();
		selector.y = targetY();
	}

	function targetX():Float
		return rows[index].x - selector.width - SELECTOR_GAP;

	function targetY():Float
		return rows[index].y + rows[index].height / 2 - selector.height / 2 + Math.sin(bobTime * BOB_SPEED) * BOB;
}
