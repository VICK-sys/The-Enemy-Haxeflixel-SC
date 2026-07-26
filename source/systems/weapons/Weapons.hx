package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
import systems.Arena;
import systems.EnemyDirector;
import systems.PlayerCombat;
import systems.Fx;
import systems.Pickups;

class Weapons
{
	static var WEAPON_MODES:Array<Array<WeaponMode>> = [[Swing, Slice, Throw], [Hammer, Quake], [Bow, Rain], [Hook, Whirl, Grapple]];

	public var held:HeldWeapon;
	public var hits:HitPipeline;
	public var swing:SwingAttack;
	public var slice:SliceAttack;
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
	private var modeIndexes:Array<Int> = [0, 0, 0, 0];
	private var wasHookBusy:Bool = false;
	private var wasArms:Bool = false;

	public function new(player:Player, scythe:FlxSprite, arena:Arena, director:EnemyDirector, status:PlayerCombat, fx:Fx, pickups:Pickups)
	{
		this.player = player;
		this.status = status;
		hits = new HitPipeline(status, fx, pickups, director);
		hits.owner = player;
		held = new HeldWeapon(player, scythe);
		swing = new SwingAttack(director, hits);
		slice = new SliceAttack(arena, director, hits);
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
		updateWeaponInput();
		held.charge = bow.charging ? bow.charge : 0;
		if (!superBusy)
			held.update(elapsed);
		updateAttackInput();
		slice.update();
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
		return switch (held.mode)
		{
			case Swing: "SWING";
			case Slice: "AIR SLICE";
			case Throw: "THROW";
			case Hammer: "HAMMER";
			case Quake: "SHOCKWAVE";
			case Bow: "BOW";
			case Rain: "ARROW RAIN";
			case Hook: "HOOK";
			case Whirl: "SPIN";
			case Grapple: "GRAPPLE";
		};
	}

	function updateWeaponInput():Void
	{
		if (FlxG.mouse.justPressedRight)
		{
			var list = WEAPON_MODES[weapon];
			if (list.length > 1)
			{
				modeIndexes[weapon] = (modeIndexes[weapon] + 1) % list.length;
				bow.cancelCharge();
				held.setMode(list[modeIndexes[weapon]]);
			}
		}
	}

	public function equip(i:Int):Void
	{
		weapon = i < 0 || i >= WEAPON_MODES.length ? 0 : i;
		bow.cancelCharge();
		held.setMode(WEAPON_MODES[weapon][modeIndexes[weapon]]);
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

	function updateBowCharge():Void
	{
		if (hookAttack.busy || throwAttack.airborne)
		{
			bow.cancelCharge();
			return;
		}

		if (FlxG.mouse.justPressed)
			bow.beginCharge();

		if (bow.charging && !FlxG.mouse.pressed)
		{
			var aim = aimFromPlayer();
			var power = bow.charge;
			held.beginSwing(aim.deg);
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

		if (held.mode == Bow)
		{
			updateBowCharge();
			return;
		}

		if (!FlxG.mouse.justPressed || throwAttack.airborne)
			return;

		var pmx:Float = player.x + player.width * 0.5;
		var pmy:Float = player.y + player.height * 0.5;
		var aim = aimFromPlayer();
		var dx:Float = aim.dx;
		var dy:Float = aim.dy;
		var aimDeg:Float = aim.deg;

		if (superScythes.active())
		{
			superScythes.tryLaunch(FlxG.mouse.x, FlxG.mouse.y);
			if (onSuperLaunch != null)
				onSuperLaunch(FlxG.mouse.x, FlxG.mouse.y);
			return;
		}

		if (hookAttack.holding)
		{
			hookAttack.throwHeld(dx, dy);
			return;
		}

		if (hookAttack.busy || held.swinging)
			return;

		if (held.mode == Throw)
		{
			throwAttack.launch(pmx, pmy, dx, dy);
			emitAttack(Throw, pmx, pmy, dx, dy, aimDeg);
			return;
		}

		held.beginSwing(aimDeg);

		if (held.mode == Rain)
			emitAttack(Rain, held.handX(), held.handY(), dx, dy, aimDeg);
		else
			emitAttack(held.mode, pmx, pmy, dx, dy, aimDeg);

		switch (held.mode)
		{
			case Slice:
				slice.fire(pmx, pmy, dx, dy, aimDeg);
			case Hammer:
				hammer.slam(pmx, pmy, dx, dy);
			case Quake:
				hammer.quake(pmx, pmy, dx, dy);
			case Rain:
				bow.rainFire(FlxG.mouse.x, FlxG.mouse.y, held.handX(), held.handY());
			case Hook:
				hookAttack.fire(pmx, pmy, dx, dy, aimDeg);
			case Whirl:
				hookAttack.whirl(aimDeg);
			case Grapple:
				hookAttack.grapple(pmx, pmy, dx, dy, aimDeg);
			default:
				swing.fire(pmx, pmy, dx, dy, aimDeg);
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
