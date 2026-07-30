package util;

import flixel.FlxG;
import flixel.util.FlxSave;

class SaveData
{
	static var save:FlxSave;

	static function ensure():Void
	{
		if (save == null)
		{
			save = new FlxSave();
			save.bind("TheEnemy");
		}
	}

	public static function bestWave():Int
	{
		ensure();
		return save.data.bestWave != null ? save.data.bestWave : 0;
	}

	public static function submitWave(wave:Int):Void
	{
		ensure();
		if (save.data.bestWave == null || wave > save.data.bestWave)
		{
			save.data.bestWave = wave;
			save.flush();
		}
	}

	public static function resetBest():Void
	{
		ensure();
		save.data.bestWave = 0;
		save.flush();
	}

	public static function volume():Float
	{
		ensure();
		return save.data.volume != null ? save.data.volume : 1.0;
	}

	public static function setVolume(v:Float):Void
	{
		ensure();
		if (v < 0)
			v = 0;
		if (v > 1)
			v = 1;
		save.data.volume = Math.round(v * 10) / 10;
		save.flush();
	}

	public static function displayMode():String
	{
		ensure();
		if (save.data.display != null)
			return save.data.display;
		return save.data.fullscreen == true ? "fullscreen" : "windowed";
	}

	public static function setDisplayMode(m:String):Void
	{
		ensure();
		save.data.display = m;
		save.flush();
	}

	public static function vsync():Bool
	{
		ensure();
		return save.data.vsync != null ? save.data.vsync : false;
	}

	public static function setVsync(b:Bool):Void
	{
		ensure();
		save.data.vsync = b;
		save.flush();
	}

	public static function framerate():Int
	{
		ensure();
		return save.data.framerate != null ? save.data.framerate : 120;
	}

	public static function setFramerate(f:Int):Void
	{
		ensure();
		save.data.framerate = f;
		save.flush();
	}

	public static var WINDOW_STEPS:Array<Int> = [50, 65, 80, 100];

	public static function windowFill():Int
	{
		ensure();
		var v:Int = save.data.windowFill != null ? save.data.windowFill : WINDOW_STEPS[0];
		return WINDOW_STEPS.indexOf(v) >= 0 ? v : WINDOW_STEPS[0];
	}

	public static function setWindowFill(pct:Int):Void
	{
		ensure();
		save.data.windowFill = pct;
		save.flush();
	}

	public static function windowSize():Array<Int>
	{
		var limit = displayBounds();
		if (limit == null)
			return [1280, 720];
		var pct = windowFill() / 100.0;
		var w = limit[0] * pct;
		var h = limit[1] * pct;
		var side = w / h > 16 / 9 ? h * 16 / 9 : w;
		return [Std.int(side), Std.int(side * 9 / 16)];
	}

	static function displayBounds():Array<Int>
	{
		#if desktop
		var d = lime.app.Application.current.window.display;
		if (d != null)
			return [Std.int(d.bounds.width), Std.int(d.bounds.height)];
		#end
		return null;
	}

	public static function aspect():String
	{
		ensure();
		return save.data.aspect != null ? save.data.aspect : "auto";
	}

	public static function setAspect(a:String):Void
	{
		ensure();
		save.data.aspect = a;
		save.flush();
	}

	public static function shakeAmount():Float
	{
		ensure();
		return save.data.shakeAmount != null ? save.data.shakeAmount : 1.0;
	}

	public static function setShakeAmount(v:Float):Void
	{
		ensure();
		save.data.shakeAmount = clampTenth(v);
		save.flush();
	}

	public static function freezeAmount():Float
	{
		ensure();
		return save.data.freezeAmount != null ? save.data.freezeAmount : 1.0;
	}

	public static function setFreezeAmount(v:Float):Void
	{
		ensure();
		save.data.freezeAmount = clampTenth(v);
		save.flush();
	}

	public static function cameraLean():Float
	{
		ensure();
		return save.data.cameraLean != null ? save.data.cameraLean : 0.5;
	}

	public static function setCameraLean(v:Float):Void
	{
		ensure();
		save.data.cameraLean = clampTenth(v);
		save.flush();
	}

	public static inline var VOICE_MIN:Float = 0.6;
	public static inline var VOICE_MAX:Float = 1.25;

	public static function voicePitch():Float
	{
		ensure();
		return save.data.voicePitch != null ? save.data.voicePitch : 1;
	}

	public static function setVoicePitch(v:Float):Void
	{
		ensure();
		if (v < VOICE_MIN)
			v = VOICE_MIN;
		if (v > VOICE_MAX)
			v = VOICE_MAX;
		save.data.voicePitch = Math.round(v * 20) / 20;
		save.flush();
	}

	public static function showHud():Bool
	{
		ensure();
		return save.data.showHud != null ? save.data.showHud : true;
	}

	public static function setShowHud(b:Bool):Void
	{
		ensure();
		save.data.showHud = b;
		save.flush();
	}

	public static function sound3d():Bool
	{
		ensure();
		return save.data.sound3d != null ? save.data.sound3d : true;
	}

	public static function setSound3d(b:Bool):Void
	{
		ensure();
		save.data.sound3d = b;
		save.flush();
	}

	static function clampTenth(v:Float):Float
	{
		if (v < 0)
			v = 0;
		if (v > 1)
			v = 1;
		return Math.round(v * 10) / 10;
	}

	public static function showFps():Bool
	{
		ensure();
		return save.data.showFps != null ? save.data.showFps : true;
	}

	public static function setShowFps(b:Bool):Void
	{
		ensure();
		save.data.showFps = b;
		save.flush();
	}

	public static function language():String
	{
		ensure();
		return save.data.language != null ? save.data.language : "en";
	}

	public static function setLanguage(c:String):Void
	{
		ensure();
		save.data.language = c;
		save.flush();
	}

	public static function playerHue():Float
	{
		ensure();
		return save.data.playerHue != null ? save.data.playerHue : 0.0;
	}

	public static function setPlayerHue(h:Float, store:Bool = true):Void
	{
		ensure();
		var deg = Math.round(h * 360) % 360;
		if (deg < 0)
			deg += 360;
		save.data.playerHue = deg / 360.0;
		if (store)
			save.flush();
	}

	public static function commit():Void
	{
		ensure();
		save.flush();
	}

	public static function playerName():String
	{
		ensure();
		return save.data.playerName != null ? save.data.playerName : "";
	}

	public static function setPlayerName(n:String):Void
	{
		ensure();
		save.data.playerName = n;
		save.flush();
	}

	public static function lastIp():String
	{
		ensure();
		return save.data.lastIp != null ? save.data.lastIp : "";
	}

	public static function setLastIp(ip:String):Void
	{
		ensure();
		save.data.lastIp = ip;
		save.flush();
	}

	public static function runValue():Int
	{
		ensure();
		return save.data.runValue != null ? save.data.runValue : 0;
	}

	public static function setRunValue(v:Int):Void
	{
		ensure();
		save.data.runValue = v;
		save.flush();
	}

	public static function controls():{keys:Array<Int>, pad:Array<Int>}
	{
		ensure();
		if (save.data.ctrlKeys == null)
			return null;
		return {keys: save.data.ctrlKeys, pad: save.data.ctrlPads};
	}

	public static function setControls(keys:Array<Int>, pad:Array<Int>):Void
	{
		ensure();
		save.data.ctrlKeys = keys.copy();
		save.data.ctrlPads = pad.copy();
		save.flush();
	}

	public static function applySettings():Void
	{
		FlxG.sound.volume = volume();
		applyDisplay();
		applyFramerate();
		systems.Fx.shakeScale = shakeAmount();
		systems.Fx.freezeScale = freezeAmount();
		states.PlayState.cursorLean = cameraLean();
		Sfx.positional = sound3d();
		AspectBars.apply();
		if (Main.counter != null)
			Main.counter.visible = showFps();
	}

	static inline var BORDERLESS_BLEED:Int = 1;

	static function applyDisplay():Void
	{
		#if desktop
		var win = lime.app.Application.current.window;
		switch (displayMode())
		{
			case "fullscreen":
				win.borderless = false;
				win.fullscreen = true;
			case "borderless":
				win.fullscreen = false;
				win.borderless = true;
				var d = win.display;
				if (d != null)
				{
					win.move(Std.int(d.bounds.x), Std.int(d.bounds.y));
					win.resize(Std.int(d.bounds.width), Std.int(d.bounds.height) + BORDERLESS_BLEED);
				}
			default:
				win.fullscreen = false;
				win.borderless = false;
				var size = windowSize();
				var d = win.display;
				if (d != null && (win.width != size[0] || win.height != size[1]))
				{
					win.resize(size[0], size[1]);
					win.move(Std.int(d.bounds.x + (d.bounds.width - size[0]) / 2), Std.int(d.bounds.y + (d.bounds.height - size[1]) / 2));
				}
		}
		#else
		FlxG.fullscreen = displayMode() == "fullscreen";
		#end
	}

	static function applyFramerate():Void
	{
		var fps = framerate();
		if (vsync())
			fps = displayHz();
		if (fps > FlxG.updateFramerate)
		{
			FlxG.updateFramerate = fps;
			FlxG.drawFramerate = fps;
		}
		else
		{
			FlxG.drawFramerate = fps;
			FlxG.updateFramerate = fps;
		}
	}

	public static function displayHz():Int
	{
		#if desktop
		var win = lime.app.Application.current.window;
		var d = win.display;
		if (d != null && d.currentMode != null && d.currentMode.refreshRate > 0)
			return d.currentMode.refreshRate;
		#end
		return 60;
	}
}
