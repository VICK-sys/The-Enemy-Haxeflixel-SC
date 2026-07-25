package data;

import util.Paths;

typedef PropData =
{
	name:String,
	sheet:String,
	rect:Array<Int>,
	scale:Float
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

	public static function all():Array<PropData>
	{
		if (data == null)
			data = DataLoader.load(Paths.json("props"));
		return data.props;
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
