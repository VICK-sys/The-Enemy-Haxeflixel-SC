package entities;

import flixel.FlxObject;
import flixel.FlxSprite;
import util.Paths;

class ThrownScythe extends FlxSprite
{
	public static inline var RADIUS:Float = 90;

	static inline var THROW_SPEED:Float = 1000;
	static inline var SPIN:Float = 1500;

	public var returning:Bool = false;
	public var startX:Float = 0;
	public var startY:Float = 0;

	private var hitList:Array<FlxObject> = [];
	private var flightTime:Float = 0;

	public function new()
	{
		super();
		loadGraphic(Paths.image("items/mufu_scythe"));
		antialiasing = false;
		scale.set(4, 4);
		kill();
	}

	public function throwAt(cx:Float, cy:Float, dx:Float, dy:Float):Void
	{
		revive();
		setPosition(cx - width / 2, cy - height / 2);
		velocity.set(dx * THROW_SPEED, dy * THROW_SPEED);
		angularVelocity = SPIN;
		returning = false;
		startX = cx;
		startY = cy;
		hitList.resize(0);
		flightTime = 0;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		flightTime += elapsed;
		var pop:Float = flightTime < 0.15 ? (0.15 - flightTime) / 0.15 * 2.2 : 0;
		var s:Float = 4.4 + pop + Math.sin(flightTime * 16) * 0.6;
		scale.set(s, s);
	}

	public function beginReturn():Void
	{
		if (returning)
			return;
		returning = true;
		hitList.resize(0);
	}

	public function hasHit(e:FlxObject):Bool
	{
		return hitList.indexOf(e) >= 0;
	}

	public function markHit(e:FlxObject):Void
	{
		hitList.push(e);
	}
}
