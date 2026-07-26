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
	?layer:Int
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

	public static function all():Array<PropData>
	{
		if (data == null)
			data = DataLoader.load(Paths.json("props"));
		Library.ensure();
		if (merged == null || mergedAt != Library.version)
		{
			merged = data.props.concat(Library.props);
			for (p in merged)
			{
				p.hitbox = Library.hitboxOf(p.name);
				p.layer = Library.layerOf(p.name);
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

	public static function byName(name:String):PropData
	{
		for (p in all())
			if (p.name == name)
				return p;
		return null;
	}
}
