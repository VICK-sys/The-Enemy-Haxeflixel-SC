package systems.weapons;

import flixel.FlxG;
import entities.Player;
import systems.PlayerCombat;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class HammerFlurry
{
	static inline var DAMP:Float = 0.002;
	static inline var FINISH_LUNGE:Float = 1.5;
	static inline var AIM_HOLD:Float = 150;
	static inline var MAX_TURN:Float = 0.698;

	public var active(get, never):Bool;
	public var onSwing:(Float, Float, Float, Float, Float, Bool) -> Void;
	public var onFinisher:(Float, Float) -> Void;

	private var cfg = WeaponDataRegistry.get().flurry;
	private var player:Player;
	private var status:PlayerCombat;
	private var held:HeldWeapon;
	private var swingAtk:SwingAttack;
	private var finishAtk:SwingAttack;
	private var running:Bool = false;
	private var timer:Float = 0;
	private var swingsLeft:Int = 0;
	private var wound:Bool = false;
	private var lastDx:Float = 1;
	private var lastDy:Float = 0;
	private var rising:Bool = false;

	public function new(player:Player, status:PlayerCombat, held:HeldWeapon, swingAtk:SwingAttack, finishAtk:SwingAttack)
	{
		this.player = player;
		this.status = status;
		this.held = held;
		this.swingAtk = swingAtk;
		this.finishAtk = finishAtk;
	}

	function get_active():Bool
		return running;

	public function activate():Void
	{
		running = true;
		wound = false;
		rising = false;
		swingsLeft = cfg.swings;
		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var dx = util.Controls.aimX() - pmx;
		var dy = util.Controls.aimY() - pmy;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len > 0)
		{
			lastDx = dx / len;
			lastDy = dy / len;
		}
		else
		{
			lastDx = player.flipX ? -1 : 1;
			lastDy = 0;
		}
		player.blockMovement = true;
		status.invincible = true;
		status.meterLocked = true;
		player.animation.play("idle");
		FlxG.sound.play(Paths.sound("hammer"), 0.35);
		swing();
	}

	public function cancel():Void
	{
		if (!running)
			return;
		running = false;
		settle();
	}

	function settle():Void
	{
		player.blockMovement = false;
		status.invincible = false;
		player.velocity.set(0, 0);
	}

	public function update(elapsed:Float):Void
	{
		if (!running)
			return;

		var damp = Math.pow(DAMP, elapsed);
		player.velocity.x *= damp;
		player.velocity.y *= damp;

		timer -= elapsed;
		if (timer > 0)
			return;

		if (swingsLeft > 0)
			swing();
		else if (!wound)
		{
			wound = true;
			timer = cfg.windup;
			player.velocity.set(0, 0);
		}
		else
			finish();
	}

	function swing():Void
	{
		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var a = aim(pmx, pmy);
		held.beginSwing(a.deg, Giga, rising);
		swingAtk.fire(pmx, pmy, a.dx, a.dy, a.deg, held.handX(), held.handY(), false, rising);
		player.velocity.set(a.dx * cfg.lunge, a.dy * cfg.lunge);
		if (onSwing != null)
			onSwing(pmx, pmy, a.dx, a.dy, a.deg, false);
		rising = !rising;
		swingsLeft--;
		timer = cfg.gap;
	}

	function finish():Void
	{
		var pmx = player.x + player.width * 0.5;
		var pmy = player.y + player.height * 0.5;
		var a = aim(pmx, pmy);
		held.beginSwing(a.deg, Giga);
		finishAtk.fire(pmx, pmy, a.dx, a.dy, a.deg, held.handX(), held.handY(), true);
		player.velocity.set(a.dx * cfg.lunge * FINISH_LUNGE, a.dy * cfg.lunge * FINISH_LUNGE);
		Fx.shake(0.012, 0.25);
		if (onSwing != null)
			onSwing(pmx, pmy, a.dx, a.dy, a.deg, true);
		if (onFinisher != null)
			onFinisher(pmx + a.dx * cfg.finisher.spawnDist, pmy + a.dy * cfg.finisher.spawnDist);
		running = false;
		settle();
	}

	function aim(pmx:Float, pmy:Float):{dx:Float, dy:Float, deg:Float}
	{
		var dx = util.Controls.aimX() - pmx;
		var dy = util.Controls.aimY() - pmy;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len >= AIM_HOLD)
		{
			var want = Math.atan2(dy, dx);
			var have = Math.atan2(lastDy, lastDx);
			var diff = want - have;
			while (diff > Math.PI)
				diff -= Math.PI * 2;
			while (diff < -Math.PI)
				diff += Math.PI * 2;
			if (diff > MAX_TURN)
				diff = MAX_TURN;
			else if (diff < -MAX_TURN)
				diff = -MAX_TURN;
			var a = have + diff;
			lastDx = Math.cos(a);
			lastDy = Math.sin(a);
		}
		return {dx: lastDx, dy: lastDy, deg: Math.atan2(lastDy, lastDx) * 180 / Math.PI};
	}
}
