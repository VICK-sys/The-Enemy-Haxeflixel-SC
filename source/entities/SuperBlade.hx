package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import util.Paths;

class SuperBlade extends FlxSprite
{
	public static inline var RADIUS:Float = 45;

	static inline var LAUNCH_SPEED:Float = 1300;
	static inline var RANGE:Float = 750;
	static inline var FADE_TIME:Float = 0.15;
	static inline var RISE_TIME:Float = 0.15;
	static inline var RISE_HEIGHT:Float = 90;
	static inline var AIM_TIME:Float = 0.12;
	static inline var LAUNCH_ANGLE_OFFSET:Float = 90;

	public var launched:Bool = false;
	public var slot:Int = 0;
	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var fading:Bool = false;

	private var life:Float = 0;
	private var launchPhase:Int = 0;
	private var phaseTimer:Float = 0;
	private var riseBaseY:Float = 0;
	private var startAngle:Float = 0;
	private var targetAngle:Float = 0;
	private var targetX:Float = 0;
	private var targetY:Float = 0;
	private var hitList:Array<FlxObject> = [];

	public function new()
	{
		super();
		loadGraphic(Paths.image("items/mufu_scythe"));
		antialiasing = false;
		scale.set(3, 3);
	}

	public function spawnInFormation(slot:Int):Void
	{
		revive();
		launched = false;
		fading = false;
		alpha = 1;
		angle = 0;
		angularVelocity = 0;
		scale.set(3, 3);
		velocity.set(0, 0);
		this.slot = slot;
	}

	public function inFlight():Bool
	{
		return launched && launchPhase == 2;
	}

	public function launch(tx:Float, ty:Float):Void
	{
		launched = true;
		launchPhase = 0;
		phaseTimer = RISE_TIME;
		targetX = tx;
		targetY = ty;
		alpha = 1;
		scale.set(3, 3);
		angularVelocity = 0;
		velocity.set(0, 0);
		riseBaseY = y;
		hitList.resize(0);
		FlxG.sound.play(Paths.sound("scythe/slice"), 0.35);
	}

	public function hasHit(e:FlxObject):Bool
	{
		return hitList.indexOf(e) >= 0;
	}

	public function markHit(e:FlxObject):Void
	{
		hitList.push(e);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!launched)
			return;

		switch (launchPhase)
		{
			case 0:
				phaseTimer -= elapsed;
				var p = 1 - Math.max(0, phaseTimer) / RISE_TIME;
				var ease = 1 - (1 - p) * (1 - p);
				y = riseBaseY - RISE_HEIGHT * ease;
				if (phaseTimer <= 0)
				{
					var ddx = targetX - (x + width / 2);
					var ddy = targetY - (y + height / 2);
					var len = Math.sqrt(ddx * ddx + ddy * ddy);
					if (len < 0.001)
					{
						ddx = 1;
						ddy = 0;
						len = 1;
					}
					dirX = ddx / len;
					dirY = ddy / len;
					startAngle = angle;
					targetAngle = Math.atan2(dirY, dirX) * 180 / Math.PI + LAUNCH_ANGLE_OFFSET;
					launchPhase = 1;
					phaseTimer = AIM_TIME;
				}
			case 1:
				phaseTimer -= elapsed;
				var p = 1 - Math.max(0, phaseTimer) / AIM_TIME;
				var ease = 1 - (1 - p) * (1 - p) * (1 - p);
				var delta = ((targetAngle - startAngle) % 360 + 540) % 360 - 180;
				angle = startAngle + delta * ease;
				if (phaseTimer <= 0)
				{
					launchPhase = 2;
					angle = targetAngle;
					velocity.set(dirX * LAUNCH_SPEED, dirY * LAUNCH_SPEED);
					life = RANGE / LAUNCH_SPEED;
					FlxG.sound.play(Paths.sound("scythe/throw"), 0.7);
				}
			default:
				if (!fading)
				{
					life -= elapsed;
					if (life <= 0)
						fading = true;
				}
				else
				{
					alpha -= elapsed / FADE_TIME;
					if (alpha <= 0)
						kill();
				}
		}
	}
}
