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
	public var shots(get, never):FlxTypedGroup<EnemyShot>;
	public var onWave:Int->Void;
	public var onBoss:Void->Void;
	public var onWaveCleared:Void->Void;
	public var bossVeto:Int->Bool;
	public var onBossSpawn:Enemies->Void;
	public var onProbe:(Float, Float, Float) -> Void;

	public var coopBodies(default, null):Array<FlxSprite> = [];
	public var solids:FlxTypedGroup<FlxSprite>;

	private var player:Player;
	private var arena:Arena;
	private var layers:RenderLayers;
	private var status:PlayerCombat;

	private var spawner:EnemySpawner;
	private var gunfire:EnemyShots;
	private var bossDeath:BossDeath;

	private var bodies:FlxTypedGroup<Enemies>;
	private var rigs:Array<EnemyRig> = [];
	private var waveData:WaveData;
	private var betweenWaves:Float = 0;
	private var waveClock:Float = 0;
	private var bossWave:Int;
	private var bossPending:Bool = false;
	private var bossTimer:Float = 0;

	public function new(player:Player, arena:Arena, layers:RenderLayers, status:PlayerCombat)
	{
		this.player = player;
		this.arena = arena;
		this.layers = layers;
		this.status = status;

		bodies = new FlxTypedGroup<Enemies>();
		waveData = WaveDataRegistry.get();
		betweenWaves = waveData.firstDelay;
		bossWave = waveData.bossWaveMin + FlxG.random.int(0, waveData.bossWaveRange);

		spawner = new EnemySpawner(arena);
		spawner.anchor = anchorBody;
		gunfire = new EnemyShots(arena, status);
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

	public var onBossDrops(get, set):(Float, Float) -> Void;

	function get_onBossDrops()
		return bossDeath.onDrops;

	function set_onBossDrops(f:(Float, Float) -> Void)
	{
		bossDeath.onDrops = f;
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
		FlxG.collide(bodies, arena.map);
		if (solids != null)
			bodies.forEachAlive(function(e:Enemies) FootCollide.against(e, e.feetY, solids));
		FlxG.overlap(bodies, bodies, null, separateLive);
	}

	function separateLive(a:Enemies, b:Enemies):Bool
	{
		if (a.isDead || b.isDead || a.seized || b.seized)
			return false;
		return FlxObject.separate(a, b);
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
		else if (!status.dead)
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
		var boss = new Enemies("rofel");
		applyWaveScale(boss);
		spawner.placeAtEdge(boss);
		register(boss);
		bossDeath.watch(boss);
		if (onBossSpawn != null)
			onBossSpawn(boss);
	}

	function updateWaves(elapsed:Float):Void
	{
		if (betweenWaves > 0)
		{
			if (!holdWave)
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

	function ramp(perWave:Float, cap:Float):Float
	{
		var m = 1 + (wave - 1) * perWave;
		return cap > 0 && m > cap ? cap : m;
	}

	function breatherTime():Float
	{
		var s = waveData.scaling;
		var b = waveData.breather - (wave - 1) * s.breatherPerWave;
		return b < s.breatherMin ? s.breatherMin : b;
	}

	private function applyWaveScale(e:Enemies):Void
	{
		var s = waveData.scaling;
		e.applyScale(ramp(s.hpPerWave, s.hpMax), ramp(s.speedPerWave, s.speedMax), ramp(s.damagePerWave, s.damageMax));
	}

	public function resumeAfter(atWave:Int, atBossWave:Int):Void
	{
		wave = atWave;
		bossWave = atBossWave;
		betweenWaves = breatherTime();
	}

	function isBossWave(n:Int):Bool
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
		if (waveData.maxCount > 0 && count > waveData.maxCount)
			count = waveData.maxCount;
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

	function updateRigs(elapsed:Float):Void
	{
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

			if (e.entering && e.x > ENTER_MARGIN && e.y > ENTER_MARGIN
				&& e.x + e.width < arena.width - ENTER_MARGIN && e.y + e.height < arena.height - ENTER_MARGIN
				&& spawner.spotClear(e, e.x, e.y))
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
				spawner.checkStuck(rig, elapsed);

			rig.hitbox.x = e.x + (e.flipX ? e.hitOffXFlip : e.hitOffX);
			rig.hitbox.y = e.y + e.hitOffY;
			if (!e.seized && e.throwGrace <= 0 && WorldClock.scale > 0.05)
				status.hurtPlayer(rig.hitbox, e.contactDamage, e.feetY);

			gunfire.emit(e);
		}
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
		var nx = Math.max(e.x, Math.min(cx, e.x + e.width));
		var ny = Math.max(e.y, Math.min(cy, e.y + e.height));
		var dx = cx - nx;
		var dy = cy - ny;
		return dx * dx + dy * dy <= radius * radius;
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
