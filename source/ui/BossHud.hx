package ui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import entities.enemy.Enemies;

class BossHud
{
	static inline var FLASH_TIME:Float = 1.6;

	private var flash:FlxSprite;
	private var flashTimer:Float = 0;
	private var bosses:Array<Enemies> = [];
	private var bossMax:Float = 1;

	public function new(state:FlxState, camUI:FlxCamera)
	{
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

	public function beginEncounter():Void
	{
		bosses = [];
		bossMax = 0;
	}

	static var BOSS_NAMES:Map<String, String> = [
		"domo" => "Domo",
		"worm" => "Magma Wyrm"
	];

	public function bossName():String
	{
		var names:Array<String> = [];
		var seen:Map<String, Bool> = new Map();
		for (boss in bosses)
		{
			if (boss == null)
				continue;
			var kind = boss.kind == "worm_body" ? "worm" : boss.kind;
			if (!BOSS_NAMES.exists(kind) || seen.exists(kind))
				continue;
			seen.set(kind, true);
			names.push(BOSS_NAMES.get(kind));
		}
		return names.join(" and ");
	}

	public function track(pack:Array<Enemies>):Void
	{
		bosses = pack.copy();

		bossMax = 0;
		for (b in bosses)
			bossMax += b.hp > 0 ? b.hp : 1;
	}

	public function update(elapsed:Float):Void
	{
		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			var ft = FLASH_TIME - flashTimer;
			flash.alpha = flashTimer <= 0 ? 0 : 0.55 * Math.abs(Math.sin(ft * 8)) * (flashTimer / FLASH_TIME);
		}
	}

	public function fraction():Float
	{
		if (bossMax <= 0)
			return 1;
		var f = liveHp() / bossMax;
		return f < 0 ? 0 : (f > 1 ? 1 : f);
	}

	function liveHp():Float
	{
		var hp = 0.0;
		for (b in bosses)
			if (b != null && b.exists && b.hp > 0)
				hp += b.hp;
		return hp;
	}
}
