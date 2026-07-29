package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import util.Paths;
import data.PlayerData;
import data.PlayerData.PlayerDataRegistry;

class Player extends FlxSprite
{
	public static inline var FEET:Float = 90;

	public var feetY(get, never):Float;

	function get_feetY():Float
		return y + FEET * sizeScale;

	public var sizeScale(default, null):Float = 1;

	public function setSizeScale(k:Float):Void
	{
		if (k == sizeScale)
			return;
		var footX = x + width * 0.5;
		var footY = feetY;
		sizeScale = k;
		applySkin();
		x = footX - width * 0.5;
		y = footY - FEET * sizeScale;
	}

	public var blockMovement:Bool = false;
	public var isDead:Bool = false;
	public var floating:Bool = false;
	public var dashTimer:Float = 0;
	public var baseOffsetY(default, null):Float = 0;

	private var data:PlayerData;
	private var initialSpeed:Float = 0;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		data = PlayerDataRegistry.get();
		applySkin();
		initialSpeed = data.rampStart;
		drag.x = drag.y = data.drag;
	}

	public var hue(default, null):Float = 0;

	public function setHue(h:Float):Void
	{
		if (h == hue)
			return;
		hue = h;
		applySkin();
	}

	public function applySkin():Void
	{
		var wasAnim = animation.name;
		var wasFlip = flipX;

		frames = util.HuePalette.sparrow("characters/mufu", hue);
		animation.addByPrefix("idle", "Idle", 12, true);
		animation.addByPrefix("walk", "Run", 12, true);
		animation.addByPrefix("hurt", "Hurt", 12, false);
		animation.addByPrefix("death", "Death", 12, false);
		offset.set(-19, -17);

		if (graphic != null)
			graphic.persist = true;

		antialiasing = false;
		width = 75 * sizeScale;
		height = 95 * sizeScale;
		scale.set(4 * sizeScale, 4 * sizeScale);
		if (sizeScale != 1)
			offset.set(sizeScale * offset.x + frameWidth * 0.5 * (1 - sizeScale),
				sizeScale * offset.y + frameHeight * 0.5 * (1 - sizeScale));
		baseOffsetY = offset.y;
		flipX = wasFlip;
		animation.play(wasAnim == null ? "idle" : wasAnim, true);
	}

	public var shadowScaleX(get, never):Float;

	function get_shadowScaleX():Float
		return 4 * sizeScale;

	public var shadowScaleY(get, never):Float;

	function get_shadowScaleY():Float
		return 4 * sizeScale;

	public var shadowCenterX(get, never):Float;

	function get_shadowCenterX():Float
		return x + 36 * sizeScale;

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
		velocity.set(dx * data.dashSpeed, dy * data.dashSpeed);
		if (dx > 0) flipX = false;
		else if (dx < 0) flipX = true;
		this.animation.play(floating ? "idle" : "walk");
		dashTimer = data.dashTime;
	}

	override function update(elapsed:Float)
	{
		if (dashTimer > 0)
			dashTimer -= elapsed;
		else if (!blockMovement && !isDead)
			movement(elapsed);

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

			if(initialSpeed < data.moveSpeed)
			{
				initialSpeed += data.rampRate * elapsed;
			}

			if(initialSpeed >= data.moveSpeed)
			{
				initialSpeed = data.moveSpeed;
			}

			this.animation.play(floating ? "idle" : "walk");

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

			initialSpeed = data.rampReset;
		}
	}
}
