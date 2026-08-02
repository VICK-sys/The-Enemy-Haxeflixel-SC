package net;

class AckQuorum
{
	public var armed(default, null):Bool = false;

	private var eligible:Map<Int, Bool>;
	private var acks:Map<Int, Bool>;

	public function new() {}

	public function arm(ids:Array<Int>):Void
	{
		armed = true;
		eligible = new Map();
		acks = new Map();
		for (id in ids)
			eligible.set(id, true);
	}

	public function ack(id:Int):Void
	{
		if (armed && eligible.exists(id))
			acks.set(id, true);
	}

	public function unack(id:Int):Void
	{
		if (armed)
			acks.remove(id);
	}

	public function drop(id:Int):Void
	{
		if (!armed)
			return;
		eligible.remove(id);
		acks.remove(id);
	}

	public function satisfied():Bool
	{
		if (!armed)
			return false;
		for (id in eligible.keys())
			if (!acks.exists(id))
				return false;
		return true;
	}

	public function got():Int
	{
		if (acks == null)
			return 0;
		var n = 0;
		for (_ in acks)
			n++;
		return n;
	}

	public function need():Int
	{
		if (eligible == null)
			return 0;
		var n = 0;
		for (_ in eligible.keys())
			n++;
		return n;
	}

	public function disarm():Void
	{
		armed = false;
		eligible = null;
		acks = null;
	}
}
