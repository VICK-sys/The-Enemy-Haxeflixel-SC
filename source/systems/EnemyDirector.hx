package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.Enemies;
import entities.EnemyShot;
import systems.WaveData.WaveDataRegistry;

class EnemyDirector
{
	static inline var ENTER_MARGIN:Float = 40;

	public var wave:Int = 0;
	public var shots:FlxTypedGroup<EnemyShot>;
	public var onWave:Int->Void;

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
	}

	public function collide():Void
	{
		FlxG.collide(bodies, arena.map);
		FlxG.overlap(bodies, bodies, null, separateLive);
	}

	function separateLive(a:Enemies, b:Enemies):Bool
	{
		if (a.isDead || b.isDead)
			return false;
		return FlxObject.separate(a, b);
	}

	public function update(elapsed:Float):Void
	{
		if (!status.dead)
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
				status.hurtPlayer(rig.hitbox, e.contactDamage);

				if (e.shootRequested)
				{
					e.shootRequested = false;
					var sx = e.x + e.width / 2;
					var sy = e.y + e.height / 2;
					var sdx = player.x + player.width * 0.5 - sx;
					var sdy = player.y + player.height * 0.5 - sy;
					var sl = Math.sqrt(sdx * sdx + sdy * sdy);
					if (sl > 0)
						shots.recycle(EnemyShot).fire(sx, sy, sdx / sl, sdy / sl, e.shotDamage);
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
		for (shot in shots.members)
		{
			if (shot == null || !shot.exists)
				continue;
			var shx = shot.x + shot.width / 2;
			var shy = shot.y + shot.height / 2;
			if (arena.wallAt(shx + shot.dirX * 10, shy + shot.dirY * 10))
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
				e.x = -e.width - 40;
				e.y = 60 + Math.random() * (mh - 240);
			case 1:
				e.x = mw + 40;
				e.y = 60 + Math.random() * (mh - 240);
			case 2:
				e.x = 60 + Math.random() * (mw - 240);
				e.y = -e.height - 40;
			default:
				e.x = 60 + Math.random() * (mw - 240);
				e.y = mh + 40;
		}
		e.entering = true;
		e.allowCollisions = NONE;
		e.aggroRange = 100000;
		register(e);
	}

	public function spawnCenter(e:Enemies):Void
	{
		e.x = arena.width / 2 - e.width / 2 + Math.random() * 300 - 150;
		e.y = arena.height / 2 - e.height / 2 + Math.random() * 200 - 100;
		register(e);
	}

	function register(e:Enemies):Void
	{
		e.target = player;
		e.pathing.map = arena.map;
		var sh = layers.addEnemy(e);
		bodies.add(e);
		rigs.push(new EnemyRig(e, sh, new FlxObject(0, 0, 40, 40)));
	}

	public function forEachEnemy(f:Enemies->Void):Void
	{
		for (rig in rigs)
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
