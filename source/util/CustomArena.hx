package util;

class CustomArena
{
	public static inline var QUIET_SLOT:Int = -2;

	public static var csv:String = null;
	public static var spawnX:Float = 0;
	public static var spawnY:Float = 0;
	public static var props:Array<data.PropData.PropPlace> = [];
	public static var tileset:String = null;
	public static var tiles:String = null;
	public static var fromEditor:Bool = false;
	public static var slot:Int = 0;

	public static var active(get, never):Bool;

	static function get_active():Bool
		return csv != null;

	public static var quiet(get, never):Bool;

	static function get_quiet():Bool
		return active && slot == QUIET_SLOT;

	public static function set(csv:String, sx:Float, sy:Float, props:Array<data.PropData.PropPlace>):Void
	{
		CustomArena.csv = csv;
		spawnX = sx;
		spawnY = sy;
		CustomArena.props = props == null ? [] : props;
	}

	public static function setTiles(setName:String, csv:String):Void
	{
		tileset = setName;
		tiles = csv;
	}

	public static function fromStored(m:util.MapStore.StoredMap, fromSlot:Int = 0):Void
	{
		set(m.csv, m.sx, m.sy, m.props);
		setTiles(m.tileset, m.tiles);
		slot = fromSlot;
	}

	public static function clear():Void
	{
		csv = null;
		props = [];
		tileset = null;
		tiles = null;
		fromEditor = false;
		slot = 0;
	}
}
