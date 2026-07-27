package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import entities.Player;
import entities.enemy.EnemyNav;
import systems.world.Arena;
import systems.Fx;
import systems.RenderLayers;
import systems.PlayerCombat;
import systems.enemy.EnemyDirector;
import systems.TimeStop;
import systems.perspective.PerspectiveShift;
import systems.weapons.Weapons;
import systems.Pickups;
import ui.Hud;
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
	static inline var CURSOR_LEAN:Float = 1.0;
	static inline var DEFLECT_RADIUS:Float = 45;
	static inline var DEFLECT_DAMAGE:Int = 1;
	static inline var DEFLECT_PUSH:Float = 1.2;

	private var fx:Fx;
	private var arena:Arena;
	private var _player:Player;
	private var heldSprite:FlxSprite;
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
	private var props:systems.world.PropWorld;
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
		WorldClock.reset();
		persistentUpdate = Net.active;
		fx = new Fx();

		FlxG.camera.bgColor = 0xFFFFFFFF;

		arena = new Arena(this);

		_player = new Player(arena.spawnX, arena.spawnY);

		FlxG.camera.follow(_player);
		FlxG.camera.followLerp = 0.1;
		FlxG.camera.setScrollBoundsRect(0, 0, arena.width, arena.height);
		FlxG.camera.zoom = 1;

		heldSprite = new FlxSprite(0, 0, Paths.image("items/hammer"));
		heldSprite.scale.set(4, 4);
		heldSprite.origin.set(heldSprite.width * 0.5, heldSprite.height);
		heldSprite.x = _player.x - heldSprite.origin.x + 30;
		heldSprite.y = _player.y - heldSprite.origin.y + 65;

		floor = systems.world.DecorTiles.build(util.CustomArena.tiles, util.CustomArena.tileset);
		if (floor != null)
			add(floor);

		layers = new RenderLayers(this, _player, heldSprite);
		arena.addPillars(layers.entityLayer);
		props = new systems.world.PropWorld(_player, layers);
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
		combat = new Weapons(_player, heldSprite, arena, director, status, fx, pickups);

		add(combat.swing.slashes);
		add(combat.jab.slashes);
		add(combat.bow.arrows);
		add(combat.revolver.bullets);
		insert(members.indexOf(layers.entityLayer), combat.bow.rain.markers);
		insert(members.indexOf(layers.entityLayer), combat.shock.cracks);
		insert(members.indexOf(layers.entityLayer), combat.shock.rings);
		add(combat.bow.rain.arrows);
		add(combat.arrowStorm.trail.group);
		add(combat.arrowStorm.superArrow);
		add(combat.hookAttack.rope);
		add(combat.hookAttack.hook);
		insert(members.indexOf(layers.entityLayer), combat.hookArms.backGroup);
		add(combat.hookArms.frontGroup);
		add(combat.throwAttack.trail.group);
		add(combat.throwAttack.thrown);
		insert(members.indexOf(layers.entityLayer), combat.superOrbit.trail.group);
		insert(members.indexOf(layers.entityLayer), combat.superOrbit.backLayer);
		add(combat.superOrbit.frontLayer);
		add(fx.sparks);
		add(director.shots);

		add(props.overlay);

		add(timeStop.overlay);
		add(combat.deadEye.overlay);
		add(combat.deadEye.markers);

		hud = new Hud(this, status);
		shift = new PerspectiveShift(arena, _player, director, combat, layers);
		shift.disabled = true;
		director.onProbe = shift.onProbe;
		director.onWave = onWaveStarted;
		director.onBoss = onBossWave;
		director.onBossSpawn = hud.showBossBar;
		director.onBossDefeated = onBossDefeated;
		director.onFriendlyShot = onDeflectedShot;
		arena.onNormal = onArenaNormal;
		perf = new PerfLog();

		if (Net.active)
		{
			shift.locked = true;
			Net.inGame = true;
			netSync = new NetSync(_player, status, arena, layers, director, combat, pickups, hud, heldSprite);
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

		updateCameraLean();

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
			heldSprite.visible = false;
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
		heldSprite.alpha = props.buried ? 0 : 1;
		combat.swing.slashes.visible = !props.buried;
		combat.jab.slashes.visible = !props.buried;
		if (!frozen && !inputLocked)
			combat.update(elapsed);
		director.updateShots();
		if (netSync != null)
			netSync.update(elapsed);
		hud.setGauge(combat.bow.rainCharge, combat.weapon == 2);
		hud.setAmmo(combat.revolver.rounds, combat.revolver.capacity, combat.revolver.isReloading, combat.weapon == 1);
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

		var projectiles = live(director.shots.countLiving()) + live(combat.revolver.bullets.countLiving())
			+ live(combat.bow.arrows.countLiving()) + live(combat.bow.rain.arrows.countLiving())
			+ (combat.throwAttack.airborne ? 1 : 0) + (combat.hookAttack.hook.exists ? 1 : 0);
		perf.frame(director.enemyCount(), EnemyNav.usedBudget(), projectiles, director.wave);
	}

	function updateCameraLean():Void
	{
		var sx = FlxG.mouse.x - FlxG.camera.scroll.x - FlxG.width * 0.5;
		var sy = FlxG.mouse.y - FlxG.camera.scroll.y - FlxG.height * 0.5;
		FlxG.camera.targetOffset.set(sx * CURSOR_LEAN, sy * CURSOR_LEAN);
	}

















	function live(n:Int):Int
		return n < 0 ? 0 : n;



	function onDeflectedShot(shot:entities.enemy.EnemyShot):Bool
	{
		var hit = director.firstInCircle(shot.x + shot.width / 2, shot.y + shot.height / 2, DEFLECT_RADIUS);
		if (hit == null)
			return false;
		combat.hits.damageN(hit, shot.dirX * DEFLECT_PUSH, shot.dirY * DEFLECT_PUSH, DEFLECT_DAMAGE);
		return true;
	}

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
			heldSprite.visible = true;
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
