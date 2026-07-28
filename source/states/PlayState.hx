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
	private var round:states.play.ShopRound;
	private var quiet:states.play.QuietRoom;
	private var boss:states.play.BossShow;
	private var intro:states.play.RunIntro;
	private var perf:PerfLog;
	private var timeStop:TimeStop;
	private var wipe:IrisWipe;
	public var restarting(default, null):Bool = false;

	function setRestarting():Void
		restarting = true;

	/** The one way a panel opens. Clears any hitstop, so none is left frozen behind it. */
	public function openPanel(sub:flixel.FlxSubState):Void
	{
		fx.clearHitstop();
		FlxG.inputs.reset();
		openSubState(sub);
	}

	/** Leave for another state, once, through the iris. */
	public function leaveFor(go:Void->Void):Void
	{
		if (restarting)
			return;
		setRestarting();
		wipe.close(go);
	}
	private var netSync:NetSync;
	private var props:systems.world.PropWorld;
	private var floor:flixel.tile.FlxTilemap;
	private var bushes:systems.BushDrift;
	private var petals:systems.PetalFall;

	function beginRestart():Void
	{
		if (restarting)
			return;
		setRestarting();
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

		round = new states.play.ShopRound(this, _player, layers);
		quiet = new states.play.QuietRoom(this, _player);
		for (s in round.solids())
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
		pickups = new Pickups(_player, status, layers.shadowLayer);
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
		round.wire(status, director, hud);
		boss = new states.play.BossShow(arena, hud, props, round, scraps, pickups, floor);
		intro = new states.play.RunIntro(this, combat, hud);
		add(intro.flyIn.sprite);
		director.onWave = onWaveStarted;
		director.onWaveCleared = round.onWaveCleared;
		director.onBoss = boss.begin;
		director.onBossSpawn = hud.showBossBar;
		director.onBossDefeated = boss.defeated;
		director.onBossDrops = boss.dropLoot;
		director.onFriendlyShot = onDeflectedShot;
		director.bossVeto = function(w) return quiet.tryDetour(w, director, status, combat);
		perf = new PerfLog();

		if (Net.active)
		{
			Net.inGame = true;
			netSync = new NetSync(_player, status, arena, layers, director, combat, pickups, scraps, hud, heldSprite);
			netSync.makeFx = function(av) return new net.RemoteFx(this, layers, director, combat.hits, fx, av);
			round.useNet(netSync);
			netSync.onWaveEvt = onWaveStarted;
			netSync.onBossEvt = boss.begin;
			netSync.onBossDefeatedEvt = boss.defeated;
			netSync.onDropped = onNetDropped;
		netSync.onRestart = beginRestart;
		}

		DiscordPresence.beginRun();

		combat.equip(WeaponPickSubState.lastPick);
		var resumed = util.Detour.resuming();
		if (resumed)
			util.Detour.restore(status, combat, director);

		if (util.CustomArena.quiet)
			quiet.enter(combat, director, heldSprite, hud);
		else if (resumed)
			hud.showWave(director.wave);
		else if (Net.active)
			intro.openTutorialIfNew();
		else
			intro.openWeaponPick();

		Music.play(states.play.QuietRoom.track(), 0.3);

		wipe = new IrisWipe(this);
		wipe.open();

		super.create();
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
			intro.drop();
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
		round.updateShop(elapsed);
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
		var recharging = combat.weapon == 1 ? combat.revolver.isReloading : (combat.weapon == 2 && combat.bow.recovering);
		var rechargeAt = combat.weapon == 1 ? combat.revolver.reloadProgress : combat.bow.recoverProgress;
		reloadBar.update(recharging && !combat.disabled && !status.dead, rechargeAt);
		hud.setExp(util.Levels.exp);
		hud.setTimeStop(Net.active ? Lang.t("timestop.off") : timeStop.hudLabel());
		hud.setStopTimer(Net.active ? "" : timeStop.timerLabel());
		hud.update(elapsed);
		intro.update(elapsed);

		if (subState == null && !status.dead)
			DiscordPresence.playing(director.wave, boss.fighting, combat.weapon, status.kills);

		if (FlxG.keys.justPressed.ESCAPE && !status.dead && subState == null)
		{
			DiscordPresence.paused();
			var pause = new PauseSubState(hud.camUI);
			pause.closeCallback = function()
			{
				if (Lang.consumeChanged())
					hud.applyLanguage(director.wave);
			};
			openPanel(pause);
		}

		round.updateHold(elapsed);
		quiet.update(elapsed);
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
		if (n > 1)
			util.Levels.award(util.Levels.waveExp() * (n - 1));
		hud.showWave(n);
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
