package data;

import util.Library;
import util.Paths;

typedef PropData =
{
	name:String,
	sheet:String,
	rect:Array<Int>,
	scale:Float,
	?hitbox:Array<Int>,
	?layer:Int,
	?owned:Bool
}

typedef PropPlace =
{
	n:String,
	x:Float,
	y:Float,
	?f:Bool
}

typedef PropSet =
{
	props:Array<PropData>
}

class PropDataRegistry
{
	static var data:PropSet;
	static var merged:Array<PropData>;
	static var mergedAt:Int = -1;

	static var baseHitbox:Map<String, Array<Int>> = new Map();
	static var baseLayer:Map<String, Null<Int>> = new Map();

	static function ensureData():Void
	{
		if (data != null)
			return;
		data = DataLoader.load(Paths.json("props"));
		for (p in data.props)
		{
			if (p.hitbox != null && p.hitbox.length == 4)
				baseHitbox.set(p.name, p.hitbox);
			if (p.layer != null)
				baseLayer.set(p.name, p.layer);
		}
	}

	public static function all():Array<PropData>
	{
		ensureData();
		Library.ensure();
		if (merged == null || mergedAt != Library.version)
		{
			merged = data.props.concat(Library.props);
			for (p in merged)
			{
				var box = Library.hitboxOf(p.name);
				p.hitbox = box != null ? box : baseHitbox.get(p.name);
				var lm = Library.layerOf(p.name);
				p.layer = lm != null ? lm : baseLayer.get(p.name);
			}
			mergedAt = Library.version;
		}
		return merged;
	}

	public static function get(i:Int):PropData
	{
		var list = all();
		if (list.length == 0)
			return null;
		if (i < 0 || i >= list.length)
			i = 0;
		return list[i];
	}

	public static function count():Int
		return all().length;

	public static function placeable():Array<PropData>
	{
		var out:Array<PropData> = [];
		for (p in all())
			if (p.owned != true)
				out.push(p);
		return out;
	}

	public static function placeableAt(i:Int):PropData
	{
		var list = placeable();
		if (list.length == 0)
			return null;
		if (i < 0 || i >= list.length)
			i = 0;
		return list[i];
	}

	public static function placeableCount():Int
		return placeable().length;

	public static function byName(name:String):PropData
	{
		for (p in all())
			if (p.name == name)
				return p;
		return null;
	}
}
