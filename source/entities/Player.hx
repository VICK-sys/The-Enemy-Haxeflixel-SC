package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import util.Paths;
import data.PlayerData;
import data.PlayerData.PlayerDataRegistry;

class Player extends FlxSprite
{
	public static inline var FEET:Float = 41;

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
	public var moveScale:Float = 1;
	public var animHold:Bool = false;
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

		frames = util.HuePalette.sparrow(util.Skins.sheet(), hue);
		animation.addByPrefix("idle", "Idle", 9, true);
		animation.addByPrefix("walk", "Run", 12, true);
		animation.addByPrefix("dash", "Dash", 12, false);
		animation.addByPrefix("dashBack", "Backdash", 12, false);
		animation.addByPrefix("hurt", "Hurt", 12, false);
		offset.set(2, 56);

		if (graphic != null)
			graphic.persist = true;

		antialiasing = false;
		width = 42 * sizeScale;
		height = 44 * sizeScale;
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
		return x + 16 * sizeScale;

	public function dash():Void
	{
		var dx:Float = 0;
		var dy:Float = 0;
		if (util.Controls.moveUp()) dy -= 1;
		if (util.Controls.moveDown()) dy += 1;
		if (util.Controls.moveLeft()) dx -= 1;
		if (util.Controls.moveRight()) dx += 1;
		if (dx == 0 && dy == 0)
			dx = flipX ? -1 : 1;
		var len:Float = Math.sqrt(dx * dx + dy * dy);
		dx /= len;
		dy /= len;
		velocity.set(dx * data.dashSpeed, dy * data.dashSpeed);
		this.animation.play(dashAnim(dx), true);
		dashTimer = data.dashTime;
	}

	public var hitRadius(get, never):Float;

	function get_hitRadius():Float
		return width * 0.5;

	public function touches(bx:Float, by:Float, bw:Float, bh:Float):Bool
	{
		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		var nx = cx < bx ? bx : (cx > bx + bw ? bx + bw : cx);
		var ny = cy < by ? by : (cy > by + bh ? by + bh : cy);
		var dx = cx - nx;
		var dy = cy - ny;
		var r = hitRadius;
		return dx * dx + dy * dy <= r * r;
	}

	public function touchesRound(bx:Float, by:Float, bw:Float, bh:Float):Bool
	{
		var dx = bx + bw * 0.5 - (x + width * 0.5);
		var dy = by + bh * 0.5 - (y + height * 0.5);
		var reach = hitRadius + (bw < bh ? bw : bh) * 0.5;
		return dx * dx + dy * dy <= reach * reach;
	}

	public function dashAnim(dx:Float):String
	{
		if (floating)
			return "idle";
		return dx * (flipX ? -1 : 1) < 0 ? "dashBack" : "dash";
	}

	override function update(elapsed:Float)
	{
		if (dashTimer > 0)
			dashTimer -= elapsed;
		else if (!blockMovement && (!isDead || net.Net.active))
			movement(elapsed);

		if (!isDead || net.Net.active)
			flipX = util.Controls.aimX() < x + width * 0.5;

		super.update(elapsed);
	}

	private function movement(elapsed:Float)
	{
		var up:Bool = false;
		var down:Bool = false;
		var left:Bool = false;
		var right:Bool = false;

		up = util.Controls.moveUp();
		down = util.Controls.moveDown();
		left = util.Controls.moveLeft();
		right = util.Controls.moveRight();

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

			if (!animHold)
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
			}
			else if (right)
			{
				newAngle = 0;
			}

			var speed = (util.Controls.walkHeld() ? initialSpeed * data.walkScale : initialSpeed) * moveScale;
			velocity.set(speed, 0);
			velocity.pivotDegrees(FlxPoint.weak(0, 0), newAngle);
		}
		else
		{
			if (!animHold)
				this.animation.play("idle");

			initialSpeed = data.rampReset;
		}
	}
}
