package systems;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class DamageNumbers
{
	public static inline var HIT:Int = 0;
	public static inline var CRIT:Int = 1;
	public static inline var HEAL:Int = 2;
	public static inline var BLOCKED:Int = 3;

	static inline var POOL:Int = 48;
	static inline var BIG_AT:Float = 4.5;
	static inline var BASE_SCALE:Float = 0.8;
	static inline var PER_DAMAGE:Float = 0.05;
	static inline var MAX_BONUS:Float = 0.55;
	static inline var CRIT_BONUS:Float = 0.3;
	static inline var POP:Float = 1.1;
	static inline var POP_TIME:Float = 0.15;
	static inline var RISE_MIN:Float = 22;
	static inline var RISE_MAX:Float = 38;
	static inline var LIFE_MIN:Float = 0.45;
	static inline var LIFE_MAX:Float = 0.7;
	static inline var HOLD:Float = 0.45;
	static inline var JITTER_X:Float = 16;
	static inline var JITTER_Y:Float = 10;

	static inline var BIG_TINT:Int = 0xFFFFD24A;
	static inline var CRIT_TINT:Int = 0xFFFF6A2A;
	static inline var HEAL_TINT:Int = 0xFF6BE06B;
	static inline var BLOCKED_TINT:Int = 0xFF9A9A9A;

	public var group:FlxTypedGroup<FlxText>;
	public var enabled:Bool = true;

	private var texts:Array<FlxText> = [];
	private var life:Array<Float> = [];
	private var span:Array<Float> = [];
	private var rise:Array<Float> = [];
	private var homeX:Array<Float> = [];
	private var homeY:Array<Float> = [];
	private var base:Array<Float> = [];
	private var total:Array<Float> = [];
	private var tier:Array<Int> = [];
	private var owner:Array<Dynamic> = [];
	private var stamp:Array<Int> = [];
	private var frame:Int = 0;

	public function new()
	{
		group = new FlxTypedGroup<FlxText>(POOL);
		for (i in 0...POOL)
		{
			var t = new FlxText(0, 0, 0, "");
			t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			t.exists = false;
			group.add(t);
			texts.push(t);
			life.push(0);
			span.push(1);
			rise.push(0);
			homeX.push(0);
			homeY.push(0);
			base.push(1);
			total.push(0);
			tier.push(HIT);
			owner.push(null);
			stamp.push(-1);
		}
		applyLanguage();
	}

	public function applyLanguage():Void
	{
		for (t in texts)
			t.setFormat(util.Lang.bodyFont(), util.Lang.bodySize(), FlxColor.WHITE, CENTER);
	}

	public function pop(x:Float, y:Float, amount:Float, kind:Int, ?from:Dynamic):Void
	{
		if (!enabled)
			return;

		if (from != null)
		{
			for (i in 0...POOL)
				if (life[i] > 0 && owner[i] == from && stamp[i] == frame && tier[i] == kind)
				{
					total[i] += amount;
					label(i);
					return;
				}
		}

		var i = slot();
		owner[i] = from;
		stamp[i] = frame;
		total[i] = amount;
		tier[i] = kind;
		span[i] = LIFE_MIN + FlxG.random.float() * (LIFE_MAX - LIFE_MIN);
		life[i] = span[i];
		rise[i] = RISE_MIN + FlxG.random.float() * (RISE_MAX - RISE_MIN);
		homeX[i] = x + (FlxG.random.float() * 2 - 1) * JITTER_X;
		homeY[i] = y + (FlxG.random.float() * 2 - 1) * JITTER_Y;

		var t = texts[i];
		t.exists = true;
		t.alpha = 1;
		label(i);
		place(i, 0);
	}

	public function update(elapsed:Float):Void
	{
		frame++;
		for (i in 0...POOL)
		{
			if (life[i] <= 0)
				continue;

			life[i] -= elapsed;
			var t = texts[i];
			if (life[i] <= 0)
			{
				t.exists = false;
				owner[i] = null;
				stamp[i] = -1;
				continue;
			}

			var age = 1 - life[i] / span[i];
			t.alpha = age < HOLD ? 1 : 1 - (age - HOLD) / (1 - HOLD);
			place(i, age);
		}
	}

	public function clear():Void
	{
		for (i in 0...POOL)
		{
			life[i] = 0;
			owner[i] = null;
			stamp[i] = -1;
			texts[i].exists = false;
		}
	}

	function slot():Int
	{
		var oldest = 0;
		var least:Float = -1;
		for (i in 0...POOL)
		{
			if (life[i] <= 0)
				return i;
			if (least < 0 || life[i] < least)
			{
				least = life[i];
				oldest = i;
			}
		}
		return oldest;
	}

	function label(i:Int):Void
	{
		var t = texts[i];
		var amount = total[i];
		var shown = Math.round(amount);
		t.text = (tier[i] == HEAL ? "+" : "") + shown;
		t.color = tint(tier[i], amount);
		base[i] = BASE_SCALE + Math.min(amount * PER_DAMAGE, MAX_BONUS) + (tier[i] == CRIT ? CRIT_BONUS : 0);
	}

	function place(i:Int, age:Float):Void
	{
		var t = texts[i];
		var s = base[i];
		var since = span[i] - life[i];
		if (tier[i] == CRIT && since < POP_TIME)
			s *= POP + (1 - POP) * (since / POP_TIME);
		t.scale.set(s, s);
		t.origin.set(t.frameWidth * 0.5, t.frameHeight * 0.5);
		t.setPosition(homeX[i] - t.frameWidth * 0.5, homeY[i] - rise[i] * age - t.frameHeight * 0.5);
	}

	function tint(kind:Int, amount:Float):FlxColor
	{
		return switch (kind)
		{
			case CRIT: CRIT_TINT;
			case HEAL: HEAL_TINT;
			case BLOCKED: BLOCKED_TINT;
			default: amount >= BIG_AT ? BIG_TINT : FlxColor.WHITE;
		}
	}
}
