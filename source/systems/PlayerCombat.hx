package systems;

import flixel.FlxG;
import flixel.FlxObject;
import entities.Player;
import data.PlayerData;
import data.PlayerData.PlayerDataRegistry;
import util.Paths;
import systems.world.PropBlock;

class PlayerCombat
{
	public var health:Float = 0;
	public var superMeter:Float = 0;
	public var dead:Bool = false;
	public var invincible:Bool = false;
	public var kills:Int = 0;
	public var healthMax:Float = 0;
	public var superMax:Float = 0;

	private var player:Player;
	private var fx:Fx;
	private var data:PlayerData;
	private var iframeTimer:Float = 0;
	private var blink:Bool = false;
	private var hurtLockTimer:Float = 0;
	private var dashCooldownTimer:Float = 0;
	private var dashLineTimer:Float = 0;
	private var justDied:Bool = false;

	public function new(player:Player, fx:Fx)
	{
		this.player = player;
		this.fx = fx;
		data = PlayerDataRegistry.get();
		healthMax = data.healthMax + util.Levels.healthBonus();
		superMax = data.superMax;
		health = healthMax;
		superMeter = superMax;
	}

	public function update(elapsed:Float):Void
	{
		if (iframeTimer > 0)
		{
			iframeTimer -= elapsed;
			if (blink)
				player.visible = dead || Std.int(iframeTimer * 20) % 2 == 0;
			if (iframeTimer <= 0)
			{
				blink = false;
				player.visible = true;
			}
		}

		if (hurtLockTimer > 0)
		{
			hurtLockTimer -= elapsed;
			if (hurtLockTimer <= 0 && !dead)
				player.blockMovement = false;
		}

		if (dashCooldownTimer > 0)
			dashCooldownTimer -= elapsed;

		if (util.Controls.justPressed(util.Controls.DASH) && !dead && !player.blockMovement && dashCooldownTimer <= 0 && player.dashTimer <= 0)
		{
			dashCooldownTimer = data.dashCooldown * util.Levels.dashScale();
			player.dash();
			iframeTimer = data.dashIframes;
			blink = false;
			player.visible = true;
		}

		if (player.dashTimer > 0)
		{
			dashLineTimer -= elapsed;
			if (dashLineTimer <= 0)
			{
				dashLineTimer = 0.05;
				var vx = player.velocity.x;
				var vy = player.velocity.y;
				var vlen = Math.sqrt(vx * vx + vy * vy);
				if (vlen > 0)
					fx.dashLine(player.x + player.width / 2, player.y + player.height / 2, vx / vlen, vy / vlen);
			}
		}

		if (health <= 0 && !dead)
		{
			player.animation.play("death", false);
			dead = true;
			player.isDead = true;
			justDied = true;
		}

		if (dead)
		{
			player.blockMovement = true;
			if (player.animation.name != "death")
				player.animation.play("death", false);
		}

		if (health <= 0)
			health = 0;
	}

	public function consumeJustDied():Bool
	{
		if (!justDied)
			return false;
		justDied = false;
		return true;
	}

	public function hurtPlayer(source:FlxObject, damage:Float, ?fromY:Null<Float>):Bool
	{
		if (dead || iframeTimer > 0 || invincible)
			return false;
		if (source.x + source.width <= player.x || player.x + player.width <= source.x
			|| source.y + source.height <= player.y || player.y + player.height <= source.y)
			return false;
		if (PropBlock.between(source.x + source.width / 2, fromY == null ? source.y + source.height : fromY,
			player.x + player.width / 2, player.feetY))
			return false;

		FlxG.sound.play(Paths.sound("damaged/hit"));
		fx.hurtShake();

		player.velocity.x = data.knockback * (player.x > source.x ? 1 : -1);
		player.velocity.y = data.knockback * (player.y > source.y ? 1 : -1);

		health -= damage;
		player.animation.play("hurt", false);
		player.blockMovement = true;
		iframeTimer = data.iframeTime;
		blink = true;
		hurtLockTimer = data.hurtLockTime;
		return true;
	}

	public function dropScale():Float
	{
		if (healthMax <= 0)
			return 1;
		var frac = health / healthMax;
		if (frac < 0)
			frac = 0;
		if (frac > 1)
			frac = 1;
		return 1 + (1 - frac) * data.dropLowHealthBonus;
	}

	public function refreshMax():Void
	{
		var was = healthMax;
		healthMax = data.healthMax + util.Levels.healthBonus();
		if (healthMax > was)
			health += healthMax - was;
		if (health > healthMax)
			health = healthMax;
	}

	public function heal(amount:Float):Void
	{
		if (dead)
			return;
		health += amount;
		if (health > healthMax)
			health = healthMax;
	}

	public function canSuper():Bool
	{
		return superMeter >= superMax;
	}

	public function spendSuper():Void
	{
		superMeter = 0;
	}

	public function rewardKill():Void
	{
		kills++;
		superMeter += data.superPerKill * util.Levels.superGainScale();
		if (superMeter > superMax)
			superMeter = superMax;
	}

	public function revive():Void
	{
		health = healthMax;
		superMeter = superMax;
		dead = false;
		player.isDead = false;
		player.blockMovement = false;
		player.visible = true;
	}
}
