package net;

import flixel.FlxSprite;
import flixel.util.FlxTimer;
import entities.Player;
import entities.enemy.Enemies;
import entities.enemy.EnemyShot;
import systems.world.Arena;
import systems.enemy.EnemyDirector;
import ui.Hud;
import systems.Pickups;
import systems.Scraps;
import systems.PlayerCombat;
import systems.RenderLayers;
import systems.weapons.WeaponMode;
import systems.weapons.Weapons;
import util.SaveData;

class NetSync
{
	static inline var SNAP_FRAMES:Int = 4;
	static inline var RESPAWN_WAVES:Int = 2;
	static inline var STUN_CAP:Float = 3;
	static inline var SHOT_DAMAGE_CAP:Float = 4;
	static inline var SHOT_SPEED_CAP:Float = 4000;
	static inline var SHOT_RANGE_CAP:Float = 100000;
	static inline var DRAG_PULL:Float = 10;

	public var onWaveEvt:Int->Void;
	public var onBossEvt:Void->Void;
	public var onBossDefeatedEvt:Void->Void;
	public var onBossKillEvt:(Float, Float) -> Void;
	public var onDropped:Void->Void;
	public var onRestart:Void->Void;
	public var runFailed(default, null):Bool = false;
	public var makeFx:RemoteAvatar->RemoteFx;

	private var player:Player;
	private var status:PlayerCombat;
	private var arena:Arena;
	private var layers:RenderLayers;
	private var director:EnemyDirector;
	private var combat:Weapons;
	private var pickups:Pickups;
	private var scraps:Scraps;
	private var hud:Hud;
	private var heldSprite:FlxSprite;

	private var roster:PeerRoster;
	private var mirror:PuppetMirror;
	private var frame:Int = 0;
	private var nextEnemyId:Int = 1;
	public var onLevelOpen:Void->Void;
	public var onLevelIn:Int->Void;
	public var onLevelAck:Int->Void;
	public var onLevelGo:Void->Void;
	public var onReady:Int->Void;
	public var onUnready:Int->Void;
	public var onReadyGo:Void->Void;
	public var onReadyArm:Void->Void;

	public var onPeerLost:Int->Void;

	private var deathWave:Int = -1;
	private var deathBoss:Int = -1;
	private var bossBeat:Int = 0;
	private var reviving:Bool = false;
	public var startRevive:Void->Void;
	public var reviveDone:Void->Bool;
	private var droppedHandled:Bool = false;
	private var bossDown:Bool = false;
	private var hitCap:Float = 0;

	public function new(player:Player, status:PlayerCombat, arena:Arena, layers:RenderLayers, director:EnemyDirector,
			combat:Weapons, pickups:Pickups, scraps:Scraps, hud:Hud, heldSprite:FlxSprite)
	{
		this.player = player;
		this.status = status;
		this.arena = arena;
		this.layers = layers;
		this.director = director;
		this.combat = combat;
		this.pickups = pickups;
		this.scraps = scraps;
		this.hud = hud;
		this.heldSprite = heldSprite;

		roster = new PeerRoster(function()
		{
			var av = new RemoteAvatar(layers);
			return new Peer(av, makeFx != null ? makeFx(av) : null);
		});
		if (Net.isClient)
			mirror = new PuppetMirror(director, pickups, scraps, status, hud, layers);

		combat.onAttack = function(mode, pmx, pmy, dx, dy, aimDeg, tx, ty, power, perfect)
			Net.send({
				t: "atk",
				h: perfect ? 1 : 0,
				m: Type.enumIndex(mode),
				x: r1(pmx),
				y: r1(pmy),
				dx: r2(dx),
				dy: r2(dy),
				a: r1(aimDeg),
				tx: r1(tx),
				ty: r1(ty),
				p: r2(power)
			});

		combat.onSuper = function(kind) Net.send({t: "sup", k: kind});
		combat.onSuperLaunch = function(tx, ty) Net.send({t: "sla", x: r1(tx), y: r1(ty)});

		if (Net.isHost)
			wireHost();
		else
			wireClient();

		announceName();
	}

	function myName():String
	{
		var n = SaveData.playerName();
		return n.length > 0 ? n : "PLAYER " + (Net.selfId + 1);
	}

	function announceName():Void
		Net.send({t: "nm", n: myName()});

	public function requestRestart():Void
		Net.send({t: "rst"});

	public function peerCount():Int
		return roster.count();

	function wireHost():Void
	{
		var oldWave = director.onWave;
		director.onWave = function(n)
		{
			Net.send({t: "wave", n: n});
			if (oldWave != null)
				oldWave(n);
		};

		var oldBoss = director.onBoss;
		director.onBoss = function()
		{
			Net.send({t: "boss"});
			if (oldBoss != null)
				oldBoss();
		};

		var oldSpawn = director.onBossSpawn;
		director.onBossSpawn = function(b)
		{
			if (b.netId < 0)
				b.netId = nextEnemyId++;
			Net.send({t: "bossSpawn", id: b.netId});
			if (oldSpawn != null)
				oldSpawn(b);
		};

		var oldFall = director.onBossFall;
		director.onBossFall = function(x, y, last)
		{
			if (!last)
				Net.send({t: "bossFall", x: r1(x), y: r1(y)});
			if (oldFall != null)
				oldFall(x, y, last);
		};

		var oldKill = director.onBossKill;
		director.onBossKill = function(x, y)
		{
			Net.send({t: "bossKill", x: r1(x), y: r1(y)});
			if (oldKill != null)
				oldKill(x, y);
		};

		var oldDead = director.onBossDefeated;
		director.onBossDefeated = function()
		{
			bossBeat++;
			Net.send({t: "bossDead"});
			if (oldDead != null)
				oldDead();
		};

		director.onShot = function(x, y, dx, dy, dmg, spd, rng, sprite)
			Net.send({t: "shot", x: r1(x), y: r1(y), dx: dx, dy: dy, dm: dmg, sp: spd, rg: rng, im: sprite});

		combat.hits.onImpact = function(x, y) Net.send({t: "imp", x: r1(x), y: r1(y)});
	}

	function wireClient():Void
	{
		combat.hits.remote = true;
		combat.hits.onClaim = function(e, px, py, d, s)
		{
			if (e.netId < 0)
				return;
			mirror.noteClaim(e.netId);
			Net.send({t: "hit", id: e.netId, px: r2(px), py: r2(py), d: d, s: s});
		};

		combat.hookAttack.onGrab = sendGrab;
		combat.yoyoSpin.onGrab = sendGrab;

		pickups.onCollect = function(p)
		{
			if (p.netId >= 0)
				Net.send({t: "took", id: p.netId});
		};
	}

	public function setLeveling(id:Int, on:Bool):Void
	{
		var p = roster.get(id);
		if (p != null)
			p.avatar.setLeveling(on);
	}

	public function setAllLeveling(on:Bool):Void
		roster.eachAvatar(function(a) a.setLeveling(on));

	public function setReady(id:Int, on:Bool):Void
	{
		var p = roster.get(id);
		if (p != null)
			p.avatar.setReady(on);
	}

	public function setAllReady(on:Bool):Void
		roster.eachAvatar(function(a) a.setReady(on));

	static inline function r1(v:Float):Float
		return Math.round(v * 10) / 10;

	static inline function r2(v:Float):Float
		return Math.round(v * 100) / 100;

	static var MODE_COUNT:Int = Type.allEnums(WeaponMode).length;

	public static function validAttackMode(m:Dynamic):Bool
	{
		if (!Std.isOfType(m, Int))
			return false;
		var i:Int = m;
		return i >= 0 && i < MODE_COUNT;
	}

	public function update(elapsed:Float):Void
	{
		frame++;

		for (msg in Net.poll())
			handle(msg);

		if (Net.dropped && !droppedHandled)
		{
			droppedHandled = true;
			roster.dropAll();
			if (onDropped != null)
				onDropped();
		}

		if (Net.connected && frame % SNAP_FRAMES == 0)
		{
			if (Net.isHost)
				sendSnapshot();
			else
				sendDrags();
			sendAvatar();
		}

		if (mirror != null)
			mirror.update(elapsed);

		roster.update(elapsed);
		roster.fillBodies(director.coopBodies);
		updateRespawn(elapsed);
	}

	function handle(msg:Dynamic):Void
	{
		switch ((msg.t : String))
		{
			case "av":
				var p = roster.get(msg.f);
				if (p != null)
					p.applyAvatar(msg);

			case "atk":
				var p = roster.get(msg.f);
				if (p != null && p.fx != null && validAttackMode(msg.m))
					p.fx.attack(msg.m, msg.x, msg.y, msg.dx, msg.dy, msg.a, msg.tx, msg.ty, msg.p, msg.h == 1);

			case "sup":
				var p = roster.get(msg.f);
				if (p != null && p.fx != null)
					p.fx.superActivate(msg.k);

			case "sla":
				var p = roster.get(msg.f);
				if (p != null && p.fx != null)
					p.fx.superLaunch(msg.x, msg.y);

			case "nm":
				var p = roster.get(msg.f);
				if (p != null)
					p.avatar.setName(msg.n);

			case "lvl" if (Net.isClient):
				if (onLevelOpen != null)
					onLevelOpen();

			case "lvlin":
				if (onLevelIn != null)
					onLevelIn(msg.f);

			case "lvldone":
				if (onLevelAck != null)
					onLevelAck(msg.f);

			case "lvlgo" if (Net.isClient):
				if (onLevelGo != null)
					onLevelGo();

			case "rdy":
				if (onReady != null)
					onReady(msg.f);
			case "unrdy":
				if (onUnready != null)
					onUnready(msg.f);

			case "rdyarm" if (Net.isClient):
				if (onReadyArm != null)
					onReadyArm();

			case "rdygo" if (Net.isClient):
				if (onReadyGo != null)
					onReadyGo();

			case "join":
				announceName();

			case "bye":
				roster.drop(msg.id);
				if (onPeerLost != null)
					onPeerLost(msg.id);

			case "rst":
				if (onRestart != null)
					onRestart();

			case "imp" if (Net.isClient):
				var p = roster.get(msg.f);
				if (p != null && p.fx != null)
					p.fx.spark(msg.x, msg.y);

			case "hit" if (Net.isHost):
				var e = findEnemy(msg.id);
				if (e != null && !e.isDead)
				{
					combat.hits.applyHit(e, msg.px, msg.py, clampHit(msg.d), false);
					var stun:Float = msg.s;
					if (stun > 0)
						e.stun = stun < STUN_CAP ? stun : STUN_CAP;
				}

			case "took" if (Net.isHost):
				var p = pickups.findById(msg.id);
				if (p != null)
					p.kill();

			case "grab" if (Net.isHost):
				var e = findEnemy(msg.id);
				if (e != null && !e.isDead && e.grabbable)
				{
					if (msg.on == 1)
					{
						e.seized = true;
						e.velocity.set(0, 0);
						e.drag.set(0, 0);
					}
					else
					{
						var gx:Float = msg.x;
						var gy:Float = msg.y;
						if (gx >= 0 && gy >= 0 && gx + e.width <= arena.width && gy + e.height <= arena.height)
							e.setPosition(gx, gy);
						e.unseize(0.35);
					}
				}

			case "drag" if (Net.isHost):
				var rows:Array<Dynamic> = msg.g;
				if (rows != null)
					for (row in rows)
					{
						var e = findEnemy(row[0]);
						if (e != null && e.seized && !e.isDead)
						{
							var rx:Float = row[1];
							var ry:Float = row[2];
							e.velocity.set((rx - e.x) * DRAG_PULL, (ry - e.y) * DRAG_PULL);
						}
					}

			case "snap" if (Net.isClient):
				mirror.apply(msg);

			case "shot" if (Net.isClient):
				spawnShot(msg);

			case "wave" if (Net.isClient):
				if (onWaveEvt != null)
					onWaveEvt(msg.n);

			case "boss" if (Net.isClient):
				bossDown = false;
				mirror.resetBossPack();
				if (onBossEvt != null)
					onBossEvt();

			case "bossSpawn" if (Net.isClient):
				bossDown = false;
				mirror.expectBoss(msg.id);

			case "bossKill" if (Net.isClient):
				if (onBossKillEvt != null)
					onBossKillEvt(msg.x, msg.y);

			case "bossFall" if (Net.isClient):
				mirror.blastAt(msg.x, msg.y);

			case "bossDead" if (Net.isClient):
				if (!bossDown)
				{
					bossDown = true;
					bossBeat++;
					mirror.blastLastBoss();
					new FlxTimer().start(0.9, function(_)
					{
						if (onBossDefeatedEvt != null)
							onBossDefeatedEvt();
					});
				}

			default:
		}
	}

	function clampHit(d:Float):Float
	{
		if (hitCap == 0)
		{
			var w = data.WeaponData.WeaponDataRegistry.get();
			var fin = w.flurry.finisher;
			var top:Float = w.swing.damage;
			for (v in [w.yoyo.damage, w.revolver.damage, w.bowCharge.damage * w.bowCharge.sweetMult, w.revolver.bigDamage, w.hook.snagDamage, w.hook.slamDamage, w.flurry.swing.damage, fin.damage * (fin.shineMult == null ? 1 : fin.shineMult),
				w.yoyoSpin.grabDamage + w.yoyoSpin.launchDamage])
				if (v > top)
					top = v;
			hitCap = top + util.Levels.damageAt(9999);
		}
		return d < 0 ? 0 : (d > hitCap ? hitCap : d);
	}

	function spawnShot(msg:Dynamic):Void
	{
		var image:String = msg.im;
		if (image != null && !openfl.utils.Assets.exists(util.Paths.image(image)))
			return;
		var dm:Float = msg.dm;
		var sp:Float = msg.sp;
		var rg:Float = msg.rg;
		if (dm < 0)
			dm = 0;
		if (dm > SHOT_DAMAGE_CAP)
			dm = SHOT_DAMAGE_CAP;
		if (sp < 1)
			sp = 1;
		if (sp > SHOT_SPEED_CAP)
			sp = SHOT_SPEED_CAP;
		if (rg < 0)
			rg = 0;
		if (rg > SHOT_RANGE_CAP)
			rg = SHOT_RANGE_CAP;
		director.shots.recycle(EnemyShot).fire(msg.x, msg.y, msg.dx, msg.dy, dm, sp, rg, image);
	}

	function sendGrab(e:Enemies, on:Bool):Void
	{
		if (e.netId < 0)
			return;
		if (on)
			Net.send({t: "grab", id: e.netId, on: 1});
		else
			Net.send({t: "grab", id: e.netId, on: 0, x: r1(e.x), y: r1(e.y)});
	}

	function sendDrags():Void
	{
		var rows:Array<Array<Float>> = [];
		var addRow = function(e:Enemies)
		{
			if (e != null && e.exists && !e.isDead && e.seized && e.netId >= 0)
				rows.push([e.netId, r1(e.x), r1(e.y)]);
		};
		addRow(combat.hookAttack.heldEnemy);
		var spun:Array<Enemies> = [];
		combat.yoyoSpin.captives(spun);
		for (e in spun)
			addRow(e);
		if (rows.length > 0)
			Net.send({t: "drag", g: rows});
	}

	function findEnemy(id:Int):Enemies
	{
		var found:Enemies = null;
		director.eachEnemy(function(e)
		{
			if (e.netId == id)
				found = e;
		});
		return found;
	}

	function sendSnapshot():Void
	{
		var en:Array<Array<Dynamic>> = [];
		director.eachEnemy(function(e)
		{
			if (e.netId < 0)
				e.netId = nextEnemyId++;
			var row:Array<Dynamic> = [
				e.netId, e.kind, r1(e.x), r1(e.y), e.flipX ? 1 : 0,
				e.animation.name, e.hp, e.isDead ? 1 : 0
			];
			if (e.gun != null && e.gun.graphic != null)
			{
				row.push(e.gun.graphic.key);
				row.push(r1(e.gun.x));
				row.push(r1(e.gun.y));
				row.push(r1(e.gun.angle));
				row.push(e.gun.flipY ? 1 : 0);
			}
			en.push(row);
		});

		var pk:Array<Array<Dynamic>> = [];
		for (p in pickups.group.members)
			if (p != null && p.exists && p.netId >= 0)
				pk.push([p.netId, r1(p.x), r1(p.y)]);

		Net.send({t: "snap", w: director.wave, en: en, pk: pk});
	}

	function sendAvatar():Void
	{
		var held = combat.held.sprite;
		var hookShot = combat.hookAttack.hook;
		var yo = combat.yoyoJab.flight;
		var fly = combat.throwAttack.thrown;

		Net.send({
			t: "av",
			x: r1(player.x),
			y: r1(player.y),
			hu: SaveData.playerHue(),
			sk: SaveData.playerSkin(),
			gr: SaveData.playerGear(),
			fx: player.flipX,
			an: player.animation.name,
			wi: combat.weapon,
			hv: held.visible && heldSprite.visible,
			ha: r1(held.angle),
			hf: held.flipX,
			hg: held.flipY,
			ho: [r1(held.x - player.x), r1(held.y - player.y), r2(held.scale.x), r2(combat.held.charge)],
			bd: [r1(player.angle), r1(player.offset.y - player.baseOffsetY), r2(player.scale.x), r2(player.scale.y)],
			dd: status.dead && !status.throes,
			rv: reviving,
			hk: hookShot.exists ? [r1(hookShot.x), r1(hookShot.y), r1(hookShot.angle), r1(combat.held.handX()), r1(combat.held.handY())] : null,
			yo: yo.active ? [r1(yo.cx), r1(yo.cy), r1(yo.yoyo.angle)] : null,
			th: fly.exists ? [r1(fly.x), r1(fly.y), r1(fly.velocity.x), r1(fly.velocity.y)] : null
		});
	}

	function updateRespawn(elapsed:Float):Void
	{
		if (!status.dead)
		{
			deathWave = -1;
			deathBoss = -1;
			runFailed = false;
			reviving = false;
			director.lobbyDown = false;
			return;
		}

		if (roster.everyoneDown())
		{
			if (!runFailed)
			{
				runFailed = true;
				deathWave = -1;
				director.lobbyDown = true;
				hud.showDeath(director.wave, SaveData.bestWave());
			}
			return;
		}

		if (deathWave < 0)
		{
			deathWave = director.wave;
			deathBoss = bossBeat;
			hud.showRespawn();
		}
		if (director.wave >= deathWave + RESPAWN_WAVES || bossBeat > deathBoss)
		{
			if (!reviving)
			{
				reviving = true;
				if (startRevive != null)
					startRevive();
			}
			if (reviveDone != null && !reviveDone())
				return;
			reviving = false;
			deathWave = -1;
			deathBoss = -1;
			status.revive();
			status.health = status.healthMax * 0.5;
			player.setPosition(arena.spawnX, arena.spawnY);
			layers.playerShadow.visible = true;
			heldSprite.visible = true;
			hud.hideDeath();
		}
	}
}
