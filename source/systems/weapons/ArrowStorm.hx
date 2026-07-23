package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
import data.WeaponData.WeaponDataRegistry;
import util.GhostTrail;
import util.Paths;

class ArrowStorm
{
	static inline var BOW_RAISE:Float = 35;
	static inline var LAUNCH_SPEED:Float = 1700;
	static inline var LAUNCH_TIME:Float = 0.6;
	static inline var ARROW_SCALE:Float = 9;
	static inline var CHARGE_TINT:Int = 0xFF9BE9FF;
	static inline var TRAIL_INTERVAL:Float = 0.014;
	static inline var TRAIL_ALPHA:Float = 0.55;
	static inline var TRAIL_FADE:Float = 3.2;

	public var active(get, never):Bool;
	public var superArrow:FlxSprite;
	public var trail:GhostTrail;

	private var cfg = WeaponDataRegistry.get().arrowStorm;
	private var player:Player;
	private var bow:FlxSprite;
	private var rain:ArrowRain;
	private var phase:Int = 0;
	private var timer:Float = 0;
	private var spawnTimer:Float = 0;
	private var launchTimer:Float = 0;

	public function new(player:Player, bow:FlxSprite, rain:ArrowRain)
	{
		this.player = player;
		this.bow = bow;
		this.rain = rain;
		trail = new GhostTrail("items/arrow", TRAIL_ALPHA, TRAIL_FADE, TRAIL_INTERVAL);
		superArrow = new FlxSprite();
		superArrow.loadGraphic(Paths.image("items/arrow"));
		superArrow.antialiasing = false;
		superArrow.scale.set(ARROW_SCALE, ARROW_SCALE);
		superArrow.color = CHARGE_TINT;
		superArrow.kill();
	}

	function get_active():Bool
		return phase != 0;

	public function activate():Void
	{
		phase = 1;
		launchTimer = LAUNCH_TIME;
		positionBow();

		superArrow.revive();
		superArrow.color = CHARGE_TINT;
		superArrow.scale.set(ARROW_SCALE, ARROW_SCALE);
		superArrow.angle = 0;
		superArrow.alpha = 1;
		superArrow.velocity.set(0, -LAUNCH_SPEED);
		superArrow.setPosition(bow.x + bow.origin.x - superArrow.width / 2, bow.y + bow.origin.y - superArrow.height / 2);

		FlxG.sound.play(Paths.sound("bow"), 0.9);
	}

	public function update(elapsed:Float):Void
	{
		if (phase == 0)
			return;

		positionBow();
		var cadence = trail.tick(elapsed);

		if (phase == 1)
			updateLaunch(elapsed, cadence);
		else
			updateStorm(elapsed);
	}

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
		phase = 2;
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
			var vw = FlxG.width / FlxG.camera.zoom;
			var vh = FlxG.height / FlxG.camera.zoom;
			for (i in 0...cfg.dropsPer)
			{
				var vx = FlxG.camera.scroll.x + FlxG.random.float() * vw;
				var vy = FlxG.camera.scroll.y + FlxG.random.float() * vh;
				rain.rainAt(vx, vy);
			}
		}

		if (timer <= 0 && trail.drained())
			phase = 0;
	}

	function positionBow():Void
	{
		bow.flipX = false;
		bow.angle = -90;
		bow.scale.set(4, 4);
		bow.x = player.x - bow.origin.x + 30;
		bow.y = player.y - bow.origin.y - BOW_RAISE;
		bow.visible = true;
	}
}
