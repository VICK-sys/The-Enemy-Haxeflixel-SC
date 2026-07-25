package util;

class CustomArena
{
	public static var csv:String = null;
	public static var spawnX:Float = 0;
	public static var spawnY:Float = 0;
	public static var theme:Int = 0;
	public static var props:Array<data.PropData.PropPlace> = [];
	public static var tileset:String = null;
	public static var tiles:String = null;

	public static var active(get, never):Bool;

	static function get_active():Bool
		return csv != null;

	public static function set(csv:String, sx:Float, sy:Float, theme:Int, props:Array<data.PropData.PropPlace>):Void
	{
		CustomArena.csv = csv;
		spawnX = sx;
		spawnY = sy;
		CustomArena.theme = theme;
		CustomArena.props = props == null ? [] : props;
	}

	public static function setTiles(setName:String, csv:String):Void
	{
		tileset = setName;
		tiles = csv;
	}

	public static function clear():Void
	{
		csv = null;
		props = [];
		tileset = null;
		tiles = null;
	}
}
