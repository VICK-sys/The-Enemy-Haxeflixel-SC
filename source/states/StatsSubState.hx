package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxColor;
import util.Lang;
import util.SaveData;
import util.Stats;

class StatsSubState extends LobbyPanel
{
	static inline var STEP:Float = 30;
	static inline var HEAD_GAP:Float = 40;
	static inline var BLOCK_GAP:Float = 34;
	static inline var KEY_W:Float = 210;
	static inline var VAL_W:Float = 230;
	static inline var VAL_GAP:Float = 12;

	public var onDone:Void->Void;

	public function new(camUI:FlxCamera)
	{
		super(camUI, 900, 600);
	}

	override public function create():Void
	{
		chrome("stats.title");

		var leftX = px + 300;
		var rightX = px + 690;
		var top = py + 100;

		var y = block(leftX, top, "stats.total", [
			{key: "stats.kills", value: count(Stats.KILLS)},
			{key: "stats.runs", value: count(Stats.RUNS)},
			{key: "stats.deaths", value: count(Stats.DEATHS)},
			{key: "stats.waves", value: count(Stats.WAVES)},
			{key: "stats.bosses", value: count(Stats.BOSSES)},
			{key: "stats.time", value: Stats.clock(Stats.total(Stats.TIME))}
		]);

		block(leftX, y + BLOCK_GAP, "stats.bestRun", [
			{key: "stats.globalWave", value: Std.string(SaveData.bestWave())},
			{key: "stats.kills", value: count(Stats.BEST_KILLS)},
			{key: "stats.time", value: Stats.clock(Stats.total(Stats.BEST_TIME))}
		]);

		var byWeapon = [];
		for (i in 0...4)
			byWeapon.push({name: WeaponPickSubState.nameOf(i), value: waveOf(i)});
		named(rightX, top, "stats.byWeapon", byWeapon);

		hints(Lang.t("stats.hints"), py + panelH - 46);

		super.create();
	}

	function block(colX:Float, top:Float, headKey:String, rows:Array<{key:String, value:String}>):Float
	{
		var out = [];
		for (r in rows)
			out.push({name: Lang.t(r.key), value: r.value});
		return named(colX, top, headKey, out);
	}

	function named(colX:Float, top:Float, headKey:String, rows:Array<{name:String, value:String}>):Float
	{
		label(colX - KEY_W, top, KEY_W + VAL_GAP + VAL_W, Lang.t(headKey), Lang.bodySize(), FlxColor.WHITE, CENTER);
		var y = top + HEAD_GAP;
		for (r in rows)
		{
			label(colX - KEY_W, y, KEY_W, r.name, Lang.smallSize(), LobbyPanel.DIM, RIGHT);
			label(colX + VAL_GAP, y, VAL_W, r.value, Lang.smallSize(), FlxColor.WHITE, LEFT);
			y += STEP;
		}
		return y;
	}

	function count(key:String):String
		return Std.string(Std.int(Stats.total(key)));

	function waveOf(weapon:Int):String
	{
		var best = Stats.weaponBest(weapon);
		return best <= 0 ? "-" : Std.string(best);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		tickArm(elapsed);

		if (!armed())
			return;

		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE
			|| util.Controls.justPressed(util.Controls.ACCEPT))
		{
			if (onDone != null)
				onDone();
			close();
		}
	}
}
