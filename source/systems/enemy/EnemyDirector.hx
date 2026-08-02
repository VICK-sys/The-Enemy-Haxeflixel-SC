package systems.enemy;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import entities.enemy.EnemyShot;
import data.WaveData;
import data.WaveData.WaveDataRegistry;
import util.WorldClock;
import systems.world.Arena;
import systems.world.FootCollide;

class EnemyDirector
{
	static inline var ENTER_MARGIN:Float = 40;
	static inline var BOSS_INTRO_TIME:Float = 4.8;
	static inline var WAVE_TIMEOUT:Float = 75;

	public var wave:Int = 0;
	public var spawning:Bool = true;

	private var queued:Array<String> = [];
	private var dripTimer:Float = 0;
	public var holdWave:Bool = false;
	public var holdReady:Bool = false;
	public var lobbyDown:Bool = false;
	public var shots(get, never):FlxTypedGroup<EnemyShot>;
	public var onWave:Int->Void;
	public var onBoss:Void->Void;
	public var onWaveCleared:Void->Void;
	public var bossVeto:Int->Bool;
	public var onBossSpawn:Enemies->Void;
	public var onBossPack:Array<Enemies>->Void;
	public var onProbe:(Float, Float, Float) -> Void;

	public var coopBodies(default, null):Array<FlxSprite> = [];
	public var solids:FlxTypedGroup<FlxSprite>;

	private var player:Player;
	private var arena:Arena;
	private var layers:RenderLayers;
	private var status:PlayerCombat;

	private var spawner:EnemySpawner;
	private var worm:WormFlock = null;
	private var fx:Fx;
	private var gunfire:EnemyShots;
	private var bossDeath:BossDeath;

	public var bodies(default, null):FlxTypedGroup<Enemies>;
	private var rigs:Array<EnemyRig> = [];
	private var waveData:WaveData;
	private var betweenWaves:Float = 0;
	private var waveClock:Float = 0;
	private var bossWave:Int;
	private var bossPending:Bool = false;
	private var bossTimer:Float = 0;
	private var bossesFought:Int = 0;
	private var forcedBoss:String = null;
	private var forcedCount:Int = 0;

	public function new(player:Player, arena:Arena, layers:RenderLayers, status:PlayerCombat, fx:Fx)
	{
		this.player = player;
		this.arena = arena;
		this.layers = layers;
		this.status = status;

		bodies = new FlxTypedGroup<Enemies>();
		waveData = WaveDataRegistry.get();
		betweenWaves = waveData.firstDelay;
		bossWave = waveData.bossWaveMin + FlxG.random.int(0, waveData.bossWaveRange);

		this.fx = fx;
		spawner = new EnemySpawner(arena);
		spawner.anchor = anchorBody;
		gunfire = new EnemyShots(arena, status, fx);
		bossDeath = new BossDeath(layers);
	}

	function get_shots():FlxTypedGroup<EnemyShot>
		return gunfire.group;

	public var onShot(get, set):(Float, Float, Float, Float, Float, Float, Float, String) -> Void;

	function get_onShot()
		return gunfire.onShot;

	function set_onShot(f:(Float, Float, Float, Float, Float, Float, Float, String) -> Void)
	{
		gunfire.onShot = f;
		return f;
	}

	public var onFriendlyShot(get, set):EnemyShot->Bool;

	function get_onFriendlyShot()
		return gunfire.onFriendly;

	function set_onFriendlyShot(f:EnemyShot->Bool)
	{
		gunfire.onFriendly = f;
		return f;
	}

	public var onShieldShot(get, set):EnemyShot->Bool;

	function get_onShieldShot()
		return gunfire.onShield;

	function set_onShieldShot(f:EnemyShot->Bool)
	{
		gunfire.onShield = f;
		return f;
	}

	public function seizedAt(shot:EnemyShot):Enemies
	{
		for (rig in rigs)
		{
			var e = rig.enemy;
			if (!e.seized || e.isDead || !e.exists)
				continue;
			if (shot.x + shot.width <= e.x || e.x + e.width <= shot.x
				|| shot.y + shot.height <= e.y || e.y + e.height <= shot.y)
				continue;
			return e;
		}
		return null;
	}

	public var onBossDrops(get, set):(Float, Float) -> Void;

	function get_onBossDrops()
		return bossDeath.onDrops;

	function set_onBossDrops(f:(Float, Float) -> Void)
	{
		bossDeath.onDrops = f;
		return f;
	}

	public var onBossFall(get, set):(Float, Float, Bool) -> Void;

	function get_onBossFall()
		return bossDeath.onFall;

	function set_onBossFall(f:(Float, Float, Bool) -> Void)
	{
		bossDeath.onFall = f;
		return f;
	}

	public var onBossKill(get, set):(Float, Float) -> Void;

	function get_onBossKill()
		return bossDeath.onKill;

	function set_onBossKill(f:(Float, Float) -> Void)
	{
		bossDeath.onKill = f;
		return f;
	}

	public var onBossDefeated(get, set):Void->Void;

	function get_onBossDefeated()
		return bossDeath.onDefeated;

	function set_onBossDefeated(f:Void->Void)
	{
		bossDeath.onDefeated = f;
		return f;
	}

	public function collide():Void
	{
		bodies.forEachAlive(function(e:Enemies)
		{
			if (!e.railed && (!e.entering || inBounds(e)))
				systems.world.CircleCollide.resolve(e, e.hitRadius, arena.map, solids);
		});
		FlxG.overlap(bodies, bodies, null, separateLive);
	}

	function inBounds(e:Enemies):Bool
	{
		return e.x > ENTER_MARGIN && e.y > ENTER_MARGIN && e.x + e.width < arena.width - ENTER_MARGIN
			&& e.y + e.height < arena.height - ENTER_MARGIN;
	}

	function separateLive(a:Enemies, b:Enemies):Bool
	{
		if (a.isDead || b.isDead || a.seized || b.seized || a.entering || b.entering || a.railed || b.railed)
			return false;
		return systems.world.CircleCollide.separate(a, a.hitRadius, b, b.hitRadius);
	}

	public function update(elapsed:Float):Void
	{
		if (!spawning)
		{
			updateRigs(elapsed);
			return;
		}

		if (bossPending)
			updateBossIntro(elapsed);
		else if (!lobbyDown && (net.Net.active || !status.dead))
			updateWaves(elapsed);

		updateRigs(elapsed);
		bossDeath.update(elapsed);
	}

	function updateBossIntro(elapsed:Float):Void
	{
		bossTimer -= elapsed;
		if (bossTimer > 0)
			return;

		bossPending = false;
		spawnBossPack(bossCount());
	}

	function bossCount():Int
	{
		if (forcedCount > 0)
		{
			var n = forcedCount;
			forcedCount = 0;
			return n;
		}
		return bossesFought > 0 && FlxG.random.float() < waveData.duoChance ? 2 : 1;
	}

	public function bossAlive():Bool
	{
		for (rig in rigs)
			if (rig.enemy.bossBody && rig.enemy.exists && !rig.enemy.isDead)
				return true;
		return false;
	}

	public function summonBoss(kind:String, count:Int = 1):Bool
	{
		if (bossPending || bossAlive() || !spawning)
			return false;
		forcedBoss = kind;
		forcedCount = count;
		queued.resize(0);
		betweenWaves = 0;
		waveClock = 0;
		if (onBoss != null)
			onBoss();
		bossPending = true;
		bossTimer = BOSS_INTRO_TIME;
		return true;
	}

	function bossKind():String
	{
		if (forcedBoss != null)
		{
			var forced = forcedBoss;
			forcedBoss = null;
			return data.EnemyData.EnemyDataRegistry.has(forced) ? forced : "domo";
		}
		var roster = bossRoster();
		if (roster.length == 0)
			return "domo";
		var pick = roster[FlxG.random.int(0, roster.length - 1)];
		return data.EnemyData.EnemyDataRegistry.has(pick) ? pick : "domo";
	}

	public function bossRoster():Array<String>
	{
		var roster = waveData.bosses != null ? waveData.bosses.copy() : [];
		#if debug
		if (waveData.debugBosses != null)
			for (k in waveData.debugBosses)
				roster.push(k);
		#end
		return roster;
	}

	function spawnBossPack(count:Int):Void
	{
		bossesFought++;
		var pack = [];
		var s = waveData.scaling;
		var kind = bossKind();
		if (data.EnemyData.EnemyDataRegistry.get(kind).worm != null)
		{
			spawnWorm(kind);
			return;
		}
		for (i in 0...count)
		{
			var boss = new Enemies(kind);
			boss.applyScale(ramp(s.bossHpPerWave), ramp(s.bossSpeedPerWave), ramp(s.bossDamagePerWave));
			spawner.placeAtEdge(boss);
			register(boss);
			bossDeath.watch(boss);
			pack.push(boss);
			if (onBossSpawn != null)
				onBossSpawn(boss);
		}
		if (onBossPack != null)
			onBossPack(pack);
	}

	function spawnWorm(kind:String):Void
	{
		var wcfg = data.EnemyData.EnemyDataRegistry.get(kind).worm;
		var s = waveData.scaling;
		var a = anchorBody();
		var hx = a.x + a.width * 0.5;
		if (hx < 200)
			hx = 200;
		if (hx > arena.width - 200)
			hx = arena.width - 200;
		var hy = arena.height + 60;

		var segs:Array<Enemies> = [];
		for (i in 0...wcfg.parts)
		{
			var e = new Enemies(i == 0 ? kind : kind + "_body");
			e.x = hx - e.width * 0.5;
			e.y = hy + i * wcfg.spacing - e.height * 0.5;
			e.buried = true;
			e.shadowScaleX = 0;
			e.applyScale(ramp(s.bossHpPerWave), ramp(s.bossSpeedPerWave), ramp(s.bossDamagePerWave));
			register(e);
			segs.push(e);
			if (i == 0 && onBossSpawn != null)
				onBossSpawn(e);
		}
		worm = new WormFlock(layers, fx, arena.width, arena.height);
		worm.floorAt = arena.floorColorAt;
		worm.adopt(segs);
	}

	function wormDown():Void
	{
		var wasX = worm.lastX;
		var wasY = worm.lastY;
		worm = null;
		if (onBossKill != null)
			onBossKill(wasX, wasY);
		if (onBossDrops != null)
			onBossDrops(wasX, wasY);
		if (onBossDefeated != null)
			onBossDefeated();
	}

	function updateWaves(elapsed:Float):Void
	{
		if (betweenWaves > 0)
		{
			if (!holdWave && !holdReady)
				betweenWaves -= elapsed;
			waveClock = 0;
			if (betweenWaves <= 0)
				startWave();
			return;
		}

		if (queued.length > 0)
		{
			dripTimer -= elapsed;
			if (dripTimer <= 0)
				dripSpawn();
		}

		if (queued.length == 0 && waveCleared())
		{
			betweenWaves = breatherTime();
			if (wave > 0 && onWaveCleared != null)
				onWaveCleared();
			return;
		}

		waveClock += elapsed;
		if (waveClock <= WAVE_TIMEOUT)
			return;

		waveClock = 0;
		for (rig in rigs)
			if (rig.enemy.exists && !rig.enemy.isDead && !rig.enemy.seized && !rig.enemy.selfDriven)
				spawner.rescue(rig);
	}

	function ramp(perWave:Float):Float
		return 1 + (wave - 1) * perWave;

	function breatherTime():Float
	{
		var s = waveData.scaling;
		var b = waveData.breather - (wave - 1) * s.breatherPerWave;
		return b < s.breatherMin ? s.breatherMin : b;
	}

	private function applyWaveScale(e:Enemies):Void
	{
		var s = waveData.scaling;
		e.applyScale(ramp(s.hpPerWave), ramp(s.speedPerWave), ramp(s.damagePerWave));
	}

	public function resumeAfter(atWave:Int, atBossWave:Int):Void
	{
		wave = atWave;
		bossWave = atBossWave;
		betweenWaves = breatherTime();
	}

	public function isBossWave(n:Int):Bool
	{
		if (n < bossWave)
			return false;
		if (n == bossWave)
			return true;
		return waveData.bossRepeat > 0 && (n - bossWave) % waveData.bossRepeat == 0;
	}

	function startWave():Void
	{
		wave++;
		if (onWave != null)
			onWave(wave);

		if (isBossWave(wave))
		{
			if (bossVeto != null && bossVeto(bossWave))
				return;
			if (onBoss != null)
				onBoss();
			bossPending = true;
			bossTimer = BOSS_INTRO_TIME;
			return;
		}

		var count = waveData.baseCount + wave * waveData.countPerWave;
		var poolIndex = wave - 1;
		if (poolIndex >= waveData.waves.length)
			poolIndex = waveData.waves.length - 1;

		var pool = waveData.waves[poolIndex].types;
		queued = [for (i in 0...count) pool[Std.random(pool.length)]];
		dripTimer = 0;
		dripSpawn();
	}

	function dripSpawn():Void
	{
		var n = waveData.spawnBatch > 0 ? waveData.spawnBatch : queued.length;
		while (n-- > 0 && queued.length > 0)
		{
			var e = new Enemies(queued.shift());
			applyWaveScale(e);
			spawner.placeAtEdge(e);
			register(e);
		}
		dripTimer = waveData.spawnEvery;
	}

	function retally():Void
	{
		Enemies.census.clear();
		for (rig in rigs)
		{
			var e = rig.enemy;
			if (!e.exists || e.isDead)
				continue;
			Enemies.census.set(e.kind, Enemies.countOf(e.kind) + 1);
		}
	}

	function updateRigs(elapsed:Float):Void
	{
		retally();
		if (worm != null)
		{
			worm.update(elapsed);
			if (worm.done)
				wormDown();
		}
		var i = rigs.length;
		while (i-- > 0)
		{
			var rig = rigs[i];
			var e = rig.enemy;

			if (!e.exists)
			{
				retire(rig, i);
				continue;
			}

			e.target = pickTarget(e);
			var alive = !e.isDead;

			if (e.gun != null)
				e.gun.visible = alive;

			if (e.entering && inBounds(e) && spawner.spotClear(e, e.x, e.y))
			{
				e.entering = false;
				e.allowCollisions = ANY;
			}

			rig.shadow.visible = alive;
			rig.shadow.x = e.x + (e.flipX ? e.shadowOffXFlip : e.shadowOffX);
			rig.shadow.y = e.feetY;
			rig.shadow.scale.set(e.shadowScaleX, 4);

			if (!alive)
			{
				rig.hitbox.x = -100000;
				continue;
			}

			if (!e.seized && !e.selfDriven && !e.puppet && !status.dead)
				spawner.checkStuck(rig, elapsed, touchingOther(e));

			rig.hitbox.x = e.x + (e.flipX ? e.hitOffXFlip : e.hitOffX);
			rig.hitbox.y = e.y + e.hitOffY;
			if (!e.seized && !e.buried && e.throwGrace <= 0 && WorldClock.scale > 0.05)
				status.hurtPlayer(rig.hitbox, e.contactDamage, e.feetY, e.contactPush);

			gunfire.emit(e);
			if (e.pendingSummons.length > 0)
				drainSummons(e);
		}

		ramFling();
	}

	static inline var FLING_SPEED:Float = 1000;
	static inline var FLING_STUN:Float = 0.7;
	static inline var FLING_DRAG:Float = 600;

	function drainSummons(e:Enemies):Void
	{
		while (e.pendingSummons.length > 0)
		{
			var s = e.pendingSummons.pop();
			if (!data.EnemyData.EnemyDataRegistry.has(s.kind))
				continue;
			var add = new Enemies(s.kind);
			add.setPosition(s.x - add.width * 0.5, s.y - add.height * 0.5);
			applyWaveScale(add);
			add.throwGrace = 0.5;
			register(add);
		}
	}

	function ramFling():Void
	{
		for (rig in rigs)
		{
			var d = rig.enemy;
			if (!d.ramming || d.isDead || !d.exists)
				continue;
			var t = d.target;
			if (t == null)
				continue;
			for (o in rigs)
			{
				var f = o.enemy;
				if (f == d || f.isDead || !f.exists || f.bossBody || f.stun > 0 || f.seized || f.entering)
					continue;
				if (f.x + f.width <= d.x || d.x + d.width <= f.x
					|| f.y + f.height <= d.y || d.y + d.height <= f.y)
					continue;
				var vx = t.x + t.width * 0.5 - (f.x + f.width * 0.5);
				var vy = t.y + t.height * 0.5 - (f.y + f.height * 0.5);
				var l = Math.sqrt(vx * vx + vy * vy);
				if (l <= 0)
					continue;
				f.velocity.set(vx / l * FLING_SPEED, vy / l * FLING_SPEED);
				f.drag.set(FLING_DRAG, FLING_DRAG);
				f.stun = FLING_STUN;
				if (f.animation.getByName("spin") != null)
					f.animation.play("spin", true);
				util.Sfx.at("weapon/throw", f.x + f.width * 0.5, f.y + f.height * 0.5, 0.6);
			}
		}
	}

	function touchingOther(e:Enemies):Bool
	{
		for (rig in rigs)
		{
			var o = rig.enemy;
			if (o == e || !o.exists || o.isDead)
				continue;
			if (e.x < o.x + o.width + 8 && o.x < e.x + e.width + 8
				&& e.y < o.y + o.height + 8 && o.y < e.y + e.height + 8)
				return true;
		}
		return false;
	}

	function retire(rig:EnemyRig, i:Int):Void
	{
		var e = rig.enemy;
		if (e.gun != null)
		{
			layers.entityLayer.remove(e.gun, true);
			e.gun.destroy();
		}
		layers.removeEnemy(e, rig.shadow);
		bodies.remove(e, true);
		e.destroy();
		rig.shadow.destroy();
		rig.hitbox.destroy();
		rigs.splice(i, 1);
	}

	public function updateShots():Void
		gunfire.update();

	public function spawnNear(e:Enemies):Void
	{
		spawner.placeNear(e);
		register(e);
	}

	function register(e:Enemies):Void
	{
		e.target = anchorBody();
		e.pathing.map = arena.map;
		var sh = layers.addEnemy(e);
		if (e.gun != null)
			layers.entityLayer.add(e.gun);
		bodies.add(e);
		rigs.push(new EnemyRig(e, sh, new FlxObject(0, 0, 40, 40)));
	}

	function pickTarget(e:Enemies):FlxSprite
	{
		var ex = e.x + e.width * 0.5;
		var ey = e.y + e.height * 0.5;
		var best:FlxSprite = status.dead ? null : player;
		var bestD:Float = best != null ? sqTo(ex, ey, best) : -1;

		for (b in coopBodies)
		{
			var d = sqTo(ex, ey, b);
			if (best == null || d < bestD)
			{
				best = b;
				bestD = d;
			}
		}
		return best;
	}

	static function sqTo(x:Float, y:Float, s:FlxSprite):Float
	{
		var dx = s.x + s.width * 0.5 - x;
		var dy = s.y + s.height * 0.5 - y;
		return dx * dx + dy * dy;
	}

	function anchorBody():FlxSprite
	{
		if (status.dead && coopBodies.length > 0)
			return coopBodies[0];
		return player;
	}

	public function firstInCircle(cx:Float, cy:Float, radius:Float, skipSeized:Bool = false):Enemies
	{
		if (onProbe != null)
			onProbe(cx, cy, radius);
		for (rig in rigs)
		{
			var e = rig.enemy;
			if (e.isDead || (skipSeized && e.seized))
				continue;
			if (circleTouches(e, cx, cy, radius))
				return e;
		}
		return null;
	}

	public function eachInCircle(cx:Float, cy:Float, radius:Float, f:Enemies->Void):Void
	{
		if (onProbe != null)
			onProbe(cx, cy, radius);
		for (rig in rigs)
		{
			var e = rig.enemy;
			if (e.isDead)
				continue;
			if (circleTouches(e, cx, cy, radius))
				f(e);
		}
	}

	function circleTouches(e:Enemies, cx:Float, cy:Float, radius:Float):Bool
	{
		var dx = cx - (e.x + e.width * 0.5);
		var dy = cy - (e.y + e.height * 0.5);
		var reach = radius + e.hitRadius;
		return dx * dx + dy * dy <= reach * reach;
	}

	public function enemyCount():Int
		return rigs.length;

	public function eachEnemy(f:Enemies->Void):Void
	{
		for (rig in rigs)
			if (rig.enemy.exists)
				f(rig.enemy);
	}

	function waveCleared():Bool
	{
		for (rig in rigs)
			if (rig.enemy.exists && !rig.enemy.isDead)
				return false;
		return true;
	}
}
