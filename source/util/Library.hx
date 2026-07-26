package util;

import haxe.Json;
import data.PropData.PropData;
import data.TilesetData.TilesetData;
#if sys
import flixel.FlxG;
import openfl.display.BitmapData;
import sys.FileSystem;
import sys.io.File;
#end

typedef LibraryFile =
{
	?tilesets:Array<TilesetData>,
	?props:Array<PropData>,
	?wall:String,
	?hitboxes:Dynamic,
	?layers:Dynamic
}

class Library
{
	public static inline var TILESETS:String = "tilesets";
	public static inline var PROPS:String = "props";
	public static inline var WALLS:String = "walls";

	public static var version(default, null):Int = 0;
	public static var tilesets(default, null):Array<TilesetData> = [];
	public static var props(default, null):Array<PropData> = [];
	public static var wallImage(default, null):String;

	static var started:Bool = false;
	static var found:Map<String, Array<String>> = new Map();
	static var hitboxes:Map<String, Array<Int>> = new Map();
	static var layerModes:Map<String, Int> = new Map();

	public static function available():Bool
	{
		#if sys
		return true;
		#else
		return false;
		#end
	}

	public static function ensure():Void
	{
		if (started)
			return;
		started = true;
		#if sys
		scan(TILESETS);
		scan(PROPS);
		scan(WALLS);
		read();
		#end
	}

	public static function rescan():Void
	{
		started = false;
		found = new Map();
		hitboxes = new Map();
		layerModes = new Map();
		wallImage = null;
		ensure();
		version++;
	}

	public static function files(kind:String):Array<String>
	{
		ensure();
		var f = found.get(kind);
		return f == null ? [] : f;
	}

	public static function displayName(asset:String):String
	{
		var base = asset.substr(asset.lastIndexOf("/") + 1);
		return StringTools.replace(base, "_", " ").toUpperCase();
	}

	public static function root():String
	{
		#if sys
		return dir();
		#else
		return "desktop only";
		#end
	}

	public static function addTileset(asset:String, tw:Int, th:Int):String
	{
		var name = displayName(asset);
		tilesets = tilesets.filter(function(t) return t.image != asset);
		tilesets.push({name: name, image: asset, tileW: tw, tileH: th});
		commit();
		return name;
	}

	public static function addProp(asset:String, scale:Float):String
	{
		var name = displayName(asset);
		props = props.filter(function(p) return p.sheet != asset);
		props.push({name: name, sheet: asset, rect: [], scale: scale});
		#if sys
		FlxG.bitmap.removeByKey("prop:" + name);
		#end
		commit();
		return name;
	}

	public static function setWall(asset:String):String
	{
		wallImage = asset;
		commit();
		return displayName(asset);
	}

	public static function clearWall():Void
	{
		wallImage = null;
		commit();
	}

	public static function hitboxOf(name:String):Array<Int>
	{
		ensure();
		return hitboxes.get(name);
	}

	public static function setHitbox(name:String, box:Array<Int>):Void
	{
		if (box == null)
			hitboxes.remove(name);
		else
			hitboxes.set(name, box);
		commit();
	}

	public static function layerOf(name:String):Null<Int>
	{
		ensure();
		return layerModes.exists(name) ? layerModes.get(name) : null;
	}

	public static function setLayer(name:String, mode:Int):Void
	{
		if (mode == 0)
			layerModes.remove(name);
		else
			layerModes.set(name, mode);
		commit();
	}

	static function commit():Void
	{
		version++;
		#if sys
		write();
		#end
	}

	#if sys
	static function dir():String
		return haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "library"]);

	static function folder(kind:String):String
		return haxe.io.Path.join([dir(), kind]);

	static function jsonPath():String
		return haxe.io.Path.join([dir(), "library.json"]);

	static function scan(kind:String):Void
	{
		var path = folder(kind);
		var names:Array<String> = [];
		found.set(kind, names);

		if (!FileSystem.exists(path))
		{
			try
			{
				FileSystem.createDirectory(path);
			}
			catch (e:Dynamic) {}
			return;
		}

		var listing:Array<String> = try FileSystem.readDirectory(path) catch (e:Dynamic) [];
		listing.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));

		for (f in listing)
		{
			if (!StringTools.endsWith(f.toLowerCase(), ".png"))
				continue;
			var base = f.substr(0, f.length - 4);
			var asset = "library/" + kind + "/" + base;
			if (register(asset, haxe.io.Path.join([path, f])))
				names.push(asset);
		}
	}

	static function register(asset:String, file:String):Bool
	{
		var key = Paths.image(asset);
		if (FlxG.bitmap.get(key) != null)
			return true;

		var bmp:BitmapData = try BitmapData.fromFile(file) catch (e:Dynamic) null;
		if (bmp == null)
			return false;

		var g = FlxG.bitmap.add(bmp, false, key);
		if (g == null)
			return false;
		g.persist = true;
		g.destroyOnNoUse = false;
		return true;
	}

	static function known(kind:String, asset:String):Bool
	{
		var f = found.get(kind);
		return asset != null && f != null && f.indexOf(asset) >= 0;
	}

	static function read():Void
	{
		var p = jsonPath();
		if (!FileSystem.exists(p))
			return;
		var raw:String = try File.getContent(p) catch (e:Dynamic) null;
		if (raw == null)
			return;
		var d:LibraryFile = try Json.parse(raw) catch (e:Dynamic) null;
		if (d == null)
			return;

		if (d.tilesets != null)
			tilesets = d.tilesets.filter(function(t) return known(TILESETS, t.image));
		if (d.props != null)
			props = d.props.filter(function(p) return known(PROPS, p.sheet));
		if (d.wall != null && known(WALLS, d.wall))
			wallImage = d.wall;

		if (d.hitboxes != null)
			for (f in Reflect.fields(d.hitboxes))
			{
				var box:Array<Int> = Reflect.field(d.hitboxes, f);
				if (box != null && box.length == 4)
					hitboxes.set(f, box);
			}

		if (d.layers != null)
			for (f in Reflect.fields(d.layers))
			{
				var mode:Null<Int> = Reflect.field(d.layers, f);
				if (mode != null && mode > 0)
					layerModes.set(f, mode);
			}
	}

	static function write():Void
	{
		try
		{
			if (!FileSystem.exists(dir()))
				FileSystem.createDirectory(dir());
			var boxes:Dynamic = {};
			for (k in hitboxes.keys())
				Reflect.setField(boxes, k, hitboxes.get(k));
			var modes:Dynamic = {};
			for (k in layerModes.keys())
				Reflect.setField(modes, k, layerModes.get(k));
			File.saveContent(jsonPath(),
				Json.stringify({tilesets: tilesets, props: props, wall: wallImage, hitboxes: boxes, layers: modes}, null, "\t"));
		}
		catch (e:Dynamic) {}
	}
	#end
}
