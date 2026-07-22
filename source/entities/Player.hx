package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import util.Paths;

class Player extends FlxSprite
{

	static inline var MOVEMENT_SPEED:Float = 450;
	static inline var DASH_SPEED:Float = 1100;
	static inline var DASH_TIME:Float = 0.15;

	public var blockMovement:Bool = false;
	public var isDead:Bool = false;
	public var dashTimer:Float = 0;

	private var initialSpeed:Float = 50;
	private var walkingSound:FlxSound;
	private var walkSound:Bool = false;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		this.frames = Paths.sparrow("characters/mufu");
		this.animation.addByPrefix("idle", "Idle", 12, true);
		this.animation.addByPrefix("walk", "Run", 12, true);
		this.animation.addByPrefix("hurt", "Hurt", 12, false);
		this.animation.addByPrefix("death", "Death", 12, false);
		this.antialiasing = false;
		this.width = 75;
		this.height = 95;
		this.offset.set(-19, -17);
		this.scale.set(4, 4);

		drag.x = drag.y = 700;

		walkingSound = FlxG.sound.load(Paths.sound("walk/wave"), 1, true);
	}

	public function dash():Void
	{
		var dx:Float = 0;
		var dy:Float = 0;
		if (FlxG.keys.anyPressed([W])) dy -= 1;
		if (FlxG.keys.anyPressed([S])) dy += 1;
		if (FlxG.keys.anyPressed([A])) dx -= 1;
		if (FlxG.keys.anyPressed([D])) dx += 1;
		if (dx == 0 && dy == 0)
			dx = flipX ? -1 : 1;
		var len:Float = Math.sqrt(dx * dx + dy * dy);
		dx /= len;
		dy /= len;
		velocity.set(dx * DASH_SPEED, dy * DASH_SPEED);
		if (dx > 0) flipX = false;
		else if (dx < 0) flipX = true;
		this.animation.play("walk");
		dashTimer = DASH_TIME;
	}

	override function update(elapsed:Float)
	{
		if (dashTimer > 0)
			dashTimer -= elapsed;
		else if (!blockMovement)
			movement(elapsed);

		if(isDead)
		{
			if(walkSound)
			{
				walkingSound.stop();
				walkSound = false;
			}
		}

		super.update(elapsed);
	}

	private function movement(elapsed:Float)
	{

		var up:Bool = false;
		var down:Bool = false;
		var left:Bool = false;
		var right:Bool = false;

		up = FlxG.keys.anyPressed([W]);
		down = FlxG.keys.anyPressed([S]);
		left = FlxG.keys.anyPressed([A]);
		right = FlxG.keys.anyPressed([D]);

		if (up && down)
		{
			up = down = false;
		}

		if (right && left)
		{
			right = left = false;
		}

		if (up || down || left || right)
		{
			var newAngle:Float = 0;

			if(!walkSound && !isDead)
			{
				walkingSound.play();
				walkSound = true;
			}

			if(initialSpeed < MOVEMENT_SPEED)
			{
				initialSpeed += 900 * elapsed;
			}

			if(initialSpeed >= MOVEMENT_SPEED)
			{
				initialSpeed = MOVEMENT_SPEED;
			}

			this.animation.play("walk");

			if (up)
			{
				newAngle = -90;

				if (left)
				{
					newAngle -= 45;
				}
				else if (right)
				{
					newAngle += 45;
				}
			}
			else if (down)
			{
				newAngle = 90;

				if (left)
				{
					newAngle += 45;
				}
				else if (right)
				{
					newAngle -= 45;
				}
			}
			else if (left)
			{
				newAngle = 180;
				this.flipX = true;
			}
			else if (right)
			{
				newAngle = 0;
				this.flipX = false;
			}

			velocity.set(initialSpeed, 0);
			velocity.pivotDegrees(FlxPoint.weak(0, 0), newAngle);
		}
		else
		{

			this.animation.play("idle");

			if(walkSound)
			{
				walkingSound.stop();
				walkSound = false;
			}

			initialSpeed = 100;
		}
	}
}
