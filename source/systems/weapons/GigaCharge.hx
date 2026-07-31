package systems.weapons;

import flixel.FlxG;
import flixel.sound.FlxSound;
import data.WeaponData.SwingConfig;
import util.Paths;

class GigaCharge
{
	static inline var CHARGE_VOL:Float = 0.8;
	static inline var READY_VOL:Float = 0.6;
	static inline var GLOW_RAMP:Float = 0.3;
	static inline var GLOW_BASE:Float = 0.5;
	static inline var GLOW_WAVE:Float = 0.22;
	static inline var WAVE_SPEED:Float = 10;
	static inline var SHINE_WINDOW:Float = 0.18;
	static inline var HEAD_REACH:Float = 0.7;

	public var engaged(default, null):Bool = false;
	public var ready(default, null):Bool = false;
	public var progress(default, null):Float = 0;
	public var shineTimed(get, never):Bool;

	private var cfg:SwingConfig;
	private var held:HeldWeapon;
	private var fx:systems.Fx;
	private var wave:Float = 0;
	private var shineClock:Float = 0;
	private var fed:Bool = false;
	private var chargeSound:FlxSound;

	public function new(held:HeldWeapon, fx:systems.Fx, cfg:SwingConfig)
	{
		this.held = held;
		this.fx = fx;
		this.cfg = cfg;
		chargeSound = FlxG.sound.create(Paths.sound("weapon/gigaCharge")).setup(0, true);
	}

	function get_shineTimed():Bool
		return ready && shineClock <= SHINE_WINDOW;

	public function charge(elapsed:Float):Void
	{
		fed = true;
		if (!engaged)
		{
			engaged = true;
			ready = false;
			progress = 0;
			wave = 0;
			chargeSound.volume = 0;
			chargeSound.play(true);
		}
		if (!ready)
		{
			progress += elapsed / (cfg.chargeTime * util.Levels.actionScale());
			if (progress >= 1)
			{
				progress = 1;
				ready = true;
				chargeSound.stop();
				FlxG.sound.play(Paths.sound("weapon/gigaReady"), READY_VOL);
				shineClock = 0;
				sparkle();
			}
			else
				chargeSound.volume = CHARGE_VOL * progress * progress;
		}
		else
		{
			wave += elapsed * WAVE_SPEED;
			shineClock += elapsed;
		}
		held.windup = progress;
		held.glow = ready ? GLOW_BASE + GLOW_WAVE * (0.5 + 0.5 * Math.sin(wave)) : GLOW_RAMP * progress * progress;
	}

	public function tick():Void
	{
		if (engaged && !fed)
			letGo();
		fed = false;
	}

	public function letGo():Void
	{
		if (!engaged)
			return;
		engaged = false;
		ready = false;
		progress = 0;
		shineClock = 0;
		chargeSound.stop();
		held.windup = 0;
		held.glow = 0;
	}

	function sparkle():Void
	{
		held.flash();
		var s = held.sprite;
		var rad = (s.angle - 90) * Math.PI / 180;
		var reach = s.frameHeight * s.scale.y * HEAD_REACH;
		fx.chargePop(s.x + s.origin.x + Math.cos(rad) * reach, s.y + s.origin.y + Math.sin(rad) * reach);
	}
}
