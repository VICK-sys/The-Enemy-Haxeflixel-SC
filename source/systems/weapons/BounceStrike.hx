package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
import systems.Fx;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class BounceStrike
{
	static inline var APEX:Float = 240;
	static inline var SPIN:Float = 360;
	static inline var HAND_X:Float = 30;
	static inline var HAND_Y:Float = 65;

	public var active(get, never):Bool;

	private var cfg = WeaponDataRegistry.get().bounceStrike;
	private var player:Player;
	private var fx:Fx;
	private var hits:HitPipeline;
	private var hammer:FlxSprite;
	private var shock:Shockwave;
	private var running:Bool = false;
	private var hopTimer:Float = 0;
	private var strikesLeft:Int = 0;
	private var baseOffsetY:Float = 0;
	private var spinDir:Int = 1;
	private var slamPop:Float = 0;

	public function new(player:Player, fx:Fx, hits:HitPipeline, hammer:FlxSprite, shock:Shockwave)
	{
		this.player = player;
		this.fx = fx;
		this.hits = hits;
		this.hammer = hammer;
		this.shock = shock;
	}

	function get_active():Bool
		return running;

	public function activate():Void
	{
		running = true;
		baseOffsetY = player.offset.y;
		strikesLeft = cfg.strikes;
		spinDir = FlxG.mouse.x >= player.x + player.width * 0.5 ? 1 : -1;
		player.blockMovement = true;
		player.floating = true;
		player.animation.play("idle");
		slam();
		hopTimer = cfg.hopTime;
	}

	public function update(elapsed:Float):Void
	{
		if (!running)
			return;

		hopTimer -= elapsed;
		var t = 1 - hopTimer / cfg.hopTime;
		if (t > 1)
			t = 1;
		var h = APEX * Math.sin(Math.PI * t);
		player.offset.y = baseOffsetY + h;
		player.angle = spinDir * SPIN * t;
		if (slamPop > 0)
			slamPop -= elapsed * 8;

		positionHammer(h);

		if (hopTimer <= 0)
		{
			player.offset.y = baseOffsetY;
			player.angle = 0;
			strikesLeft--;
			if (strikesLeft > 0)
			{
				slam();
				hopTimer = cfg.hopTime;
			}
			else
			{
				running = false;
				player.floating = false;
				player.blockMovement = false;
				player.angle = 0;
				player.velocity.set(0, 0);
			}
		}
	}

	function slam():Void
	{
		var cx = player.x + player.width * 0.5;
		var cy = player.y + player.height * 0.5;
		fx.sparksAt(cx, player.y + player.height);
		fx.slamShake();
		FlxG.sound.play(Paths.sound("hammer"), 1);
		shock.blast(cx, cy, false);
		slamPop = 2;

		launch(cx, cy);

		hits.blastRadial(cx, cy, cfg.radius, cfg.force, cfg.damage);
	}

	function launch(cx:Float, cy:Float):Void
	{
		var dx:Float = 0;
		var dy:Float = 0;
		if (FlxG.keys.anyPressed([W]))
			dy -= 1;
		if (FlxG.keys.anyPressed([S]))
			dy += 1;
		if (FlxG.keys.anyPressed([A]))
			dx -= 1;
		if (FlxG.keys.anyPressed([D]))
			dx += 1;
		if (dx == 0 && dy == 0)
		{
			dx = FlxG.mouse.x - cx;
			dy = FlxG.mouse.y - cy;
		}
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len <= 0)
			return;
		player.velocity.set(dx / len * cfg.catapultSpeed, dy / len * cfg.catapultSpeed);
	}

	function positionHammer(h:Float):Void
	{
		var pcx = player.x + player.width * 0.5;
		var pcy = player.y + player.height * 0.5;
		var rad = player.angle * Math.PI / 180;
		var cos = Math.cos(rad);
		var sin = Math.sin(rad);
		var relX = player.x + HAND_X - pcx;
		var relY = player.y + HAND_Y - pcy;
		var pivotX = pcx + (relX * cos - relY * sin);
		var pivotY = pcy - h + (relX * sin + relY * cos);
		hammer.x = pivotX - hammer.origin.x;
		hammer.y = pivotY - hammer.origin.y;
		hammer.angle = player.angle + 180;
		var s = 4 + slamPop;
		hammer.scale.set(s, s);
		hammer.visible = true;
	}
}
