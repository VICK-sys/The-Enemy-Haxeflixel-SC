package util;

import haxe.Json;
import openfl.utils.Assets;

class DataLoader
{
	public static function load(path:String):Dynamic
	{
		var text = Assets.getText(path);
		if (text == null)
			throw "Missing data file: " + path;
		return Json.parse(text);
	}
}
