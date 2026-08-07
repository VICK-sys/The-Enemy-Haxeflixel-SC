package util;

import haxe.Json;
#if sys
import sys.FileSystem;
import sys.io.File;
#else
import flixel.util.FlxSave;
#end

typedef StoredMap =
{
	sx:Float,
	sy:Float,
	csv:String,
	?props:Array<data.PropData.PropPlace>,
	?tileset:String,
	?tiles:String,
	?tileW:Int,
	?shopX:Float,
	?shopY:Float
}

class MapStore
{
	public static inline var SLOTS:Int = 5;

	#if sys
	static inline var FOLDER:String = "maps";

	static var cachedDir:String;
	static var carried:Bool = false;

	static function dir():String
	{
		if (cachedDir != null)
			return cachedDir;
		var root = lime.system.System.applicationStorageDirectory;
		if (root == null || root == "")
			root = haxe.io.Path.directory(Sys.programPath());
		cachedDir = haxe.io.Path.join([root, FOLDER]);
		carryOver();
		return cachedDir;
	}

	static function besideExe():String
		return haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), FOLDER]);

	static function carryOver():Void
	{
		if (carried)
			return;
		carried = true;

		var from = besideExe();
		if (from == cachedDir || !FileSystem.exists(from))
			return;

		try
		{
			if (!FileSystem.exists(cachedDir))
				FileSystem.createDirectory(cachedDir);
			for (slot in 1...SLOTS + 1)
			{
				var name = "slot" + slot + ".json";
				var old = haxe.io.Path.join([from, name]);
				var moved = haxe.io.Path.join([cachedDir, name]);
				if (FileSystem.exists(old) && !FileSystem.exists(moved))
					File.saveContent(moved, File.getContent(old));
			}
		}
		catch (e:Dynamic) {}
	}
	#else
	static var save:FlxSave;

	static function ensure():Void
	{
		if (save == null)
		{
			save = new FlxSave();
			save.bind("TheEnemyMaps");
		}
	}
	#end

	#if (sys && probe)
	public static function probeDir():String
		return dir();

	public static function probeBesideExe():String
		return besideExe();
	#end

	public static function load(slot:Int):StoredMap
	{
		var raw:String = null;
		#if sys
		var path = haxe.io.Path.join([dir(), "slot" + slot + ".json"]);
		if (FileSystem.exists(path))
			try raw = File.getContent(path) catch (e:Dynamic) {}
		#else
		ensure();
		raw = Reflect.field(save.data, "slot" + slot);
		#end
		if (raw == null)
			return null;
		return try Json.parse(raw) catch (e:Dynamic) null;
	}

	public static function store(slot:Int, m:StoredMap):Void
	{
		var raw = Json.stringify(m);
		#if sys
		try
		{
			if (!FileSystem.exists(dir()))
				FileSystem.createDirectory(dir());
			File.saveContent(haxe.io.Path.join([dir(), "slot" + slot + ".json"]), raw);
		}
		catch (e:Dynamic) {}
		#else
		ensure();
		Reflect.setField(save.data, "slot" + slot, raw);
		save.flush();
		#end
	}
}
