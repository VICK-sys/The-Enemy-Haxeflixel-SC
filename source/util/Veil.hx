package util;

import flixel.FlxG;
import flixel.FlxSprite;

class Veil
{
	static inline var CELL:Int = 4;
	static inline var SLACK:Float = 1.25;

	public static function make(color:Int):FlxSprite
	{
		var s = new FlxSprite();
		s.makeGraphic(CELL, CELL, color);
		s.scrollFactor.set();
		s.alpha = 0;
		fit(s);
		return s;
	}

	public static function fit(s:FlxSprite):Void
	{
		var zoom = FlxG.camera != null && FlxG.camera.zoom > 0 ? FlxG.camera.zoom : 1;
		var w = FlxG.width / zoom * SLACK;
		var h = FlxG.height / zoom * SLACK;
		s.scale.set(w / CELL, h / CELL);
		s.updateHitbox();
		s.setPosition(FlxG.width * 0.5 - w * 0.5, FlxG.height * 0.5 - h * 0.5);
	}
}
