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

	public var engaged(default, null):Bool = false;
	public var ready(default, null):Bool = false;
	public var progress(default, null):Float = 0;

	private var cfg:SwingConfig;
	private var held:HeldWeapon;
	private var wave:Float = 0;
	private var fed:Bool = false;
	private var chargeSound:FlxSound;

	public function new(held:HeldWeapon, cfg:SwingConfig)
	{
		this.held = held;
		this.cfg = cfg;
		chargeSound = FlxG.sound.create(Paths.sound("weapon/gigaCharge")).setup(0, true);
	}

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
				held.flash();
			}
			else
				chargeSound.volume = CHARGE_VOL * progress * progress;
		}
		else
			wave += elapsed * WAVE_SPEED;
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
		chargeSound.stop();
		held.windup = 0;
		held.glow = 0;
	}
}
