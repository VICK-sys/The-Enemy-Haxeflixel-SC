package systems;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.sound.FlxSound;
import entities.Player;
import data.PlayerData;
import data.PlayerData.PlayerDataRegistry;
import util.Paths;
import systems.world.PropBlock;

class PlayerCombat
{
	public static inline var VOICE:Float = 0.5;
	static inline var THROES:Float = 1.5;
	static inline var THROES_SHAKE:Float = 7;
	static inline var BOOM:Float = 0.9;
	static inline var WHITEN:Float = 1.7;
	public static inline var HURT_LINES:Int = 4;
	static inline var DEATH_LINES:Int = 3;
	static inline var DASH_LINES:Int = 2;
	static inline var DASH_VOL:Float = 0.55;
	static inline var READY_VOL:Float = 0.4;
	static inline var STEAM_BACK:Float = 34;
	static inline var STEAM_RISE:Float = 26;

	public var health:Float = 0;
	public var superMeter:Float = 0;
	public var dead:Bool = false;
	public var invincible:Bool = false;
	public var onHurt:Void->Void;
	public var meterLocked:Bool = false;
	public var kills:Int = 0;
	public var healthMax:Float = 0;
	public var superMax:Float = 0;

	private var player:Player;
	private var fx:Fx;
	private var data:PlayerData;
	private var iframeTimer:Float = 0;
	private var blink:Bool = false;
	private var dashGuard:Bool = false;

	public var guarding(get, never):Bool;

	function get_guarding():Bool
		return iframeTimer > 0 && dashGuard && !dead;
	private var hurtLockTimer:Float = 0;
	private var hurtSlowTimer:Float = 0;
	private var dashCooldownTimer:Float = 0;
	private var dashLineTimer:Float = 0;
	private var justDied:Bool = false;
	private var justBurst:Bool = false;
	private var dying:Float = 0;
	private var gone:Bool = false;

	private var throeX:Float = 0;
	private var throeY:Float = 0;
	private var voice:FlxSound;
	private var voices:Map<String, FlxSound> = new Map();
	private var hitSound:FlxSound;
	private var steamPuff:flixel.FlxSprite;

	function steamX():Float
		return player.x + player.width * 0.5 - (player.flipX ? -1.0 : 1.0) * STEAM_BACK * player.sizeScale;

	function steamY():Float
		return player.y + player.height * 0.5 - STEAM_RISE * player.sizeScale;

	function trackSteam():Void
	{
		if (steamPuff == null)
			return;
		if (!steamPuff.exists)
		{
			steamPuff = null;
			return;
		}
		steamPuff.flipX = !player.flipX;
		steamPuff.setPosition(steamX() - steamPuff.width * 0.5, steamY() - steamPuff.height * 0.5);
	}

	public function new(player:Player, fx:Fx)
	{
		this.player = player;
		this.fx = fx;
		data = PlayerDataRegistry.get();
		healthMax = data.healthMax + util.Levels.healthBonus();
		superMax = data.superMax;
		health = healthMax;
		superMeter = 0;
		hitSound = FlxG.sound.create(Paths.sound("damaged/hit"));
	}

	public function update(elapsed:Float):Void
	{
		trackSteam();

		if (iframeTimer > 0)
		{
			iframeTimer -= elapsed;
			if (blink)
				player.visible = !gone && Std.int(iframeTimer * 20) % 2 == 0;
			if (iframeTimer <= 0)
			{
				blink = false;
				dashGuard = false;
				player.visible = !gone;
			}
		}

		if (superCd > 0)
			superCd -= elapsed;

		if (hurtLockTimer > 0)
		{
			hurtLockTimer -= elapsed;
			if (hurtLockTimer <= 0 && !dead)
				player.blockMovement = false;
		}

		if (hurtSlowTimer > 0)
		{
			hurtSlowTimer -= elapsed;
			if (hurtSlowTimer <= 0)
				clearHurtSlow();
		}

		if (dashCooldownTimer > 0)
		{
			dashCooldownTimer -= elapsed;
			if (dashCooldownTimer <= 0 && !dead)
			{
				FlxG.sound.play(Paths.sound("dash/charged"), READY_VOL);
				steamPuff = fx.steamAt(steamX(), steamY(), !player.flipX);
			}
		}

		if (util.Controls.justPressed(util.Controls.DASH) && !dead && !player.blockMovement && dashCooldownTimer <= 0 && player.dashTimer <= 0)
		{
			dashCooldownTimer = data.dashCooldown * util.Levels.dashScale();
			player.dash();
			FlxG.sound.play(Paths.sound("dash/dash" + (1 + Std.random(DASH_LINES))), DASH_VOL);
			iframeTimer = data.dashIframes;
			blink = false;
			dashGuard = true;
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
			say("voice/death" + (1 + Std.random(DEATH_LINES)));
			dead = true;
			player.isDead = true;
			justDied = true;
			dying = THROES;
			throeX = player.offset.x;
			throeY = player.offset.y;
			blink = false;
			player.visible = true;
			player.animation.play("hurt", true);
		}

		if (dying > 0)
		{
			dying -= elapsed;
			player.blockMovement = true;
			if (dying > 0)
			{
				player.offset.set(throeX + FlxG.random.float(-THROES_SHAKE, THROES_SHAKE),
					throeY + FlxG.random.float(-THROES_SHAKE, THROES_SHAKE));
				var ramp = 1 - dying / THROES;
				var lit = Math.pow(ramp, WHITEN);
				var add = Std.int(255 * lit);
				var keep = 1 - lit;
				player.setColorTransform(keep, keep, keep, 1, add, add, add, 0);
			}
			else
			{
				dying = 0;
				justBurst = true;
				gone = true;
				player.offset.set(throeX, throeY);
				player.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
				util.Sfx.at("player_explode", player.x + player.width * 0.5, player.y + player.height * 0.5, BOOM);
			}
		}
		else if (dead)
			player.blockMovement = !net.Net.active;

		if (health <= 0)
			health = 0;
	}

	function say(name:String):Void
	{
		if (voice != null && voice.playing)
			voice.stop();

		var line = voices.get(name);
		if (line == null)
		{
			line = FlxG.sound.load(Paths.sound(name), VOICE, false, FlxG.sound.defaultSoundGroup);
			voices.set(name, line);
		}

		voice = line;
		voice.volume = VOICE;
		voice.pitch = util.SaveData.voicePitch();
		voice.play(true);
	}


	public var throes(get, never):Bool;

	function get_throes():Bool
		return dying > 0;

	public function consumeJustDied():Bool
	{
		if (!justDied)
			return false;
		justDied = false;
		return true;
	}

	public function consumeJustBurst():Bool
	{
		if (!justBurst)
			return false;
		justBurst = false;
		return true;
	}

	function shove(source:FlxObject, speed:Float):Void
	{
		var dx = player.x + player.width * 0.5 - (source.x + source.width * 0.5);
		var dy = player.y + player.height * 0.5 - (source.y + source.height * 0.5);
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len < 0.001)
		{
			dx = player.flipX ? 1 : -1;
			dy = 0;
			len = 1;
		}
		player.velocity.set(dx / len * speed, dy / len * speed);
	}

	public function hurtPlayer(source:FlxObject, damage:Float, ?fromY:Null<Float>, push:Float = 0):Bool
	{
		if (dead || iframeTimer > 0 || invincible)
			return false;
		if (!player.touchesRound(source.x, source.y, source.width, source.height))
			return false;
		if (PropBlock.between(source.x + source.width / 2, fromY == null ? source.y + source.height : fromY,
			player.x + player.width / 2, player.feetY))
			return false;

		hitSound.play(true);
		if (onHurt != null)
			onHurt();
		if (health - damage > 0)
			say("voice/hurt" + (1 + Std.random(HURT_LINES)));
		fx.hurtShake();

		shove(source, push > 0 ? push : data.knockback);

		health -= damage;
		player.animation.play("hurt", false);
		player.blockMovement = true;
		iframeTimer = data.iframeTime;
		blink = true;
		dashGuard = false;
		hurtLockTimer = data.hurtLockTime;
		hurtSlowTimer = data.hurtLockTime + data.hurtSlowTime;
		player.moveScale = data.hurtMoveScale;
		player.animHold = true;
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

	public var onHeal:Float->Void;

	public function heal(amount:Float):Void
	{
		if (dead)
			return;
		var room = healthMax - health;
		health += amount;
		if (health > healthMax)
			health = healthMax;
		if (onHeal != null)
			onHeal(amount < room ? amount : room);
	}

	public function canSuper():Bool
	{
		return superMeter >= superMax && superCd <= 0;
	}

	public var superCd(default, null):Float = 0;

	public function spendSuper():Void
	{
		superMeter = 0;
		superCd = data.superCooldown;
	}

	public function drainSuper(frac:Float):Bool
	{
		superMeter -= superMax * frac;
		if (superMeter > 0)
			return true;
		superMeter = 0;
		superCd = data.superCooldown;
		return false;
	}

	public function rewardKill():Void
	{
		kills++;
		util.Stats.addKill();
	}

	public function rewardDamage(amount:Float):Void
	{
		if (amount <= 0 || meterLocked)
			return;
		superMeter += amount * data.superPerDamage * util.Levels.superGainScale();
		if (superMeter > superMax)
			superMeter = superMax;
	}

	public function revive():Void
	{
		dying = 0;
		justBurst = false;
		gone = false;
		player.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		player.offset.set(throeX, throeY);
		health = healthMax;
		superMeter = 0;
		superCd = 0;
		dead = false;
		player.isDead = false;
		player.blockMovement = false;
		player.visible = true;
		hurtSlowTimer = 0;
		clearHurtSlow();
	}

	function clearHurtSlow():Void
	{
		player.moveScale = 1;
		player.animHold = false;
	}
}
