package util;

#if sys
import sys.io.File;
import sys.io.FileOutput;
#end

class PerfLog
{
	static inline var SPIKE_MS:Float = 24;
	static inline var GAP_MS:Float = 500;

	#if sys
	static var out:FileOutput;
	#end

	private var lastStamp:Float = -1;
	private var startStamp:Float = 0;
	private var secAccum:Float = 0;
	private var secFrames:Int = 0;
	private var secWorst:Float = 0;

	public function new()
	{
		#if sys
		if (out == null)
		{
			out = File.write("perflog.txt");
			out.writeString("t\tkind\tavgMs\tworstMs\tfps\tenemies\tpaths\tprojectiles\twave\n");
		}
		startStamp = haxe.Timer.stamp();
		#end
	}

	public function frame(enemies:Int, paths:Int, projectiles:Int, wave:Int):Void
	{
		#if sys
		var now = haxe.Timer.stamp();
		if (lastStamp < 0)
		{
			lastStamp = now;
			return;
		}
		var ms = (now - lastStamp) * 1000;
		lastStamp = now;
		var t = now - startStamp;

		if (ms > GAP_MS)
		{
			out.writeString(fmt(t) + "\tgap\t" + fmt(ms) + "\t" + fmt(ms) + "\t\t" + enemies + "\t" + paths + "\t" + projectiles + "\t" + wave + "\n");
			out.flush();
			secAccum = 0;
			secFrames = 0;
			secWorst = 0;
			return;
		}

		secAccum += ms;
		secFrames++;
		if (ms > secWorst)
			secWorst = ms;

		if (ms > SPIKE_MS)
		{
			out.writeString(fmt(t) + "\tSPIKE\t" + fmt(ms) + "\t" + fmt(ms) + "\t\t" + enemies + "\t" + paths + "\t" + projectiles + "\t" + wave + "\n");
			out.flush();
		}

		if (secAccum >= 1000)
		{
			var avg = secAccum / secFrames;
			out.writeString(fmt(t) + "\tsec\t" + fmt(avg) + "\t" + fmt(secWorst) + "\t" + fmt(1000 / avg) + "\t" + enemies + "\t" + paths + "\t" + projectiles + "\t" + wave + "\n");
			out.flush();
			secAccum = 0;
			secFrames = 0;
			secWorst = 0;
		}
		#end
	}

	function fmt(v:Float):String
		return Std.string(Math.round(v * 10) / 10);
}
