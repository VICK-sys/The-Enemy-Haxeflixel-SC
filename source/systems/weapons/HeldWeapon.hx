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
	static inline var GIGA_TIME:Float = 0.32;
	static inline var GIGA_SCALE:Float = 4.5;
	static inline var WINDUP_ARC:Float = 115;
	static inline var IMPACT_AT:Float = 0.10;
	static inline var BASH_TIME:Float = 0.3;
	static inline var THRUST_DIST:Float = 34;
	static inline var THRUST_OUT:Float = 0.35;
	static inline var SWING_SCALE:Float = 2.5;
	static inline var REV_FRAMES:Int = 11;
	static inline var REV_CELL:Int = 32;
	static inline var XBOW_CELL_W:Int = 39;
	static inline var XBOW_CELL_H:Int = 32;
	static inline var XBOW_SHOOT_FRAMES:Int = 5;
	static inline var XBOW_RELOAD_START:Int = 11;
	static inline var XBOW_RELOAD_FRAMES:Int = 11;
	static inline var XBOW_SHOOT_CUT:Float = 0.2;
	static inline var REV_KICK:Float = 16;
	static inline var REV_BACK:Float = 11;
	static inline var REV_TIME:Float = 0.4;
	static inline var BOW_KICK:Float = 29;
	static inline var BOW_BACK:Float = 26;
	static inline var BOW_RECOIL_TIME:Float = 0.56;
	static inline var FLASH_TIME:Float = 0.16;
	static inline var BOW_RECOIL_FLOOR:Float = 0.4;
	static inline var SHAKE_TILT:Float = 2.5;
	static inline var SHAKE_FLIP:Float = 0.04;
	static inline var GRIP_DIST:Float = 36;
	static inline var MUZZLE:Float = 70;
	static inline var PROBE_STEP:Float = 6;
	static inline var AIM_LERP:Float = 0.25;
	static inline var FLIP_MARGIN:Float = 12;
	static inline var SHOOT_TIME:Float = 0.12;
	static inline var FAN_TIME:Float = 0.3;
	static inline var BOW_TIME:Float = 0.3;
	static inline var BOW_DIST:Float = 55;
	static inline var RAIN_TIME:Float = 0.6;
	static inline var RAIN_RAISE:Float = 35;
	static inline var HOOK_TIME:Float = 0.4;
	public static inline var HAND_DX:Float = 10;
	public static inline var HAND_DY:Float = 1;

	public static inline var HAMMER:Int = 0;
	public static inline var REVOLVER:Int = 1;
	public static inline var BOW:Int = 2;
	public static inline var HOOK:Int = 3;

	public var sprite:FlxSprite;
	public var kind:Int = HAMMER;
	public var charge:Float = 0;
	public var glow:Float = 0;
	public var windup:Float = 0;
	public var swinging(get, never):Bool;

	private var player:Player;
	public var attack(default, null):WeaponMode = Swing;
	private var swingTimer:Float = 0;
	private var swingBaseAngle:Float = 0;
	private var swingDir:Int = 1;
	private var activeSwingTime:Float = SWING_TIME;
	private var swingSweep:Bool = true;
	private var aimLocked:Bool = false;
	private var lockAngle:Float = 0;
	private var recoilBack:Float = 0;
	private var recoilTilt:Float = 0;
	private var tiltShown:Float = 0;
	private var boltTimer:Float = 0;
	private var boltSpan:Float = BOW_RECOIL_TIME;
	private var boltPower:Float = 1;
	private var kickAmp:Float = BOW_KICK;
	private var backAmp:Float = BOW_BACK;
	private var flashTime:Float = 0;
	private var shakeClock:Float = 0;
	private var shakeSign:Int = 1;
	private var reloadP:Float = -1;
	private var reloadGfx:Bool = false;

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
		glow = 0;
		windup = 0;
		swingTimer = 0;
		recoilBack = 0;
		recoilTilt = 0;
		tiltShown = 0;
		boltTimer = 0;
		flashTime = 0;
		shakeClock = 0;
		shakeSign = 1;
		reloadP = -1;
		reloadGfx = false;
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
		if (boltTimer > 0)
		{
			boltTimer -= elapsed;
			var t:Float = 1 - boltTimer / boltSpan;
			if (t > 1)
				t = 1;
			var p:Float = BOW_RECOIL_FLOOR + (1 - BOW_RECOIL_FLOOR) * boltPower;
			recoilTilt = kickAmp * p * (1 - FlxEase.backInOut(t));
			recoilBack = backAmp * p * (1 - FlxEase.quadOut(t));
		}
		else
		{
			var decay:Float = Math.pow(1 - AIM_LERP, elapsed * 60);
			recoilBack *= decay;
			recoilTilt *= decay;
		}

		if (charge > 0)
		{
			shakeClock += elapsed;
			while (shakeClock >= SHAKE_FLIP)
			{
				shakeClock -= SHAKE_FLIP;
				shakeSign = -shakeSign;
			}
		}

		updateReload();
		anchor();
		updateSwing(elapsed);
	}

	public function reloadPose(p:Float):Void
	{
		if (kind == REVOLVER || kind == BOW)
			reloadP = p;
	}

	public static function bowFrame(p:Float):Int
	{
		if (p < XBOW_SHOOT_CUT)
		{
			var idx = Std.int(p / XBOW_SHOOT_CUT * XBOW_SHOOT_FRAMES);
			return idx > XBOW_SHOOT_FRAMES - 1 ? XBOW_SHOOT_FRAMES - 1 : idx;
		}
		var idx = Std.int((p - XBOW_SHOOT_CUT) / (1 - XBOW_SHOOT_CUT) * XBOW_RELOAD_FRAMES);
		if (idx > XBOW_RELOAD_FRAMES - 1)
			idx = XBOW_RELOAD_FRAMES - 1;
		return XBOW_RELOAD_START + idx;
	}

	function updateReload():Void
	{
		if (kind == BOW)
		{
			sprite.animation.frameIndex = reloadP >= 0 ? bowFrame(reloadP) : 0;
			reloadP = -1;
			return;
		}

		if (reloadP >= 0)
		{
			if (!reloadGfx)
			{
				reloadGfx = true;
				applyGraphic();
			}
			var idx = Std.int(reloadP * REV_FRAMES);
			if (idx > REV_FRAMES - 1)
				idx = REV_FRAMES - 1;
			sprite.animation.frameIndex = idx;
			reloadP = -1;
			return;
		}

		if (reloadGfx)
		{
			reloadGfx = false;
			applyGraphic();
		}
	}

	public function loose(power:Float):Void
	{
		if (kind != BOW)
			return;

		boltPower = power;
		kickAmp = BOW_KICK;
		backAmp = BOW_BACK;
		boltSpan = BOW_RECOIL_TIME * util.Levels.actionScale();
		boltTimer = boltSpan;
	}

	public function kick():Void
	{
		if (kind != REVOLVER)
			return;

		boltPower = 1;
		kickAmp = REV_KICK;
		backAmp = REV_BACK;
		boltSpan = REV_TIME * util.Levels.actionScale();
		boltTimer = boltSpan;
	}

	public function beginSwing(aimDeg:Float, mode:WeaponMode, rising:Bool = false):Void
	{
		attack = mode;
		swingSweep = !bowLike();
		if (swingSweep)
		{
			updateFlip(aimDeg);
			swingDir = (sprite.flipX ? -1 : 1) * (rising ? -1 : 1);
			swingBaseAngle = sprite.flipX ? aimDeg - 180 : aimDeg;
		}
		activeSwingTime = switch (mode)
		{
			case Shoot: SHOOT_TIME;
			case BigShot: FAN_TIME;
			case Bow: BOW_TIME;
			case Rain: RAIN_TIME;
			case Hook: HOOK_TIME;
			case Bash: BASH_TIME;
			case Giga: GIGA_TIME;
			default: SWING_TIME;
		};
		activeSwingTime *= util.Levels.actionScale();
		swingTimer = activeSwingTime;
	}

	public function impactPose():Void
	{
		if (swingTimer <= 0 || !swingSweep)
			return;
		var at = activeSwingTime * (1 - IMPACT_AT);
		if (swingTimer > at)
			swingTimer = at;
	}

	function bowLike():Bool
		return kind == BOW || kind == REVOLVER;

	function raining():Bool
		return attack == Rain && swingTimer > 0;

	function clearReach(hx:Float, hy:Float, ux:Float, uy:Float, want:Float):Float
	{
		if (systems.world.PropBlock.solids == null)
			return want;

		var limit = want + MUZZLE;
		var d = PROBE_STEP;
		while (d <= limit)
		{
			if (systems.world.PropBlock.at(hx + ux * d, hy + uy * d))
			{
				limit = d - PROBE_STEP;
				break;
			}
			d += PROBE_STEP;
		}

		var r = limit - MUZZLE;
		if (r >= want)
			return want;
		return r < 0 ? 0 : r;
	}

	function thrustReach():Float
	{
		if (attack != Bash || swingTimer <= 0 || activeSwingTime <= 0)
			return 0;

		var t:Float = 1 - swingTimer / activeSwingTime;
		if (t < 0)
			t = 0;
		if (t > 1)
			t = 1;

		var out:Float = t < THRUST_OUT ? FlxEase.quadOut(t / THRUST_OUT) : 1 - FlxEase.quadIn((t - THRUST_OUT) / (1 - THRUST_OUT));
		return THRUST_DIST * out;
	}

	public function repaint():Void
		applyGraphic();

	function applyGraphic():Void
	{
		if (kind == REVOLVER && reloadGfx)
			sprite.loadGraphic(util.HuePalette.graphic("items/revolver_reload", util.SaveData.playerHue()), true, REV_CELL, REV_CELL);
		else if (kind == BOW)
			sprite.loadGraphic(util.HuePalette.graphic("items/crossbow_reload", util.SaveData.playerHue()), true, XBOW_CELL_W, XBOW_CELL_H);
		else
		{
			var img = switch (kind)
			{
				case REVOLVER: "items/revolver";
				case HOOK: "items/yoyo";
				default: "items/hammer";
			};
			sprite.loadGraphic(util.HuePalette.graphic(img, util.SaveData.playerHue()));
		}
		if (bowLike())
			sprite.origin.set(sprite.width * 0.5, sprite.height * 0.5);
		else
			sprite.origin.set(sprite.width * 0.5, sprite.height);
	}

	public function anchor():Void
	{
		sprite.x = player.x - sprite.origin.x + HAND_DX;
		sprite.y = player.y - sprite.origin.y + HAND_DY;
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
				dx = util.Controls.aimX() - pmx;
				dy = util.Controls.aimY() - pmy;
				len = Math.sqrt(dx * dx + dy * dy);
			}
			if (len > 0.001)
			{
				var reach = BOW_DIST - recoilBack + thrustReach();
				reach = clearReach(sprite.x + sprite.origin.x, sprite.y + sprite.origin.y, dx / len, dy / len, reach);
				sprite.x += dx / len * reach;
				sprite.y += dy / len * reach;

				var vis:Float = sprite.flipY ? recoilTilt : -recoilTilt;
				if (charge > 0)
					vis += shakeSign * SHAKE_TILT * charge;
				var rad = vis * Math.PI / 180;
				sprite.x += -dy / len * rad * GRIP_DIST;
				sprite.y += dx / len * rad * GRIP_DIST;
			}
		}
	}

	function updateSwing(elapsed:Float):Void
	{
		sprite.angle -= tiltShown;

		if (swingTimer > 0)
		{
			swingTimer -= elapsed;
			var t:Float = 1 - swingTimer / activeSwingTime;
			if (t > 1)
				t = 1;
			if (swingSweep)
			{
				sprite.angle = swingBaseAngle + swingDir * SWING_ARC * (FlxEase.quintOut(t) - 0.5);
				var s:Float = BASE_SCALE + (attack == Giga ? GIGA_SCALE : SWING_SCALE) * Math.sin(Math.PI * t);
				sprite.scale.set(s, s);
			}
			else
			{
				sprite.scale.set(BASE_SCALE, BASE_SCALE);
				trackCursor(util.Controls.aimX(), util.Controls.aimY(), elapsed);
			}
		}
		else
		{
			sprite.scale.set(BASE_SCALE, BASE_SCALE);
			trackCursor(util.Controls.aimX(), util.Controls.aimY(), elapsed);
		}

		tiltShown = sprite.flipY ? recoilTilt : -recoilTilt;
		if (charge > 0)
			tiltShown += shakeSign * SHAKE_TILT * charge;
		sprite.angle += tiltShown;

		applyTint(elapsed);
	}

	public function flash():Void
		flashTime = FLASH_TIME;

	function applyTint(elapsed:Float):Void
	{
		if (flashTime > 0)
			flashTime -= elapsed;

		var lit:Float = flashTime > 0 ? flashTime / FLASH_TIME : 0;
		if (glow > lit)
			lit = glow;
		var keep:Float = 1 - lit;
		var add:Float = 255 * lit;
		sprite.setColorTransform(keep, keep, keep, sprite.alpha, add, add, add, 0);
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
			target -= (sprite.flipX ? -1 : 1) * WINDUP_ARC * windup;
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
