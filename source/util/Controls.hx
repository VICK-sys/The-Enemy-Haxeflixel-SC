package util;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class Controls
{
	public static inline var UP:Int = 0;
	public static inline var DOWN:Int = 1;
	public static inline var LEFT:Int = 2;
	public static inline var RIGHT:Int = 3;
	public static inline var DASH:Int = 4;
	public static inline var ATTACK:Int = 5;
	public static inline var SECOND:Int = 6;
	public static inline var SUPER:Int = 7;
	public static inline var RELOAD:Int = 8;
	public static inline var ACCEPT:Int = 9;
	public static inline var PAUSE:Int = 10;
	public static inline var COUNT:Int = 11;

	public static inline var MOUSE_LEFT:Int = -101;
	public static inline var MOUSE_RIGHT:Int = -102;
	public static inline var MOUSE_MIDDLE:Int = -103;

	static inline var STICK_MOVE:Float = 0.35;
	static inline var STICK_AIM:Float = 0.25;
	static inline var STICK_MENU:Float = 0.5;
	static inline var TRIGGER_ON:Float = 0.3;
	static inline var AIM_RADIUS:Float = 360;

	public static var padMode(default, null):Bool = false;

	static var inited:Bool = false;
	static var keys:Array<Int> = [];
	static var pads:Array<Int> = [];
	static var trigPrev:Array<Bool> = [false, false];
	static var trigNow:Array<Bool> = [false, false];
	static var menuXPrev:Int = 0;
	static var menuYPrev:Int = 0;
	static var menuXNow:Int = 0;
	static var menuYNow:Int = 0;
	static var aimDirX:Float = 1;
	static var aimDirY:Float = 0;
	static var anchorX:Float = 0;
	static var anchorY:Float = 0;
	static var lastMouseX:Float = 0;
	static var lastMouseY:Float = 0;
	static var gamePoint:flixel.math.FlxPoint = flixel.math.FlxPoint.get();

	public static function defaultKeys():Array<Int>
		return [FlxKey.W, FlxKey.S, FlxKey.A, FlxKey.D, FlxKey.SPACE, MOUSE_LEFT, MOUSE_RIGHT, FlxKey.Q, FlxKey.R, FlxKey.ENTER, FlxKey.ESCAPE];

	public static function defaultPads():Array<Int>
		return [
			FlxGamepadInputID.DPAD_UP, FlxGamepadInputID.DPAD_DOWN, FlxGamepadInputID.DPAD_LEFT, FlxGamepadInputID.DPAD_RIGHT,
			FlxGamepadInputID.A, FlxGamepadInputID.RIGHT_TRIGGER, FlxGamepadInputID.LEFT_TRIGGER, FlxGamepadInputID.Y,
			FlxGamepadInputID.X, FlxGamepadInputID.A, FlxGamepadInputID.START
		];

	public static function init():Void
	{
		if (inited)
			return;
		inited = true;
		var saved = SaveData.controls();
		keys = saved != null && saved.keys != null && saved.keys.length == COUNT ? saved.keys.copy() : defaultKeys();
		pads = saved != null && saved.pad != null && saved.pad.length == COUNT ? saved.pad.copy() : defaultPads();
		if (keys[ATTACK] == FlxKey.NONE)
			keys[ATTACK] = MOUSE_LEFT;
		if (keys[SECOND] == FlxKey.NONE)
			keys[SECOND] = MOUSE_RIGHT;
		FlxG.signals.preUpdate.add(tick);
	}

	public static function keyOf(action:Int):Int
		return keys[action];

	public static function padOf(action:Int):Int
		return pads[action];

	public static function bindKey(action:Int, key:Int):Void
	{
		for (i in 0...COUNT)
			if (i != action && keys[i] == key && key != FlxKey.NONE)
				keys[i] = keys[action];
		keys[action] = key;
		SaveData.setControls(keys, pads);
	}

	public static function bindPad(action:Int, id:Int):Void
	{
		for (i in 0...COUNT)
			if (i != action && pads[i] == id && id != FlxGamepadInputID.NONE && !(action == DASH && i == ACCEPT)
				&& !(action == ACCEPT && i == DASH))
				pads[i] = pads[action];
		pads[action] = id;
		SaveData.setControls(keys, pads);
	}

	public static function resetBinds():Void
	{
		keys = defaultKeys();
		pads = defaultPads();
		SaveData.setControls(keys, pads);
	}

	static function pad():FlxGamepad
		return FlxG.gamepads.firstActive;

	static function trigVal(p:FlxGamepad, id:Int):Float
		return id == FlxGamepadInputID.LEFT_TRIGGER ? p.analog.value.LEFT_TRIGGER : p.analog.value.RIGHT_TRIGGER;

	static function isTrigger(id:Int):Bool
		return id == FlxGamepadInputID.LEFT_TRIGGER || id == FlxGamepadInputID.RIGHT_TRIGGER;

	static function padPressed(id:Int):Bool
	{
		var p = pad();
		if (p == null || id == FlxGamepadInputID.NONE)
			return false;
		if (isTrigger(id))
			return trigVal(p, id) > TRIGGER_ON;
		return p.anyPressed([id]);
	}

	static function padJust(id:Int):Bool
	{
		var p = pad();
		if (p == null || id == FlxGamepadInputID.NONE)
			return false;
		if (isTrigger(id))
			return trigNow[id == FlxGamepadInputID.LEFT_TRIGGER ? 0 : 1]
				&& !trigPrev[id == FlxGamepadInputID.LEFT_TRIGGER ? 0 : 1];
		return p.anyJustPressed([id]);
	}

	static function isMouse(k:Int):Bool
		return k <= MOUSE_LEFT && k >= MOUSE_MIDDLE;

	static function keyPressed(k:Int):Bool
	{
		if (isMouse(k))
			return k == MOUSE_LEFT ? FlxG.mouse.pressed : (k == MOUSE_RIGHT ? FlxG.mouse.pressedRight : FlxG.mouse.pressedMiddle);
		return k != FlxKey.NONE && FlxG.keys.anyPressed([k]);
	}

	static function keyJust(k:Int):Bool
	{
		if (isMouse(k))
			return k == MOUSE_LEFT ? FlxG.mouse.justPressed : (k == MOUSE_RIGHT ? FlxG.mouse.justPressedRight : FlxG.mouse.justPressedMiddle);
		return k != FlxKey.NONE && FlxG.keys.anyJustPressed([k]);
	}

	public static function pressed(action:Int):Bool
		return keyPressed(keys[action]) || padPressed(pads[action]);

	public static function justPressed(action:Int):Bool
		return keyJust(keys[action]) || padJust(pads[action]);

	static function stickX():Float
	{
		var p = pad();
		return p == null ? 0 : p.analog.value.LEFT_STICK_X;
	}

	static function stickY():Float
	{
		var p = pad();
		return p == null ? 0 : p.analog.value.LEFT_STICK_Y;
	}

	public static function moveUp():Bool
		return pressed(UP) || stickY() < -STICK_MOVE;

	public static function moveDown():Bool
		return pressed(DOWN) || stickY() > STICK_MOVE;

	public static function moveLeft():Bool
		return pressed(LEFT) || stickX() < -STICK_MOVE;

	public static function moveRight():Bool
		return pressed(RIGHT) || stickX() > STICK_MOVE;

	public static function attackJustPressed():Bool
		return justPressed(ATTACK);

	public static function attackHeld():Bool
		return pressed(ATTACK);

	public static function secondJustPressed():Bool
		return justPressed(SECOND);

	public static function acceptJustPressed():Bool
		return justPressed(ACCEPT) || FlxG.keys.anyJustPressed([FlxKey.Z]);

	public static function setAimAnchor(x:Float, y:Float):Void
	{
		anchorX = x;
		anchorY = y;
	}

	public static function aimX():Float
		return padMode ? anchorX + aimDirX * AIM_RADIUS : FlxG.mouse.x;

	public static function aimY():Float
		return padMode ? anchorY + aimDirY * AIM_RADIUS : FlxG.mouse.y;

	public static function aimViewX(cam:flixel.FlxCamera):Float
		return (aimX() - cam.scroll.x - cam.viewMarginLeft) * cam.zoom;

	public static function aimViewY(cam:flixel.FlxCamera):Float
		return (aimY() - cam.scroll.y - cam.viewMarginTop) * cam.zoom;

	public static function menuUp():Bool
		return FlxG.keys.anyJustPressed([FlxKey.W, FlxKey.UP]) || padJust(FlxGamepadInputID.DPAD_UP) || menuYNow < 0 && menuYPrev >= 0;

	public static function menuDown():Bool
		return FlxG.keys.anyJustPressed([FlxKey.S, FlxKey.DOWN]) || padJust(FlxGamepadInputID.DPAD_DOWN) || menuYNow > 0 && menuYPrev <= 0;

	public static function menuLeftJust():Bool
		return FlxG.keys.anyJustPressed([FlxKey.A, FlxKey.LEFT]) || padJust(FlxGamepadInputID.DPAD_LEFT) || menuXNow < 0 && menuXPrev >= 0;

	public static function menuRightJust():Bool
		return FlxG.keys.anyJustPressed([FlxKey.D, FlxKey.RIGHT]) || padJust(FlxGamepadInputID.DPAD_RIGHT) || menuXNow > 0 && menuXPrev <= 0;

	public static function menuLeftHeld():Bool
		return FlxG.keys.anyPressed([FlxKey.A, FlxKey.LEFT]) || padPressed(FlxGamepadInputID.DPAD_LEFT) || menuXNow < 0;

	public static function menuRightHeld():Bool
		return FlxG.keys.anyPressed([FlxKey.D, FlxKey.RIGHT]) || padPressed(FlxGamepadInputID.DPAD_RIGHT) || menuXNow > 0;

	public static function menuAccept():Bool
		return FlxG.keys.anyJustPressed([FlxKey.ENTER, FlxKey.Z]) || padJust(FlxGamepadInputID.A);

	public static function menuBack():Bool
		return FlxG.keys.anyJustPressed([FlxKey.ESCAPE]) || padJust(FlxGamepadInputID.B);

	public static function pausePressed():Bool
		return justPressed(PAUSE) || padJust(FlxGamepadInputID.START);

	static function tick():Void
	{
		var p = pad();

		trigPrev[0] = trigNow[0];
		trigPrev[1] = trigNow[1];
		trigNow[0] = p != null && p.analog.value.LEFT_TRIGGER > TRIGGER_ON;
		trigNow[1] = p != null && p.analog.value.RIGHT_TRIGGER > TRIGGER_ON;

		menuXPrev = menuXNow;
		menuYPrev = menuYNow;
		menuXNow = stickX() > STICK_MENU ? 1 : (stickX() < -STICK_MENU ? -1 : 0);
		menuYNow = stickY() > STICK_MENU ? 1 : (stickY() < -STICK_MENU ? -1 : 0);

		if (p != null)
		{
			var rx = p.analog.value.RIGHT_STICK_X;
			var ry = p.analog.value.RIGHT_STICK_Y;
			var len = Math.sqrt(rx * rx + ry * ry);
			if (len > STICK_AIM)
			{
				aimDirX = rx / len;
				aimDirY = ry / len;
				padMode = true;
			}
			if (p.anyJustPressed([
				FlxGamepadInputID.A, FlxGamepadInputID.B, FlxGamepadInputID.X, FlxGamepadInputID.Y, FlxGamepadInputID.START,
				FlxGamepadInputID.DPAD_UP, FlxGamepadInputID.DPAD_DOWN, FlxGamepadInputID.DPAD_LEFT, FlxGamepadInputID.DPAD_RIGHT,
				FlxGamepadInputID.LEFT_SHOULDER, FlxGamepadInputID.RIGHT_SHOULDER
			]) || (trigNow[0] && !trigPrev[0]) || (trigNow[1] && !trigPrev[1]) || Math.abs(stickX()) > STICK_MOVE
				|| Math.abs(stickY()) > STICK_MOVE)
				padMode = true;
		}

		FlxG.mouse.getGamePosition(gamePoint);
		var mdx = gamePoint.x - lastMouseX;
		var mdy = gamePoint.y - lastMouseY;
		if (mdx * mdx + mdy * mdy > 9 || FlxG.mouse.justPressed || FlxG.mouse.justPressedRight)
			padMode = false;
		lastMouseX = gamePoint.x;
		lastMouseY = gamePoint.y;
	}

	public static function keyName(k:Int):String
	{
		if (k == MOUSE_LEFT)
			return "MOUSE 1";
		if (k == MOUSE_RIGHT)
			return "MOUSE 2";
		if (k == MOUSE_MIDDLE)
			return "MOUSE 3";
		return k == FlxKey.NONE ? "-" : (k : FlxKey).toString();
	}

	public static function padName(id:Int):String
		return id == FlxGamepadInputID.NONE ? "-" : (id : FlxGamepadInputID).toString();

	public static function capturedKey():Int
	{
		if (FlxG.mouse.justPressed)
			return MOUSE_LEFT;
		if (FlxG.mouse.justPressedRight)
			return MOUSE_RIGHT;
		if (FlxG.mouse.justPressedMiddle)
			return MOUSE_MIDDLE;
		var k = FlxG.keys.firstJustPressed();
		return k <= 0 ? FlxKey.NONE : k;
	}

	public static function capturedPad():Int
	{
		var p = pad();
		if (p == null)
			return FlxGamepadInputID.NONE;
		if (trigNow[0] && !trigPrev[0])
			return FlxGamepadInputID.LEFT_TRIGGER;
		if (trigNow[1] && !trigPrev[1])
			return FlxGamepadInputID.RIGHT_TRIGGER;
		var id = p.firstJustPressedID();
		if (id == FlxGamepadInputID.NONE || id == FlxGamepadInputID.LEFT_STICK_DIGITAL_UP
			|| id == FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN || id == FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT
			|| id == FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT || id == FlxGamepadInputID.RIGHT_STICK_DIGITAL_UP
			|| id == FlxGamepadInputID.RIGHT_STICK_DIGITAL_DOWN || id == FlxGamepadInputID.RIGHT_STICK_DIGITAL_LEFT
			|| id == FlxGamepadInputID.RIGHT_STICK_DIGITAL_RIGHT)
			return FlxGamepadInputID.NONE;
		return id;
	}
}
