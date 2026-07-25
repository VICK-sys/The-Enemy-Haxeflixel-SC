package util;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class MenuSlash
{
	static inline var AIM_TIME:Float = 0.34;
	static inline var CUT_TIME:Float = 0.09;
	static inline var FOLLOW_TIME:Float = 0.16;
	static inline var LINGER:Float = 0.7;
	static inline var GRAVITY:Float = 1100;

	private var state:FlxState;
	private var row:FlxText;
	private var scythe:FlxSprite;
	private var onDone:Void->Void;
	private var midX:Float;
	private var cy:Float;

	public static function play(state:FlxState, row:FlxText, scythe:FlxSprite, onDone:Void->Void):Void
	{
		new MenuSlash(state, row, scythe, onDone);
	}

	function new(state:FlxState, row:FlxText, scythe:FlxSprite, onDone:Void->Void)
	{
		this.state = state;
		this.row = row;
		this.scythe = scythe;
		this.onDone = onDone;

		cy = row.y + row.height * 0.5 - scythe.height * 0.5;
		midX = row.x + row.width * 0.5 - scythe.width * 0.5;

		FlxTween.tween(scythe, {x: row.x - scythe.width - 70, y: cy - 46, angle: -125}, AIM_TIME,
			{ease: FlxEase.backOut, onComplete: cut});
	}

	function cut(_:FlxTween):Void
	{
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.8);
		FlxTween.tween(scythe, {x: midX, y: cy, angle: -20}, CUT_TIME, {ease: FlxEase.quadIn, onComplete: shatter});
	}

	function shatter(_:FlxTween):Void
	{
		FlxG.sound.play(Paths.sound("scythe/slice"), 0.7);
		FlxG.camera.shake(0.013, 0.3);

		spawnLetters();
		row.visible = false;

		FlxTween.tween(scythe, {x: row.x + row.width + 60, y: cy + 26, angle: 55}, FOLLOW_TIME, {ease: FlxEase.quadOut});
		new FlxTimer().start(LINGER, function(_)
		{
			if (onDone != null)
				onDone();
		});
	}

	function spawnLetters():Void
	{
		var label = row.text;
		var widths:Array<Float> = [];
		var total:Float = 0;

		var probe = new FlxText(0, 0, 0, "");
		probe.setFormat(null, Std.int(row.size), FlxColor.WHITE, LEFT);
		for (i in 0...label.length)
		{
			probe.text = label.charAt(i);
			widths.push(probe.width);
			total += probe.width;
		}
		probe.destroy();

		var squeeze = total > 0 ? row.width / total : 1;
		var penX = row.x;

		for (i in 0...label.length)
		{
			var ch = label.charAt(i);
			var w = widths[i] * squeeze;
			if (ch != " ")
				state.add(makeShard(ch, penX, w));
			penX += w;
		}
	}

	function makeShard(ch:String, x:Float, w:Float):FlxText
	{
		var t = new FlxText(x, row.y, 0, ch);
		t.setFormat(null, Std.int(row.size), row.color, LEFT);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);

		t.moves = true;

		var away = (x + w * 0.5 - midX - scythe.width * 0.5) / Math.max(1, row.width * 0.5);
		t.velocity.set(away * FlxG.random.float(90, 210) + FlxG.random.float(-40, 40), FlxG.random.float(-320, -140));
		t.acceleration.y = GRAVITY;
		t.angularVelocity = FlxG.random.float(-420, 420);

		FlxTween.tween(t, {alpha: 0}, 0.55, {startDelay: 0.35, onComplete: function(_)
		{
			state.remove(t, true);
			t.destroy();
		}});
		return t;
	}
}
