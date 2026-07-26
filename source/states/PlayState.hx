package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import entities.Player;
import entities.enemy.Enemies;
import entities.enemy.EnemyNav;
import systems.Arena;
import systems.Fx;
import systems.RenderLayers;
import systems.PlayerCombat;
import systems.EnemyDirector;
import systems.TimeStop;
import systems.perspective.PerspectiveShift;
import systems.weapons.Weapons;
import systems.Pickups;
import systems.Hud;
import util.Paths;
import util.SaveData;
import util.PerfLog;
import util.Music;
import util.SideView;
import util.IrisWipe;
import util.WorldClock;
import util.DiscordPresence;
import net.Net;
import net.NetSync;
import net.PuppetDirector;

class PlayState extends FlxState
{
	private var fx:Fx;
	private var arena:Arena;
	private var _player:Player;
	private var scythe:FlxSprite;
	private var layers:RenderLayers;
	private var status:PlayerCombat;
	private var pickups:Pickups;
	private var director:EnemyDirector;
	private var combat:Weapons;
	private var hud:Hud;
	private var perf:PerfLog;
	private var bossAlarm:FlxSound;
	private var bossFight:Bool = false;
	private var timeStop:TimeStop;
	private var shift:PerspectiveShift;
	private var wipe:IrisWipe;
	private var restarting:Bool = false;
	private var netSync:NetSync;
	private var props:systems.PropWorld;
	private var floor:flixel.tile.FlxTilemap;

	function showDecor(on:Bool):Void
	{
		props.setDecorVisible(on);
		if (floor != null)
			floor.visible = on;
	}

	function beginRestart():Void
	{
		if (restarting)
			return;
		restarting = true;
		wipe.close(function() FlxG.resetState());
	}

	override public function create()
	{
		SideView.reset();
		WorldClock.scale = 1;
		persistentUpdate = Net.active;
		fx = new Fx();

		FlxG.camera.bgColor = 0xFFFFFFFF;

		arena = new Arena(this);

		_player = new Player(arena.spawnX, arena.spawnY);

		FlxG.camera.follow(_player);
		FlxG.camera.followLerp = 0.1;
		FlxG.camera.setScrollBoundsRect(0, 0, arena.width, arena.height);
		FlxG.camera.zoom = 1;

		scythe = new FlxSprite(0, 0, Paths.image("items/mufu_scythe"));
		scythe.scale.set(4, 4);
		scythe.origin.set(scythe.width * 0.5, scythe.height);
		scythe.x = _player.x - scythe.origin.x + 30;
		scythe.y = _player.y - scythe.origin.y + 65;

		floor = systems.DecorTiles.build(util.CustomArena.tiles, util.CustomArena.tileset);
		if (floor != null)
			add(floor);

		layers = new RenderLayers(this, _player, scythe);
		arena.addPillars(layers.entityLayer);
		props = new systems.PropWorld(_player, layers);
		add(props.solids);

		status = new PlayerCombat(_player, fx);
		timeStop = new TimeStop(_player, layers.playerShadow, status);
		pickups = new Pickups(_player, status);
		insert(members.indexOf(layers.entityLayer), pickups.group);
		insert(members.indexOf(layers.entityLayer), fx.dashTrail);
		insert(members.indexOf(layers.entityLayer), timeStop.shadowTrail.group);
		insert(members.indexOf(layers.entityLayer), timeStop.trail.group);
		director = Net.isClient ? new PuppetDirector(_player, arena, layers, status) : new EnemyDirector(_player, arena, layers, status);
		director.solids = props.solids;
		combat = new Weapons(_player, scythe, arena, director, status, fx, pickups);

		add(combat.swing.slashes);
		add(combat.slice.slices);
		add(combat.bow.arrows);
		insert(members.indexOf(layers.entityLayer), combat.bow.rain.markers);
		insert(members.indexOf(layers.entityLayer), combat.hammer.shock.cracks);
		insert(members.indexOf(layers.entityLayer), combat.hammer.shock.rings);
		add(combat.bow.rain.arrows);
		add(combat.arrowStorm.trail.group);
		add(combat.arrowStorm.superArrow);
		add(combat.hookAttack.rope);
		add(combat.hookAttack.hook);
		insert(members.indexOf(layers.entityLayer), combat.hookArms.backGroup);
		add(combat.hookArms.frontGroup);
		add(combat.throwAttack.trail.group);
		add(combat.throwAttack.thrown);
		insert(members.indexOf(layers.entityLayer), combat.superScythes.trail.group);
		insert(members.indexOf(layers.entityLayer), combat.superScythes.backLayer);
		add(combat.superScythes.frontLayer);
		add(fx.sparks);
		add(director.shots);

		add(props.overlay);

		add(timeStop.overlay);

		hud = new Hud(this, status);
		shift = new PerspectiveShift(arena, _player, director, combat, layers);
		shift.disabled = util.CustomArena.active;
		director.onProbe = shift.onProbe;
		director.onWave = onWaveStarted;
		director.onBoss = onBossWave;
		director.onBossSpawn = hud.showBossBar;
		director.onBossDefeated = onBossDefeated;
		arena.onNormal = onArenaNormal;
		perf = new PerfLog();

		if (Net.active)
		{
			shift.locked = true;
			Net.inGame = true;
			netSync = new NetSync(_player, status, arena, layers, director, combat, pickups, hud, scythe);
			netSync.makeFx = function(av) return new net.RemoteFx(this, layers, director, combat.hits, fx, av);
			netSync.onWaveEvt = onWaveStarted;
			netSync.onBossEvt = onBossWave;
			netSync.onBossDefeatedEvt = onBossDefeated;
			netSync.onDropped = onNetDropped;
		netSync.onRestart = beginRestart;
		}

		DiscordPresence.beginRun();

		combat.equip(WeaponPickSubState.lastPick);
		if (Net.active)
			openTutorialIfNew();
		else
			openWeaponPick();

		Music.play("stage/gloomDoomWoods", 0.3);

		wipe = new IrisWipe(this);
		wipe.open();

		super.create();
	}

	function openWeaponPick():Void
	{
		var picker = new WeaponPickSubState(hud.camUI);
		picker.onPicked = function(i) combat.equip(i);
		picker.closeCallback = openTutorialIfNew;
		openSubState(picker);
	}

	function openTutorialIfNew():Void
	{
		if (TutorialSubState.shown || Net.active)
			return;
		TutorialSubState.shown = true;
		openSubState(new TutorialSubState(hud.camUI));
		DiscordPresence.tutorial();
	}

	override public function update(elapsed:Float):Void
	{
		EnemyNav.resetBudget();

		var frozen = SideView.morphing;
		var inputLocked = Net.active && subState != null;

		if (!frozen && !Net.active)
			timeStop.update(elapsed);

		super.update(elapsed);

		fx.update();
		arena.update(elapsed * timeStop.factor);
		shift.update(elapsed);

		if (!SideView.active && !frozen)
		{
			FlxG.collide(_player, arena.map);
			props.collidePlayer();
		}
		director.collide();

		status.update(elapsed);

		if (status.consumeJustDied())
		{
			layers.playerShadow.visible = false;
			scythe.visible = false;
			if (!Net.active)
			{
				hud.showDeath(director.wave, SaveData.bestWave());
				DiscordPresence.died(director.wave, SaveData.bestWave());
			}
		}

		director.update(frozen ? 0 : elapsed * timeStop.factor);
		pickups.update();
		layers.update();
		props.update();
		scythe.alpha = props.buried ? 0 : 1;
		combat.swing.slashes.visible = !props.buried;
		combat.slice.slices.visible = !props.buried;
		if (!frozen && !inputLocked)
			combat.update(elapsed);
		director.updateShots();
		if (netSync != null)
			netSync.update(elapsed);
		hud.setMode(combat.modeName());
		hud.setTimeStop(Net.active ? "OFF" : timeStop.hudLabel());
		hud.setStopTimer(Net.active ? "" : timeStop.timerLabel());
		hud.update(elapsed);

		if (subState == null && !status.dead)
			DiscordPresence.playing(director.wave, bossFight, combat.weapon, status.kills);

		if (FlxG.keys.justPressed.ESCAPE && !status.dead && subState == null)
		{
			DiscordPresence.paused();
			openSubState(new PauseSubState(hud.camUI));
		}

		debugKeys();

		var projectiles = live(combat.slice.slices.countLiving()) + live(director.shots.countLiving())
			+ live(combat.bow.arrows.countLiving()) + live(combat.bow.rain.arrows.countLiving())
			+ (combat.throwAttack.airborne ? 1 : 0) + (combat.hookAttack.hook.exists ? 1 : 0);
		perf.frame(director.enemyCount(), EnemyNav.usedBudget(), projectiles, director.wave);
	}

	function live(n:Int):Int
		return n < 0 ? 0 : n;

	function onWaveStarted(n:Int):Void
	{
		SaveData.submitWave(n);
		hud.showWave(n);
		shift.onWave(n);
	}

	function onBossWave():Void
	{
		bossFight = true;
		shift.locked = true;
		shift.forceRevert();
		shift.cancelArrival();
		arena.beginBossTransition();
		arena.onWhiteout = onBossWhiteout;
		hud.showBoss();
		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(2.4, 0);
		bossAlarm = FlxG.sound.play(Paths.sound("boss_alarm"), 0.7);
	}

	function onBossWhiteout():Void
	{
		showDecor(false);
		shift.clearTotem();
		hud.fadeBanner();
		if (bossAlarm != null)
			bossAlarm.fadeOut(0.8, 0, function(_)
			{
				if (bossAlarm != null)
				{
					bossAlarm.stop();
					bossAlarm = null;
				}
			});
		Music.play("biggestBandit", 0.5);
		FlxTween.tween(FlxG.camera, {zoom: 0.8}, 1.2);
	}

	function onBossDefeated():Void
	{
		bossFight = false;
		arena.endBossTransition();
		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.6, 0);
	}

	function onNetDropped():Void
	{
		hud.showBanner("CONNECTION LOST");
		if (Net.isClient)
		{
			new flixel.util.FlxTimer().start(1.4, function(_)
			{
				Net.stop();
				wipe.close(function()
				{
					FlxG.mouse.visible = true;
					FlxG.switchState(new MainMenuState());
				});
			});
		}
	}

	function onArenaNormal():Void
	{
		showDecor(true);
		if (!Net.active)
			shift.locked = false;
		shift.restoreTotem();
		Music.play("stage/gloomDoomWoods", 0.3);
		FlxTween.tween(FlxG.camera, {zoom: 1}, 0.8);
	}

	function debugKeys():Void
	{
		if (FlxG.keys.justPressed.MINUS)
			FlxG.sound.changeVolume(-0.1);

		if (FlxG.keys.justPressed.PLUS)
			FlxG.sound.changeVolume(0.1);

		if (FlxG.keys.justPressed.FIVE)
		{
			status.health = 0;
			status.itemBar = 0;
		}

		if (FlxG.keys.justPressed.SIX)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;

		if (FlxG.keys.justPressed.F4)
		{
			status.revive();
			layers.playerShadow.visible = true;
			scythe.visible = true;
			hud.hideDeath();
		}

		if (FlxG.keys.justPressed.R && status.dead && !restarting && (!Net.active || (netSync != null && netSync.runFailed)))
		{
			if (netSync != null)
				netSync.requestRestart();
			beginRestart();
		}
	}
}
