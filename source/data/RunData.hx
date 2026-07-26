package data;

import util.Paths;

typedef RunEvent =
{
	name:String,
	min:Int,
	max:Int,
	?note:String
}

typedef RunSet =
{
	min:Int,
	max:Int,
	events:Array<RunEvent>
}

class RunDataRegistry
{
	static var data:RunSet;

	public static function get():RunSet
	{
		if (data == null)
			data = DataLoader.load(Paths.json("run"));
		return data;
	}

	public static function event(name:String):RunEvent
	{
		for (e in get().events)
			if (e.name == name)
				return e;
		return null;
	}

	public static function names():Array<String>
	{
		var out = [];
		for (e in get().events)
			out.push(e.name);
		return out;
	}
}
