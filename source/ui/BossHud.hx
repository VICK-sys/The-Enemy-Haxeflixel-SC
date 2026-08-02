package ui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import util.Paths;
import util.Lang;
import entities.enemy.Enemies;

class BossHud
{
	static inline var ART_W:Float = 176;
	static inline var ART_H:Float = 17;
	static inline var CH_X:Float = 8;
	static inline var CH_Y:Float = 7;
	static inline var CH_W:Float = 160;
	static inline var CH_H:Float = 4;
	static inline var BAR_SCALE:Float = 4 * states.PlayState.BASE_ZOOM;
	static inline var BAR_START_Y:Float = 46;
	static inline var BAR_REST_Y:Float = 72;
	static inline var EXPAND:Float = 0.55;
	static inline var NAME_Y:Float = 112;
	static inline var NAME_SPACING:Float = 4;
	static inline var LETTER_STAGGER:Float = 0.14;
	static inline var LETTER_FADE:Float = 0.3;
	static inline var FLASH_TIME:Float = 1.6;

	private var state:FlxState;
	private var camUI:FlxCamera;
	private var flash:FlxSprite;
	private var flashTimer:Float = 0;
	private var bosses:Array<Enemies> = [];
	private var barFrame:FlxSprite;
	private var barFill:FlxSprite;
	private var fillClip:FlxRect;
	private var bossMax:Float = 1;
	private var letters:Array<FlxText> = [];
	private var barTimer:Float = 0;
	private var barActive:Bool = false;
	private var shown:Bool = true;

	public function setShown(on:Bool):Void
	{
		shown = on;
		if (barFrame != null)
			barFrame.visible = on && barActive;
		if (barFill != null)
			barFill.visible = on && barActive;
		for (t in letters)
			t.visible = on;
	}

	public function new(state:FlxState, camUI:FlxCamera)
	{
		this.state = state;
		this.camUI = camUI;

		flash = new FlxSprite();
		flash.makeGraphic(FlxG.width, FlxG.height, 0xFFB2001E);
		flash.cameras = [camUI];
		flash.alpha = 0;
		state.add(flash);
	}

	public function startFlash():Void
	{
		flashTimer = FLASH_TIME;
	}

	public function dispose():Void
		dropBar();

	function dropBar():Void
	{
		if (barFrame != null)
		{
			state.remove(barFrame, true);
			barFrame.destroy();
			barFrame = null;
		}
		if (barFill != null)
		{
			barFill.clipRect = null;
			state.remove(barFill, true);
			barFill.destroy();
			barFill = null;
		}
		if (fillClip != null)
		{
			fillClip.put();
			fillClip = null;
		}
		for (t in letters)
		{
			state.remove(t, true);
			t.destroy();
		}
		letters = [];
	}

	static var BOSS_NAMES:Map<String, String> = [
		"rofel" => "Rofel",
		"domo" => "Domo",
		"worm" => "Magma Wyrm"
	];

	function bossName():String
	{
		var kind = bosses.length > 0 && bosses[0] != null ? bosses[0].kind : "domo";
		var word = BOSS_NAMES.exists(kind) ? BOSS_NAMES.get(kind) : "Domo";
		return bosses.length == 2 ? word + " Duo" : word;
	}

	public function showBar(pack:Array<Enemies>):Void
	{
		dropBar();
		bosses = pack.copy();

		bossMax = 0;
		for (b in bosses)
			bossMax += b.hp > 0 ? b.hp : 1;

		barFrame = plate("ui/bar_long_empty");
		barFill = plate("ui/bar_long_red");
		fillClip = FlxRect.get(0, 0, CH_W, CH_H);
		barFill.clipRect = fillClip;
		state.add(barFrame);
		state.add(barFill);

		var word = bossName();
		var total = 0.0;
		var built = [];
		for (i in 0...word.length)
		{
			var t = new FlxText(0, NAME_Y, 0, word.charAt(i));
			t.setFormat(Lang.display(), 32, FlxColor.WHITE, LEFT);
			t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			t.cameras = [camUI];
			t.alpha = 0;
			t.visible = shown;
			state.add(t);
			built.push(t);
			total += t.width + NAME_SPACING;
		}
		total -= NAME_SPACING;

		var cx = FlxG.width / 2 - total / 2;
		letters = [];
		for (t in built)
		{
			t.x = cx;
			cx += t.width + NAME_SPACING;
			letters.push(t);
		}

		barTimer = 0;
		barActive = true;
	}

	function plate(art:String):FlxSprite
	{
		var s = new FlxSprite();
		s.loadGraphic(Paths.image(art));
		s.antialiasing = false;
		s.origin.set(0, 0);
		s.cameras = [camUI];
		s.visible = shown;
		return s;
	}

	public function update(elapsed:Float):Void
	{
		if (barActive)
			updateBar(elapsed);

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			var ft = FLASH_TIME - flashTimer;
			flash.alpha = flashTimer <= 0 ? 0 : 0.55 * Math.abs(Math.sin(ft * 8)) * (flashTimer / FLASH_TIME);
		}
	}

	function anyAlive():Bool
	{
		for (b in bosses)
			if (b != null && b.exists)
				return true;
		return false;
	}

	function liveHp():Float
	{
		var hp = 0.0;
		for (b in bosses)
			if (b != null && b.exists && b.hp > 0)
				hp += b.hp;
		return hp;
	}

	function updateBar(elapsed:Float):Void
	{
		if (!anyAlive())
		{
			if (barFrame != null)
				barFrame.visible = false;
			if (barFill != null)
				barFill.visible = false;
			for (t in letters)
				t.visible = false;
			barActive = false;
			return;
		}

		barTimer += elapsed;

		var e = barTimer < EXPAND ? barTimer / EXPAND : 1;
		var ease = 1 - Math.pow(1 - e, 3);
		var cy = BAR_START_Y + (BAR_REST_Y - BAR_START_Y) * ease;
		var sx = BAR_SCALE * (0.03 + 0.97 * ease);
		var fw = ART_W * sx;
		var fh = ART_H * BAR_SCALE;

		barFrame.scale.set(sx, BAR_SCALE);
		barFrame.x = FlxG.width / 2 - fw / 2;
		barFrame.y = cy - fh / 2;

		var frac = liveHp() / bossMax;
		if (frac < 0)
			frac = 0;
		if (frac > 1)
			frac = 1;

		barFill.scale.set(sx, BAR_SCALE);
		barFill.x = barFrame.x + CH_X * sx;
		barFill.y = barFrame.y + CH_Y * BAR_SCALE;
		fillClip.width = CH_W * frac;
		barFill.clipRect = fillClip;

		for (i in 0...letters.length)
		{
			var start = EXPAND + i * LETTER_STAGGER;
			var a = (barTimer - start) / LETTER_FADE;
			letters[i].alpha = a < 0 ? 0 : (a > 1 ? 1 : a);
		}
	}
}
