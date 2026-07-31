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
import systems.weapons.HeldWeapon;
import systems.weapons.WeaponMode;
import systems.weapons.YoyoFlight;
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
	private var yoyo:YoyoFlight;
	private var rain:ArrowRain;
	private var thrownTrail:GhostTrail;

	private var avatar:RemoteAvatar;
	private var dummyBow:FlxSprite;
	private var stormPending:Bool = false;
	private var storm:ArrowStorm;

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
	private var yoyoOn:Bool = false;
	private var yoyoTX:Float = 0;
	private var yoyoTY:Float = 0;
	private var yoyoAng:Float = 0;

	public function new(state:FlxState, layers:RenderLayers, director:EnemyDirector, hits:HitPipeline, fx:Fx, avatar:RemoteAvatar)
	{
		this.fx = fx;
		this.avatar = avatar;

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
		yoyo = new YoyoFlight();
		thrownTrail = new GhostTrail("items/hammer", 0.45, 3, 0.035);

		dummyBow = new FlxSprite();
		dummyBow.loadGraphic(Paths.image("items/crossbow"));
		storm = new ArrowStorm(avatar.sprite, dummyBow, rain);

		var below = state.members.indexOf(layers.entityLayer);
		state.insert(below, rain.markers);
		state.add(arrows);
		state.add(bullets);
		state.add(rain.arrows);
		state.add(slashes);
		state.add(rope);
		state.add(hook);
		state.add(yoyo.string);
		state.add(yoyo.yoyo);
		state.add(thrownTrail.group);
		state.add(thrown);
		state.add(storm.trail.group);
		state.add(storm.superArrow);
	}

	public function superActivate(kind:Int):Void
	{
		switch (kind)
		{
			case 0:
				FlxG.sound.play(Paths.sound("hammer"), 0.35);
			case 1:
				FlxG.sound.play(Paths.sound("power_up"), 0.5);
			case 2:
				storm.paint(avatar.hue);
				dummyBow.loadGraphic(util.HuePalette.graphic("items/crossbow", avatar.hue));
				stormPending = true;
			case 3:
				util.Sfx.at("arms_deploy", avatar.sprite.x + avatar.sprite.width * 0.5, avatar.sprite.y, 0.8);
			default:
		}
	}

	public function superLaunch(tx:Float, ty:Float):Void
	{
		if (stormPending)
		{
			stormPending = false;
			storm.beginAt(tx, ty);
			return;
		}
		fx.sparksAt(tx, ty);
		FlxG.sound.play(Paths.sound("hammer"), 0.6);
	}

	public function attack(modeIndex:Int, pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float, tx:Float, ty:Float, power:Float,
			perfect:Bool = false):Void
	{
		var mode = Type.createEnumIndex(WeaponMode, modeIndex);
		switch (mode)
		{
			case Swing:
				slashes.recycle(SlashEffect).fire(pmx + dx * cfg.swing.spawnDist, pmy + dy * cfg.swing.spawnDist, dx, dy, aimDeg, cfg.swing.effectScale);
				FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.5);

			case Bash:
				slashes.recycle(SlashEffect).fire(pmx + dx * cfg.bash.spawnDist, pmy + dy * cfg.bash.spawnDist, dx, dy, aimDeg,
					cfg.bash.effectScale, cfg.bash.effect == null ? "sword" : cfg.bash.effect);
				FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.5);

			case Giga:
				slashes.recycle(SlashEffect).fire(pmx + dx * cfg.giga.spawnDist, pmy + dy * cfg.giga.spawnDist, dx, dy, aimDeg, cfg.giga.effectScale);
				FlxG.sound.play(Paths.sound("weapon/gigaSwing"), 0.6);

			case Yoyo:
				FlxG.sound.play(Paths.sound("weapon/throw"), 0.35);

			case Shoot:
				var rc = cfg.revolver;
				bullets.recycle(Bullet).fire(pmx + dx * 24, pmy + dy * 24, dx, dy, aimDeg, rc.damage, rc.speed, rc.range, rc.knock);
				fx.sparksAt(pmx + dx * 24, pmy + dy * 24);
				FlxG.sound.play(Paths.sound("revolver"), 0.5);

			case BigShot:
				var bc = cfg.revolver;
				var big = bullets.recycle(Bullet);
				big.setSprite("bullets/shotgun_bullet_player");
				big.fire(pmx + dx * 24, pmy + dy * 24, dx, dy, aimDeg, bc.bigDamage, bc.speed, bc.range, bc.knock, bc.bigRadius);
				fx.sparksAt(pmx + dx * 24, pmy + dy * 24);
				FlxG.sound.play(Paths.sound("revolver"), 0.6);

			case Pellet:
				var pc = cfg.revolver;
				bullets.recycle(Bullet).fire(pmx + dx * 24, pmy + dy * 24, dx, dy, aimDeg, pc.damage, pc.speed, pc.range, pc.knock);
				FlxG.sound.play(Paths.sound("revolver"), 0.45);

			case Bow:
				var bc = cfg.bowCharge;
				var arrow = arrows.recycle(Arrow);
				arrow.paint(avatar.hue, perfect);
				arrow.fire(pmx + dx * 10, pmy + dy * 10, dx, dy, aimDeg, 1, 1 + power * bc.speedBonus,
					1 + power * bc.sizeBonus, 1);
				FlxG.sound.play(Paths.sound("crossbow_fire"), 0.7 + power * 0.3);
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

	public function setYoyo(on:Bool, px:Float, py:Float, ang:Float):Void
	{
		if (!on)
		{
			if (yoyoOn)
			{
				yoyoOn = false;
				yoyo.stop();
			}
			return;
		}

		if (!yoyoOn)
		{
			yoyoOn = true;
			yoyo.drive(px, py, ang, handOfAvatarX(), handOfAvatarY());
		}
		yoyoTX = px;
		yoyoTY = py;
		yoyoAng = ang;
	}

	function handOfAvatarX():Float
		return avatar.sprite.x + HeldWeapon.HAND_DX;

	function handOfAvatarY():Float
		return avatar.sprite.y + HeldWeapon.HAND_DY;

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
		rain.hue = avatar.hue;
		yoyo.setHue(avatar.hue);
		hook.paint(avatar.hue);
		thrown.paint(avatar.hue);

		rain.update(elapsed);
		storm.update(elapsed);
		if (yoyoOn)
		{
			var yk = Math.min(1, HOOK_LERP * elapsed);
			yoyo.drive(yoyo.cx + (yoyoTX - yoyo.cx) * yk, yoyo.cy + (yoyoTY - yoyo.cy) * yk, yoyoAng,
				handOfAvatarX(), handOfAvatarY());
		}

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
