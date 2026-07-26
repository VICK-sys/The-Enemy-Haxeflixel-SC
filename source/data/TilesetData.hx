package data;

import util.Library;
import util.Paths;

typedef TilesetData =
{
	name:String,
	image:String,
	tileW:Int,
	tileH:Int
}

typedef TilesetSet =
{
	tilesets:Array<TilesetData>
}

class TilesetDataRegistry
{
	static var data:TilesetSet;
	static var merged:Array<TilesetData>;
	static var mergedAt:Int = -1;

	public static function all():Array<TilesetData>
	{
		if (data == null)
			data = DataLoader.load(Paths.json("tilesets"));
		Library.ensure();
		if (merged == null || mergedAt != Library.version)
		{
			merged = data.tilesets.concat(Library.tilesets);
			mergedAt = Library.version;
		}
		return merged;
	}

	public static function get(i:Int):TilesetData
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

	public static function byName(name:String):TilesetData
	{
		if (name == null)
			return null;
		for (t in all())
			if (t.name == name)
				return t;
		return null;
	}

	public static function indexOf(name:String):Int
	{
		var list = all();
		for (i in 0...list.length)
			if (list[i].name == name)
				return i;
		return 0;
	}
}
