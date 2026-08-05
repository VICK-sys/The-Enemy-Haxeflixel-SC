package util;

class Version
{
	static inline var UNKNOWN:String = "0.0.0";

	public static var id(get, never):String;

	static var cached:String = null;

	static function get_id():String
	{
		if (cached != null)
			return cached;

		cached = UNKNOWN;
		try
		{
			var meta = lime.app.Application.current.meta;
			if (meta != null)
			{
				var v = meta.get("version");
				if (v != null && v != "")
					cached = v;
			}
		}
		catch (e:Dynamic) {}
		return cached;
	}

	public static function label():String
		return "v" + id;

	public static function matches(other:Dynamic):Bool
		return other != null && Std.isOfType(other, String) && (other : String) == id;
}
