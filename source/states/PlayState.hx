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
	public static inline var BASE_ZOOM:Float = 0.75;
	public static var cursorLean:Float = 0.5;

	static inline var FOLLOW_LERP:Float = 0.055;
	static inline var DEFLECT_RADIUS:Float = 45;
	static inline var DEFLECT_DAMAGE:Int = 1;
	static inline var DEFLECT_PUSH:Float = 1.2;
	static inline var SHIELD_DAMAGE:Int = 1;
	static inline var SHIELD_PUSH:Float = 0.15;

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
	private var gate:states.play.ReadyGate;
	private var quiet:states.play.QuietRoom;
	private var boss:states.play.BossShow;
	private var intro:states.play.RunIntro;
	private var perf:PerfLog;
	private var timeStop:TimeStop;
	private var burst:systems.DeathBurst;
	private var ghost:systems.CoopGhost;
	private var ritual:systems.ReviveRitual;
	private var backGear:systems.BackGear;
	private var boxes:systems.HitboxView;
	private var wipe:IrisWipe;
	public var restarting(default, null):Bool = false;
	private var hadSub:Bool = false;

	function setRestarting():Void
		restarting = true;

	function canPause():Bool
		return !status.dead && subState == null && !restarting;

	function openPause():Void
	{
		DiscordPresence.paused();
		var pause = new PauseSubState(hud.camUI);
		pause.closeCallback = function()
		{
			if (Lang.consumeChanged())
				hud.applyLanguage(director.wave);
			_player.setHue(SaveData.playerHue());
			combat.repaint();
			backGear.paint(SaveData.playerHue());
		};
		openPanel(pause);
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		if (!Net.active && canPause())
			openPause();
	}

	public function openPanel(sub:flixel.FlxSubState):Void
	{
		fx.clearHitstop();
		FlxG.keys.reset();
		openSubState(sub);
	}

	static inline var WHITE_OUT:Float = 1.2;

	public function warnInto(go:Void->Void):Void
	{
		if (restarting)
			return;
		setRestarting();
		director.spawning = false;
		boss.warn(go);
	}

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
		util.Detour.abandon();
		wipe.close(function() FlxG.resetState());
	}

	override public function create()
	{
		if (!util.Detour.resuming() && !util.Detour.inRoom)
		{
			util.Levels.startRun();
			util.Run.reroll();
			states.play.QuietRoom.rollTrack();
			systems.TreeMan.reset();
		}
		WorldClock.reset();
		persistentUpdate = Net.active;
		fx = new Fx();

		FlxG.camera.bgColor = 0xFFFFFFFF;

		arena = new Arena(this);

		_player = new Player(arena.spawnX, arena.spawnY);

		FlxG.camera.follow(_player);
		FlxG.camera.followLerp = FOLLOW_LERP;
		FlxG.camera.setScrollBoundsRect(0, 0, arena.width, arena.height);
		FlxG.camera.zoom = BASE_ZOOM;

		heldSprite = new FlxSprite(0, 0, Paths.image("items/hammer"));
		heldSprite.scale.set(4, 4);
		heldSprite.origin.set(heldSprite.width * 0.5, heldSprite.height);
		heldSprite.x = _player.x - heldSprite.origin.x + 10;
		heldSprite.y = _player.y - heldSprite.origin.y + 1;

		floor = systems.world.DecorTiles.build(util.CustomArena.tiles, util.CustomArena.tileset);
		if (floor != null)
			add(floor);

		layers = new RenderLayers(this, _player, heldSprite);
		arena.addPillars(layers.entityLayer);
		props = new systems.world.PropWorld(_player, layers);
		add(props.solids);

		round = new states.play.ShopRound(this, _player, layers);
		gate = new states.play.ReadyGate(this, _player, layers);
		quiet = new states.play.QuietRoom(this, _player);
		if (!util.CustomArena.quiet)
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
		burst = new systems.DeathBurst();
		insert(members.indexOf(layers.entityLayer), burst.group);
		ghost = new systems.CoopGhost();
		insert(members.indexOf(layers.entityLayer), ghost.sprite);
		ritual = new systems.ReviveRitual(burst, ghost);
		backGear = new systems.BackGear();
		backGear.paint(SaveData.playerHue());
		layers.entityLayer.add(backGear.sprite);
		insert(members.indexOf(layers.entityLayer), fx.dashTrail);
		insert(members.indexOf(layers.entityLayer), fx.steam);
		insert(members.indexOf(layers.entityLayer), timeStop.shadowTrail.group);
		insert(members.indexOf(layers.entityLayer), timeStop.trail.group);
		director = Net.isClient ? new PuppetDirector(_player, arena, layers, status, fx) : new EnemyDirector(_player, arena, layers, status, fx);
		director.solids = props.solids;
		combat = new Weapons(_player, heldSprite, arena, director, status, fx, pickups, scraps);

		add(combat.swing.slashes);
		add(combat.bash.slashes);
		add(combat.gigaSwing.slashes);
		add(combat.yoyoJab.flight.string);
		add(combat.yoyoJab.flight.yoyo);
		insert(members.indexOf(layers.entityLayer), combat.revolver.twinSprite);
		insert(members.indexOf(layers.entityLayer), combat.arrowStorm.marker);
		insert(members.indexOf(layers.entityLayer), combat.bow.rain.markers);
		add(combat.arrowStorm.trail.group);
		add(combat.arrowStorm.superArrow);
		add(combat.hookAttack.rope);
		add(combat.hookAttack.hook);
		add(fx.sparks);
		add(fx.pops);
		add(fx.bursts);

		add(props.overlay);

		reloadBar = new ui.ReloadBar(_player);
		add(reloadBar.group);

		if (petals != null)
			add(petals.group);

		add(timeStop.overlay);

		boxes = new systems.HitboxView();
		add(boxes.group);

		hud = new Hud(this, status);
		round.wire(status, director, hud);
		gate.wire(status, director, hud);
		gate.blocked = round.shop.inReach;
		gate.onCommit = round.shutShop;
		boss = new states.play.BossShow(arena, hud, props, round, scraps, pickups, floor);
		intro = new states.play.RunIntro(this, combat, hud);
		add(intro.flyIn.sprite);
		director.onWave = onWaveStarted;
		director.onWaveCleared = onWaveCleared;
		director.onBoss = boss.begin;
		director.onBossPack = hud.showBossBar;
		director.onBossDefeated = boss.defeated;
		director.onBossDrops = boss.dropLoot;
		director.onFriendlyShot = onDeflectedShot;
		director.onShieldShot = onShieldedShot;
		director.bossVeto = function(w) return quiet.tryDetour(w, director, status, combat);
		perf = new PerfLog();

		_player.setHue(SaveData.playerHue());

		if (Net.active)
		{
			Net.inGame = true;
			netSync = new NetSync(_player, status, arena, layers, director, combat, pickups, scraps, hud, heldSprite);
			netSync.makeFx = function(av) return new net.RemoteFx(this, layers, director, combat.hits, fx, av);
			round.useNet(netSync);
			round.onLostPeer = gate.peerLost;
			gate.useNet(netSync);
			netSync.onWaveEvt = onWaveStarted;
			netSync.onBossEvt = boss.begin;
			netSync.onBossDefeatedEvt = boss.defeated;
			netSync.onDropped = onNetDropped;
			netSync.startRevive = ritual.begin;
			netSync.reviveDone = function() return ritual.done;
		netSync.onRestart = beginRestart;
		}

		DiscordPresence.beginRun();

		combat.equip(WeaponPickSubState.lastPick);
		var resumed = util.Detour.resuming();
		if (resumed)
			util.Detour.restore(status, combat, director);

		if (util.CustomArena.quiet)
		{
			round.shop.setVisible(false);
			quiet.enter(combat, director, heldSprite, hud);
		}
		else
		{
			if (resumed)
				hud.showWave(director.wave);
			else if (Net.active)
				intro.openTutorialIfNew();
			else
				intro.openWeaponPick();
			if (!Net.isClient)
				gate.arm();
		}

		Music.play(states.play.QuietRoom.track(), 0.3);

		arena.raiseWhite(this);

		wipe = new IrisWipe(this);
		if (util.Detour.consumeWhite())
		{
			wipe.visible = false;
			arena.fadeFromWhite(WHITE_OUT);
		}
		else
			wipe.open();

		super.create();
	}

	override public function destroy():Void
	{
		if (hud != null)
			hud.dispose();
		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		EnemyNav.resetBudget();


		var inputLocked = Net.active && subState != null;

		util.Controls.setAimAnchor(_player.x + _player.width * 0.5, _player.y + _player.height * 0.5);
		updateCameraLean();

		super.update(elapsed);

		var nowSub = subState != null;
		if (hadSub && !nowSub)
			util.Controls.pinFire();
		hadSub = nowSub;

		fx.update();
		var step = elapsed * WorldClock.scale;
		arena.update(step);

		if (!status.dead)
		{
			systems.world.CircleCollide.resolve(_player, _player.hitRadius, arena.map, props.solids);
		}
		director.collide();

		status.update(elapsed);

		if (status.consumeJustDied())
			intro.drop();

		if (status.consumeJustBurst())
		{
			layers.playerShadow.visible = false;
			heldSprite.visible = false;
			_player.visible = false;
			burst.burst(_player.x + _player.width * 0.5, _player.y + _player.height * 0.5, SaveData.playerHue(), _player.flipX);
			if (Net.active)
				ghost.show(_player.x + _player.width * 0.5, _player.y + _player.height * 0.5, SaveData.playerHue());
			else
			{
				hud.showDeath(director.wave, SaveData.bestWave());
				DiscordPresence.died(director.wave, SaveData.bestWave());
			}
		}

		if (!status.dead)
		{
			if (burst.any())
				burst.clear();
			if (ghost.sprite.exists)
				ghost.hide();
			ritual.cancel();
		}
		burst.update(elapsed);
		ritual.update(elapsed, _player.x + _player.width * 0.5, _player.y + _player.height * 0.5);
		if (ghost.sprite.exists)
			ghost.track(_player.x + _player.width * 0.5, _player.y + _player.height * 0.5, _player.flipX);
		ghost.update(elapsed);
		backGear.update(elapsed, _player.x + _player.width * 0.5, _player.y - 21, _player.flipX,
			systems.BackGear.leanFor(_player.animation.name), _player.visible);

		director.update(step);
		pickups.update();
		scraps.update(elapsed);
		layers.adopt(cast director.shots);
		layers.adopt(cast combat.revolver.bullets);
		layers.adopt(cast combat.bow.arrows);
		layers.adopt(cast combat.bow.rain.arrows);
		layers.adopt(cast combat.throwAttack.trail.group);
		layers.adoptOne(combat.throwAttack.thrown);
		layers.update();
		props.update();
		drawBoxes();
		bushes.update(step);
		round.updateShop(elapsed);
		if (petals != null)
			petals.update(step);
		heldSprite.alpha = props.buried ? 0 : 1;
		combat.swing.slashes.visible = !props.buried;
		combat.gigaSwing.slashes.visible = !props.buried;
		combat.yoyoJab.flight.string.visible = !props.buried;
		combat.yoyoJab.flight.yoyo.visible = !props.buried;
		if (!inputLocked)
			combat.update(elapsed);
		director.updateShots();
		if (netSync != null)
			netSync.update(elapsed);
		hud.setAmmo(combat.revolver.displayRounds, combat.revolver.capacity, combat.revolver.isReloading, combat.weapon == 1);
		hud.setTwinAmmo(combat.revolver.displayTwinRounds, combat.revolver.capacity, combat.weapon == 1 && combat.revolver.twinActive);
		hud.setBowLoaded(!combat.bow.recovering, combat.weapon == 2);
		var recharging = combat.weapon == 1 ? combat.revolver.isReloading
			: combat.weapon == 2 ? combat.bow.recovering
			: combat.weapon == 3 ? combat.yoyoJab.recovering
			: combat.swing.recovering;
		var rechargeAt = combat.weapon == 1 ? combat.revolver.reloadProgress
			: combat.weapon == 2 ? combat.bow.recoverProgress
			: combat.weapon == 3 ? combat.yoyoJab.recoverProgress
			: combat.swing.recoverProgress;
		reloadBar.update(recharging && !combat.disabled && !status.dead, rechargeAt);
		hud.setShown(SaveData.showHud());
		hud.setExp(util.Levels.exp);
		hud.update(elapsed);
		intro.update(elapsed);

		if (subState == null && !status.dead)
			DiscordPresence.playing(director.wave, boss.fighting, combat.weapon, status.kills);

		if (util.Controls.pausePressed() && canPause())
			openPause();

		round.updateHold(elapsed);
		gate.update(elapsed);
		quiet.update(elapsed);
		debugKeys();

		var projectiles = live(director.shots.countLiving()) + live(combat.revolver.bullets.countLiving())
			+ live(combat.bow.arrows.countLiving()) + live(combat.bow.rain.arrows.countLiving())
			+ (combat.throwAttack.airborne ? 1 : 0) + (combat.hookAttack.hook.exists ? 1 : 0);
		perf.frame(director.enemyCount(), EnemyNav.usedBudget(), projectiles, director.wave);
	}

	function updateCameraLean():Void
	{
		var sx = util.Controls.aimX() - FlxG.camera.scroll.x - FlxG.width * 0.5;
		var sy = util.Controls.aimY() - FlxG.camera.scroll.y - FlxG.height * 0.5;
		FlxG.camera.targetOffset.set(sx * cursorLean, sy * cursorLean);
	}

	function live(n:Int):Int
		return n < 0 ? 0 : n;

	function onDeflectedShot(shot:entities.enemy.EnemyShot):Bool
	{
		var hit = director.firstInCircle(shot.x + shot.width / 2, shot.y + shot.height / 2, DEFLECT_RADIUS);
		if (hit == null)
			return false;
		if (shot.superTurned)
			combat.hits.damageSuper(hit, shot.dirX * DEFLECT_PUSH, shot.dirY * DEFLECT_PUSH, DEFLECT_DAMAGE);
		else
			combat.hits.damageN(hit, shot.dirX * DEFLECT_PUSH, shot.dirY * DEFLECT_PUSH, DEFLECT_DAMAGE);
		return true;
	}

	function onShieldedShot(shot:entities.enemy.EnemyShot):Bool
	{
		var e = director.seizedAt(shot);
		if (e == null)
			return false;
		combat.hits.damageN(e, shot.dirX * SHIELD_PUSH, shot.dirY * SHIELD_PUSH, SHIELD_DAMAGE);
		return true;
	}

	function onWaveStarted(n:Int):Void
	{
		SaveData.submitWave(n);
		hud.showWave(n);
	}

	function onWaveCleared():Void
	{
		round.onWaveCleared();
		var rest = director.wave % systems.Shop.EVERY == 0 || director.isBossWave(director.wave);
		if (rest && !Net.isClient)
			gate.arm();
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
					FlxG.switchState(() -> new MainMenuState());
				});
			});
		}
	}

	function drawBoxes():Void
	{
		if (!boxes.on)
			return;

		boxes.clear();
		boxes.circle(_player.x + _player.width * 0.5, _player.y + _player.height * 0.5, _player.hitRadius,
			systems.HitboxView.BODY);
		boxes.span(_player.x, _player.feetY, _player.width, systems.HitboxView.FEET);

		var reach = combat.meleeShown;
		if (reach > 0)
		{
			var pmx = _player.x + _player.width * 0.5;
			var pmy = _player.y + _player.height * 0.5 - combat.meleeLift;
			var rdx = util.Controls.aimX() - pmx;
			var rdy = util.Controls.aimY() - pmy;
			var rlen = Math.sqrt(rdx * rdx + rdy * rdy);
			if (rlen > 0.001)
			{
				var push = combat.meleePush;
				boxes.ray(pmx + rdx / rlen * push, pmy + rdy / rlen * push, rdx / rlen, rdy / rlen, reach,
					systems.HitboxView.REACH);
			}
		}

		for (e in director.bodies.members)
			if (e != null && e.exists && e.alive)
			{
				boxes.circle(e.x + e.width * 0.5, e.y + e.height * 0.5, e.hitRadius, systems.HitboxView.FOE);
				boxes.span(e.x, e.feetY, e.width, systems.HitboxView.FEET);
			}

		for (b in director.shots.members)
			if (b != null && b.exists)
				boxes.circle(b.x + b.width * 0.5, b.y + b.height * 0.5, b.width * 0.5, systems.HitboxView.FOE);

		for (s in props.solids.members)
			if (s != null && s.exists)
				boxes.box(s.x, s.y, s.width, s.height, systems.HitboxView.SOLID);

		for (p in pickups.group.members)
			if (p != null && p.exists)
				boxes.box(p.x, p.y, p.width, p.height, systems.HitboxView.LOOT);

		for (s in scraps.group.members)
			if (s != null && s.exists)
				boxes.box(s.x, s.y, s.width, s.height, systems.HitboxView.LOOT);
	}

	function debugKeys():Void
	{
		if (FlxG.keys.justPressed.MINUS)
			FlxG.sound.changeVolume(-0.1);

		if (FlxG.keys.justPressed.PLUS)
			FlxG.sound.changeVolume(0.1);

		#if debug
		if (FlxG.keys.justPressed.FIVE)
		{
			status.health = 0;
			status.superMeter = 0;
		}

		if (FlxG.keys.justPressed.SIX)
			boxes.toggle();

		if (FlxG.keys.justPressed.F4)
		{
			status.revive();
			layers.playerShadow.visible = true;
			heldSprite.visible = true;
			hud.hideDeath();
		}
		#end

		if (util.Controls.justPressed(util.Controls.RELOAD) && status.dead && !restarting && (!Net.active || (netSync != null && netSync.runFailed)))
		{
			if (netSync != null)
				netSync.requestRestart();
			beginRestart();
		}
	}
}
