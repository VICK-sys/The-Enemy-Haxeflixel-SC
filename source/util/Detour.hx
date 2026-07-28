package util;

import flixel.FlxG;
import data.PropData.PropPlace;
import net.Net;

class Detour
{
	public static inline var EVENT:String = "treeRoom";
	public static inline var ROOM:String = "treeRoom";
	public static inline var ODDS:Int = 66;

	public static var inRoom(default, null):Bool = false;
	public static var used(default, null):Bool = false;

	static var csv:String;
	static var spawnX:Float;
	static var spawnY:Float;
	static var props:Array<PropPlace>;
	static var tileset:String;
	static var tiles:String;
	static var slot:Int;
	static var fromEditor:Bool;

	static var wave:Int;
	static var bossWave:Int;
	static var health:Float;
	static var superMeter:Float;
	static var kills:Int;
	static var weapon:Int;
	static var pending:Bool = false;

	public static function reset():Void
	{
		inRoom = false;
		used = false;
		pending = false;
	}

	public static function rolls():Bool
	{
		if (used || inRoom || Net.active || CustomArena.quiet)
			return false;
		if (!Run.allows(EVENT))
			return false;
		if (MapStore.builtin(ROOM) == null)
			return false;
		return FlxG.random.int(1, ODDS) == 1;
	}

	public static function begin(atWave:Int, atBossWave:Int, hp:Float, superAt:Float, killCount:Int, heldWeapon:Int):Bool
	{
		var room = MapStore.builtin(ROOM);
		if (room == null)
			return false;

		csv = CustomArena.csv;
		spawnX = CustomArena.spawnX;
		spawnY = CustomArena.spawnY;
		props = CustomArena.props;
		tileset = CustomArena.tileset;
		tiles = CustomArena.tiles;
		slot = CustomArena.slot;
		fromEditor = CustomArena.fromEditor;

		wave = atWave;
		bossWave = atBossWave;
		health = hp;
		superMeter = superAt;
		kills = killCount;
		weapon = heldWeapon;

		used = true;
		inRoom = true;
		CustomArena.fromStored(room, CustomArena.QUIET_SLOT);
		return true;
	}

	public static function leave():Void
	{
		inRoom = false;
		pending = true;

		CustomArena.csv = csv;
		CustomArena.spawnX = spawnX;
		CustomArena.spawnY = spawnY;
		CustomArena.props = props;
		CustomArena.tileset = tileset;
		CustomArena.tiles = tiles;
		CustomArena.slot = slot;
		CustomArena.fromEditor = fromEditor;
	}

	public static function resuming():Bool
		return pending;

	public static function restore(status:systems.PlayerCombat, combat:systems.weapons.Weapons, director:systems.enemy.EnemyDirector):Void
	{
		if (!pending)
			return;
		pending = false;
		status.health = health;
		status.superMeter = superMeter;
		status.kills = kills;
		combat.equip(weapon);
		director.resumeAfter(wave, bossWave);
	}
}
