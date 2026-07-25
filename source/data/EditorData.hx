package data;

import util.Paths;

typedef EditorViewData =
{
	startZoom:Float,
	minZoom:Float,
	maxZoom:Float,
	zoomStep:Float,
	panSpeed:Float
}

typedef EditorPaletteData =
{
	width:Float,
	height:Float,
	padding:Float,
	propCell:Int,
	maxZoom:Float
}

typedef EditorBrushData =
{
	maxSize:Int,
	undoDepth:Int
}

typedef EditorData =
{
	view:EditorViewData,
	palette:EditorPaletteData,
	brush:EditorBrushData,
	flashTime:Float
}

class EditorDataRegistry
{
	static var data:EditorData;

	public static function get():EditorData
	{
		if (data == null)
			data = DataLoader.load(Paths.json("editor"));
		return data;
	}
}
