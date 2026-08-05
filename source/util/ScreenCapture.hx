package util;

import flixel.FlxG;
import haxe.io.Bytes;
import lime.graphics.RenderContext;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class ScreenCapture
{
	static inline var LATE:Int = -1000;

	public static var folder:String = defaultFolder();
	public static var onShot:String->Void;
	public static var onGrab:BitmapData->Void;

	static var pending:String = null;
	static var ready:Bool = false;

	public static function init():Void
	{
		if (ready)
			return;
		ready = true;
		FlxG.signals.postUpdate.add(watch);
		FlxG.stage.window.onRender.add(flush, false, LATE);
	}

	public static function capture(?path:String):String
	{
		if (path == null)
			path = generatePath();
		pending = path;
		return path;
	}

	static function watch():Void
	{
		if (FlxG.keys.justPressed.F12)
			ShotCard.request();
	}

	static function flush(_:RenderContext):Void
	{
		if (pending == null)
			return;
		var path = pending;
		pending = null;
		perform(path);
	}

	static function perform(path:String):Void
	{
		var view = viewport();
		var w = Std.int(view.width);
		var h = Std.int(view.height);
		if (w <= 0 || h <= 0)
			return;

		var image = FlxG.stage.window.readPixels(new lime.math.Rectangle(view.x, view.y, w, h));
		if (image == null)
			return;

		if (onGrab != null)
		{
			var shot = BitmapData.fromImage(image);
			if (shot != null)
			{
				onGrab(shot);
				shot.dispose();
			}
		}

		#if sys
		save(path, image.data, w, h, image.buffer.format);
		#end
	}

	#if sys
	static function save(path:String, rgba:lime.utils.UInt8Array, w:Int, h:Int,
			format:lime.graphics.PixelFormat):Void
	{
		var rOff = 0;
		var gOff = 1;
		var bOff = 2;
		switch (format)
		{
			case BGRA32:
				rOff = 2;
				bOff = 0;
			case ARGB32:
				rOff = 1;
				gOff = 2;
				bOff = 3;
			default:
		}
		sys.thread.Thread.create(function()
		{
			try
			{
				var dir = haxe.io.Path.directory(path);
				if (dir != null && dir != "" && !FileSystem.exists(dir))
					FileSystem.createDirectory(dir);
				File.saveBytes(path, PngWriter.encode(rgba, w, h, rOff, gOff, bOff));
				trace("[Screenshot] Saved: " + path + " (" + w + "x" + h + ")");
				if (onShot != null)
					onShot(path);
			}
			catch (e:Dynamic)
			{
				trace("[Screenshot] Failed: " + Std.string(e));
			}
		});
	}
	#end

	public static inline function viewRect():Rectangle
		return viewport();

	static function viewport():Rectangle
	{
		var w:Float = FlxG.stage.stageWidth;
		var h:Float = FlxG.stage.stageHeight;
		var x:Float = 0;
		var y:Float = 0;
		var m = FlxG.scaleMode;
		if (m != null && m.gameSize.x > 0 && m.gameSize.y > 0)
		{
			x = m.offset.x;
			y = m.offset.y;
			w = m.gameSize.x;
			h = m.gameSize.y;
		}
		return new Rectangle(x, y, w, h);
	}

	static function generatePath():String
	{
		return haxe.io.Path.join([folder, "screenshot_" + stamp() + ".png"]);
	}

	static function stamp():String
	{
		var now = Date.now();
		var ms = Std.int(haxe.Timer.stamp() * 1000) % 1000;
		return pad(now.getFullYear(), 4) + pad(now.getMonth() + 1, 2) + pad(now.getDate(), 2)
			+ "_" + pad(now.getHours(), 2) + pad(now.getMinutes(), 2) + pad(now.getSeconds(), 2)
			+ "_" + pad(ms, 3);
	}

	static inline function pad(v:Int, len:Int):String
		return StringTools.lpad(Std.string(v), "0", len);

	static function defaultFolder():String
	{
		#if sys
		var base = haxe.io.Path.directory(Sys.programPath());
		if (base != null && base != "")
			return haxe.io.Path.join([base, "Screenshots"]);
		#end
		return "Screenshots";
	}
}
