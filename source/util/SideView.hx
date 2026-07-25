package util;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import data.SideViewData.SideViewDataRegistry;

class SideView
{
	public static inline var SHADOW_REACH:Float = 420;
	public static inline var SHADOW_SHRINK:Float = 0.45;
	public static inline var SHADOW_FADE:Float = 0.72;

	public static var GRAVITY:Float = 2400;
	public static var MAX_FALL:Float = 1600;
	public static var PLAYER_JUMP:Float = 1000;
	public static var ENEMY_JUMP:Float = 850;

	public static var active:Bool = false;
	public static var morphing:Bool = false;
	public static var groundY:Float = 0;
	public static var platforms:Array<FlxRect> = [];

	public static function reset():Void
	{
		var d = SideViewDataRegistry.get();
		GRAVITY = d.gravity;
		MAX_FALL = d.maxFall;
		PLAYER_JUMP = d.playerJump;
		ENEMY_JUMP = d.enemyJump;
		active = false;
		morphing = false;
		platforms = [];
	}

	public static function fall(vy:Float, elapsed:Float):Float
	{
		vy += GRAVITY * elapsed;
		return vy > MAX_FALL ? MAX_FALL : vy;
	}

	public static function settle(s:FlxSprite, prevBottom:Float, elapsed:Float):Bool
	{
		var bottom = s.y + s.height;
		var snap = landing(s.x, s.width, prevBottom, bottom, s.velocity.y >= 0);
		if (snap >= 0 && bottom >= snap)
		{
			s.y = snap - s.height;
			if (s.velocity.y > 0)
				s.velocity.y = 0;
			return s.velocity.y >= 0;
		}
		s.velocity.y = fall(s.velocity.y, elapsed);
		return false;
	}

	public static function surfaceBelow(left:Float, w:Float, feet:Float):Float
	{
		var best = groundY;
		for (p in platforms)
		{
			if (left + w <= p.x || p.x + p.width <= left)
				continue;
			if (p.y >= feet - 4 && p.y < best)
				best = p.y;
		}
		return best;
	}

	public static function placeShadow(shadow:FlxSprite, left:Float, w:Float, feet:Float, restY:Float, scaleX:Float, scaleY:Float):Void
	{
		if (!active)
		{
			shadow.y = restY;
			shadow.scale.set(scaleX, scaleY);
			shadow.alpha = 1;
			return;
		}

		var surface = surfaceBelow(left, w, feet);
		var air = (surface - feet) / SHADOW_REACH;
		if (air < 0)
			air = 0;
		if (air > 1)
			air = 1;

		shadow.y = restY + (surface - feet);
		shadow.scale.set(scaleX * (1 - SHADOW_SHRINK * air), scaleY * (1 - SHADOW_SHRINK * air));
		shadow.alpha = 1 - SHADOW_FADE * air;
	}

	public static function landing(left:Float, w:Float, prevBottom:Float, bottom:Float, falling:Bool):Float
	{
		if (bottom >= groundY)
			return groundY;
		if (!falling)
			return -1;
		for (p in platforms)
		{
			if (left + w <= p.x || p.x + p.width <= left)
				continue;
			if (prevBottom <= p.y + 4 && bottom >= p.y)
				return p.y;
		}
		return -1;
	}
}
