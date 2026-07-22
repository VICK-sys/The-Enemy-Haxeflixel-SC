package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.tweens.FlxEase;
import flixel.sound.FlxSound;

class Player extends FlxSprite
{

	static inline var MOVEMENT_SPEED:Float = 450;
	var intialSpeed:Float = 50;

	private var walkingSound:FlxSound;
	var walkSound:Bool = false;

	public var blockMovement:Bool = false;
	public var isDead:Bool = false;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		this.loadGraphic("assets/images/characters/mufu.png", true, 20, 23);
		this.frames = FlxAtlasFrames.fromSparrow("assets/images/characters/mufu.png", "assets/images/characters/mufu.xml");
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

		walkingSound = FlxG.sound.load("assets/sounds/walk/wave.ogg", 1, true);
	}

	override function update(elapsed:Float)
	{
		if (!blockMovement) movement(elapsed);

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

			if(intialSpeed < MOVEMENT_SPEED)
			{
				intialSpeed += 900 * elapsed;
			}

			if(intialSpeed >= MOVEMENT_SPEED)
			{
				intialSpeed = MOVEMENT_SPEED;
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

			velocity.set(intialSpeed, 0);
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

			intialSpeed = 100;
		}
	}
}
