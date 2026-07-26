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
	static var WEAPON_NAMES:Array<String> = ["SCYTHE", "HAMMER", "BOW", "HOOK"];

	public var held:HeldWeapon;
	public var hits:HitPipeline;
	public var swing:SwingAttack;
	public var jab:SwingAttack;
	public var hammer:HammerAttack;
	public var bow:BowAttack;
	public var throwAttack:ThrowAttack;
	public var hookAttack:HookAttack;
	public var superScythes:SuperScythes;
	public var bounceStrike:BounceStrike;
	public var arrowStorm:ArrowStorm;
	public var hookArms:HookArms;
	public var weapon:Int = 0;
	public var onAttack:(WeaponMode, Float, Float, Float, Float, Float, Float, Float, Float) -> Void;
	public var onSuper:Int -> Void;
	public var onSuperLaunch:(Float, Float) -> Void;

	private var player:Player;
	private var status:PlayerCombat;
	private var wasHookBusy:Bool = false;
	private var wasArms:Bool = false;

	public function new(player:Player, scythe:FlxSprite, arena:Arena, director:EnemyDirector, status:PlayerCombat, fx:Fx, pickups:Pickups)
	{
		this.player = player;
		this.status = status;
		hits = new HitPipeline(status, fx, pickups, director);
		hits.owner = player;
		held = new HeldWeapon(player, scythe);
		var weaponCfg = data.WeaponData.WeaponDataRegistry.get();
		swing = new SwingAttack(director, hits, weaponCfg.swing);
		jab = new SwingAttack(director, hits, weaponCfg.jab, 0.6);
		hammer = new HammerAttack(director, fx, hits);
		bow = new BowAttack(arena, director, fx, hits);
		throwAttack = new ThrowAttack(player, scythe, arena, director, status, hits);
		hookAttack = new HookAttack(player, arena, director, status, hits);
		superScythes = new SuperScythes(player, scythe, arena, director, status, fx, hits);
		bounceStrike = new BounceStrike(player, fx, hits, held.sprite, hammer.shock);
		arrowStorm = new ArrowStorm(player, held.sprite, bow.rain);
		hookArms = new HookArms(player, director, hits);
	}

	public var superBusy(get, never):Bool;

	function get_superBusy():Bool
		return superScythes.activating || bounceStrike.active || arrowStorm.active || hookArms.active;

	public var playerBusy(get, never):Bool;

	function get_playerBusy():Bool
		return superBusy || superScythes.active();

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
		held.charge = bow.charging ? bow.charge : 0;
		if (!superBusy)
			held.update(elapsed);
		updateAttackInput();
		swing.update(elapsed, player.x + player.width * 0.5, player.y + player.height * 0.5);
		jab.update(elapsed, player.x + player.width * 0.5, player.y + player.height * 0.5);
		bow.update(elapsed);
		hammer.update(elapsed);
		hookAttack.update(elapsed);
		throwAttack.update(elapsed);
		superScythes.update(elapsed);
		bounceStrike.update(elapsed);
		arrowStorm.update(elapsed);
		if (status.dead && hookArms.active)
			hookArms.deactivate();
		if (status.dead && bounceStrike.active)
			bounceStrike.cancel();
		hookArms.update(elapsed);
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

	public function modeName():String
	{
		if (bounceStrike.active)
			return "BOUNCE STRIKE";
		if (arrowStorm.active)
			return "ARROW STORM";
		if (hookArms.active)
			return "ARMS";
		if (superScythes.active())
			return "SUPER " + superScythes.orbiterCount();
		return WEAPON_NAMES[weapon];
	}

	public function equip(i:Int):Void
	{
		weapon = i < 0 || i >= WEAPON_NAMES.length ? 0 : i;
		bow.cancelCharge();
		held.setKind(weapon);
	}

	function aimFromPlayer():{dx:Float, dy:Float, deg:Float}
	{
		var pmx:Float = player.x + player.width * 0.5;
		var pmy:Float = player.y + player.height * 0.5;
		var dx:Float = FlxG.mouse.x - pmx;
		var dy:Float = FlxG.mouse.y - pmy;
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
			var power = bow.charge;
			held.beginSwing(aim.deg, Bow);
			bow.release(held.handX(), held.handY(), aim.dx, aim.dy, aim.deg);
			emitAttack(Bow, held.handX(), held.handY(), aim.dx, aim.dy, aim.deg, power);
		}
	}

	function updateAttackInput():Void
	{
		if (status.dead || superBusy)
		{
			bow.cancelCharge();
			return;
		}

		if (FlxG.keys.justPressed.Q && status.canSuper() && !superScythes.active() && !throwAttack.airborne && !hookAttack.busy)
		{
			status.spendSuper();
			switch (weapon)
			{
				case 0: superScythes.activate();
				case 1: bounceStrike.activate();
				case 2: arrowStorm.activate();
				default: hookArms.activate();
			}
			if (onSuper != null)
				onSuper(weapon);
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

		if (superScythes.active())
		{
			if (!leftClick)
				return;
			superScythes.tryLaunch(FlxG.mouse.x, FlxG.mouse.y);
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
			case 1:
				held.beginSwing(aimDeg, Hammer);
				emitAttack(Hammer, pmx, pmy, dx, dy, aimDeg);
				hammer.slam(pmx, pmy, dx, dy);
			case 3:
				held.beginSwing(aimDeg, Jab);
				emitAttack(Jab, pmx, pmy, dx, dy, aimDeg);
				jab.fire(pmx, pmy, dx, dy, aimDeg);
			default:
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
