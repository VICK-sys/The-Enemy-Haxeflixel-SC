package states.play;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import systems.Pickups;
import systems.Scraps;
import systems.world.Arena;
import systems.world.PropWorld;
import ui.Hud;
import util.Music;
import util.Paths;

class BossShow
{
	static inline var BOSS_ZOOM:Float = 0.8;
	static inline var MUSIC:String = "batallon_de_las_velas";

	public var fighting(default, null):Bool = false;

	private var arena:Arena;
	private var hud:Hud;
	private var props:PropWorld;
	private var round:ShopRound;
	private var scraps:Scraps;
	private var pickups:Pickups;
	private var floor:FlxTilemap;
	private var alarm:FlxSound;

	public function new(arena:Arena, hud:Hud, props:PropWorld, round:ShopRound, scraps:Scraps, pickups:Pickups,
			floor:FlxTilemap)
	{
		this.arena = arena;
		this.hud = hud;
		this.props = props;
		this.round = round;
		this.scraps = scraps;
		this.pickups = pickups;
		this.floor = floor;
		arena.onNormal = normal;
	}

	public function begin():Void
	{
		fighting = true;
		arena.beginBossTransition();
		arena.onWhiteout = whiteout;
		hud.showBoss();
		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(2.4, 0);
		alarm = FlxG.sound.play(Paths.sound("boss_alarm"), 0.7);
	}

	function whiteout():Void
	{
		showDecor(false);
		hud.fadeBanner();
		if (alarm != null)
			alarm.fadeOut(0.8, 0, function(_)
			{
				if (alarm != null)
				{
					alarm.stop();
					alarm = null;
				}
			});
		Music.play(MUSIC, 0.5);
		FlxTween.tween(FlxG.camera, {zoom: BOSS_ZOOM}, 1.2);
	}

	public function dropLoot(cx:Float, cy:Float):Void
	{
		for (i in 0...Scraps.BOSS_SCRAP)
			scraps.drop(cx, cy);
		pickups.drop(cx, cy);
	}

	public function defeated():Void
	{
		fighting = false;
		arena.endBossTransition();
		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.6, 0);
	}

	function normal():Void
	{
		showDecor(true);
		Music.play(QuietRoom.track(), 0.3);
		FlxTween.tween(FlxG.camera, {zoom: 1}, 0.8);
	}

	function showDecor(on:Bool):Void
	{
		props.setDecorVisible(on);
		round.shop.setVisible(on);
		if (floor != null)
			floor.visible = on;
	}
}
