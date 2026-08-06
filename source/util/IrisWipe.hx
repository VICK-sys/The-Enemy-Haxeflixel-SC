package util;

import openfl.display.BitmapData;
import openfl.geom.Matrix;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class IrisWipe extends FlxTypedGroup<FlxSprite>
{
	public static inline var OPEN_TIME:Float = 0.65;
	public static inline var CLOSE_TIME:Float = 0.5;

	static inline var MASK_SIZE:Int = 256;
	static inline var FULL_SCALE:Float = 11;
	static inline var MASK_KEY:String = "iriswipe_icon_mask";

	static var maskGraphic:FlxGraphic = null;

	private var iris:FlxSprite;
	private var bars:Array<FlxSprite> = [];
	private var cam:FlxCamera;
	private var motion:FlxTween;

	public function new(state:FlxState)
	{
		super();

		cam = new FlxCamera();
		cam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(cam, false);

		iris = new FlxSprite();
		iris.loadGraphic(buildMask());
		iris.antialiasing = true;
		iris.origin.set(MASK_SIZE * 0.5, MASK_SIZE * 0.5);
		iris.cameras = [cam];
		add(iris);

		for (i in 0...4)
		{
			var b = new FlxSprite();
			b.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			b.cameras = [cam];
			bars.push(b);
			add(b);
		}

		state.add(this);
		setScale(0);
	}

	static function buildMask():FlxGraphic
	{
		if (maskGraphic != null && maskGraphic.bitmap != null)
			return maskGraphic;

		var src = FlxG.bitmap.add(Paths.image("icon")).bitmap;
		var shape = new BitmapData(MASK_SIZE, MASK_SIZE, true, 0x00000000);
		var m = new Matrix();
		m.scale(MASK_SIZE / src.width, MASK_SIZE / src.height);
		shape.draw(src, m, null, null, null, true);

		var data = new BitmapData(MASK_SIZE, MASK_SIZE, true, 0xFF000000);
		for (y in 0...MASK_SIZE)
			for (x in 0...MASK_SIZE)
			{
				var a = shape.getPixel32(x, y) >>> 24;
				if (a > 0)
					data.setPixel32(x, y, (255 - a) << 24);
			}
		shape.dispose();

		maskGraphic = FlxG.bitmap.add(data, false, MASK_KEY);
		maskGraphic.persist = true;
		maskGraphic.destroyOnNoUse = false;
		return maskGraphic;
	}

	function setScale(s:Float):Void
	{
		iris.scale.set(s, s);
		iris.x = FlxG.width * 0.5 - MASK_SIZE * 0.5;
		iris.y = FlxG.height * 0.5 - MASK_SIZE * 0.5;

		var halfW = MASK_SIZE * s * 0.5;
		var halfH = MASK_SIZE * s * 0.5;
		var cx = FlxG.width * 0.5;
		var cy = FlxG.height * 0.5;
		var bw = bars[0].width;
		var bh = bars[0].height;

		bars[0].setPosition(cx - bw * 0.5, cy - halfH - bh);
		bars[1].setPosition(cx - bw * 0.5, cy + halfH);
		bars[2].setPosition(cx - halfW - bw, cy - bh * 0.5);
		bars[3].setPosition(cx + halfW, cy - bh * 0.5);
	}

	public function open(?onComplete:Void->Void):Void
	{
		if (motion != null)
			motion.cancel();
		visible = true;
		setScale(0);
		motion = FlxTween.num(0, FULL_SCALE, OPEN_TIME, {ease: FlxEase.quadOut, onComplete: function(_)
		{
			motion = null;
			visible = false;
			if (onComplete != null)
				onComplete();
		}}, setScale);
	}

	public function close(?onComplete:Void->Void):Void
	{
		if (motion != null)
			motion.cancel();
		visible = true;
		setScale(FULL_SCALE);
		motion = FlxTween.num(FULL_SCALE, 0, CLOSE_TIME, {ease: FlxEase.quadIn, onComplete: function(_)
		{
			motion = null;
			if (onComplete != null)
				onComplete();
		}}, setScale);
	}
}
