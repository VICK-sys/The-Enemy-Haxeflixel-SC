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
import systems.weapons.Weapons;
import systems.Pickups;
import systems.Scraps;
import ui.Hud;
import util.Paths;
import util.SaveData;
import util.PerfLog;
import util.Music;
import util.IrisWipe;
import util.WorldClock;
import util.DiscordPresence;
import net.Net;
import net.NetSync;
import net.PuppetDirector;
import util.Lang;

class PlayState extends FlxState
{
	static inline var CURSOR_LEAN:Float = 1.0;
	static inline var QUIET_PLAYER_SCALE:Float = 1.5;
	static inline var QUIET_ZOOM:Float = 0.7;
	static inline var EXIT_ARM_UP:Float = 240;
	static inline var EXIT_BACK:Float = 40;
	static inline var LEVEL_WAIT_CAP:Float = 60;
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
	private var scraps:Scraps;
	private var director:EnemyDirector;
	private var combat:Weapons;
	private var hud:Hud;
	private var reloadBar:ui.ReloadBar;
	private var shop:systems.Shop;
	private var levelHold:Bool = false;
	private var levelDone:Bool = false;
	private var levelClock:Float = 0;
	private var levelAcks:Map<Int, Bool>;
	private var perf:PerfLog;
	private var bossAlarm:FlxSound;
	private var bossFight:Bool = false;
	private var timeStop:TimeStop;
	private var wipe:IrisWipe;
	private var restarting:Bool = false;
	private var netSync:NetSync;
	private var props:systems.world.PropWorld;
	private var floor:flixel.tile.FlxTilemap;
	private var flyIn:ui.WeaponFlyIn;
	private var flyPick:Int = -1;
	private var flyX:Float = 0;
	private var flyY:Float = 0;
	private var exitFrom:Float = 0;
	private var exitArmed:Bool = false;
	private var watchExit:Bool = false;
	private var treeMan:systems.TreeMan;
	private var bushes:systems.BushDrift;
	private var petals:systems.PetalFall;

	function tryDetour(bossWave:Int):Bool
	{
		if (!util.Detour.rolls())
			return false;
		if (!util.Detour.begin(director.wave, bossWave, status.health, status.superMeter, status.kills, combat.weapon))
			return false;
		restarting = true;
		wipe.close(function() FlxG.switchState(new PlayState()));
		return true;
	}

	function updateDetour(elapsed:Float):Void
	{
		if (treeMan != null)
			treeMan.update(elapsed);

		if (!watchExit || restarting)
			return;
		if (treeMan != null && treeMan.talking)
			return;

		var up = exitFrom - _player.feetY;
		if (up > EXIT_ARM_UP)
			exitArmed = true;
		if (!exitArmed || up > EXIT_BACK)
			return;

		watchExit = false;
		util.Detour.leave();
		restarting = true;
		wipe.close(function() FlxG.switchState(new PlayState()));
	}

	function addTreeMan():Void
	{
		for (p in util.CustomArena.props)
			if (p.n == "tree")
			{
				treeMan = new systems.TreeMan(this, hud.camUI, _player, p.x, p.y);
				return;
			}
	}

	function stageTrack():String
		return util.CustomArena.quiet ? "stage/Man_music" : "stage/gloomDoomWoods";

	function showDecor(on:Bool):Void
	{
		props.setDecorVisible(on);
		shop.setVisible(on);
		if (floor != null)
			floor.visible = on;
	}

	function beginRestart():Void
	{
		if (restarting)
			return;
		restarting = true;
		util.Detour.reset();
		util.Levels.startRun();
		wipe.close(function() FlxG.resetState());
	}

	override public function create()
	{
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

		shop = new systems.Shop(_player, layers);
		for (s in shop.solid())
			props.solids.add(s);

		bushes = new systems.BushDrift();
		for (s in props.named("treeBush"))
			bushes.add(s, false);
		for (s in props.named("treeBush2"))
			bushes.add(s, true);

		for (s in props.named("treeBush2"))
		{
			petals = new systems.PetalFall(s, "props/treeBush2");
			break;
		}

		status = new PlayerCombat(_player, fx);
		timeStop = new TimeStop(_player, layers.playerShadow, status);
		pickups = new Pickups(_player, status);
		insert(members.indexOf(layers.entityLayer), pickups.group);
		scraps = new Scraps(_player, status, layers.shadowLayer);
		insert(members.indexOf(layers.entityLayer), scraps.group);
		insert(members.indexOf(layers.entityLayer), fx.dashTrail);
		insert(members.indexOf(layers.entityLayer), timeStop.shadowTrail.group);
		insert(members.indexOf(layers.entityLayer), timeStop.trail.group);
		director = Net.isClient ? new PuppetDirector(_player, arena, layers, status) : new EnemyDirector(_player, arena, layers, status);
		director.solids = props.solids;
		combat = new Weapons(_player, heldSprite, arena, director, status, fx, pickups, scraps);

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

		reloadBar = new ui.ReloadBar(_player);
		add(reloadBar.group);

		if (petals != null)
			add(petals.group);

		add(timeStop.overlay);
		add(combat.deadEye.overlay);
		add(combat.deadEye.markers);

		hud = new Hud(this, status);
		shop.addTo(this);
		shop.onEnter = enterShop;
		shop.onClose = releaseShopHold;
		flyIn = new ui.WeaponFlyIn(hud.camUI, combat.held);
		add(flyIn.sprite);
		director.onWave = onWaveStarted;
		director.onWaveCleared = onRoundCleared;
		director.onBoss = onBossWave;
		director.onBossSpawn = hud.showBossBar;
		director.onBossDefeated = onBossDefeated;
		director.onFriendlyShot = onDeflectedShot;
		director.bossVeto = tryDetour;
		arena.onNormal = onArenaNormal;
		perf = new PerfLog();

		if (Net.active)
		{
			Net.inGame = true;
			netSync = new NetSync(_player, status, arena, layers, director, combat, pickups, scraps, hud, heldSprite);
			netSync.makeFx = function(av) return new net.RemoteFx(this, layers, director, combat.hits, fx, av);
			netSync.onLevelOpen = beginLevelUp;
			netSync.onLevelAck = noteLevelAck;
			netSync.onLevelGo = releaseLevelUp;
			netSync.onWaveEvt = onWaveStarted;
			netSync.onBossEvt = onBossWave;
			netSync.onBossDefeatedEvt = onBossDefeated;
			netSync.onDropped = onNetDropped;
		netSync.onRestart = beginRestart;
		}

		DiscordPresence.beginRun();

		combat.equip(WeaponPickSubState.lastPick);
		var resumed = util.Detour.resuming();
		if (resumed)
			util.Detour.restore(status, combat, director);

		if (util.CustomArena.quiet)
		{
			combat.disabled = true;
			director.spawning = false;
			heldSprite.visible = false;
			_player.setSizeScale(QUIET_PLAYER_SCALE);
			FlxG.camera.zoom = QUIET_ZOOM;
			addTreeMan();
			if (util.Detour.inRoom)
			{
				watchExit = true;
				exitArmed = false;
				exitFrom = _player.feetY;
			}
		}
		else if (resumed)
			hud.showWave(director.wave);
		else if (Net.active)
			openTutorialIfNew();
		else
			openWeaponPick();

		Music.play(stageTrack(), 0.3);

		wipe = new IrisWipe(this);
		wipe.open();

		super.create();
	}

	function openWeaponPick():Void
	{
		var picker = new WeaponPickSubState(hud.camUI);
		picker.onPicked = function(i)
		{
			combat.equip(i);
			flyPick = i;
			flyX = picker.pickedX;
			flyY = picker.pickedY;
		};
		picker.closeCallback = openTutorialIfNew;
		openSubState(picker);
	}

	function openTutorialIfNew():Void
	{
		if (TutorialSubState.shown || Net.active)
		{
			startFlyIn();
			return;
		}
		TutorialSubState.shown = true;
		var tutorial = new TutorialSubState(hud.camUI);
		tutorial.closeCallback = startFlyIn;
		openSubState(tutorial);
		DiscordPresence.tutorial();
	}

	function startFlyIn():Void
	{
		if (flyPick < 0)
			return;
		flyIn.begin(WeaponPickSubState.artOf(flyPick), flyX, flyY);
		flyPick = -1;
	}

	override public function update(elapsed:Float):Void
	{
		EnemyNav.resetBudget();

		var inputLocked = Net.active && subState != null;

		updateCameraLean();

		if (!Net.active)
			timeStop.update(elapsed);

		super.update(elapsed);

		fx.update();
		arena.update(elapsed * timeStop.factor);

		FlxG.collide(_player, arena.map);
		props.collidePlayer();
		director.collide();

		status.update(elapsed);

		if (status.consumeJustDied())
		{
			layers.playerShadow.visible = false;
			flyIn.drop();
			heldSprite.visible = false;
			if (!Net.active)
			{
				hud.showDeath(director.wave, SaveData.bestWave());
				DiscordPresence.died(director.wave, SaveData.bestWave());
			}
		}

		director.update(elapsed * timeStop.factor);
		pickups.update();
		scraps.update(elapsed);
		layers.update();
		props.update();
		bushes.update(elapsed);
		shop.update(elapsed);
		if (petals != null)
			petals.update(elapsed);
		heldSprite.alpha = props.buried ? 0 : 1;
		combat.swing.slashes.visible = !props.buried;
		combat.jab.slashes.visible = !props.buried;
		if (!inputLocked)
			combat.update(elapsed);
		director.updateShots();
		if (netSync != null)
			netSync.update(elapsed);
		hud.setGauge(combat.bow.rainCharge, combat.weapon == 2);
		hud.setAmmo(combat.revolver.displayRounds, combat.revolver.capacity, combat.revolver.isReloading, combat.weapon == 1);
		reloadBar.update(combat.weapon == 1 && !combat.disabled && !status.dead && combat.revolver.isReloading, combat.revolver.reloadProgress);
		hud.setExp(util.Levels.exp);
		hud.setTimeStop(Net.active ? Lang.t("timestop.off") : timeStop.hudLabel());
		hud.setStopTimer(Net.active ? "" : timeStop.timerLabel());
		hud.update(elapsed);
		flyIn.update(elapsed);

		if (subState == null && !status.dead)
			DiscordPresence.playing(director.wave, bossFight, combat.weapon, status.kills);

		if (FlxG.keys.justPressed.ESCAPE && !status.dead && subState == null)
		{
			DiscordPresence.paused();
			var pause = new PauseSubState(hud.camUI);
			pause.closeCallback = function()
			{
				if (Lang.consumeChanged())
					hud.applyLanguage(director.wave);
			};
			openSubState(pause);
		}

		updateLevelPause(elapsed);
		updateDetour(elapsed);
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

	function onRoundCleared():Void
	{
		if (director.wave <= 0 || director.wave % systems.Shop.EVERY != 0)
			return;
		shop.setOpen(true);
		hud.showBanner(Lang.t("shop.open"));
		if (!Net.active || Net.isHost)
			director.holdWave = true;
	}

	function enterShop():Void
	{
		if (!shop.open)
			return;
		if (offerLevelUp())
			shop.dismiss();
	}

	function syncScrap():Void
		hud.setExp(util.Levels.exp);

	function releaseShopHold():Void
	{
		if (!Net.active || Net.isHost)
			director.holdWave = false;
	}

	function offerLevelUp():Bool
	{
		if (status.dead || restarting || subState != null || levelHold)
			return false;

		if (Net.active)
		{
			if (!Net.isHost)
				return false;
			Net.send({t: "lvl"});
			beginLevelUp();
			return true;
		}

		FlxG.inputs.reset();
		var screen = new LevelUpSubState(hud.camUI);
		screen.onSpent = syncScrap;
		screen.closeCallback = releaseShopHold;
		openSubState(screen);
		return true;
	}

	function beginLevelUp():Void
	{
		if (levelHold)
			return;
		levelHold = true;
		levelDone = false;
		levelClock = 0;
		levelAcks = new Map();
		if (Net.isHost)
			director.holdWave = true;
		if (netSync != null)
			netSync.setAllLeveling(true);

		if (status.dead || restarting || subState != null || !util.Levels.canSpend())
		{
			finishLevelUp();
			return;
		}

		FlxG.inputs.reset();
		var screen = new LevelUpSubState(hud.camUI);
		screen.onSpent = syncScrap;
		screen.closeCallback = finishLevelUp;
		openSubState(screen);
	}

	function finishLevelUp():Void
	{
		if (!levelHold || levelDone)
			return;
		levelDone = true;
		Net.send({t: "lvldone"});
		if (Net.isHost)
			noteLevelAck(Net.selfId);
	}

	function noteLevelAck(id:Int):Void
	{
		if (netSync != null)
			netSync.setLeveling(id, false);
		if (!Net.isHost || !levelHold || levelAcks == null)
			return;
		levelAcks.set(id, true);
		var got = 0;
		for (v in levelAcks)
			got++;
		if (got >= Net.guestCount + 1)
			releaseLevelUp();
	}

	function releaseLevelUp():Void
	{
		if (!levelHold)
			return;
		if (Net.isHost)
			Net.send({t: "lvlgo"});
		levelHold = false;
		levelAcks = null;
		director.holdWave = false;
		if (netSync != null)
			netSync.setAllLeveling(false);
	}

	function updateLevelPause(elapsed:Float):Void
	{
		if (!levelHold)
			return;
		levelClock += elapsed;
		if (Net.isHost && (levelClock > LEVEL_WAIT_CAP || Net.dropped))
			releaseLevelUp();
	}

	function onWaveStarted(n:Int):Void
	{
		SaveData.submitWave(n);
		if (n > 1)
			util.Levels.award(util.Levels.waveExp() * (n - 1));
		hud.showWave(n);
	}

	function onBossWave():Void
	{
		bossFight = true;
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
		Music.play("batallon_de_las_velas", 0.5);
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
		hud.showBanner(Lang.t("hud.connectionLost"));
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
		Music.play(stageTrack(), 0.3);
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
			status.superMeter = 0;
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
