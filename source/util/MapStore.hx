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
	?tileW:Int
}

class MapStore
{
	public static inline var SLOTS:Int = 5;

	#if sys
	static function dir():String
		return haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "maps"]);
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
