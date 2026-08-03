package util;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxShader;

class PixelPerfectShader extends FlxShader
{
	static inline var NEAREST:Float = 0.0001;
	static inline var SNAP:Float = 0.05;

	public static var sprites(default, null):PixelPerfectShader;
	public static var floor(default, null):PixelPerfectShader;

	static var pool:Array<PixelPerfectShader>;

	public var artScale:Float;

	@:glFragmentSource('
		#pragma header

		uniform float uCell;
		uniform float uBand;

		void main()
		{
			vec2 grid = openfl_TextureSize / uCell;
			vec2 pix = openfl_TextureCoordv * grid;
			vec2 snapped = floor(pix)
				+ clamp(fract(pix) / uBand, 0.0, 0.5)
				+ clamp((fract(pix) - 1.0) / uBand + 0.5, 0.0, 0.5);
			gl_FragColor = flixel_texture2D(bitmap, snapped / grid);
		}
	')
	public function new(art:Float, cell:Float)
	{
		super();
		artScale = art;
		uCell.value = [cell];
		uBand.value = [NEAREST];
	}

	public static function on(s:FlxSprite):FlxSprite
	{
		boot();
		s.antialiasing = true;
		s.shader = sprites;
		return s;
	}

	public static function ground(s:FlxSprite, art:Float, cell:Float):Void
	{
		boot();
		floor.artScale = art;
		floor.uCell.value[0] = cell;
		s.antialiasing = true;
		s.shader = floor;
	}

	static function boot():Void
	{
		if (pool != null)
			return;
		sprites = new PixelPerfectShader(4, 1);
		floor = new PixelPerfectShader(2, 1);
		pool = [sprites, floor];
		FlxG.signals.postUpdate.add(tick);
		tick();
	}

	static function tick():Void
	{
		var zs = (FlxG.camera == null ? 1.0 : FlxG.camera.zoom)
			* (FlxG.scaleMode == null ? 1.0 : FlxG.scaleMode.scale.x);
		var live = SaveData.pixelFilter();
		for (sh in pool)
			sh.uBand.value[0] = band(live ? sh.artScale * zs : 0);
	}

	public static function band(texelPx:Float):Float
	{
		if (texelPx <= 0)
			return NEAREST;
		if (Math.abs(texelPx - Math.round(texelPx)) < SNAP)
			return NEAREST;
		var w = 1 / texelPx;
		return w > 1 ? 1 : w;
	}
}
