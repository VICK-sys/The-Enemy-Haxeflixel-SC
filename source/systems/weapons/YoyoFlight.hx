package systems.weapons;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import data.WeaponData.WeaponDataRegistry;
import util.Paths;

class YoyoFlight
{
	static inline var SPIN_RATE:Float = 1500;
	static inline var SCALE:Float = 4;

	public var yoyo:FlxSprite;
	public var string:FlxTypedGroup<FlxSprite>;
	public var cx(default, null):Float = 0;
	public var cy(default, null):Float = 0;

	public var active(get, never):Bool;
	public var returning(get, never):Bool;

	private var cfg = WeaponDataRegistry.get().yoyo;
	private var dirX:Float = 1;
	private var dirY:Float = 0;
	private var spin:Float = 1;
	private var timer:Float = 0;

	public function new()
	{
		yoyo = new FlxSprite();
		yoyo.loadGraphic(Paths.image("items/yoyo_axel"));
		yoyo.antialiasing = false;
		yoyo.scale.set(SCALE, SCALE);
		yoyo.kill();
		string = new FlxTypedGroup<FlxSprite>();
	}

	function get_active():Bool
		return timer > 0;

	function get_returning():Bool
		return timer > 0 && timer <= cfg.backTime;

	public function fire(hx:Float, hy:Float, dx:Float, dy:Float, spinDir:Float):Void
	{
		dirX = dx;
		dirY = dy;
		spin = spinDir;
		timer = cfg.outTime + cfg.backTime;
		cx = hx;
		cy = hy;
		yoyo.revive();
		yoyo.setPosition(hx - yoyo.width * 0.5, hy - yoyo.height * 0.5);
	}

	public function stop():Void
	{
		timer = 0;
		yoyo.kill();
		Rope.clear(string);
	}

	public function update(elapsed:Float, hx:Float, hy:Float):Void
	{
		if (timer <= 0)
			return;

		timer -= elapsed;
		if (timer <= 0)
		{
			stop();
			return;
		}

		var out = timer > cfg.backTime;
		var t = out ? 1 - (timer - cfg.backTime) / cfg.outTime : timer / cfg.backTime;
		if (t < 0)
			t = 0;
		else if (t > 1)
			t = 1;

		var span = cfg.reach * FlxEase.quadOut(t);
		cx = hx + dirX * span;
		cy = hy + dirY * span;

		yoyo.angle += spin * SPIN_RATE * elapsed;
		yoyo.setPosition(cx - yoyo.width * 0.5, cy - yoyo.height * 0.5);
		Rope.line(string, hx, hy, cx, cy);
	}
}
