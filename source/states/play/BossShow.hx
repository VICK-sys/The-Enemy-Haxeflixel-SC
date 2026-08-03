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
	static inline var BOSS_PULL:Float = 0.8;
	static inline var MUSIC:String = "batallon_de_las_velas";
	static inline var WARN_HOLD:Float = 1.1;
	static inline var ARRIVE_AT:Float = 2.6;

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
	}

	public function begin():Void
	{
		fighting = true;
		hud.showBoss();
		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(2.4, 0);
		alarm = FlxG.sound.play(Paths.sound("boss_alarm"), 0.7);
		new flixel.util.FlxTimer().start(ARRIVE_AT, function(_)
		{
			if (!fighting)
				return;
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
			FlxTween.tween(FlxG.camera, {zoom: PlayState.BASE_ZOOM * BOSS_PULL}, 1.2);
		});
	}

	public function warn(onPeak:Void->Void):Void
	{
		hud.showBoss();
		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(2.4, 0);
		alarm = FlxG.sound.play(Paths.sound("boss_alarm"), 0.7);
		arena.beginWhiteFlash(function()
		{
			hud.fadeBanner();
			if (alarm != null)
				alarm.fadeOut(WARN_HOLD, 0, function(_)
				{
					if (alarm != null)
					{
						alarm.stop();
						alarm = null;
					}
				});
		}, onPeak, WARN_HOLD);
	}

	public var wantHeal:Void->Bool;

	public function dropLoot(cx:Float, cy:Float):Void
	{
		for (i in 0...Scraps.BOSS_SCRAP)
			scraps.drop(cx, cy);
		if (wantHeal == null || wantHeal())
			pickups.drop(cx, cy);
	}

	public function defeated():Void
	{
		fighting = false;
		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.6, 0);
		new flixel.util.FlxTimer().start(0.8, function(_)
		{
			if (fighting)
				return;
			normal();
		});
	}

	function normal():Void
	{
		showDecor(true);
		Music.play(QuietRoom.track(), 0.3);
		FlxTween.tween(FlxG.camera, {zoom: PlayState.BASE_ZOOM}, 0.8);
	}

	function showDecor(on:Bool):Void
	{
		props.setDecorVisible(on);
		props.setSolid(on);
		round.shop.setVisible(on);
		if (floor != null)
			floor.visible = on;
	}
}
