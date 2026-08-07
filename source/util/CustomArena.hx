package util;

class CustomArena
{
	public static var csv:String = null;
	public static var spawnX:Float = 0;
	public static var spawnY:Float = 0;
	public static var shopX:Float = 0;
	public static var shopY:Float = 0;
	public static var shopSet:Bool = false;
	public static var props:Array<data.PropData.PropPlace> = [];
	public static var tileset:String = null;
	public static var pixelW:Int = 0;
	public static var pixelH:Int = 0;
	public static var tiles:String = null;
	public static var fromEditor:Bool = false;
	public static var slot:Int = 0;

	public static var active(get, never):Bool;

	static function get_active():Bool
		return csv != null;

	public static function set(csv:String, sx:Float, sy:Float, props:Array<data.PropData.PropPlace>):Void
	{
		CustomArena.csv = csv;
		measure(csv);
		spawnX = sx;
		spawnY = sy;
		CustomArena.props = props == null ? [] : props;
	}

	static function measure(csv:String):Void
	{
		pixelW = 0;
		pixelH = 0;
		if (csv == null || csv == "")
			return;
		var lines = csv.split("
");
		var step = data.ArenaData.ArenaDataRegistry.get().tileSize;
		pixelH = lines.length * step;
		pixelW = lines[0].split(",").length * step;
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
		setShop(m.shopX, m.shopY);
		slot = fromSlot;
	}

	public static function setShop(x:Null<Float>, y:Null<Float>):Void
	{
		shopSet = x != null && y != null;
		shopX = shopSet ? x : 0;
		shopY = shopSet ? y : 0;
	}

	public static function clear():Void
	{
		shopSet = false;
		csv = null;
		props = [];
		tileset = null;
		pixelW = 0;
		pixelH = 0;
		tiles = null;
		fromEditor = false;
		slot = 0;
	}
}
