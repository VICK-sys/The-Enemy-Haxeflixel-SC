package ui;

import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

class Counter extends TextField
{
	static inline var ALARM_BYTES:Float = 1024 * 1024 * 1024;
	static inline var MEGABYTE:Float = 1024 * 1024;
	static inline var PLAIN:Int = 0xFFFFFF;
	static inline var ALARM:Int = 0x560101;
	static inline var SIZE:Int = 12;

	private var times:Array<Float> = [];
	private var clock:Float = 0;
	private var lastCount:Int = 0;
	private var shownText:String = "";
	private var shownAlarm:Bool = false;

	public function new(x:Float, y:Float)
	{
		super();
		this.x = x;
		this.y = y;
		selectable = false;
		mouseEnabled = false;
		autoSize = LEFT;
		defaultTextFormat = new TextFormat("_sans", SIZE, PLAIN);
		text = "FPS: 0\nMEM: 0 MB";
	}

	override private function __enterFrame(delta:Float):Void
	{
		clock += delta;
		times.push(clock);
		while (times.length > 0 && times[0] < clock - 1000)
			times.shift();

		var count = times.length;
		var fps = Std.int((count + lastCount) / 2);
		lastCount = count;

		var used = System.totalMemoryNumber;
		var alarm = used > ALARM_BYTES;
		var line = "FPS: " + fps + "\nMEM: " + size(used);
		if (line == shownText && alarm == shownAlarm)
			return;
		shownText = line;
		shownAlarm = alarm;

		text = line;
		var at = line.indexOf("\n") + 1;
		setTextFormat(new TextFormat("_sans", SIZE, alarm ? ALARM : PLAIN), at, line.length);
	}

	static function size(bytes:Float):String
	{
		var mb = bytes / MEGABYTE;
		if (mb < 1024)
			return Math.round(mb) + " MB";
		return (Math.round(mb / 1024 * 100) / 100) + " GB";
	}
}
