package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
import systems.world.Arena;
import systems.enemy.EnemyDirector;
import systems.PlayerCombat;
import systems.Fx;
import systems.Pickups;

class Weapons
{
	static inline var WEAPON_COUNT:Int = 4;
	static inline var BOW_MUZZLE:Float = 70;

	public var held:HeldWeapon;
	public var hits:HitPipeline;
	public var swing:SwingAttack;
	public var bash:SwingAttack;
	public var gigaSwing:SwingAttack;
	public var giga:GigaCharge;
	public var yoyoJab:YoyoJab;
	public var revolver:RevolverAttack;
	public var bow:BowAttack;
	public var throwAttack:ThrowAttack;
	public var hookAttack:HookAttack;
	public var bounce:HammerBounce;
	public var arrowStorm:ArrowStorm;
	public var yoyoSpin:YoyoSpin;
	public var weapon:Int = 0;
	public var disabled:Bool = false;
	public var onAttack:(WeaponMode, Float, Float, Float, Float, Float, Float, Float, Float, Bool) -> Void;
	public var onSuper:Int -> Void;
	public var onSuperLaunch:(Float, Float) -> Void;

	private var player:Player;
	private var status:PlayerCombat;
	private var wasHookBusy:Bool = false;

	public function new(player:Player, heldSprite:FlxSprite, arena:Arena, director:EnemyDirector, status:PlayerCombat, fx:Fx, pickups:Pickups, scraps:systems.Scraps)
	{
		this.player = player;
		this.status = status;
		hits = new HitPipeline(status, fx, pickups, scraps, director);
		hits.owner = player;
		held = new HeldWeapon(player, heldSprite);
		var weaponCfg = data.WeaponData.WeaponDataRegistry.get();
		swing = new SwingAttack(director, hits, fx, weaponCfg.swing);
		bash = new SwingAttack(director, hits, fx, weaponCfg.bash);
		swing.onConnect = held.impactPose;
		bash.onConnect = held.impactPose;
		gigaSwing = new SwingAttack(director, hits, fx, weaponCfg.giga);
		gigaSwing.onConnect = function()
		{
			held.impactPose();
			if (gigaSwing.boosted)
			{
				var punch = FlxG.sound.play(util.Paths.sound("weapon/gigaHit"), 1.0);
				if (punch != null)
					punch.pitch = 0.82;
				FlxG.sound.play(util.Paths.sound("hammer"), 0.5);
			}
			else
				FlxG.sound.play(util.Paths.sound("weapon/gigaHit"), 0.9);
		}
		giga = new GigaCharge(held, fx, weaponCfg.giga);
		yoyoJab = new YoyoJab(director, hits, fx);
		yoyoJab.flight.setHue(util.SaveData.playerHue());
		revolver = new RevolverAttack(arena, director, fx, hits, status);
		bow = new BowAttack(arena, director, fx, hits);
		throwAttack = new ThrowAttack(player, heldSprite, arena, director, status, hits);
		throwAttack.onCaught = function() swing.coolFor(weaponCfg.thrown.catchCooldown);
		hookAttack = new HookAttack(player, arena, director, status, hits);
		bounce = new HammerBounce(player, status, fx, hits, heldSprite);
		bounce.onSlam = function(cx, cy)
		{
			if (onSuperLaunch != null)
				onSuperLaunch(cx, cy);
		}
		arrowStorm = new ArrowStorm(player, held.sprite, bow.rain);
		arrowStorm.paint(util.SaveData.playerHue());
		arrowStorm.onMarked = function(x, y)
		{
			if (onSuperLaunch != null)
				onSuperLaunch(x, y);
		}
		yoyoSpin = new YoyoSpin(player, director, hits, yoyoJab.flight);
		bow.onFull = function()
		{
			var a = aimFrom(held.handX(), held.handY());
			fx.chargePop(held.handX() + a.dx * BOW_MUZZLE, held.handY() + a.dy * BOW_MUZZLE);
			held.flash();
		}
	}

	public var superBusy(get, never):Bool;

	function get_superBusy():Bool
		return bounce.active || arrowStorm.busy || yoyoSpin.active;

	public var playerBusy(get, never):Bool;

	function get_playerBusy():Bool
		return superBusy;

	public function anchorHeld():Void
	{
		if (!superBusy)
			held.anchor();
	}

	public function releaseHook():Void
	{
		if (hookAttack.busy)
			hookAttack.drop();
	}

	public function update(elapsed:Float):Void
	{
		giga.tick();
		status.meterLocked = superBusy || revolver.twinActive;
		if (disabled)
		{
			held.sprite.visible = false;
			return;
		}

		held.charge = bow.charging ? bow.charge : (giga.engaged ? giga.progress : 0);
		if (!superBusy)
			held.update(elapsed);
		updateAttackInput();
		swing.update(elapsed, player.x + player.width * 0.5, player.y + player.height * 0.5);
		bash.update(elapsed, player.x + player.width * 0.5, player.y + player.height * 0.5);
		gigaSwing.update(elapsed, player.x + player.width * 0.5, player.y + player.height * 0.5);
		if (status.dead && yoyoJab.active)
			yoyoJab.stop();
		yoyoJab.update(elapsed, handX(), handY(), util.Controls.aimX(), util.Controls.aimY());
		bow.update(elapsed);
		var gunAim = aimFrom(held.handX(), held.handY());
		if (status.dead)
		{
			revolver.endTwin();
			bow.hushReload();
		}
		revolver.update(elapsed, held.handX(), held.handY(), gunAim.deg);
		revolver.placeTwin(held.sprite, player.x + player.width * 0.5, player.y + player.height * 0.5, handX(), handY(), gunAim.dx, gunAim.dy);
		if (held.kind == HeldWeapon.REVOLVER && revolver.isReloading)
			held.reloadPose(revolver.reloadProgress);
		hookAttack.update(elapsed);
		throwAttack.update(elapsed);
		if (status.dead && bounce.active)
			bounce.cancel();
		bounce.update(elapsed);
		arrowStorm.update(elapsed);
		if (status.dead && yoyoSpin.active)
			yoyoSpin.cancel();
		if (status.dead && arrowStorm.active)
			arrowStorm.cancel();
		yoyoSpin.update(elapsed, handX(), handY());
		updateHeldHook();
	}

	public function hasSuper():Bool
		return weapon != 1 || !revolver.twinActive;

	public function repaint():Void
	{
		held.repaint();
		yoyoJab.flight.setHue(util.SaveData.playerHue());
		arrowStorm.paint(util.SaveData.playerHue());
		bow.rain.hue = util.SaveData.playerHue();
	}

	public var meleeShown(get, never):Float;

	function get_meleeShown():Float
	{
		if (!held.swinging)
			return 0;
		return held.attack == Bash ? bash.reach : (held.attack == Swing ? swing.reach : (held.attack == Giga ? gigaSwing.reach : 0));
	}

	public var meleeLift(get, never):Float;

	function get_meleeLift():Float
	{
		if (!held.swinging)
			return 0;
		return held.attack == Bash ? bash.hitLift : (held.attack == Swing ? swing.hitLift : (held.attack == Giga ? gigaSwing.hitLift : 0));
	}

	public var meleePush(get, never):Float;

	function get_meleePush():Float
	{
		if (!held.swinging)
			return 0;
		return held.attack == Bash ? bash.hitPush : (held.attack == Swing ? swing.hitPush : (held.attack == Giga ? gigaSwing.hitPush : 0));
	}

	public function equip(i:Int):Void
	{
		weapon = i < 0 || i >= WEAPON_COUNT ? 0 : i;
		bow.cancelCharge();
		giga.letGo();
		revolver.reset();
		held.setKind(weapon);
	}

	function handX():Float
		return player.x + HeldWeapon.HAND_DX;

	function handY():Float
		return player.y + HeldWeapon.HAND_DY;

	function aimFromPlayer():{dx:Float, dy:Float, deg:Float}
		return aimFrom(player.x + player.width * 0.5, player.y + player.height * 0.5);

	function aimFrom(ox:Float, oy:Float):{dx:Float, dy:Float, deg:Float}
	{
		var dx:Float = util.Controls.aimX() - ox;
		var dy:Float = util.Controls.aimY() - oy;
		var len:Float = Math.sqrt(dx * dx + dy * dy);
		if (len < 0.001)
		{
			dx = 1;
			dy = 0;
			len = 1;
		}
		dx /= len;
		dy /= len;
		return {dx: dx, dy: dy, deg: Math.atan2(dy, dx) * 180 / Math.PI};
	}

	function updateBowInput():Void
	{
		if (throwAttack.airborne)
		{
			bow.cancelCharge();
			return;
		}

		if (util.Controls.secondHeld() && bash.ready && !held.swinging)
		{
			var aim = aimFromPlayer();
			var pmx = player.x + player.width * 0.5;
			var pmy = player.y + player.height * 0.5;
			bow.cancelCharge();
			held.beginSwing(aim.deg, Bash);
			emitAttack(Bash, pmx, pmy, aim.dx, aim.dy, aim.deg);
			bash.fire(pmx, pmy, aim.dx, aim.dy, aim.deg, held.handX(), held.handY());
			return;
		}

		if (util.Controls.attackHeld() && !bow.charging)
			bow.beginCharge();

		if (bow.charging && !util.Controls.attackHeld())
		{
			var aim = aimFromPlayer();
			var shot = aimFrom(held.handX(), held.handY());
			var power = bow.charge;
			held.beginSwing(aim.deg, Bow);
			held.loose(power);
			var perfect = bow.release(held.handX(), held.handY(), shot.dx, shot.dy, shot.deg);
			emitAttack(Bow, held.handX(), held.handY(), shot.dx, shot.dy, shot.deg, power, perfect);
		}
	}

	function updateGunInput():Void
	{
		if (throwAttack.airborne)
			return;

		if (util.Controls.justPressed(util.Controls.RELOAD))
			revolver.beginReload();

		var aim = aimFromPlayer();
		var shot = aimFrom(held.handX(), held.handY());

		if (util.Controls.secondHeld() && revolver.canBig())
		{
			held.beginSwing(aim.deg, BigShot);
			held.kick();
			emitAttack(BigShot, held.handX(), held.handY(), shot.dx, shot.dy, shot.deg);
			revolver.fireBig(held.handX(), held.handY(), shot.dx, shot.dy, shot.deg);
			return;
		}

		if (util.Controls.attackHeld() && revolver.canFire())
		{
			held.beginSwing(aim.deg, Shoot);
			held.kick();
			emitAttack(Shoot, held.handX(), held.handY(), shot.dx, shot.dy, shot.deg);
			revolver.fire(held.handX(), held.handY(), shot.dx, shot.dy, shot.deg);
		}
	}

	function updateAttackInput():Void
	{
		if (status.dead || superBusy)
		{
			bow.cancelCharge();
			return;
		}

		if (util.Controls.justPressed(util.Controls.SUPER) && hasSuper() && status.canSuper() && !throwAttack.airborne
			&& !hookAttack.busy)
		{
			yoyoJab.stop();
			if (weapon == 1)
				revolver.activateTwin();
			else
			{
				status.spendSuper();
				switch (weapon)
				{
					case 0: bounce.activate();
					case 2: arrowStorm.activate();
					default: yoyoSpin.activate(aimFromPlayer().deg);
				}
			}
			if (onSuper != null)
				onSuper(weapon);
			return;
		}

		if (weapon == 1)
		{
			updateGunInput();
			return;
		}

		if (weapon == 2)
		{
			updateBowInput();
			return;
		}

		if (weapon == 3)
		{
			updateYoyoInput();
			return;
		}

		var leftClick = util.Controls.attackHeld();
		var rightClick = util.Controls.secondHeld();
		if (throwAttack.airborne)
			return;

		var pmx:Float = player.x + player.width * 0.5;
		var pmy:Float = player.y + player.height * 0.5;
		var aim = aimFromPlayer();
		var dx:Float = aim.dx;
		var dy:Float = aim.dy;
		var aimDeg:Float = aim.deg;

		if (giga.engaged && !leftClick)
		{
			var strike = giga.ready;
			var timed = giga.sparkTimed;
			giga.letGo();
			if (strike)
			{
				held.beginSwing(aimDeg, Giga);
				if (timed)
					held.flash();
				emitAttack(Giga, pmx, pmy, dx, dy, aimDeg, 0, timed);
				gigaSwing.fire(pmx, pmy, dx, dy, aimDeg, null, null, timed);
			}
			return;
		}

		if (!leftClick && !rightClick)
			return;

		if (held.swinging)
			return;

		if (leftClick)
		{
			if (util.Controls.attackJustPressed())
			{
				if (!swing.ready)
					return;
				held.beginSwing(aimDeg, Swing);
				emitAttack(Swing, pmx, pmy, dx, dy, aimDeg);
				swing.fire(pmx, pmy, dx, dy, aimDeg);
			}
			else if (swing.ready)
				giga.charge(FlxG.elapsed);
		}
		else
		{
			if (!swing.ready)
				return;
			throwAttack.launch(pmx, pmy, dx, dy);
			emitAttack(Throw, pmx, pmy, dx, dy, aimDeg);
		}
	}

	function updateYoyoInput():Void
	{
		if (throwAttack.airborne)
			return;

		var aim = aimFromPlayer();

		if (hookAttack.holding)
		{
			if (util.Controls.attackJustPressed())
				hookAttack.throwHeld(aim.dx, aim.dy);
			return;
		}

		if (hookAttack.busy)
			return;

		if (util.Controls.secondHeld())
		{
			var pmx = player.x + player.width * 0.5;
			var pmy = player.y + player.height * 0.5;
			yoyoJab.stop();
			held.beginSwing(aim.deg, Hook);
			emitAttack(Hook, pmx, pmy, aim.dx, aim.dy, aim.deg);
			hookAttack.fire(pmx, pmy, aim.dx, aim.dy, aim.deg);
			return;
		}

		if (util.Controls.attackHeld())
		{
			if (yoyoJab.ready)
			{
				emitAttack(Yoyo, handX(), handY(), aim.dx, aim.dy, aim.deg);
				yoyoJab.fire(handX(), handY(), aim.dx, aim.dy);
			}
		}
		else
			yoyoJab.release();
	}

	function emitAttack(mode:WeaponMode, pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float, power:Float = 0,
			perfect:Bool = false):Void
	{
		if (onAttack != null)
			onAttack(mode, pmx, pmy, dx, dy, aimDeg, util.Controls.aimX(), util.Controls.aimY(), power, perfect);
	}

	function updateHeldHook():Void
	{
		var busy = hookAttack.busy || yoyoJab.active;
		if (busy)
			held.sprite.visible = false;
		else if (wasHookBusy && !status.dead && !throwAttack.airborne)
			held.sprite.visible = true;
		wasHookBusy = busy;
	}
}
