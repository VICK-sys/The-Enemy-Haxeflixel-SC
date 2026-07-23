package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
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
	static inline var HAMMER_SWING_TIME:Float = 0.45;
	static inline var QUAKE_TIME:Float = 0.8;
	static inline var BOW_TIME:Float = 0.3;
	static inline var BOW_DIST:Float = 55;
	static inline var RAIN_TIME:Float = 0.6;
	static inline var RAIN_RAISE:Float = 35;
	static inline var HOOK_TIME:Float = 0.4;

	public var sprite:FlxSprite;
	public var mode:WeaponMode = Swing;
	public var swinging(get, never):Bool;

	private var player:Player;
	private var swingTimer:Float = 0;
	private var swingBaseAngle:Float = 0;
	private var swingDir:Int = 1;
	private var activeSwingTime:Float = SWING_TIME;
	private var swingSweep:Bool = true;

	public function new(player:Player, sprite:FlxSprite)
	{
		this.player = player;
		this.sprite = sprite;
	}

	function get_swinging():Bool
		return swingTimer > 0;

	public function setMode(m:WeaponMode):Void
	{
		mode = m;
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

	public function beginSwing(aimDeg:Float):Void
	{
		if (!bowLike())
		{
			updateFlip(aimDeg);
			swingDir = sprite.flipX ? -1 : 1;
			swingBaseAngle = sprite.flipX ? aimDeg - 180 : aimDeg;
		}
		swingSweep = !bowLike();
		activeSwingTime = switch (mode)
		{
			case Hammer: HAMMER_SWING_TIME;
			case Quake: QUAKE_TIME;
			case Bow: BOW_TIME;
			case Rain: RAIN_TIME;
			case Hook: HOOK_TIME;
			default: SWING_TIME;
		};
		swingTimer = activeSwingTime;
	}

	function bowLike():Bool
		return mode == Bow || mode == Rain;

	function applyGraphic():Void
	{
		var img = switch (mode)
		{
			case Hammer, Quake: "items/mufu_hammer";
			case Bow, Rain: "items/mufu_bow";
			case Hook, Whirl, Grapple: "items/mufu_hook";
			default: "items/mufu_scythe";
		};
		sprite.loadGraphic(Paths.image(img));
		if (bowLike())
			sprite.origin.set(sprite.width * 0.5, sprite.height * 0.5);
		else
			sprite.origin.set(sprite.width * 0.5, sprite.height);
	}

	function anchor():Void
	{
		sprite.x = player.x - sprite.origin.x + 30;
		sprite.y = player.y - sprite.origin.y + 65;
		if (mode == Bow)
		{
			var pmx:Float = player.x + player.width * 0.5;
			var pmy:Float = player.y + player.height * 0.5;
			var dx:Float = FlxG.mouse.x - pmx;
			var dy:Float = FlxG.mouse.y - pmy;
			var len:Float = Math.sqrt(dx * dx + dy * dy);
			if (len > 0.001)
			{
				sprite.x += dx / len * BOW_DIST;
				sprite.y += dy / len * BOW_DIST;
			}
		}
		else if (mode == Rain)
		{
			sprite.y = player.y - sprite.origin.y - RAIN_RAISE;
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
			sprite.scale.set(BASE_SCALE, BASE_SCALE);
			trackCursor(FlxG.mouse.x, FlxG.mouse.y, elapsed);
		}
	}

	function trackCursor(mouseX:Float, mouseY:Float, elapsed:Float):Void
	{
		var pmx:Float = player.x + player.width * 0.5;
		var pmy:Float = player.y + player.height * 0.5;
		var theta:Float = Math.atan2(mouseY - pmy, mouseX - pmx) * 180 / Math.PI;
		var target:Float;
		if (mode == Rain)
		{
			sprite.flipX = false;
			target = -90;
		}
		else if (mode == Bow)
		{
			sprite.flipX = false;
			target = theta;
		}
		else
		{
			updateFlip(theta);
			target = sprite.flipX ? theta - 180 : theta;
		}
		var delta:Float = ((target - sprite.angle) % 360 + 540) % 360 - 180;
		sprite.angle += delta * (1 - Math.pow(1 - AIM_LERP, elapsed * 60));
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
