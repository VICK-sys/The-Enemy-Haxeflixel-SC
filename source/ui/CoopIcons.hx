package ui;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxRect;

class CoopIcons
{
	static inline var SCALE:Float = 3;
	static inline var RIGHT:Float = 1264;
	static inline var BOTTOM:Float = 704;
	static inline var STEP:Float = 24;
	static inline var MAX:Int = 8;
	static inline var BAR_X:Float = 6;
	static inline var BAR_Y:Float = 25;
	static inline var BAR_W:Int = 20;
	static inline var BAR_H:Int = 6;

	static inline var BAR_ART:String = "ui/coop_bar";
	static var SHEETS:Array<String> = ["ui/coop_icon_a", "ui/coop_icon_b"];

	public var sprites(default, null):Array<FlxSprite> = [];

	private var healthBacks:Array<FlxSprite> = [];
	private var healthFills:Array<FlxSprite> = [];
	private var healthClips:Array<FlxRect> = [];
	private var healthWidths:Array<Int> = [];
	private var healthShown:Array<Bool> = [];
	private var hues:Array<Float> = [];
	private var skins:Array<Int> = [];
	private var downs:Array<Bool> = [];
	private var shown:Int = 0;
	private var enabled:Bool = true;

	public function new(state:FlxState, cam:FlxCamera)
	{
		for (i in 0...MAX)
		{
			var s = new FlxSprite();
			s.antialiasing = false;
			s.cameras = [cam];
			s.visible = false;
			sprites.push(s);

			var back = new FlxSprite();
			back.antialiasing = false;
			back.cameras = [cam];
			back.visible = false;
			healthBacks.push(back);
			state.add(back);

			var fill = new FlxSprite();
			fill.antialiasing = false;
			fill.cameras = [cam];
			fill.visible = false;
			healthFills.push(fill);
			state.add(fill);

			healthClips.push(new FlxRect(0, 0, BAR_W, BAR_H));
			healthWidths.push(BAR_W);
			healthShown.push(false);
			hues.push(-1);
			skins.push(-1);
			downs.push(false);
			state.add(s);
		}
	}

	public function setVisible(on:Bool):Void
	{
		enabled = on;
		for (i in 0...MAX)
		{
			sprites[i].visible = on && i < shown;
			healthBacks[i].visible = on && i < shown && healthShown[i];
			healthFills[i].visible = on && i < shown && healthShown[i] && healthWidths[i] > 0;
		}
	}

	public function clear():Void
	{
		shown = 0;
		for (i in 0...MAX)
		{
			sprites[i].visible = false;
			healthBacks[i].visible = false;
			healthFills[i].visible = false;
		}
	}

	public function begin():Void
		shown = 0;

	public function add(hue:Float, skin:Int, down:Bool, health:Float):Void
	{
		if (shown >= MAX)
			return;
		var i = shown++;
		var use = skin == 1 ? 1 : 0;
		if (hues[i] != hue || skins[i] != use || downs[i] != down)
		{
			hues[i] = hue;
			skins[i] = use;
			downs[i] = down;
			var name = SHEETS[use];
			sprites[i].loadGraphic(down ? util.HuePalette.faded(name, hue) : util.HuePalette.graphic(name, hue));
			sprites[i].antialiasing = false;
			sprites[i].scale.set(SCALE, SCALE);
			sprites[i].updateHitbox();

			healthBacks[i].loadGraphic(util.HuePalette.faded(BAR_ART, hue));
			healthBacks[i].antialiasing = false;
			healthBacks[i].scale.set(SCALE, SCALE);
			healthBacks[i].updateHitbox();

			healthFills[i].loadGraphic(down ? util.HuePalette.faded(BAR_ART, hue) : util.HuePalette.graphic(BAR_ART, hue));
			healthFills[i].antialiasing = false;
			healthFills[i].scale.set(SCALE, SCALE);
			healthFills[i].updateHitbox();
			healthFills[i].clipRect = healthClips[i];
		}
		sprites[i].visible = enabled;

		var showHealth = health >= 0;
		var healthWidth = showHealth ? Math.round(BAR_W * Math.max(0, Math.min(1, health))) : 0;
		healthShown[i] = showHealth;
		if (healthWidths[i] != healthWidth)
		{
			healthWidths[i] = healthWidth;
			healthClips[i].set(0, 0, healthWidth, BAR_H);
			healthFills[i].clipRect = healthClips[i];
		}
		healthBacks[i].visible = enabled && showHealth;
		healthFills[i].visible = enabled && showHealth && healthWidth > 0;
	}

	public function layout():Void
	{
		for (i in shown...MAX)
		{
			sprites[i].visible = false;
			healthBacks[i].visible = false;
			healthFills[i].visible = false;
		}
		if (shown == 0)
			return;

		var step = STEP * SCALE;
		var last = sprites[shown - 1];
		var right = RIGHT;
		for (i in 0...shown)
		{
			var s = sprites[i];
			s.x = right - last.width - (shown - 1 - i) * step;
			s.y = BOTTOM - s.height;
			healthBacks[i].x = s.x + BAR_X * SCALE;
			healthBacks[i].y = s.y + BAR_Y * SCALE;
			healthFills[i].x = healthBacks[i].x;
			healthFills[i].y = healthBacks[i].y;
		}
	}
}
