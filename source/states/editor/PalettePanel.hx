package states.editor;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import openfl.display.BitmapData;

class PalettePanel
{
	public var bg(default, null):FlxSprite;
	public var sheet(default, null):FlxSprite;
	public var sel(default, null):FlxSprite;

	private var cam:FlxCamera;
	private var px:Float;
	private var py:Float;
	private var w:Float;
	private var h:Float;
	private var pad:Float;

	public function new(state:FlxState, cam:FlxCamera, px:Float, py:Float, w:Float, h:Float, pad:Float)
	{
		this.cam = cam;
		this.px = px;
		this.py = py;
		this.w = w;
		this.h = h;
		this.pad = pad;

		bg = new FlxSprite();
		bg.makeGraphic(1, 1, 0xFF0E0E0E);
		bg.cameras = [cam];
		state.add(bg);

		sheet = new FlxSprite();
		sheet.antialiasing = false;
		sheet.cameras = [cam];
		state.add(sheet);

		sel = new FlxSprite();
		sel.makeGraphic(1, 1, 0x66FFFFFF);
		sel.cameras = [cam];
		state.add(sel);
	}

	public var x(get, never):Float;

	function get_x():Float
		return px;

	public var y(get, never):Float;

	function get_y():Float
		return py;

	public var width(get, never):Float;

	function get_width():Float
		return w;

	public var height(get, never):Float;

	function get_height():Float
		return h;

	public function show(on:Bool):Void
	{
		bg.visible = on;
		sheet.visible = on;
		sel.visible = on;
	}

	public function frame():Void
	{
		bg.setGraphicSize(Std.int(w + pad * 2), Std.int(h + pad * 2));
		bg.updateHitbox();
		bg.x = x - pad;
		bg.y = y - pad;
	}

	public function contains():Bool
	{
		var m = FlxG.mouse.getScreenPosition(cam);
		return bg.visible && m.x >= bg.x && m.x <= bg.x + bg.width && m.y >= bg.y && m.y <= bg.y + bg.height;
	}

	public function localX():Float
		return FlxG.mouse.getScreenPosition(cam).x - x;

	public function localY():Float
		return FlxG.mouse.getScreenPosition(cam).y - y;

	function setWindow(view:BitmapData, scale:Float):Void
	{
		var old = sheet.graphic;
		sheet.loadGraphic(view);
		if (old != null && old != sheet.graphic)
			FlxG.bitmap.remove(old);
		sheet.scale.set(scale, scale);
		sheet.updateHitbox();
		sheet.x = x;
		sheet.y = y;
	}

	public static function clamp(v:Float, lo:Float, hi:Float):Float
		return v < lo ? lo : (v > hi ? hi : v);
}
