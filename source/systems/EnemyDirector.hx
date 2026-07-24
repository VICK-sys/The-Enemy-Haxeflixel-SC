package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import entities.enemy.EnemyShot;
import data.WaveData;
import data.WaveData.WaveDataRegistry;
import util.Paths;
import util.WorldClock;

class EnemyDirector
{
	static inline var ENTER_MARGIN:Float = 40;
	static inline var SPAWN_OUT:Float = 40;
	static inline var SPAWN_PAD:Float = 60;
	static inline var SPAWN_TRIM:Float = 240;
	static inline var SPAWN_SPREAD:Float = 700;
	static inline var SHOT_PROBE:Float = 10;
	static inline var BOSS_INTRO_TIME:Float = 4.8;
	static inline var BOSS_SHAKE_DUR:Float = 1.0;
	static inline var BOSS_SHAKE_AMP:Float = 12;
	static inline var EXPLO_SCALE:Float = 9;

	public var wave:Int = 0;
	public var shots:FlxTypedGroup<EnemyShot>;
	public var onWave:Int->Void;
	public var onBoss:Void->Void;
	public var onBossSpawn:Enemies->Void;
	public var onBossDefeated:Void->Void;

	private var bossWave:Int;
	private var bossPending:Bool = false;
	private var bossTimer:Float = 0;
	private var bossRef:Enemies;
	private var bossDying:Bool = false;
	private var bossDeathPhase:Int = 0;
	private var bossDeathTimer:Float = 0;
	private var bossBaseX:Float = 0;
	private var bossBaseY:Float = 0;
	private var bossExplosion:FlxSprite;

	private var player:Player;
	private var arena:Arena;
	private var layers:RenderLayers;
	private var status:PlayerCombat;
	private var bodies:FlxTypedGroup<Enemies>;
	private var rigs:Array<EnemyRig> = [];
	private var waveData:WaveData;
	private var betweenWaves:Float = 0;

	public function new(player:Player, arena:Arena, layers:RenderLayers, status:PlayerCombat)
	{
		this.player = player;
		this.arena = arena;
		this.layers = layers;
		this.status = status;
		bodies = new FlxTypedGroup<Enemies>();
		shots = new FlxTypedGroup<EnemyShot>();
		waveData = WaveDataRegistry.get();
		betweenWaves = waveData.firstDelay;
		bossWave = waveData.bossWaveMin + FlxG.random.int(0, waveData.bossWaveRange);
	}

	public function collide():Void
	{
		FlxG.collide(bodies, arena.map);
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
		if (bossPending)
		{
			bossTimer -= elapsed;
			if (bossTimer <= 0)
			{
				bossPending = false;
				var boss = new Enemies("rofel");
				spawnWaveEnemy(boss);
				bossRef = boss;
				if (onBossSpawn != null)
					onBossSpawn(boss);
			}
		}
		else if (!status.dead)
		{
			if (betweenWaves > 0)
			{
				betweenWaves -= elapsed;
				if (betweenWaves <= 0)
					startWave();
			}
			else if (waveCleared())
			{
				betweenWaves = waveData.breather;
			}
		}

		updateRigs();

		if (bossRef != null)
		{
			if (!bossDying && bossRef.isDead)
				beginBossDeath();
			else if (bossDying)
				updateBossDeath(elapsed);
		}
	}

	function beginBossDeath():Void
	{
		bossDying = true;
		bossDeathPhase = 0;
		bossDeathTimer = BOSS_SHAKE_DUR;
		bossBaseX = bossRef.x;
		bossBaseY = bossRef.y;
		bossRef.velocity.set(0, 0);
		bossRef.allowCollisions = NONE;
	}

	function updateBossDeath(elapsed:Float):Void
	{
		if (bossDeathPhase == 0)
		{
			bossDeathTimer -= elapsed;
			var amp = BOSS_SHAKE_AMP * (1 - bossDeathTimer / BOSS_SHAKE_DUR);
			bossRef.x = bossBaseX + (Math.random() * 2 - 1) * amp;
			bossRef.y = bossBaseY + (Math.random() * 2 - 1) * amp;
			bossRef.velocity.set(0, 0);
			if (bossDeathTimer <= 0)
			{
				bossRef.x = bossBaseX;
				bossRef.y = bossBaseY;
				bossRef.visible = false;
				spawnExplosion(bossRef.x + bossRef.width / 2, bossRef.y + bossRef.height / 2);
				FlxG.sound.play(Paths.sound("rofel_explode"), 0.9);
				FlxG.camera.shake(0.02, 0.5);
				bossDeathPhase = 1;
			}
		}
		else if (bossExplosion != null && bossExplosion.animation.finished)
		{
			layers.entityLayer.remove(bossExplosion, true);
			bossExplosion.destroy();
			bossExplosion = null;
			bossRef.kill();
			bossRef = null;
			bossDying = false;
			if (onBossDefeated != null)
				onBossDefeated();
		}
	}

	function spawnExplosion(cx:Float, cy:Float):Void
	{
		bossExplosion = new FlxSprite();
		bossExplosion.loadGraphic(Paths.image("effects/rofel_explosion"), true, 80, 48);
		bossExplosion.animation.add("boom", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 14, false);
		bossExplosion.antialiasing = false;
		bossExplosion.scale.set(EXPLO_SCALE, EXPLO_SCALE);
		bossExplosion.updateHitbox();
		bossExplosion.x = cx - bossExplosion.width / 2;
		bossExplosion.y = cy - bossExplosion.height / 2;
		bossExplosion.animation.play("boom");
		layers.entityLayer.add(bossExplosion);
	}

	function updateRigs():Void
	{
		var i = rigs.length;
		while (i-- > 0)
		{
			var rig = rigs[i];
			var e = rig.enemy;

			if (!e.exists)
			{
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
				continue;
			}

			e.target = status.dead ? null : player;

			var alive = !e.isDead;

			if (e.gun != null)
				e.gun.visible = alive;

			if (e.entering && e.x > ENTER_MARGIN && e.y > ENTER_MARGIN
				&& e.x + e.width < arena.width - ENTER_MARGIN && e.y + e.height < arena.height - ENTER_MARGIN)
			{
				e.entering = false;
				e.allowCollisions = ANY;
			}

			rig.shadow.visible = alive;
			rig.shadow.x = e.x + (e.flipX ? e.shadowOffXFlip : e.shadowOffX);
			rig.shadow.y = e.y + e.shadowOffY;

			if (alive)
			{
				rig.hitbox.x = e.x + (e.flipX ? e.hitOffXFlip : e.hitOffX);
				rig.hitbox.y = e.y + e.hitOffY;
				if (!e.seized && e.throwGrace <= 0 && WorldClock.scale > 0.05)
					status.hurtPlayer(rig.hitbox, e.contactDamage);

				if (e.pendingShots.length > 0)
				{
					var cx = e.x + e.width / 2;
					var cy = e.y + e.height / 2;
					var lastSound:String = null;
					for (spec in e.pendingShots)
					{
						var sx = spec.useOrigin ? spec.originX : cx;
						var sy = spec.useOrigin ? spec.originY : cy;
						shots.recycle(EnemyShot).fire(sx, sy, spec.dirX, spec.dirY, spec.damage, spec.speed, spec.range, spec.sprite);
						if (spec.sound != null && spec.sound != lastSound)
						{
							FlxG.sound.play(Paths.sound(spec.sound), 0.5);
							lastSound = spec.sound;
						}
					}
					e.recycleShots();
				}
			}
			else
			{
				rig.hitbox.x = -100000;
			}
		}
	}

	public function updateShots():Void
	{
		if (WorldClock.scale <= 0.05)
			return;
		for (shot in shots.members)
		{
			if (shot == null || !shot.exists)
				continue;
			var shx = shot.x + shot.width / 2;
			var shy = shot.y + shot.height / 2;
			if (arena.wallAt(shx + shot.dirX * SHOT_PROBE, shy + shot.dirY * SHOT_PROBE))
			{
				shot.kill();
				continue;
			}
			if (status.hurtPlayer(shot, shot.damage))
				shot.kill();
		}
	}

	function startWave():Void
	{
		wave++;
		if (onWave != null)
			onWave(wave);
		if (wave == bossWave)
		{
			if (onBoss != null)
				onBoss();
			bossPending = true;
			bossTimer = BOSS_INTRO_TIME;
			return;
		}
		var count = waveData.baseCount + wave * waveData.countPerWave;
		if (count > waveData.maxCount)
			count = waveData.maxCount;
		var poolIndex = wave - 1;
		if (poolIndex >= waveData.waves.length)
			poolIndex = waveData.waves.length - 1;
		var pool = waveData.waves[poolIndex].types;
		for (i in 0...count)
			spawnWaveEnemy(new Enemies(pool[Std.random(pool.length)]));
	}

	function spawnWaveEnemy(e:Enemies):Void
	{
		var mw = arena.width;
		var mh = arena.height;
		switch (Std.random(4))
		{
			case 0:
				e.x = -e.width - SPAWN_OUT;
				e.y = edgeCoord(player.y, mh);
			case 1:
				e.x = mw + SPAWN_OUT;
				e.y = edgeCoord(player.y, mh);
			case 2:
				e.x = edgeCoord(player.x, mw);
				e.y = -e.height - SPAWN_OUT;
			default:
				e.x = edgeCoord(player.x, mw);
				e.y = mh + SPAWN_OUT;
		}
		e.entering = true;
		e.allowCollisions = NONE;
		e.aggroRange = 100000;
		register(e);
	}

	function edgeCoord(near:Float, max:Float):Float
	{
		var v = near + (Math.random() * 2 - 1) * SPAWN_SPREAD;
		if (v < SPAWN_PAD)
			v = SPAWN_PAD;
		if (v > max - SPAWN_TRIM + SPAWN_PAD)
			v = max - SPAWN_TRIM + SPAWN_PAD;
		return v;
	}

	public function spawnNear(e:Enemies):Void
	{
		e.x = player.x + player.width * 0.5 - e.width / 2 + Math.random() * 600 - 300;
		e.y = player.y + player.height * 0.5 - e.height / 2 + Math.random() * 400 - 200;
		register(e);
	}

	function register(e:Enemies):Void
	{
		e.target = player;
		e.pathing.map = arena.map;
		var sh = layers.addEnemy(e);
		if (e.gun != null)
			layers.entityLayer.add(e.gun);
		bodies.add(e);
		rigs.push(new EnemyRig(e, sh, new FlxObject(0, 0, 40, 40)));
	}

	public function firstInCircle(cx:Float, cy:Float, radius:Float, skipSeized:Bool = false):Enemies
	{
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
	{
		return rigs.length;
	}

	function waveCleared():Bool
	{
		for (rig in rigs)
			if (rig.enemy.exists && !rig.enemy.isDead)
				return false;
		return true;
	}
}

class EnemyRig
{
	public var enemy:Enemies;
	public var shadow:FlxSprite;
	public var hitbox:FlxObject;

	public function new(enemy:Enemies, shadow:FlxSprite, hitbox:FlxObject)
	{
		this.enemy = enemy;
		this.shadow = shadow;
		this.hitbox = hitbox;
	}
}
