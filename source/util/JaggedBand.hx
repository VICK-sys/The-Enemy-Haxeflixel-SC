package util;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxSpriteUtil;

class JaggedBand extends FlxSprite
{
	private var toothW:Float;
	private var speed:Float;
	private var homeX:Float;
	private var scroll:Float = 0;

	public function new(top:Bool, bandH:Int, toothW:Int, toothH:Int, color:Int, speed:Float)
	{
		super();

		this.toothW = toothW;
		this.speed = speed;

		var w = FlxG.width + toothW * 2;
		makeGraphic(w, bandH, 0x00000000, true);

		var pts:Array<FlxPoint> = [FlxPoint.get(0, toothH)];
		var i = 0;
		while (i * toothW < w)
		{
			var tx = i * toothW;
			pts.push(FlxPoint.get(tx + toothW * 0.5, 0));
			pts.push(FlxPoint.get(tx + toothW, toothH));
			i++;
		}
		pts.push(FlxPoint.get(w, bandH));
		pts.push(FlxPoint.get(0, bandH));
		FlxSpriteUtil.drawPolygon(this, pts, color);

		flipY = top;
		homeX = -toothW;
		x = homeX;
		y = top ? 0 : FlxG.height - bandH;
		scrollFactor.set();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		scroll = (scroll + speed * elapsed) % toothW;
		x = homeX - scroll;
	}
}
