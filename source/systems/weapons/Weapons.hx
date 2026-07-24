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

	public function update(elapsed:Float):Void
	{
		updateWeaponInput();
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
		if (FlxG.keys.justPressed.ONE)
			selectWeapon(0);
		if (FlxG.keys.justPressed.TWO)
			selectWeapon(1);
		if (FlxG.keys.justPressed.THREE)
			selectWeapon(2);
		if (FlxG.keys.justPressed.FOUR)
			selectWeapon(3);

		var wheel = FlxG.mouse.wheel;
		if (wheel < 0)
			selectWeapon((weapon + 1) % WEAPON_MODES.length);
		else if (wheel > 0)
			selectWeapon((weapon + WEAPON_MODES.length - 1) % WEAPON_MODES.length);

		if (FlxG.mouse.justPressedRight)
		{
			var list = WEAPON_MODES[weapon];
			if (list.length > 1)
			{
				modeIndexes[weapon] = (modeIndexes[weapon] + 1) % list.length;
				held.setMode(list[modeIndexes[weapon]]);
			}
		}
	}

	function selectWeapon(i:Int):Void
	{
		if (i == weapon)
			return;
		weapon = i;
		held.setMode(WEAPON_MODES[i][modeIndexes[i]]);
	}

	function updateAttackInput():Void
	{
		if (status.dead || superBusy)
			return;

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
			return;
		}

		if (!FlxG.mouse.justPressed || throwAttack.airborne)
			return;

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
		var aimDeg:Float = Math.atan2(dy, dx) * 180 / Math.PI;

		if (superScythes.active())
		{
			superScythes.tryLaunch(FlxG.mouse.x, FlxG.mouse.y);
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
			return;
		}

		held.beginSwing(aimDeg);

		switch (held.mode)
		{
			case Slice:
				slice.fire(pmx, pmy, dx, dy, aimDeg);
			case Hammer:
				hammer.slam(pmx, pmy, dx, dy);
			case Quake:
				hammer.quake(pmx, pmy, dx, dy);
			case Bow:
				bow.shoot(held.handX(), held.handY(), dx, dy, aimDeg);
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

	function updateHeldHook():Void
	{
		if (hookAttack.busy)
			held.sprite.visible = false;
		else if (wasHookBusy && !status.dead && !throwAttack.airborne)
			held.sprite.visible = true;
		wasHookBusy = hookAttack.busy;
	}
}
