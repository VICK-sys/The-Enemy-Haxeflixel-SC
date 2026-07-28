package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import entities.Player;
import net.Net;
import entities.enemy.Enemies;
import systems.enemy.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;
import util.WorldClock;

class DeadEye
{
	static inline var MARK_SIZE:Int = 24;
	static inline var MARK_INSET:Float = 5;
	static inline var MARK_THICK:Float = 3;
	static inline var MARK_COLOR:Int = 0xFFE0132D;
	static inline var MARK_SCALE:Float = 3;
	static inline var PULSE_RATE:Float = 9;
	static inline var PULSE_AMP:Float = 0.18;
	static inline var SEPIA:Int = 0xFF8A5A22;
	static inline var ARM_TIME:Float = 0.12;
	static inline var LIVE_MARK_TIME:Float = 3;

	public var markers:FlxTypedGroup<FlxSprite>;
	public var overlay:FlxSprite;
	public var active(get, never):Bool;
	public var marking(get, never):Bool;
	public var onShot:(Float, Float, Float, Float, Float) -> Void;

	private var cfg = WeaponDataRegistry.get().deadEye;
	private var player:Player;
	private var director:EnemyDirector;
	private var revolver:RevolverAttack;
	private var held:HeldWeapon;
	private var heartbeat:FlxSound;
	private var phase:Int = 0;
	private var flash:Float = 0;
	private var fade:Float = 0;
	private var arm:Float = 0;
	private var shotTimer:Float = 0;
	private var pulse:Float = 0;
	private var blockSaved:Bool = false;
	private var froze:Bool = false;
	private var liveTimer:Float = 0;
	private var targets:Array<Enemies> = [];

	public function new(player:Player, director:EnemyDirector, revolver:RevolverAttack, held:HeldWeapon)
	{
		this.player = player;
		this.director = director;
		this.revolver = revolver;
		this.held = held;

		markers = new FlxTypedGroup<FlxSprite>();
		heartbeat = FlxG.sound.create(Paths.sound("heartbeat")).setup(0.8, true);

		overlay = new FlxSprite();
		overlay.makeGraphic(4, 4, FlxColor.WHITE);
		overlay.scale.set(400, 225);
		overlay.updateHitbox();
		overlay.setPosition(-160, -90);
		overlay.scrollFactor.set();
		overlay.alpha = 0;
	}

	function get_active():Bool
		return phase == 1 || phase == 2;

	function get_marking():Bool
		return phase == 1;

	public function canActivate():Bool
		return phase == 0 && !revolver.isReloading && !revolver.isFanning && revolver.rounds > 0;

	public function activate():Void
	{
		if (!canActivate())
			return;

		phase = 1;
		flash = cfg.flashTime;
		arm = ARM_TIME;
		pulse = 0;
		targets = [];

		froze = !Net.active;
		if (froze)
		{
			WorldClock.superSlow = 0;
			blockSaved = player.blockMovement;
			player.blockMovement = true;
		}
		else
			liveTimer = LIVE_MARK_TIME;

		overlay.color = FlxColor.WHITE;
		overlay.alpha = 1;

		heartbeat.play(true);
		FlxG.sound.play(Paths.sound("weapon/ascend"), 0.7);
	}

	public function cancel():Void
	{
		letGo();
		phase = 0;
		fade = 0;
		overlay.alpha = 0;
	}

	function letGo():Void
	{
		targets = [];
		if (froze)
		{
			WorldClock.superSlow = 1;
			player.blockMovement = blockSaved;
		}
		held.unlockAim();
		heartbeat.stop();
		for (m in markers.members)
			if (m != null)
				m.kill();
	}

	public function update(elapsed:Float):Void
	{
		if (phase == 0)
		{
			if (overlay.alpha != 0)
				overlay.alpha = 0;
			return;
		}

		if (phase == 3)
		{
			fade -= elapsed;
			if (fade > 0)
				overlay.alpha = cfg.sepiaAlpha * (fade / cfg.fadeTime);
			else
			{
				overlay.alpha = 0;
				phase = 0;
			}
			return;
		}

		if (froze)
			player.blockMovement = true;

		if (phase == 1)
			updateMarking(elapsed);
		else
			updateFiring(elapsed);

		if (phase == 0)
			return;

		updateOverlay(elapsed);
		placeMarkers(elapsed);
	}

	function updateMarking(elapsed:Float):Void
	{
		if (arm > 0)
			arm -= elapsed;

		if (!froze)
		{
			liveTimer -= elapsed;
			if (liveTimer <= 0)
			{
				release();
				return;
			}
		}

		if (targets.length < revolver.rounds)
		{
			var hit = director.firstInCircle(FlxG.mouse.x, FlxG.mouse.y, cfg.markRadius);
			if (hit != null && !hit.isDead && targets.indexOf(hit) < 0)
			{
				targets.push(hit);
				markers.recycle(FlxSprite, newMarker);
				FlxG.sound.play(Paths.sound("tick"), 0.55);
			}
		}

		if (arm <= 0 && FlxG.mouse.justPressed)
			release();
	}

	public function release():Void
	{
		if (phase != 1)
			return;

		if (targets.length == 0)
		{
			cancel();
			return;
		}

		phase = 2;
		fade = cfg.fadeTime;
		shotTimer = 0;
		if (froze)
			WorldClock.superSlow = 1;
		heartbeat.stop();
	}

	function updateFiring(elapsed:Float):Void
	{
		shotTimer -= elapsed;
		if (shotTimer > 0)
			return;

		shotTimer = cfg.shotInterval;

		while (targets.length > 0)
		{
			var t = targets.shift();
			if (t == null || !t.exists || t.isDead)
				continue;
			var bx = held.handX();
			var by = held.handY();
			var tx = t.x + t.width / 2;
			var ty = t.y + t.height / 2;
			held.lockAim(Math.atan2(ty - by, tx - bx) * 180 / Math.PI);
			revolver.fireAt(bx, by, t, cfg.damage);
			if (onShot != null)
				onShot(bx, by, tx, ty, Math.atan2(ty - by, tx - bx) * 180 / Math.PI);
			systems.Fx.shake(0.004, 0.14);
			return;
		}

		letGo();
		phase = 3;
	}

	function updateOverlay(elapsed:Float):Void
	{
		if (phase == 1 && flash > 0)
		{
			flash -= elapsed;
			var t = 1 - flash / cfg.flashTime;
			if (t > 1)
				t = 1;
			overlay.color = FlxColor.interpolate(FlxColor.WHITE, SEPIA, t);
			overlay.alpha = 1 - (1 - cfg.sepiaAlpha) * t;
			return;
		}

		overlay.color = SEPIA;
		overlay.alpha = cfg.sepiaAlpha;
	}

	function placeMarkers(elapsed:Float):Void
	{
		pulse += elapsed * PULSE_RATE;
		var s = MARK_SCALE * (1 + Math.sin(pulse) * PULSE_AMP);

		var i = 0;
		for (m in markers.members)
		{
			if (m == null || !m.exists)
				continue;
			if (i >= targets.length)
			{
				m.kill();
				continue;
			}
			var t = targets[i++];
			if (t == null || !t.exists || t.isDead)
			{
				m.visible = false;
				continue;
			}
			m.visible = true;
			m.scale.set(s, s);
			m.setPosition(t.x + t.width / 2 - m.width / 2, t.y + t.height / 2 - m.height / 2);
		}
	}

	function newMarker():FlxSprite
	{
		var m = new FlxSprite();
		m.makeGraphic(MARK_SIZE, MARK_SIZE, FlxColor.TRANSPARENT, true);
		var lo = MARK_INSET;
		var hi = MARK_SIZE - MARK_INSET;
		var style = {color: MARK_COLOR, thickness: MARK_THICK};
		FlxSpriteUtil.drawLine(m, lo, lo, hi, hi, style);
		FlxSpriteUtil.drawLine(m, hi, lo, lo, hi, style);
		m.antialiasing = false;
		m.scale.set(MARK_SCALE, MARK_SCALE);
		return m;
	}
}
