package systems.perspective;

import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
import systems.Arena;
import systems.EnemyDirector;
import systems.RenderLayers;
import systems.weapons.Weapons;
import util.Paths;
import util.SideView;
import util.WorldClock;
import data.SideViewData.SideViewData;
import data.SideViewData.SideViewDataRegistry;

class PerspectiveShift
{
	static inline var HIT_COOLDOWN:Float = 0.9;

	public var locked:Bool = false;
	public var disabled:Bool = false;
	public var morphing(get, never):Bool;

	private var sv:SideViewData;
	private var arena:Arena;
	private var player:Player;
	private var director:EnemyDirector;
	private var combat:Weapons;
	private var totem:Totem;
	private var arrival:MeteorArrival;

	private var hitCd:Float = 0;

	private var phase:Int = 0;
	private var t:Float = 0;
	private var speedMult:Float = 1;
	private var worldT:Float = 0;
	private var startWorldT:Float = 0;
	private var endWorldT:Float = 0;
	private var blockSaved:Bool = false;
	private var holding:Bool = false;

	private var movers:Array<FlxSprite> = [];
	private var fromX:Array<Float> = [];
	private var fromY:Array<Float> = [];
	private var toX:Array<Float> = [];
	private var toY:Array<Float> = [];

	public function new(arena:Arena, player:Player, director:EnemyDirector, combat:Weapons, layers:RenderLayers)
	{
		this.arena = arena;
		this.player = player;
		this.director = director;
		this.combat = combat;
		sv = SideViewDataRegistry.get();

		arena.buildSideAssets();

		totem = new Totem(layers);
		arrival = new MeteorArrival(arena, player, totem, layers);
		arrival.onImpact = impactBlast;
	}

	function get_morphing():Bool
		return phase == 1 || phase == 3;

	function impactBlast(cx:Float, cy:Float):Void
	{
		hitCd = HIT_COOLDOWN;
		combat.hits.blastRadial(cx, cy - Totem.H * 0.3, sv.impactRadius, 900, sv.impactDamage);
	}

	public function onWave(n:Int):Void
	{
		arrival.tryBegin(n, locked || disabled);
	}

	public function onProbe(cx:Float, cy:Float, radius:Float):Void
	{
		if (disabled || !arrival.arrived || hitCd > 0 || morphing || locked || WorldClock.scale < 1 || combat.playerBusy)
			return;
		if (!totem.hitTest(cx, cy, radius))
			return;

		hitCd = HIT_COOLDOWN;
		totem.flash();
		FlxG.camera.shake(0.006, 0.4);

		if (phase == 0)
			beginMorph(true);
		else if (phase == 2)
			beginMorph(false);
	}

	public function cancelArrival():Void
	{
		arrival.cancel();
	}

	public function clearTotem():Void
	{
		arrival.cancel();
		totem.hide();
	}

	public function restoreTotem():Void
	{
		if (disabled)
			return;
		if (arrival.arrived)
			totem.show();
	}

	public function forceRevert():Void
	{
		if (phase == 1 || phase == 2)
		{
			beginMorph(false);
			speedMult = 2;
		}
	}

	function beginMorph(toSide:Bool):Void
	{
		SideView.morphing = true;
		SideView.active = false;
		SideView.platforms = [];

		combat.releaseHook();

		if (!holding)
		{
			blockSaved = player.blockMovement;
			holding = true;
		}
		player.blockMovement = true;
		player.velocity.set(0, 0);

		for (shot in director.shots.members)
			if (shot != null && shot.exists)
				shot.kill();

		startWorldT = worldT;
		endWorldT = toSide ? 1 : 0;
		phase = toSide ? 1 : 3;
		t = 0;
		speedMult = 1;

		captureMovers(toSide);
		totem.applyFace(toSide);

		FlxG.sound.play(Paths.sound(toSide ? "platswap_side" : "platswap_top"), 0.85);
		FlxG.camera.shake(0.004, 0.8);
	}

	function captureMovers(toSide:Bool):Void
	{
		movers = [];
		fromX = [];
		fromY = [];
		toX = [];
		toY = [];

		addMover(player, toSide, true);
		if (arrival.arrived)
			addMover(totem.sprite, toSide, false);
		director.eachEnemy(function(e)
		{
			if (e.seized || e.entering)
				return;
			addMover(e, toSide, false);
		});
	}

	function addMover(s:FlxSprite, toSide:Bool, isPlayer:Bool):Void
	{
		movers.push(s);
		fromX.push(s.x);
		fromY.push(s.y);

		var top = 120.0;
		var bottom = arena.height - 120.0;
		var feet = s.y + s.height;
		var targetX = s.x;
		if (targetX < 40)
			targetX = 40;
		if (targetX + s.width > arena.width - 40)
			targetX = arena.width - 40 - s.width;

		var targetFeet:Float;
		if (toSide)
		{
			if (isPlayer || s == totem.sprite)
				targetFeet = SideView.groundY;
			else
			{
				var yNorm = (feet - top) / (bottom - top);
				if (yNorm < 0)
					yNorm = 0;
				if (yNorm > 1)
					yNorm = 1;
				targetFeet = sv.enemyHighFeet + (SideView.groundY - sv.enemyHighFeet) * yNorm;
			}
		}
		else
		{
			if (s == totem.sprite)
				targetFeet = totem.homeY + Totem.H;
			else
			{
				var hNorm = (SideView.groundY - feet) / (SideView.groundY - sv.enemyHighFeet);
				if (hNorm < 0)
					hNorm = 0;
				if (hNorm > 1)
					hNorm = 1;
				targetFeet = bottom - (bottom - top - 100) * hNorm;
			}
		}

		if (s == totem.sprite && !toSide)
			targetX = totem.homeX;

		toX.push(targetX);
		toY.push(targetFeet - s.height);
	}

	public function update(elapsed:Float):Void
	{
		if (hitCd > 0)
			hitCd -= elapsed;

		arrival.update(elapsed);
		totem.update(elapsed, hitCd > 0);

		if (morphing)
		{
			t += elapsed * speedMult / (phase == 1 ? sv.morphTime : sv.revertTime);
			if (t > 1)
				t = 1;
			var e = t * t * (3 - 2 * t);

			worldT = startWorldT + (endWorldT - startWorldT) * e;
			arena.applySideMorph(worldT);

			for (i in 0...movers.length)
			{
				var s = movers[i];
				if (s == null || !s.exists)
					continue;
				s.x = fromX[i] + (toX[i] - fromX[i]) * e;
				s.y = fromY[i] + (toY[i] - fromY[i]) * e;
				s.velocity.set(0, 0);
			}

			combat.anchorHeld();

			if (t >= 1)
				finishMorph();
		}
	}

	function finishMorph():Void
	{
		if (phase == 1)
		{
			phase = 2;
			SideView.morphing = false;
			SideView.active = true;
			SideView.platforms = arena.sidePlatforms();
			player.setSideMode(true);
		}
		else
		{
			phase = 0;
			SideView.morphing = false;
			SideView.active = false;
			SideView.platforms = [];
			player.setSideMode(false);
			arena.applySideMorph(0);
		}
		player.blockMovement = blockSaved;
		holding = false;
	}
}
