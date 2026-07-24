package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
import data.PlayerData.PlayerDataRegistry;
import util.GhostTrail;
import util.Paths;
import util.WorldClock;

enum TimePhase {
	Running;
	Slowing;
	Stopped;
	Recovering;
}

class TimeStop
{
	static inline var TRAIL_TINT:Int = 0xFF5AA9FF;
	static inline var TRAIL_ALPHA:Float = 0.45;
	static inline var TRAIL_FADE:Float = 2.2;
	static inline var TRAIL_INTERVAL:Float = 0.03;
	static inline var TRAIL_MIN_SPEED:Float = 150;
	static inline var OVERLAY_MAX:Float = 0.22;
	static inline var MIN_PITCH:Float = 0.05;

	public var factor(default, null):Float = 1;
	public var cooldown(default, null):Float = 0;
	public var active(get, never):Bool;
	public var overlay:FlxSprite;
	public var trail:GhostTrail;
	public var shadowTrail:GhostTrail;

	private var player:Player;
	private var shadow:FlxSprite;
	private var status:PlayerCombat;
	private var phase:TimePhase = Running;
	private var timer:Float = 0;
	private var slowTime:Float;
	private var holdTime:Float;
	private var lastSecond:Int = -1;
	private var tock:Bool = false;
	private var recoverTime:Float;
	private var cooldownTime:Float;

	public function new(player:Player, shadow:FlxSprite, status:PlayerCombat)
	{
		this.player = player;
		this.shadow = shadow;
		this.status = status;
		var d = PlayerDataRegistry.get();
		slowTime = d.timestopSlow;
		holdTime = d.timestopHold;
		recoverTime = d.timestopRecover;
		cooldownTime = d.timestopCooldown;

		trail = new GhostTrail("characters/mufu", TRAIL_ALPHA, TRAIL_FADE, TRAIL_INTERVAL);
		shadowTrail = new GhostTrail("effects/shadow", TRAIL_ALPHA, TRAIL_FADE, TRAIL_INTERVAL);

		overlay = new FlxSprite();
		overlay.makeGraphic(4, 4, 0xFF2B4E70);
		overlay.scale.set(400, 225);
		overlay.updateHitbox();
		overlay.setPosition(-160, -90);
		overlay.scrollFactor.set();
		overlay.alpha = 0;

		WorldClock.scale = 1;
	}

	function get_active():Bool
		return phase != Running;

	public function update(elapsed:Float):Void
	{
		if (phase == Running && cooldown > 0)
			cooldown -= elapsed;

		if (FlxG.keys.justPressed.E && !status.dead)
		{
			if (phase == Running && cooldown <= 0)
				begin();
			else if (phase == Slowing || phase == Stopped)
				endStop(true);
		}

		if (status.dead && (phase == Slowing || phase == Stopped))
			endStop(false);

		switch (phase)
		{
			case Running:
			case Slowing:
				timer -= elapsed;
				var t = timer / slowTime;
				if (t < 0)
					t = 0;
				factor = t * t;
				if (timer <= 0)
				{
					factor = 0;
					phase = Stopped;
					timer = holdTime;
					lastSecond = Std.int(holdTime);
					tock = false;
					if (FlxG.sound.music != null)
						FlxG.sound.music.pause();
				}
			case Stopped:
				timer -= elapsed;
				factor = 0;
				var second = Std.int(timer);
				if (second != lastSecond)
				{
					lastSecond = second;
					tock = !tock;
					FlxG.sound.play(Paths.sound(tock ? "tick" : "tock"), 0.6);
				}
				if (FlxG.sound.music != null && FlxG.sound.music.playing)
					FlxG.sound.music.pause();
				if (timer <= 0)
					endStop(true);
			case Recovering:
				timer -= elapsed;
				var t = 1 - timer / recoverTime;
				if (t > 1)
					t = 1;
				factor = t * t;
				if (timer <= 0)
				{
					factor = 1;
					phase = Running;
					cooldown = cooldownTime;
				}
		}

		WorldClock.scale = factor;
		applyMusicPitch();
		overlay.alpha = (1 - factor) * OVERLAY_MAX;
		updateTrail(elapsed);
	}

	public function timerLabel():String
	{
		if (phase == Slowing)
			return formatTimer(holdTime);
		if (phase == Stopped)
			return formatTimer(timer);
		return "";
	}

	static function formatTimer(t:Float):String
	{
		if (t < 0)
			t = 0;
		var s = Std.int(t);
		var ms = Std.int((t - s) * 1000);
		return s + "." + StringTools.lpad(Std.string(ms), "0", 3);
	}

	public function hudLabel():String
	{
		if (phase != Running)
			return "TIME STOPPED";
		if (cooldown > 0)
			return "TIME " + Math.ceil(cooldown);
		return "TIME READY";
	}

	function begin():Void
	{
		phase = Slowing;
		timer = slowTime;
		FlxG.sound.play(Paths.sound("enemies/charge"), 0.6);
	}

	function endStop(playSound:Bool):Void
	{
		if (phase == Stopped && FlxG.sound.music != null)
			FlxG.sound.music.resume();
		phase = Recovering;
		timer = recoverTime;
		if (playSound)
			FlxG.sound.play(Paths.sound("scythe/catch"), 0.5);
	}

	function applyMusicPitch():Void
	{
		var m = FlxG.sound.music;
		if (m == null)
			return;
		if (phase == Slowing || phase == Recovering)
			m.pitch = Math.max(factor, MIN_PITCH);
		else if (phase == Running && m.pitch != 1)
			m.pitch = 1;
	}

	function updateTrail(elapsed:Float):Void
	{
		var cadence = trail.tick(elapsed);
		shadowTrail.tick(elapsed);
		if (phase == Running || !cadence || factor > 0.6)
			return;
		var vx = player.velocity.x;
		var vy = player.velocity.y;
		if (vx * vx + vy * vy < TRAIL_MIN_SPEED * TRAIL_MIN_SPEED)
			return;
		if (shadow.visible)
			shadowTrail.stampFrame(shadow, 0xFFFFFFFF);
		trail.stampFrame(player, TRAIL_TINT);
	}
}
