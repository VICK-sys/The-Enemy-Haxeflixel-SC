package systems;

import flixel.FlxG;
import flixel.FlxObject;
import entities.Player;
import entities.PlayerData;
import entities.PlayerData.PlayerDataRegistry;
import util.Paths;

class PlayerCombat
{
	static inline var FLASH_TIME:Float = 0.12;

	public var health:Float = 0;
	public var itemBar:Float = 0;
	public var dead:Bool = false;
	public var healthMax:Float = 0;
	public var apMax:Float = 0;

	private var player:Player;
	private var fx:Fx;
	private var data:PlayerData;
	private var iframeTimer:Float = 0;
	private var hurtLockTimer:Float = 0;
	private var flashTimer:Float = 0;
	private var justDied:Bool = false;

	public function new(player:Player, fx:Fx)
	{
		this.player = player;
		this.fx = fx;
		data = PlayerDataRegistry.get();
		healthMax = data.healthMax;
		apMax = data.apMax;
		health = healthMax;
		itemBar = apMax;
	}

	public function update(elapsed:Float):Void
	{
		if (iframeTimer > 0)
		{
			iframeTimer -= elapsed;
			player.visible = dead || Std.int(iframeTimer * 20) % 2 == 0;
			if (iframeTimer <= 0)
				player.visible = true;
		}

		if (hurtLockTimer > 0)
		{
			hurtLockTimer -= elapsed;
			if (hurtLockTimer <= 0 && !dead)
				player.blockMovement = false;
		}

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
				player.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		}

		if (FlxG.keys.justPressed.SPACE && !dead && !player.blockMovement && itemBar >= data.dashCost && player.dashTimer <= 0)
		{
			itemBar -= data.dashCost;
			player.dash();
			iframeTimer = data.dashIframes;
		}

		if (health <= 0 && !dead)
		{
			player.animation.play("death", false);
			dead = true;
			player.isDead = true;
			player.blockMovement = true;
			justDied = true;
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

	public function hurtPlayer(source:FlxObject, damage:Float):Bool
	{
		if (dead || iframeTimer > 0)
			return false;
		if (source.x + source.width <= player.x || player.x + player.width <= source.x
			|| source.y + source.height <= player.y || player.y + player.height <= source.y)
			return false;

		FlxG.sound.play(Paths.sound("damaged/hit"));
		fx.hurtShake();
		player.setColorTransform(1, 1, 1, 1, 255, 0, 0, 0);
		flashTimer = FLASH_TIME;

		player.velocity.x = data.knockback * (player.x > source.x ? 1 : -1);
		player.velocity.y = data.knockback * (player.y > source.y ? 1 : -1);

		health -= damage;
		player.animation.play("hurt", false);
		player.blockMovement = true;
		iframeTimer = data.iframeTime;
		hurtLockTimer = data.hurtLockTime;
		return true;
	}

	public function heal(amount:Float):Void
	{
		if (dead)
			return;
		health += amount;
		if (health > healthMax)
			health = healthMax;
	}

	public function rewardKill():Void
	{
		itemBar += data.apPerKill;
		if (itemBar > apMax)
			itemBar = apMax;
	}

	public function revive():Void
	{
		health = healthMax;
		itemBar = apMax;
		dead = false;
		player.isDead = false;
		player.blockMovement = false;
		player.visible = true;
	}
}
