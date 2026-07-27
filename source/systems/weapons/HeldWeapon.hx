package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import entities.Player;
import util.Paths;

class HeldWeapon
{
	static inline var BASE_SCALE:Float = 4;
	static inline var SWING_TIME:Float = 0.2;
	static inline var SWING_ARC:Float = 300;
	static inline var SWING_SCALE:Float = 2.5;
	static inline var RECOIL_SCALE:Float = 0.8;
	static inline var AIM_LERP:Float = 0.25;
	static inline var FLIP_MARGIN:Float = 12;
	static inline var SHOOT_TIME:Float = 0.12;
	static inline var FAN_TIME:Float = 0.3;
	static inline var BOW_TIME:Float = 0.3;
	static inline var BOW_DIST:Float = 55;
	static inline var RAIN_TIME:Float = 0.6;
	static inline var RAIN_RAISE:Float = 35;
	static inline var HOOK_TIME:Float = 0.4;
	static inline var JAB_TIME:Float = 0.13;
	static inline var CHARGE_SCALE:Float = 1.6;
	static inline var CHARGE_DRAW:Float = 0.35;
	public static inline var CHARGE_TINT:Int = 0xFF9BE9FF;

	public static inline var HAMMER:Int = 0;
	public static inline var REVOLVER:Int = 1;
	public static inline var BOW:Int = 2;
	public static inline var HOOK:Int = 3;

	public var sprite:FlxSprite;
	public var kind:Int = HAMMER;
	public var charge:Float = 0;
	public var swinging(get, never):Bool;

	private var player:Player;
	private var attack:WeaponMode = Swing;
	private var swingTimer:Float = 0;
	private var swingBaseAngle:Float = 0;
	private var swingDir:Int = 1;
	private var activeSwingTime:Float = SWING_TIME;
	private var swingSweep:Bool = true;
	private var aimLocked:Bool = false;
	private var lockAngle:Float = 0;

	public function new(player:Player, sprite:FlxSprite)
	{
		this.player = player;
		this.sprite = sprite;
	}

	function get_swinging():Bool
		return swingTimer > 0;

	public function lockAim(deg:Float):Void
	{
		aimLocked = true;
		lockAngle = deg;
	}

	public function unlockAim():Void
		aimLocked = false;

	public function setKind(i:Int):Void
	{
		kind = i;
		aimLocked = false;
		attack = Swing;
		swingTimer = 0;
		sprite.flipX = false;
		sprite.flipY = false;
		applyGraphic();
	}

	public function handX():Float
		return sprite.x + sprite.origin.x;

	public function handY():Float
		return sprite.y + sprite.origin.y;

	public function update(elapsed:Float):Void
	{
		anchor();
		updateSwing(elapsed);
	}

	public function beginSwing(aimDeg:Float, mode:WeaponMode):Void
	{
		attack = mode;
		if (!bowLike())
		{
			updateFlip(aimDeg);
			swingDir = sprite.flipX ? -1 : 1;
			swingBaseAngle = sprite.flipX ? aimDeg - 180 : aimDeg;
		}
		swingSweep = !bowLike();
		activeSwingTime = switch (mode)
		{
			case Shoot: SHOOT_TIME;
			case Fan: FAN_TIME;
			case Bow: BOW_TIME;
			case Rain: RAIN_TIME;
			case Hook: HOOK_TIME;
			case Jab: JAB_TIME;
			default: SWING_TIME;
		};
		swingTimer = activeSwingTime;
	}

	function bowLike():Bool
		return kind == BOW || kind == REVOLVER;

	function raining():Bool
		return attack == Rain && swingTimer > 0;

	function applyGraphic():Void
	{
		var img = switch (kind)
		{
			case 1: "items/revolver";
			case 2: "items/crossbow";
			case 3: "items/hook";
			default: "items/hammer";
		};
		sprite.loadGraphic(Paths.image(img));
		if (bowLike())
			sprite.origin.set(sprite.width * 0.5, sprite.height * 0.5);
		else
			sprite.origin.set(sprite.width * 0.5, sprite.height);
	}

	public function anchor():Void
	{
		sprite.x = player.x - sprite.origin.x + 30;
		sprite.y = player.y - sprite.origin.y + 65;
		if (raining())
		{
			sprite.y = player.y - sprite.origin.y - RAIN_RAISE;
		}
		else if (bowLike())
		{
			var dx:Float;
			var dy:Float;
			var len:Float;
			if (aimLocked)
			{
				var rad = lockAngle * Math.PI / 180;
				dx = Math.cos(rad);
				dy = Math.sin(rad);
				len = 1;
			}
			else
			{
				var pmx:Float = player.x + player.width * 0.5;
				var pmy:Float = player.y + player.height * 0.5;
				dx = FlxG.mouse.x - pmx;
				dy = FlxG.mouse.y - pmy;
				len = Math.sqrt(dx * dx + dy * dy);
			}
			if (len > 0.001)
			{
				var reach = BOW_DIST * (1 - charge * CHARGE_DRAW);
				sprite.x += dx / len * reach;
				sprite.y += dy / len * reach;
			}
		}
	}

	function updateSwing(elapsed:Float):Void
	{
		if (swingTimer > 0)
		{
			swingTimer -= elapsed;
			var t:Float = 1 - swingTimer / activeSwingTime;
			if (t > 1)
				t = 1;
			if (swingSweep)
			{
				sprite.angle = swingBaseAngle + swingDir * SWING_ARC * (FlxEase.quintOut(t) - 0.5);
				var s:Float = BASE_SCALE + SWING_SCALE * Math.sin(Math.PI * t);
				sprite.scale.set(s, s);
			}
			else
			{
				var s:Float = BASE_SCALE + RECOIL_SCALE * Math.sin(Math.PI * t);
				sprite.scale.set(s, s);
				trackCursor(FlxG.mouse.x, FlxG.mouse.y, elapsed);
			}
		}
		else
		{
			var s:Float = BASE_SCALE + charge * CHARGE_SCALE;
			sprite.scale.set(s, s);
			trackCursor(FlxG.mouse.x, FlxG.mouse.y, elapsed);
		}

		sprite.color = charge > 0 ? FlxColor.interpolate(FlxColor.WHITE, CHARGE_TINT, charge) : FlxColor.WHITE;
	}

	function trackCursor(mouseX:Float, mouseY:Float, elapsed:Float):Void
	{
		if (aimLocked)
		{
			sprite.flipX = false;
			sprite.flipY = bowLike() && Math.abs(lockAngle) > 90;
			sprite.angle = lockAngle;
			return;
		}

		var pmx:Float = player.x + player.width * 0.5;
		var pmy:Float = player.y + player.height * 0.5;
		var theta:Float = Math.atan2(mouseY - pmy, mouseX - pmx) * 180 / Math.PI;
		var target:Float;
		if (raining())
		{
			sprite.flipX = false;
			sprite.flipY = false;
			target = -90;
		}
		else if (bowLike())
		{
			sprite.flipX = false;
			updateAimFlip(theta);
			target = theta;
		}
		else
		{
			sprite.flipY = false;
			updateFlip(theta);
			target = sprite.flipX ? theta - 180 : theta;
		}
		var delta:Float = ((target - sprite.angle) % 360 + 540) % 360 - 180;
		sprite.angle += delta * (1 - Math.pow(1 - AIM_LERP, elapsed * 60));
	}

	function updateAimFlip(deg:Float):Void
	{
		var want:Bool = sprite.flipY;
		var a:Float = Math.abs(deg);
		if (a > 90 + FLIP_MARGIN)
			want = true;
		else if (a < 90 - FLIP_MARGIN)
			want = false;
		sprite.flipY = want;
	}

	function updateFlip(deg:Float):Void
	{
		var wantFlip:Bool = sprite.flipX;
		var a:Float = Math.abs(deg);
		if (a > 90 + FLIP_MARGIN)
			wantFlip = true;
		else if (a < 90 - FLIP_MARGIN)
			wantFlip = false;
		if (wantFlip != sprite.flipX)
		{
			sprite.flipX = wantFlip;
			sprite.angle += 180;
		}
	}
}
