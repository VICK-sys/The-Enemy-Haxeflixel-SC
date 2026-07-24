package systems;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import entities.enemy.Enemies;

class BossHud
{
	static inline var BAR_W:Int = 900;
	static inline var BAR_H:Int = 30;
	static inline var BAR_START_Y:Float = 20;
	static inline var BAR_REST_Y:Float = 54;
	static inline var EXPAND:Float = 0.55;
	static inline var NAME_Y:Float = 78;
	static inline var NAME_SPACING:Float = 4;
	static inline var LETTER_STAGGER:Float = 0.14;
	static inline var LETTER_FADE:Float = 0.3;
	static inline var FLASH_TIME:Float = 1.6;

	private var state:FlxState;
	private var camUI:FlxCamera;
	private var flash:FlxSprite;
	private var flashTimer:Float = 0;
	private var boss:Enemies;
	private var bar:FlxBar;
	private var letters:Array<FlxText> = [];
	private var barTimer:Float = 0;
	private var barActive:Bool = false;

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

	public function showBar(bossEnemy:Enemies):Void
	{
		boss = bossEnemy;

		bar = new FlxBar(0, 0, LEFT_TO_RIGHT, BAR_W, BAR_H, boss, "hp", 0, boss.hp);
		bar.createFilledBar(0xFF400810, 0xFFE0132D, true, 0xFF000000);
		bar.antialiasing = false;
		bar.origin.set(BAR_W / 2, BAR_H / 2);
		bar.cameras = [camUI];
		state.add(bar);

		var word = "Rofel";
		var total = 0.0;
		var built = [];
		for (i in 0...word.length)
		{
			var t = new FlxText(0, NAME_Y, 0, word.charAt(i));
			t.setFormat(null, 32, FlxColor.WHITE, LEFT);
			t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			t.cameras = [camUI];
			t.alpha = 0;
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

	function updateBar(elapsed:Float):Void
	{
		if (boss == null || !boss.exists)
		{
			if (bar != null)
				bar.visible = false;
			for (t in letters)
				t.visible = false;
			barActive = false;
			return;
		}

		barTimer += elapsed;

		var e = barTimer < EXPAND ? barTimer / EXPAND : 1;
		var ease = 1 - Math.pow(1 - e, 3);
		bar.scale.set(0.03 + 0.97 * ease, 1);
		var cy = BAR_START_Y + (BAR_REST_Y - BAR_START_Y) * ease;
		bar.x = FlxG.width / 2 - BAR_W / 2;
		bar.y = cy - BAR_H / 2;

		for (i in 0...letters.length)
		{
			var start = EXPAND + i * LETTER_STAGGER;
			var a = (barTimer - start) / LETTER_FADE;
			letters[i].alpha = a < 0 ? 0 : (a > 1 ? 1 : a);
		}
	}
}
