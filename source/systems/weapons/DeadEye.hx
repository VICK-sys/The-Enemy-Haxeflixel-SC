package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import entities.enemy.Enemies;
import systems.enemy.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;
import util.WorldClock;

class DeadEye
{
	static inline var MARK_SIZE:Int = 24;
	static inline var MARK_RING:Float = 10;
	static inline var MARK_THICK:Float = 3;
	static inline var MARK_COLOR:Int = 0xFFE0132D;
	static inline var MARK_SCALE:Float = 3;
	static inline var PULSE_RATE:Float = 9;
	static inline var PULSE_AMP:Float = 0.35;

	public var markers:FlxTypedGroup<FlxSprite>;
	public var active(get, never):Bool;
	public var marking(get, never):Bool;
	public var onShot:(Float, Float, Float, Float, Float) -> Void;

	private var cfg = WeaponDataRegistry.get().deadEye;
	private var director:EnemyDirector;
	private var revolver:RevolverAttack;
	private var held:HeldWeapon;
	private var phase:Int = 0;
	private var timer:Float = 0;
	private var shotTimer:Float = 0;
	private var pulse:Float = 0;
	private var targets:Array<Enemies> = [];

	public function new(director:EnemyDirector, revolver:RevolverAttack, held:HeldWeapon)
	{
		this.director = director;
		this.revolver = revolver;
		this.held = held;
		markers = new FlxTypedGroup<FlxSprite>();
	}

	function get_active():Bool
		return phase != 0;

	function get_marking():Bool
		return phase == 1;

	public function canActivate():Bool
		return phase == 0 && !revolver.isReloading && revolver.rounds > 0;

	public function activate():Void
	{
		if (!canActivate())
			return;

		phase = 1;
		timer = cfg.markTime;
		pulse = 0;
		targets = [];
		WorldClock.superSlow = cfg.slowFactor;
		FlxG.sound.play(Paths.sound("weapon/ascend"), 0.7);
	}

	public function cancel():Void
	{
		phase = 0;
		targets = [];
		WorldClock.superSlow = 1;
		for (m in markers.members)
			if (m != null)
				m.kill();
	}

	public function update(elapsed:Float):Void
	{
		if (phase == 0)
			return;

		if (phase == 1)
			updateMarking(elapsed);
		else
			updateFiring(elapsed);

		placeMarkers(elapsed);
	}

	function updateMarking(elapsed:Float):Void
	{
		timer -= elapsed;

		if (targets.length < revolver.rounds)
		{
			var hit = director.firstInCircle(FlxG.mouse.x, FlxG.mouse.y, cfg.markRadius);
			if (hit != null && !hit.isDead && targets.indexOf(hit) < 0)
			{
				targets.push(hit);
				markers.recycle(FlxSprite, newMarker).revive();
				FlxG.sound.play(Paths.sound("tick"), 0.5);
			}
		}

		if (FlxG.mouse.justPressed || timer <= 0)
		{
			if (targets.length == 0)
			{
				cancel();
				return;
			}
			phase = 2;
			shotTimer = 0;
		}
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
			revolver.fireAt(bx, by, t, cfg.damage);
			if (onShot != null)
				onShot(bx, by, tx, ty, Math.atan2(ty - by, tx - bx) * 180 / Math.PI);
			FlxG.camera.shake(0.003, 0.12);
			return;
		}

		cancel();
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
		FlxSpriteUtil.drawCircle(m, MARK_SIZE / 2, MARK_SIZE / 2, MARK_RING, FlxColor.TRANSPARENT,
			{color: MARK_COLOR, thickness: MARK_THICK});
		m.antialiasing = false;
		m.scale.set(MARK_SCALE, MARK_SCALE);
		return m;
	}
}
