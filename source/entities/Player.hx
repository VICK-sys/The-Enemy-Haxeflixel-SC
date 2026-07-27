package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import util.Paths;
import util.SideView;
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
		applySkin(SideView.active);
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
	private var prevBottom:Float = 0;
	private var jumpsLeft:Int = 2;
	private var frameCentre:Array<Float> = [];
	private var measuredSheet:String = null;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		data = PlayerDataRegistry.get();
		applySkin(false);
		initialSpeed = data.rampStart;
		drag.x = drag.y = data.drag;
	}

	public function applySkin(side:Bool):Void
	{
		var wasAnim = animation.name;
		var wasFlip = flipX;

		if (side)
		{
			var skin = data.sideSkin;
			loadGraphic(Paths.image(skin.sheet), true, skin.frameW, skin.frameH);
			animation.add("idle", skin.idle, skin.idleFps, true);
			animation.add("walk", skin.walk, skin.walkFps, true);
			animation.add("jump", skin.jump, skin.jumpFps, true);
			animation.add("fall", skin.fall, skin.fallFps, true);
			animation.add("hurt", skin.hurt, skin.hurtFps, false);
			animation.add("death", skin.death, skin.deathFps, false);
			offset.set(skin.offsetX, skin.offsetY);
			measureFrames(skin.sheet, skin.frameW, skin.frameH);
		}
		else
		{
			frames = Paths.sparrow("characters/mufu");
			animation.addByPrefix("idle", "Idle", 12, true);
			animation.addByPrefix("walk", "Run", 12, true);
			animation.addByPrefix("hurt", "Hurt", 12, false);
			animation.addByPrefix("death", "Death", 12, false);
			offset.set(-19, -17);
			frameCentre = [];
		}

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

	function measureFrames(sheet:String, fw:Int, fh:Int):Void
	{
		if (measuredSheet == sheet)
			return;
		measuredSheet = sheet;
		frameCentre = [];

		var bmp = FlxG.bitmap.add(Paths.image(sheet)).bitmap;
		var cols = Std.int(bmp.width / fw);
		var rows = Std.int(bmp.height / fh);
		for (r in 0...rows)
			for (c in 0...cols)
			{
				var lo = fw;
				var hi = -1;
				for (px in 0...fw)
					for (py in 0...fh)
						if ((bmp.getPixel32(c * fw + px, r * fh + py) >>> 24) > 8)
						{
							if (px < lo)
								lo = px;
							hi = px;
							break;
						}
				frameCentre.push(hi < 0 ? fw * 0.5 : (lo + hi + 1) * 0.5);
			}
	}

	public var shadowScaleX(get, never):Float;

	function get_shadowScaleX():Float
		return (frameCentre.length > 0 ? data.sideSkin.shadowScaleX : 4) * sizeScale;

	public var shadowScaleY(get, never):Float;

	function get_shadowScaleY():Float
		return 4 * sizeScale;

	public var shadowCenterX(get, never):Float;

	function get_shadowCenterX():Float
	{
		if (frameCentre.length == 0)
			return x + 36 * sizeScale;

		var i = animation.frameIndex;
		var cp = i >= 0 && i < frameCentre.length ? frameCentre[i] : frameWidth * 0.5;
		if (flipX)
			cp = frameWidth - cp;
		return x - offset.x + origin.x * (1 - scale.x) + cp * scale.x;
	}

	public function setSideMode(on:Bool):Void
	{
		applySkin(on);

		if (on)
		{
			drag.y = 0;
			jumpsLeft = 2;
		}
		else
		{
			drag.x = drag.y = data.drag;
			velocity.y = 0;
		}
	}

	public function dash():Void
	{
		var dx:Float = 0;
		var dy:Float = 0;
		if (FlxG.keys.anyPressed([W])) dy -= 1;
		if (FlxG.keys.anyPressed([S])) dy += 1;
		if (FlxG.keys.anyPressed([A])) dx -= 1;
		if (FlxG.keys.anyPressed([D])) dx += 1;
		if (SideView.active)
			dy = 0;
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
		else if (SideView.active && !SideView.morphing)
			sideMovement(elapsed);
		else if (!blockMovement && !isDead)
			movement(elapsed);

		prevBottom = y + height;
		super.update(elapsed);
	}

	private function sideMovement(elapsed:Float)
	{
		var grounded = SideView.settle(this, prevBottom, elapsed);
		if (grounded)
			jumpsLeft = 2;

		if (!blockMovement && !isDead)
		{
			var left = FlxG.keys.anyPressed([A]);
			var right = FlxG.keys.anyPressed([D]);
			if (left && right)
				left = right = false;

			if (left || right)
			{
				if (initialSpeed < data.moveSpeed)
					initialSpeed += data.rampRate * elapsed;
				if (initialSpeed >= data.moveSpeed)
					initialSpeed = data.moveSpeed;
				velocity.x = left ? -initialSpeed : initialSpeed;
				flipX = left;
				if (grounded)
					this.animation.play("walk");
			}
			else
			{
				velocity.x = 0;
				initialSpeed = data.rampReset;
				if (grounded)
					this.animation.play("idle");
			}

			if (FlxG.keys.justPressed.W && jumpsLeft > 0)
			{
				velocity.y = -SideView.PLAYER_JUMP;
				jumpsLeft--;
				grounded = false;
			}
		}
		else if (grounded)
			velocity.x = 0;

		if (!grounded && !isDead)
			this.animation.play(velocity.y < 0 ? "jump" : "fall");

		if (x < 24)
			x = 24;
		if (x + width > FlxG.worldBounds.right - 24)
			x = FlxG.worldBounds.right - 24 - width;
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
