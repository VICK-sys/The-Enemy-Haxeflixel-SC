package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import data.WeaponData.WeaponDataRegistry;
import util.GhostTrail;
import util.Paths;

class ArrowStorm
{
	static inline var BOW_RAISE:Float = 84;
	static inline var LAUNCH_SPEED:Float = 1700;
	static inline var LAUNCH_TIME:Float = 0.6;
	static inline var ARROW_SCALE:Float = 9;
	static inline var CHARGE_TINT:Int = 0xFF9BE9FF;
	static inline var TRAIL_INTERVAL:Float = 0.014;
	static inline var TRAIL_ALPHA:Float = 0.55;
	static inline var TRAIL_FADE:Float = 3.2;
	static inline var ARM_TIME:Float = 0.12;
	static inline var PULSE_RATE:Float = 8;
	static inline var PULSE_AMP:Float = 0.07;
	static inline var MARK_FADE:Float = 2;
	static inline var MARK_HOLD:Float = 5;

	static inline var IDLE:Int = 0;
	static inline var MARKING:Int = 1;
	static inline var LAUNCH:Int = 2;
	static inline var STORM:Int = 3;

	public var active(get, never):Bool;
	public var busy(get, never):Bool;
	public var marking(get, never):Bool;
	public var superArrow:FlxSprite;
	public var marker:FlxSprite;
	public var trail:GhostTrail;
	public var onMarked:(Float, Float) -> Void;

	private var cfg = WeaponDataRegistry.get().arrowStorm;
	private var player:FlxSprite;
	private var bow:FlxSprite;
	private var rain:ArrowRain;
	private var phase:Int = IDLE;
	private var timer:Float = 0;
	private var spawnTimer:Float = 0;
	private var launchTimer:Float = 0;
	private var arm:Float = 0;
	private var hold:Float = 0;
	private var pulse:Float = 0;
	private var markScale:Float = 1;
	private var zoneX:Float = 0;
	private var zoneY:Float = 0;

	public function new(player:FlxSprite, bow:FlxSprite, rain:ArrowRain)
	{
		this.player = player;
		this.bow = bow;
		this.rain = rain;
		trail = new GhostTrail("bullets/arrow", TRAIL_ALPHA, TRAIL_FADE, TRAIL_INTERVAL);

		superArrow = new FlxSprite();
		superArrow.loadGraphic(Paths.image("bullets/arrow"));
		superArrow.antialiasing = false;
		superArrow.scale.set(ARROW_SCALE, ARROW_SCALE);
		superArrow.color = CHARGE_TINT;
		superArrow.kill();

		marker = new FlxSprite();
		marker.loadGraphic(Paths.image("effects/crosshair_marker"));
		marker.antialiasing = false;
		markScale = cfg.radius * 2 / marker.frameWidth;
		marker.scale.set(markScale, markScale);
		marker.updateHitbox();
		marker.kill();
	}

	function get_active():Bool
		return phase != IDLE;

	function get_busy():Bool
		return phase == MARKING || phase == LAUNCH;

	function get_marking():Bool
		return phase == MARKING;

	public var hue(default, null):Float = 0;

	public function paint(h:Float):Void
	{
		if (h == hue)
			return;
		hue = h;
		superArrow.loadGraphic(util.HuePalette.graphic("bullets/arrow", h));
		marker.loadGraphic(util.HuePalette.graphic("effects/crosshair_marker", h));
		marker.scale.set(markScale, markScale);
		marker.updateHitbox();
	}

	public function activate():Void
	{
		phase = MARKING;
		arm = ARM_TIME;
		hold = MARK_HOLD;
		pulse = 0;
		marker.revive();
		marker.alpha = 0.75;
		placeMarker(util.Controls.aimX(), util.Controls.aimY());
		FlxG.sound.play(Paths.sound("weapon/catch"), 0.6);
	}

	public function beginAt(x:Float, y:Float):Void
	{
		phase = MARKING;
		arm = 0;
		marker.revive();
		confirm(x, y);
	}

	public function cancel():Void
	{
		if (phase == IDLE)
			return;
		phase = IDLE;
		timer = 0;
		spawnTimer = 0;
		launchTimer = 0;
		arm = 0;
		superArrow.velocity.set(0, 0);
		superArrow.kill();
		marker.kill();
	}

	public function update(elapsed:Float):Void
	{
		if (phase == IDLE)
			return;

		if (busy)
			positionBow();

		if (phase == MARKING)
		{
			updateMarking(elapsed);
			return;
		}

		var cadence = trail.tick(elapsed);

		if (phase == LAUNCH)
			updateLaunch(elapsed, cadence);
		else
			updateStorm(elapsed);
	}

	function updateMarking(elapsed:Float):Void
	{
		pulse += elapsed * PULSE_RATE;
		var s = markScale * (1 + Math.sin(pulse) * PULSE_AMP);
		marker.scale.set(s, s);
		marker.updateHitbox();
		placeMarker(util.Controls.aimX(), util.Controls.aimY());

		if (arm > 0)
		{
			arm -= elapsed;
			return;
		}

		hold -= elapsed;
		if (util.Controls.attackJustPressed() || hold <= 0)
			confirm(util.Controls.aimX(), util.Controls.aimY());
	}

	function confirm(x:Float, y:Float):Void
	{
		zoneX = x;
		zoneY = y;
		marker.scale.set(markScale, markScale);
		marker.updateHitbox();
		marker.alpha = 0.55;
		placeMarker(zoneX, zoneY);

		phase = LAUNCH;
		launchTimer = LAUNCH_TIME;
		positionBow();

		superArrow.revive();
		superArrow.color = CHARGE_TINT;
		superArrow.scale.set(ARROW_SCALE, ARROW_SCALE);
		superArrow.angle = -90;
		superArrow.alpha = 1;
		superArrow.velocity.set(0, -LAUNCH_SPEED);
		superArrow.setPosition(bow.x + bow.origin.x - superArrow.width / 2, bow.y + bow.origin.y - superArrow.height / 2);

		if (onMarked != null)
			onMarked(zoneX, zoneY);

		FlxG.sound.play(Paths.sound("bow"), 0.9);
	}

	function placeMarker(x:Float, y:Float):Void
		marker.setPosition(x - marker.width * 0.5, y - marker.height * 0.5);

	function updateLaunch(elapsed:Float, cadence:Bool):Void
	{
		launchTimer -= elapsed;

		if (cadence)
			trail.stamp(superArrow);

		var offTop = superArrow.y + superArrow.height < FlxG.camera.scroll.y;
		if (launchTimer <= 0 || offTop)
			beginStorm();
	}

	function beginStorm():Void
	{
		phase = STORM;
		timer = cfg.stormTime;
		spawnTimer = 0;
		superArrow.velocity.set(0, 0);
		superArrow.kill();
		FlxG.sound.play(Paths.sound("enemies/charge"), 0.6);
	}

	function updateStorm(elapsed:Float):Void
	{
		timer -= elapsed;
		spawnTimer -= elapsed;

		while (spawnTimer <= 0 && timer > 0)
		{
			spawnTimer += cfg.spawnInterval;
			for (i in 0...cfg.dropsPer)
			{
				var r = cfg.radius * Math.sqrt(FlxG.random.float());
				var a = FlxG.random.float() * Math.PI * 2;
				rain.rainAt(zoneX + Math.cos(a) * r, zoneY + Math.sin(a) * r);
			}
		}

		if (timer <= 0 && marker.exists)
		{
			marker.alpha -= elapsed * MARK_FADE;
			if (marker.alpha <= 0)
				marker.kill();
		}

		if (timer <= 0 && trail.drained() && !marker.exists)
			phase = IDLE;
	}

	function positionBow():Void
	{
		bow.flipX = false;
		bow.angle = -90;
		bow.scale.set(4, 4);
		bow.x = player.x - bow.origin.x + HeldWeapon.HAND_DX;
		bow.y = player.y - bow.origin.y - BOW_RAISE;
		bow.visible = true;
	}
}
