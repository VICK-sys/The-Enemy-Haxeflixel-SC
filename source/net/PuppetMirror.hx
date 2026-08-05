package net;

import flixel.util.FlxTimer;
import entities.HealthPickup;
import entities.enemy.Enemies;
import systems.enemy.EnemyDirector;
import systems.Fx;
import ui.Hud;
import systems.Pickups;
import systems.Scraps;
import systems.PlayerCombat;
import systems.RenderLayers;

class PuppetMirror
{
	static inline var LERP:Float = 12;
	static inline var SNAP_DIST:Float = 300;
	static inline var CLAIM_CREDIT:Float = 1.5;

	private var director:EnemyDirector;
	private var pickups:Pickups;
	private var scraps:Scraps;
	private var status:PlayerCombat;
	private var hud:Hud;
	private var layers:RenderLayers;

	private var puppets:Map<Int, Enemies> = new Map();
	private var targetsX:Map<Int, Float> = new Map();
	private var targetsY:Map<Int, Float> = new Map();
	private var gunTX:Map<Int, Float> = new Map();
	private var gunTY:Map<Int, Float> = new Map();
	private var gunTA:Map<Int, Float> = new Map();
	private var puppetPickups:Map<Int, HealthPickup> = new Map();
	private var claimedAt:Map<Int, Float> = new Map();
	private var clock:Float = 0;
	private var pendingBossIds:Array<Int> = [];
	private var bossPack:Array<Enemies> = [];

	public function new(director:EnemyDirector, pickups:Pickups, scraps:Scraps, status:PlayerCombat, hud:Hud, layers:RenderLayers)
	{
		this.director = director;
		this.pickups = pickups;
		this.scraps = scraps;
		this.status = status;
		this.hud = hud;
		this.layers = layers;
	}

	public function noteClaim(netId:Int):Void
		claimedAt.set(netId, clock);

	public function expectBossPack(ids:Array<Int>):Void
	{
		resetBossPack();
		if (ids == null)
			return;
		for (id in ids)
		{
			var boss = puppets.get(id);
			if (boss != null)
				bossPack.push(boss);
			else
				pendingBossIds.push(id);
		}
		showBossPackWhenReady();
	}

	public function resetBossPack():Void
	{
		pendingBossIds = [];
		bossPack = [];
	}

	function showBossPackWhenReady():Void
	{
		if (pendingBossIds.length == 0 && bossPack.length > 0)
			hud.trackBosses(bossPack);
	}

	public function update(elapsed:Float):Void
	{
		clock += elapsed;

		var k = Math.min(1, LERP * elapsed);
		for (id in puppets.keys())
		{
			var e = puppets.get(id);
			if (e == null || !e.exists || e.seized)
				continue;
			var tx = targetsX.get(id);
			var ty = targetsY.get(id);
			if (Math.abs(e.x - tx) + Math.abs(e.y - ty) > SNAP_DIST)
			{
				e.x = tx;
				e.y = ty;
			}
			else
			{
				e.x += (tx - e.x) * k;
				e.y += (ty - e.y) * k;
			}

			if (e.gun != null && gunTX.exists(id))
			{
				e.gun.x += (gunTX.get(id) - e.gun.x) * k;
				e.gun.y += (gunTY.get(id) - e.gun.y) * k;
				var turn = ((gunTA.get(id) - e.gun.angle) % 360 + 540) % 360 - 180;
				e.gun.angle += turn * k;
			}
		}
	}

	public function apply(msg:Dynamic):Void
	{
		director.wave = msg.w;

		var seen:Map<Int, Bool> = new Map();
		var en:Array<Dynamic> = msg.en;
		for (row in en)
		{
			var id:Int = row[0];
			seen.set(id, true);

			var e = puppets.get(id);
			if (e == null)
			{
				if (!data.EnemyData.EnemyDataRegistry.has(row[1]))
					continue;
				e = new Enemies(row[1], row[2], row[3]);
				e.netId = id;
				cast(director, PuppetDirector).addPuppet(e);
				puppets.set(id, e);
				targetsX.set(id, row[2]);
				targetsY.set(id, row[3]);
			}

			targetsX.set(id, row[2]);
			targetsY.set(id, row[3]);
			e.flipX = row[4] == 1;
			e.hp = row[6];

			var anim:String = row[5];
			if (anim != null && e.animation.name != anim && e.animation.getByName(anim) != null)
				e.animation.play(anim);
			if (anim != null)
				e.buried = anim == "mound";

			var dead = row[7] == 1;
			if (dead && !e.isDead)
			{
				e.isDead = true;
				e.velocity.set(0, 0);
				var when = claimedAt.get(id);
				if (when != null && clock - when < CLAIM_CREDIT)
				{
					status.rewardKill();
					scraps.drop(e.x + e.width / 2, e.y + e.height / 2);
				}
			}

			if (e.gun != null && row.length > 8)
			{
				var gkey:String = row[8];
				if (gkey != null && (e.gun.graphic == null || e.gun.graphic.key != gkey) && openfl.utils.Assets.exists(gkey))
				{
					e.gun.loadGraphic(gkey);
					e.gun.origin.set(e.gun.frameWidth * 0.5, e.gun.frameHeight * 0.5);
					e.gun.scale.set(4, 4);
				}
				gunTX.set(id, row[9]);
				gunTY.set(id, row[10]);
				gunTA.set(id, row[11]);
				e.gun.flipY = row[12] == 1;
			}

			if (pendingBossIds.remove(id))
			{
				bossPack.push(e);
				showBossPackWhenReady();
			}
		}

		for (id in puppets.keys())
		{
			if (!seen.exists(id))
			{
				var e = puppets.get(id);
				if (e != null)
					e.kill();
				puppets.remove(id);
				targetsX.remove(id);
				targetsY.remove(id);
				gunTX.remove(id);
				gunTY.remove(id);
				gunTA.remove(id);
				claimedAt.remove(id);
			}
		}

		var pkSeen:Map<Int, Bool> = new Map();
		var pk:Array<Dynamic> = msg.pk;
		for (row in pk)
		{
			var id:Int = row[0];
			pkSeen.set(id, true);
			var p = puppetPickups.get(id);
			if (p == null)
			{
				p = pickups.group.recycle(HealthPickup);
				pickups.mount(p);
				p.drop(row[1] + p.width / 2, row[2] + p.height / 2);
				p.netId = id;
				p.puppet = true;
				puppetPickups.set(id, p);
			}
			p.setPosition(row[1], row[2]);
		}
		for (id in puppetPickups.keys())
		{
			if (!pkSeen.exists(id))
			{
				var p = puppetPickups.get(id);
				if (p != null && p.exists && p.netId == id)
					p.kill();
				puppetPickups.remove(id);
			}
		}
	}

	public function blastAt(x:Float, y:Float):Void
	{
		for (i in 0...Scraps.BOSS_SCRAP)
			scraps.drop(x, y);
		var boom = Fx.bossBlast(x, y);
		layers.entityLayer.add(boom);
		new FlxTimer().start(1.2, function(_)
		{
			layers.entityLayer.remove(boom, true);
			boom.destroy();
		});
	}
}
