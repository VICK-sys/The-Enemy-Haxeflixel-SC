package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import util.Paths;
import util.Lang;

class MenuList extends FlxGroup
{
	static inline var SELECTOR_GAP:Float = 26;
	static inline var REST_ANGLE:Float = -35;
	static inline var EASE:Float = 16;
	static inline var BOB:Float = 4;
	static inline var BOB_SPEED:Float = 5;

	static inline var HOLD_DELAY:Float = 0.34;
	static inline var HOLD_SLOW:Float = 0.055;
	static inline var HOLD_FAST:Float = 0.008;
	static inline var HOLD_RAMP:Float = 1.1;
	static inline var BLIP_GAP:Float = 0.07;

	public var index(default, null):Int = 0;
	public var onChoose:Int->Void;
	public var onAdjust:(Int, Int) -> Void;
	public var enabled:Bool = true;
	public var repeatAdjust:Bool = false;
	public var repeatFor:Int->Bool;
	public var skipRow:Array<Bool> = [];

	private var rows:Array<FlxText> = [];
	private var selector:FlxSprite;
	private var bobTime:Float = 0;
	private var lastMouseX:Float = 0;
	private var lastMouseY:Float = 0;
	private var holdDir:Int = 0;
	private var holdWait:Float = 0;
	private var holdTime:Float = 0;
	private var blipWait:Float = 0;

	public function new(labels:Array<String>, startY:Float, spacing:Float, size:Int)
	{
		super();
		for (i in 0...labels.length)
		{
			var t = new FlxText(0, startY + i * spacing, 0, labels[i]);
			t.setFormat(Lang.font(), size, FlxColor.WHITE, CENTER);
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
		selector.angle = REST_ANGLE;
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

	public function rowAt(i:Int):FlxText
		return rows[i];

	public function setSkip(i:Int, on:Bool):Void
	{
		while (skipRow.length < rows.length)
			skipRow.push(false);
		skipRow[i] = on;
	}

	public function selectable(i:Int):Bool
		return i < skipRow.length ? !skipRow[i] : true;

	public function place(i:Int, y:Float):Void
		rows[i].y = y;

	public function settle():Void
	{
		if (!selectable(index))
			for (i in 0...rows.length)
				if (selectable(i))
				{
					index = i;
					break;
				}
		snapSelector();
	}

	public var marker(get, never):FlxSprite;

	function get_marker():FlxSprite
		return selector;

	public function restoreRows():Void
	{
		for (r in rows)
			r.visible = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		bobTime += elapsed;

		if (!enabled)
			return;

		if (util.Controls.menuUp())
			move(-1);
		if (util.Controls.menuDown())
			move(1);

		if (FlxG.mouse.x != lastMouseX || FlxG.mouse.y != lastMouseY)
		{
			lastMouseX = FlxG.mouse.x;
			lastMouseY = FlxG.mouse.y;
			for (i in 0...rows.length)
			{
				if (i != index && selectable(i) && FlxG.mouse.overlaps(rows[i], rowCamera(i)))
				{
					index = i;
					blip();
				}
			}
		}

		if (overRow())
			MenuCursor.markHover();

		if (blipWait > 0)
			blipWait -= elapsed;
		updateAdjust(elapsed);

		var clicked = FlxG.mouse.justPressed && FlxG.mouse.overlaps(rows[index], rowCamera(index));
		if (util.Controls.menuAccept() || FlxG.keys.justPressed.SPACE || clicked)
		{
			util.MenuSfx.click();
			if (onChoose != null)
				onChoose(index);
		}

		positionSelector(elapsed);
	}

	static function selectorGraphic():FlxGraphic
	{
		var key = "menuWeaponOutline";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var src = FlxG.bitmap.add(Paths.image("items/hammer")).bitmap;
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
		var n = rows.length;
		var i = index;
		for (_ in 0...n)
		{
			i = (i + dir + n) % n;
			if (selectable(i))
				break;
		}
		index = i;
		blip();
	}

	function updateAdjust(elapsed:Float):Void
	{
		var dir = 0;
		if (util.Controls.menuRightHeld())
			dir = 1;
		else if (util.Controls.menuLeftHeld())
			dir = -1;

		if (dir != holdDir)
		{
			holdDir = dir;
			holdWait = HOLD_DELAY;
			holdTime = 0;
			if (dir != 0)
				adjust(dir);
			return;
		}

		if (dir == 0 || !(repeatFor != null ? repeatFor(index) : repeatAdjust))
			return;

		holdTime += elapsed;
		holdWait -= elapsed;
		if (holdWait > 0)
			return;

		var ramp = holdTime / HOLD_RAMP;
		if (ramp > 1)
			ramp = 1;
		holdWait = HOLD_SLOW + (HOLD_FAST - HOLD_SLOW) * ramp;
		adjust(dir);
	}

	function adjust(dir:Int):Void
	{
		if (onAdjust == null)
			return;
		if (blipWait <= 0)
		{
			blipWait = BLIP_GAP;
			util.MenuSfx.hover();
		}
		onAdjust(index, dir);
	}

	function overRow():Bool
	{
		for (i in 0...rows.length)
			if (selectable(i) && rows[i].visible && FlxG.mouse.overlaps(rows[i], rowCamera(i)))
				return true;
		return false;
	}

	function rowCamera(i:Int):flixel.FlxCamera
	{
		var cams = rows[i].cameras;
		return cams != null && cams.length > 0 ? cams[0] : FlxG.camera;
	}

	function blip():Void
	{
		util.MenuSfx.hover();
	}

	function positionSelector(elapsed:Float):Void
	{
		var k = Math.min(1, EASE * elapsed);
		selector.x += (targetX() - selector.x) * k;
		selector.y += (targetY() - selector.y) * k;
		selector.angle += (REST_ANGLE - selector.angle) * k;
	}

	function snapSelector():Void
	{
		selector.x = targetX();
		selector.y = targetY();
		selector.angle = REST_ANGLE;
	}

	function targetX():Float
		return rows[index].x - selector.width - SELECTOR_GAP;

	function targetY():Float
		return rows[index].y + rows[index].height / 2 - selector.height / 2 + Math.sin(bobTime * BOB_SPEED) * BOB;
}
