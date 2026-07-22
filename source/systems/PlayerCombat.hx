package systems;

import flixel.FlxG;
import flixel.FlxObject;
import entities.Player;
import util.Paths;

class PlayerCombat
{
	public static inline var HEALTH_MAX:Float = 2;
	public static inline var AP_MAX:Float = 2;
	static inline var DASH_COST:Float = 1;
	static inline var AP_PER_KILL:Float = 0.5;
	static inline var IFRAME_TIME:Float = 0.4;
	static inline var HURT_LOCK_TIME:Float = 0.1;
	static inline var DASH_IFRAMES:Float = 0.25;
	static inline var FLASH_TIME:Float = 0.12;
	static inline var KNOCKBACK:Float = 300;

	public var health:Float = HEALTH_MAX;
	public var itemBar:Float = AP_MAX;
	public var dead:Bool = false;

	private var player:Player;
	private var fx:Fx;
	private var iframeTimer:Float = 0;
	private var hurtLockTimer:Float = 0;
	private var flashTimer:Float = 0;
	private var justDied:Bool = false;

	public function new(player:Player, fx:Fx)
	{
		this.player = player;
		this.fx = fx;
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

		if (FlxG.keys.justPressed.SPACE && !dead && !player.blockMovement && itemBar >= DASH_COST && player.dashTimer <= 0)
		{
			itemBar -= DASH_COST;
			player.dash();
			iframeTimer = DASH_IFRAMES;
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

		player.velocity.x = KNOCKBACK * (player.x > source.x ? 1 : -1);
		player.velocity.y = KNOCKBACK * (player.y > source.y ? 1 : -1);

		health -= damage;
		player.animation.play("hurt", false);
		player.blockMovement = true;
		iframeTimer = IFRAME_TIME;
		hurtLockTimer = HURT_LOCK_TIME;
		return true;
	}

	public function rewardKill():Void
	{
		itemBar += AP_PER_KILL;
		if (itemBar > AP_MAX)
			itemBar = AP_MAX;
	}

	public function revive():Void
	{
		health = HEALTH_MAX;
		itemBar = AP_MAX;
		dead = false;
		player.isDead = false;
		player.blockMovement = false;
		player.visible = true;
	}
}
