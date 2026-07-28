package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import data.PlayerData.PlayerDataRegistry;
import util.Lang;
import util.Levels;

class LevelUpSubState extends FlxSubState
{
	static inline var GOLD:Int = 0xFFE8C860;
	static inline var LIT:Int = 0xFF8CE07F;
	static inline var DIM:Int = 0xFF9A9A9A;
	static inline var EDGE:Int = 0xFF6A5A32;
	static inline var FILL:Int = 0xF2100E0C;

	static inline var LEFT_X:Float = 120;
	static inline var RIGHT_X:Float = 596;
	static inline var TOP:Float = 150;
	static inline var LEFT_W:Float = 420;
	static inline var RIGHT_W:Float = 564;
	static inline var PANEL_H:Float = 430;
	static inline var ROW:Float = 40;
	static inline var FADE_TIME:Float = 0.18;
	static inline var ARROW_W:Float = 30;
	static inline var ARROW_PAD:Float = 9;
	static inline var LESS_X:Float = LEFT_X + LEFT_W - 198;
	static inline var MORE_X:Float = LEFT_X + LEFT_W - 54;

	static var STATS:Array<String> = ["vigor", "endurance", "strength", "dexterity"];

	private var camUI:FlxCamera;
	public var onSpent:Void->Void;

	private var pick:Int = 0;
	private var pieces:Array<FlxSprite> = [];
	private var fade:Float = 0;
	private var leaving:Bool = false;
	private var rows:Array<FlxText> = [];
	private var vals:Array<FlxText> = [];
	private var marker:FlxSprite;
	private var accept:FlxText;
	private var head:Array<FlxText> = [];
	private var outNow:Array<FlxText> = [];
	private var outNext:Array<FlxText> = [];
	private var arrows:Array<FlxText> = [];
	private var less:FlxText;
	private var more:FlxText;

	public function new(camUI:FlxCamera)
	{
		super();
		this.camUI = camUI;
	}

	override public function create():Void
	{
		ui(shade());

		var title = text(LEFT_X, 62, 900, Lang.t("level.title"), 40, GOLD, LEFT);
		var sub = text(LEFT_X, 108, 900, Lang.t("level.sub"), 18, DIM, LEFT);
		ui(title);
		ui(sub);

		panel(LEFT_X, TOP, LEFT_W, PANEL_H);
		panel(RIGHT_X, TOP, RIGHT_W, PANEL_H);

		for (i in 0...3)
		{
			ui(text(LEFT_X + 24, TOP + 20 + i * 32, 200, "", 20, DIM, LEFT));
			head.push(cast state().members[state().members.length - 1]);
		}

		marker = new FlxSprite(LEFT_X + 12, 0);
		marker.makeGraphic(Std.int(LEFT_W - 24), Std.int(ROW - 6), 0x66E8C860);
		ui(marker);

		for (i in 0...STATS.length)
		{
			var y = TOP + 140 + i * ROW;
			var n = text(LEFT_X + 28, y, 260, Lang.t("stat." + STATS[i]), 24, FlxColor.WHITE, LEFT);
			var v = text(LEFT_X + LEFT_W - 160, y, 100, "", 24, FlxColor.WHITE, RIGHT);
			ui(n);
			ui(v);
			rows.push(n);
			vals.push(v);
		}

		less = text(LESS_X, 0, ARROW_W, "<", 24, GOLD, CENTER);
		more = text(MORE_X, 0, ARROW_W, ">", 24, GOLD, CENTER);
		ui(less);
		ui(more);

		accept = text(LEFT_X, TOP + PANEL_H - 58, LEFT_W, Lang.t("level.done"), 26, FlxColor.WHITE, CENTER);
		ui(accept);

		var derived = ["health", "dash", "supergain", "damage", "speed"];
		for (i in 0...derived.length)
		{
			var y = TOP + 40 + i * 52;
			var n = text(RIGHT_X + 24, y, 250, Lang.t("derived." + derived[i]), 22, DIM, LEFT);
			var a = text(RIGHT_X + 232, y, 156, "", 22, FlxColor.WHITE, RIGHT);
			var g = text(RIGHT_X + 394, y, 30, ">", 22, DIM, CENTER);
			var b = text(RIGHT_X + 426, y, 134, "", 22, FlxColor.WHITE, RIGHT);
			ui(n);
			ui(a);
			ui(g);
			ui(b);
			outNow.push(a);
			arrows.push(g);
			outNext.push(b);
		}

		var keys = text(0, FlxG.height - 62, FlxG.width, Lang.t("level.keys"), 18, DIM, CENTER);
		ui(keys);

		refresh();
		FlxG.mouse.visible = true;
		super.create();
	}

	function state():FlxSubState
		return this;

	function shade():FlxSprite
	{
		var s = new FlxSprite();
		s.makeGraphic(FlxG.width, FlxG.height, 0xF0000000);
		return s;
	}

	function panel(x:Float, y:Float, w:Float, h:Float):Void
	{
		var e = new FlxSprite(x - 3, y - 3);
		e.makeGraphic(Std.int(w + 6), Std.int(h + 6), EDGE);
		ui(e);
		var f = new FlxSprite(x, y);
		f.makeGraphic(Std.int(w), Std.int(h), FILL);
		ui(f);
	}

	function text(x:Float, y:Float, w:Float, t:String, size:Int, color:Int, align:FlxTextAlign):FlxText
	{
		var f = new FlxText(x, y, w, t);
		f.setFormat(Lang.font(), size, color, align);
		f.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		return f;
	}

	function ui<T:FlxSprite>(o:T):T
	{
		o.cameras = [camUI];
		o.scrollFactor.set();
		o.alpha = 0;
		pieces.push(o);
		add(o);
		return o;
	}

	function applyFade():Void
	{
		for (o in pieces)
			o.alpha = o.visible ? fade : 0;
	}

	function two(v:Float):String
		return Std.string(Math.round(v * 100) / 100);

	function dmg(pts:Int):String
	{
		var out = "+" + Levels.damageAt(pts);
		var p = Levels.damageProgress(pts);
		return p < 0 ? out : out + "  (" + p + "/" + Levels.damageStep() + ")";
	}

	function refresh():Void
	{
		head[0].text = Lang.t("level.level") + "   " + Levels.level();
		head[1].text = Lang.t("level.exp") + "   " + Levels.exp;
		head[2].text = Lang.t("level.next") + "   " + Levels.costNext();
		head[2].color = Levels.canSpend() ? GOLD : DIM;

		marker.y = TOP + 137 + pick * ROW;
		marker.visible = pick < STATS.length;

		var onStat = pick < STATS.length;
		less.y = more.y = TOP + 140 + pick * ROW;
		less.visible = onStat && Levels.canRefund(pick);
		more.visible = onStat && Levels.canSpend();
		accept.color = pick == STATS.length ? GOLD : FlxColor.WHITE;

		for (i in 0...STATS.length)
		{
			rows[i].color = i == pick ? GOLD : FlxColor.WHITE;
			vals[i].text = Std.string(Levels.points(i));
			vals[i].color = i == pick ? GOLD : FlxColor.WHITE;
		}

		var base = PlayerDataRegistry.get();
		var up = pick < STATS.length && Levels.canSpend();
		var vg = Levels.points(Levels.VIGOR) + (up && pick == Levels.VIGOR ? 1 : 0);
		var en = Levels.points(Levels.ENDURANCE) + (up && pick == Levels.ENDURANCE ? 1 : 0);
		var st = Levels.points(Levels.STRENGTH) + (up && pick == Levels.STRENGTH ? 1 : 0);
		var dx = Levels.points(Levels.DEXTERITY) + (up && pick == Levels.DEXTERITY ? 1 : 0);

		var now = [
			two(base.healthMax + Levels.healthBonus()),
			two(base.dashCooldown * Levels.dashScale()),
			two(base.superPerKill * Levels.superGainScale()),
			dmg(Levels.points(Levels.STRENGTH)),
			two(Levels.actionScale())
		];
		var soon = [
			two(base.healthMax + Levels.healthAt(vg)),
			two(base.dashCooldown * Levels.dashAt(en)),
			two(base.superPerKill * Levels.superGainAt(en)),
			dmg(st),
			two(Levels.actionAt(dx))
		];

		for (i in 0...now.length)
		{
			outNow[i].text = now[i];
			outNext[i].text = soon[i];
			var moved = now[i] != soon[i];
			outNext[i].color = moved ? LIT : DIM;
			arrows[i].color = moved ? LIT : 0xFF4A4A4A;
		}
	}

	function leave():Void
		leaving = true;

	override public function close():Void
	{
		FlxG.mouse.visible = false;
		super.close();
	}

	function arrowAt(mx:Float, my:Float):Int
	{
		if (pick >= STATS.length)
			return 0;
		var top = TOP + 137 + pick * ROW;
		if (my < top || my > top + ROW - 6)
			return 0;
		if (less.visible && mx >= LESS_X - ARROW_PAD && mx <= LESS_X + ARROW_W + ARROW_PAD)
			return -1;
		if (more.visible && mx >= MORE_X - ARROW_PAD && mx <= MORE_X + ARROW_W + ARROW_PAD)
			return 1;
		return 0;
	}

	function rowAt(mx:Float, my:Float):Int
	{
		for (i in 0...STATS.length)
		{
			var y = TOP + 137 + i * ROW;
			if (mx >= LEFT_X && mx <= LEFT_X + LEFT_W && my >= y && my <= y + ROW - 6)
				return i;
		}
		var ay = TOP + PANEL_H - 62;
		if (mx >= LEFT_X && mx <= LEFT_X + LEFT_W && my >= ay && my <= ay + 40)
			return STATS.length;
		return -1;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var step = elapsed / FADE_TIME;
		if (leaving)
		{
			fade -= step;
			if (fade <= 0)
			{
				fade = 0;
				applyFade();
				close();
				return;
			}
			applyFade();
			return;
		}

		if (fade < 1)
		{
			fade += step;
			if (fade > 1)
				fade = 1;
		}
		applyFade();

		var m = FlxG.mouse.getScreenPosition(camUI);
		var over = rowAt(m.x, m.y);
		if (over >= 0 && over != pick)
		{
			pick = over;
			refresh();
		}
		if (FlxG.mouse.justPressed)
		{
			var hit = arrowAt(m.x, m.y);
			if (hit != 0)
			{
				if (hit > 0)
					buy();
				else
					sell();
			}
			else if (over >= 0)
			{
				pick = over;
				if (pick >= STATS.length)
				{
					leave();
					return;
				}
				refresh();
			}
		}

		if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.UP)
		{
			pick = (pick + STATS.length) % (STATS.length + 1);
			refresh();
		}
		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.DOWN)
		{
			pick = (pick + 1) % (STATS.length + 1);
			refresh();
		}
		if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT)
			buy();
		if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT)
			sell();
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z)
			choose();
		if (FlxG.keys.justPressed.ESCAPE)
			leave();
	}


	function choose():Void
	{
		if (pick >= STATS.length)
		{
			leave();
			return;
		}
		buy();
	}

	function buy():Void
	{
		if (pick >= STATS.length)
			return;
		if (Levels.spend(pick))
		{
			FlxG.sound.play(util.Paths.sound("heal"), 0.6);
			if (onSpent != null)
				onSpent();
		}
		refresh();
	}

	function sell():Void
	{
		if (pick >= STATS.length)
			return;
		if (Levels.refund(pick))
		{
			FlxG.sound.play(util.Paths.sound("bulletLoad"), 0.5);
			if (onSpent != null)
				onSpent();
		}
		refresh();
	}
}
