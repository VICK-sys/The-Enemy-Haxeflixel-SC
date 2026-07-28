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

	public var held:HeldWeapon;
	public var hits:HitPipeline;
	public var swing:SwingAttack;
	public var jab:SwingAttack;
	public var revolver:RevolverAttack;
	public var bow:BowAttack;
	public var throwAttack:ThrowAttack;
	public var hookAttack:HookAttack;
	public var superOrbit:SuperOrbit;
	public var arrowStorm:ArrowStorm;
	public var hookArms:HookArms;
	public var deadEye:DeadEye;
	public var weapon:Int = 0;
	public var disabled:Bool = false;
	public var onAttack:(WeaponMode, Float, Float, Float, Float, Float, Float, Float, Float) -> Void;
	public var onSuper:Int -> Void;
	public var onSuperLaunch:(Float, Float) -> Void;

	private var player:Player;
	private var status:PlayerCombat;
	private var wasHookBusy:Bool = false;
	private var wasArms:Bool = false;

	public function new(player:Player, heldSprite:FlxSprite, arena:Arena, director:EnemyDirector, status:PlayerCombat, fx:Fx, pickups:Pickups, scraps:systems.Scraps)
	{
		this.player = player;
		this.status = status;
		hits = new HitPipeline(status, fx, pickups, scraps, director);
		hits.owner = player;
		held = new HeldWeapon(player, heldSprite);
		var weaponCfg = data.WeaponData.WeaponDataRegistry.get();
		swing = new SwingAttack(director, hits, fx, weaponCfg.swing);
		jab = new SwingAttack(director, hits, fx, weaponCfg.jab);
		revolver = new RevolverAttack(arena, director, fx, hits);
		bow = new BowAttack(arena, director, fx, hits);
		throwAttack = new ThrowAttack(player, heldSprite, arena, director, status, hits);
		throwAttack.onCaught = function() swing.coolFor(weaponCfg.thrown.catchCooldown);
		hookAttack = new HookAttack(player, arena, director, status, hits);
		superOrbit = new SuperOrbit(player, heldSprite, arena, director, status, fx, hits);
		arrowStorm = new ArrowStorm(player, held.sprite, bow.rain);
		hookArms = new HookArms(player, director, hits);
		deadEye = new DeadEye(player, director, revolver, held);
		deadEye.onShot = function(bx, by, tx, ty, deg)
			emitAttack(Shoot, bx, by, Math.cos(deg * Math.PI / 180), Math.sin(deg * Math.PI / 180), deg);
		revolver.onPellet = function(bx, by, deg)
			emitAttack(Pellet, bx, by, Math.cos(deg * Math.PI / 180), Math.sin(deg * Math.PI / 180), deg);
	}

	public var superBusy(get, never):Bool;

	function get_superBusy():Bool
		return superOrbit.activating || arrowStorm.active || hookArms.active;

	public var playerBusy(get, never):Bool;

	function get_playerBusy():Bool
		return superBusy || superOrbit.active();

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
		if (disabled)
		{
			held.sprite.visible = false;
			return;
		}

		held.charge = bow.charging ? bow.charge : 0;
		if (!superBusy)
			held.update(elapsed);
		updateAttackInput();
		swing.update(elapsed, player.x + player.width * 0.5, player.y + player.height * 0.5);
		jab.update(elapsed, player.x + player.width * 0.5, player.y + player.height * 0.5);
		bow.update(elapsed);
		var gunAim = aimFrom(held.handX(), held.handY());
		if (status.dead)
		{
			revolver.cancelFan();
			bow.hushReload();
		}
		revolver.update(elapsed, held.handX(), held.handY(), gunAim.deg);
		hookAttack.update(elapsed);
		throwAttack.update(elapsed);
		superOrbit.update(elapsed);
		arrowStorm.update(elapsed);
		if (status.dead && hookArms.active)
			hookArms.deactivate();
		if (status.dead && arrowStorm.active)
			arrowStorm.cancel();
		hookArms.update(elapsed);
		if (status.dead && deadEye.active)
			deadEye.cancel();
		deadEye.update(elapsed);
		updateHeldHook();
		updateHeldArms();
	}

	function updateHeldArms():Void
	{
		if (hookArms.active)
			held.sprite.visible = false;
		else if (wasArms && !status.dead)
			held.sprite.visible = true;
		wasArms = hookArms.active;
	}

	public function hasSuper():Bool
		return weapon != 1 || deadEye.canActivate();

	public function equip(i:Int):Void
	{
		weapon = i < 0 || i >= WEAPON_COUNT ? 0 : i;
		bow.cancelCharge();
		revolver.reset();
		held.setKind(weapon);
	}

	function aimFromPlayer():{dx:Float, dy:Float, deg:Float}
		return aimFrom(player.x + player.width * 0.5, player.y + player.height * 0.5);

	function aimFrom(ox:Float, oy:Float):{dx:Float, dy:Float, deg:Float}
	{
		var dx:Float = FlxG.mouse.x - ox;
		var dy:Float = FlxG.mouse.y - oy;
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

		if (FlxG.mouse.justPressedRight && bow.rainReady && !held.swinging)
		{
			var aim = aimFromPlayer();
			bow.cancelCharge();
			held.beginSwing(aim.deg, Rain);
			emitAttack(Rain, held.handX(), held.handY(), aim.dx, aim.dy, aim.deg);
			bow.rainFire(FlxG.mouse.x, FlxG.mouse.y, held.handX(), held.handY());
			return;
		}

		if (FlxG.mouse.justPressed)
			bow.beginCharge();

		if (bow.charging && !FlxG.mouse.pressed)
		{
			var aim = aimFromPlayer();
			var shot = aimFrom(held.handX(), held.handY());
			var power = bow.charge;
			held.beginSwing(aim.deg, Bow);
			bow.release(held.handX(), held.handY(), shot.dx, shot.dy, shot.deg);
			emitAttack(Bow, held.handX(), held.handY(), shot.dx, shot.dy, shot.deg, power);
		}
	}

	function updateGunInput():Void
	{
		if (throwAttack.airborne || deadEye.active)
			return;

		if (FlxG.keys.justPressed.R)
			revolver.beginReload();

		var aim = aimFromPlayer();
		var shot = aimFrom(held.handX(), held.handY());

		if (FlxG.mouse.justPressedRight && revolver.canFan())
		{
			held.beginSwing(aim.deg, Fan);
			emitAttack(Fan, held.handX(), held.handY(), shot.dx, shot.dy, shot.deg);
			revolver.fanFire();
			return;
		}

		if (FlxG.mouse.justPressed && revolver.canFire())
		{
			held.beginSwing(aim.deg, Shoot);
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

		if (FlxG.keys.justPressed.Q && deadEye.marking)
		{
			deadEye.cancel();
			return;
		}

		if (FlxG.keys.justPressed.Q && hasSuper() && status.canSuper() && !superOrbit.active() && !throwAttack.airborne
			&& !hookAttack.busy)
		{
			status.spendSuper();
			switch (weapon)
			{
				case 0: superOrbit.activate();
				case 1: deadEye.activate();
				case 2: arrowStorm.activate();
				default: hookArms.activate();
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

		var leftClick = FlxG.mouse.justPressed;
		var rightClick = FlxG.mouse.justPressedRight;
		if ((!leftClick && !rightClick) || throwAttack.airborne)
			return;

		var pmx:Float = player.x + player.width * 0.5;
		var pmy:Float = player.y + player.height * 0.5;
		var aim = aimFromPlayer();
		var dx:Float = aim.dx;
		var dy:Float = aim.dy;
		var aimDeg:Float = aim.deg;

		if (superOrbit.active())
		{
			if (!leftClick)
				return;
			superOrbit.tryLaunch(FlxG.mouse.x, FlxG.mouse.y);
			if (onSuperLaunch != null)
				onSuperLaunch(FlxG.mouse.x, FlxG.mouse.y);
			return;
		}

		if (hookAttack.holding)
		{
			if (leftClick)
				hookAttack.throwHeld(dx, dy);
			return;
		}

		if (hookAttack.busy || held.swinging)
			return;

		if (leftClick)
			primary(pmx, pmy, dx, dy, aimDeg);
		else
			secondary(pmx, pmy, dx, dy, aimDeg);
	}

	function primary(pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		switch (weapon)
		{
			case 3:
				held.beginSwing(aimDeg, Jab);
				emitAttack(Jab, pmx, pmy, dx, dy, aimDeg);
				jab.fire(pmx, pmy, dx, dy, aimDeg);
			default:
				if (!swing.ready)
					return;
				held.beginSwing(aimDeg, Swing);
				emitAttack(Swing, pmx, pmy, dx, dy, aimDeg);
				swing.fire(pmx, pmy, dx, dy, aimDeg);
		}
	}

	function secondary(pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float):Void
	{
		switch (weapon)
		{
			case 0:
				if (!swing.ready)
					return;
				throwAttack.launch(pmx, pmy, dx, dy);
				emitAttack(Throw, pmx, pmy, dx, dy, aimDeg);
			case 3:
				held.beginSwing(aimDeg, Hook);
				emitAttack(Hook, pmx, pmy, dx, dy, aimDeg);
				hookAttack.fire(pmx, pmy, dx, dy, aimDeg);
			default:
		}
	}

	function emitAttack(mode:WeaponMode, pmx:Float, pmy:Float, dx:Float, dy:Float, aimDeg:Float, power:Float = 0):Void
	{
		if (onAttack != null)
			onAttack(mode, pmx, pmy, dx, dy, aimDeg, FlxG.mouse.x, FlxG.mouse.y, power);
	}

	function updateHeldHook():Void
	{
		if (hookAttack.busy)
			held.sprite.visible = false;
		else if (wasHookBusy && !status.dead && !throwAttack.airborne)
			held.sprite.visible = true;
		wasHookBusy = hookAttack.busy;
	}
}
