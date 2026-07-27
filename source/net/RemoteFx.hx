package net;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.Arrow;
import entities.weapon.Bullet;
import entities.weapon.HookShot;
import entities.weapon.SlashEffect;
import entities.weapon.ThrownWeapon;
import systems.enemy.EnemyDirector;
import systems.Fx;
import systems.RenderLayers;
import systems.weapons.ArrowRain;
import systems.weapons.ArrowStorm;
import systems.weapons.HitPipeline;
import systems.weapons.Rope;
import systems.weapons.Shockwave;
import systems.weapons.SuperOrbit;
import systems.weapons.WeaponMode;
import data.WeaponData.WeaponDataRegistry;
import util.GhostTrail;
import util.Paths;

class RemoteFx
{
	private var cfg = WeaponDataRegistry.get();
	private var fx:Fx;

	private var slashes:FlxTypedGroup<SlashEffect>;
	private var arrows:FlxTypedGroup<Arrow>;
	private var bullets:FlxTypedGroup<Bullet>;
	private var rope:FlxTypedGroup<FlxSprite>;
	private var hook:HookShot;
	private var thrown:ThrownWeapon;
	private var shock:Shockwave;
	private var rain:ArrowRain;
	private var thrownTrail:GhostTrail;

	private var avatar:RemoteAvatar;
	private var blades:SuperOrbit;
	private var storm:ArrowStorm;
	private var arms:RemoteArms;

	static inline var HOOK_LERP:Float = 22;
	static inline var THROWN_CORRECT:Float = 6;

	private var thrownTX:Float = 0;
	private var thrownTY:Float = 0;
	private var hookTX:Float = 0;
	private var hookTY:Float = 0;
	private var handTX:Float = 0;
	private var handTY:Float = 0;
	private var handCX:Float = 0;
	private var handCY:Float = 0;

	public function new(state:FlxState, layers:RenderLayers, director:EnemyDirector, hits:HitPipeline, fx:Fx, avatar:RemoteAvatar)
	{
		this.fx = fx;
		this.avatar = avatar;

		shock = new Shockwave(director, hits);
		shock.stunTime = 0;
		rain = new ArrowRain(fx, hits);
		rain.cosmetic = true;

		slashes = new FlxTypedGroup<SlashEffect>();
		arrows = new FlxTypedGroup<Arrow>();
		bullets = new FlxTypedGroup<Bullet>();
		rope = new FlxTypedGroup<FlxSprite>();

		hook = new HookShot();
		hook.kill();
		thrown = new ThrownWeapon();
		thrown.kill();
		thrownTrail = new GhostTrail("items/hammer", 0.45, 3, 0.035);

		blades = SuperOrbit.decoration(avatar.sprite, fx);
		var dummyBow = new FlxSprite();
		dummyBow.loadGraphic(Paths.image("items/crossbow"));
		storm = new ArrowStorm(avatar.sprite, dummyBow, rain);
		arms = new RemoteArms(avatar.sprite);

		var below = state.members.indexOf(layers.entityLayer);
		state.insert(below, shock.cracks);
		state.insert(below, shock.rings);
		state.insert(below, rain.markers);
		state.insert(below, blades.trail.group);
		state.insert(below, blades.backLayer);
		for (r in arms.ropes)
			state.insert(below, r);
		for (c in arms.claws)
			state.insert(below, c);
		state.add(arrows);
		state.add(bullets);
		state.add(rain.arrows);
		state.add(slashes);
		state.add(rope);
		state.add(hook);
		state.add(thrownTrail.group);
		state.add(thrown);
		state.add(blades.frontLayer);
		state.add(storm.trail.group);
		state.add(storm.superArrow);
	}

	public function superActivate(kind:Int):Void
	{
		switch (kind)
		{
			case 0:
				blades.activate();
			case 2:
				storm.activate();
			default:
		}
	}

	public function superLaunch(tx:Float, ty:Float):Void
		blades.tryLaunch(tx, ty);

	public function setBladesActive(on:Bool):Void
	{
		if (!on && blades.active())
			blades.clear();
	}

	public function slam(x:Float, y:Float):Void
	{
		fx.sparksAt(x, y);
		fx.slamShake();
		shock.blast(x, y, false);
		FlxG.sound.play(Paths.sound("hammer"), 1);
	}

	public function setArms(rows:Array<Dynamic>):Void
		arms.set(rows);

	public function attack(modeIndex:Int, pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float, tx:Float, ty:Float, power:Float):Void
	{
		var mode = Type.createEnumIndex(WeaponMode, modeIndex);
		switch (mode)
		{
			case Swing:
				slashes.recycle(SlashEffect).fire(pmx + dx * cfg.swing.spawnDist, pmy + dy * cfg.swing.spawnDist, dx, dy, aimDeg, cfg.swing.effectScale);
				FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.5);

			case Jab:
				slashes.recycle(SlashEffect).fire(pmx + dx * cfg.jab.spawnDist, pmy + dy * cfg.jab.spawnDist, dx, dy, aimDeg, cfg.jab.effectScale);
				FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.5);

			case Shoot:
				var rc = cfg.revolver;
				bullets.recycle(Bullet).fire(pmx + dx * 24, pmy + dy * 24, dx, dy, aimDeg, rc.damage, rc.speed, rc.range, rc.knock);
				fx.sparksAt(pmx + dx * 24, pmy + dy * 24);
				FlxG.sound.play(Paths.sound("revolver"), 0.5);

			case Fan:
				fx.sparksAt(pmx + dx * 24, pmy + dy * 24);
				FlxG.sound.play(Paths.sound("enemies/shoot"), 0.5);

			case Bow:
				var bc = cfg.bowCharge;
				arrows.recycle(Arrow).fire(pmx + dx * 10, pmy + dy * 10, dx, dy, aimDeg, 1, 1 + power * bc.speedBonus,
					1 + power * bc.sizeBonus, 1);
				FlxG.sound.play(Paths.sound("bow"), 0.7 + power * 0.3);
				if (power >= 1)
					fx.sparksAt(pmx + dx * 30, pmy + dy * 30);

			case Rain:
				rain.fire(tx, ty, pmx, pmy);
				FlxG.sound.play(Paths.sound("bow"), 0.5);

			case Throw:
				FlxG.sound.play(Paths.sound("weapon/throw"), 0.5);

			case Hook:
				FlxG.sound.play(Paths.sound("weapon/throw"), 0.5);
		}
	}

	public function spark(x:Float, y:Float):Void
		fx.sparksAt(x, y);

	public function setHook(on:Bool, hx:Float, hy:Float, ang:Float, handX:Float, handY:Float):Void
	{
		if (!on)
		{
			if (hook.exists)
			{
				hook.kill();
				Rope.clear(rope);
			}
			return;
		}

		if (!hook.exists)
		{
			hook.revive();
			hook.setPosition(hx, hy);
			handCX = handX;
			handCY = handY;
		}
		hook.angle = ang;
		hook.velocity.set(0, 0);
		hookTX = hx;
		hookTY = hy;
		handTX = handX;
		handTY = handY;
	}

	public function setThrown(on:Bool, tx:Float, ty:Float, vx:Float, vy:Float):Void
	{
		if (!on)
		{
			if (thrown.exists)
				thrown.kill();
			return;
		}
		if (!thrown.exists)
		{
			var sp = Math.sqrt(vx * vx + vy * vy);
			thrown.throwAt(tx + thrown.width / 2, ty + thrown.height / 2, sp > 0 ? vx / sp : 1, sp > 0 ? vy / sp : 0);
		}

		thrown.velocity.set(vx, vy);
		thrownTX = tx;
		thrownTY = ty;
	}

	public function update(elapsed:Float):Void
	{
		shock.update(elapsed);
		rain.update(elapsed);
		blades.update(elapsed);
		storm.update(elapsed);
		arms.update(elapsed);

		var stamp = thrownTrail.tick(elapsed);
		if (thrown.exists)
		{
			var k = Math.min(1, THROWN_CORRECT * elapsed);
			thrown.x += (thrownTX - thrown.x) * k;
			thrown.y += (thrownTY - thrown.y) * k;
			if (stamp)
				thrownTrail.stamp(thrown);
		}

		if (hook.exists)
		{
			var k = Math.min(1, HOOK_LERP * elapsed);
			hook.x += (hookTX - hook.x) * k;
			hook.y += (hookTY - hook.y) * k;
			handCX += (handTX - handCX) * k;
			handCY += (handTY - handCY) * k;
			Rope.line(rope, handCX, handCY, hook.x + hook.width / 2, hook.y + hook.height / 2);
		}
	}
}
