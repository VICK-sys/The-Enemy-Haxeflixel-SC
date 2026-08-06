package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.Paths;
import util.Lang;
import ui.MenuCursor;

private class Card
{
	public var edge:FlxSprite;
	public var bg:FlxSprite;
	public var icon:FlxSprite;
	public var label:FlxText;
	public var record:FlxText;
	public var ring:Array<FlxSprite> = [];
	public var baseY:Float = 0;
	public var off:Float = 0;

	public function new() {}
}

class WeaponPickSubState extends FlxSubState
{
	public static var lastPick(get, set):Int;

	static function get_lastPick():Int
		return util.SaveData.playerWeapon();

	static function set_lastPick(i:Int):Int
	{
		util.SaveData.setPlayerWeapon(i);
		return i;
	}

	static inline var ACCENT:Int = 0xFFB2273A;

	static function accent():FlxColor
	{
		var c:FlxColor = ACCENT;
		c.hue = c.hue + util.SaveData.playerHue() * 360;
		return c;
	}

	static inline var CARD:Int = 0xFF4A4550;
	static inline var CARD_ON:Int = 0xFF6E6478;
	static inline var TEXT_DIM:Int = 0xFFCFCAD4;

	static inline var ICON_SCALE:Int = 3;
	static inline var OUTLINE_PX:Float = ICON_SCALE;
	static inline var OUTLINE_COLOR:Int = 0xFBFBFB;

	static inline var CARD_W:Int = 288;
	static inline var CARD_H:Int = 300;
	static inline var CARD_GAP:Int = 20;
	static inline var CARD_TOP:Float = 210;
	static inline var ICON_TOP:Float = 40;
	static inline var LABEL_TOP:Float = 200;
	static inline var BLURB_TOP:Float = 240;
	static inline var RECORD_TOP:Float = -2;
	static inline var RECORD_LEFT:Float = 12;
	static inline var RECORD_RIGHT:Float = 64;
	static inline var RECORD_ALPHA:Float = 0.55;
	static inline var HAMMER_ICON_DROP:Float = 5;

	static inline var FLOAT_AMP:Float = 7;
	static inline var FLOAT_SPEED:Float = 3.2;
	static inline var FLOAT_EASE:Float = 12;

	static var OUTLINE_DIRS:Array<Array<Int>> = [
		[-1, 0], [1, 0], [0, -1], [0, 1],
		[-1, -1], [1, -1], [-1, 1], [1, 1]
	];

	static var KEYS:Array<String> = ["hammer", "revolver", "crossbow", "hook"];
	static var ORDER:Array<Int> = [1, 2, 0, 3];

	static function slotOf(weapon:Int):Int
	{
		for (i in 0...ORDER.length)
			if (ORDER[i] == weapon)
				return i;
		return 0;
	}

	public static function nameOf(i:Int):String
		return Lang.t("weapon." + KEYS[i >= 0 && i < KEYS.length ? i : 0]);

	static function blurbOf(i:Int):String
		return Lang.t("weapon." + KEYS[i] + ".blurb");

	public static function artOf(i:Int):String
		return i >= 0 && i < ART.length ? ART[i] : ART[0];

	public static function slots():Int
		return ORDER.length;

	public static function artInSlot(slot:Int):String
		return artOf(ORDER[slot >= 0 && slot < ORDER.length ? slot : 0]);

	static var ART:Array<String> = ["items/hammer", "items/revolver", "items/crossbow", "items/yoyo"];

	public var onPicked:Int->Void;
	public var pickedX(default, null):Float = 0;
	public var pickedY(default, null):Float = 0;
	public var cancelled(default, null):Bool = false;

	private var camUI:FlxCamera;
	private var cards:Array<Card> = [];
	private var bob:Float = 0;
	private var pick:Int = 0;
	private var done:Bool = false;
	private var lastMouseX:Float = -99999;
	private var lastMouseY:Float = -99999;

	public function new(camUI:FlxCamera)
	{
		super();
		this.camUI = camUI;
	}

	override public function create():Void
	{
		pick = slotOf(lastPick);

		var overlay = new FlxSprite(0, 0);
		overlay.makeGraphic(FlxG.width, FlxG.height, 0xDD000000);
		overlay.cameras = [camUI];
		add(overlay);

		var title = uiText(96, Lang.titleSize(), Lang.t("weaponPick.title"));
		title.font = Lang.titleFont();
		uiText(150, Lang.smallSize(), Lang.t("weaponPick.sub"));

		var total = KEYS.length * CARD_W + (KEYS.length - 1) * CARD_GAP;
		var x0 = (FlxG.width - total) / 2;
		for (i in 0...KEYS.length)
			cards.push(buildCard(i, x0 + i * (CARD_W + CARD_GAP)));

		uiText(560, Lang.smallSize(), Lang.t("weaponPick.hint"));

		refresh();
		FlxG.mouse.visible = true;
		super.create();
	}

	override public function close():Void
	{
		FlxG.mouse.visible = false;
		super.close();
	}

	function buildCard(slot:Int, x:Float):Card
	{
		var i = ORDER[slot];
		var c = new Card();

		c.edge = new FlxSprite(x - 3, CARD_TOP - 3);
		c.edge.makeGraphic(CARD_W + 6, CARD_H + 6, accent());
		ui(c.edge);

		c.bg = new FlxSprite(x, CARD_TOP);
		c.bg.makeGraphic(CARD_W, CARD_H, CARD);
		ui(c.bg);

		var best = util.Stats.weaponBest(i);
		c.record = new FlxText(x + RECORD_LEFT, CARD_TOP + RECORD_TOP, CARD_W - RECORD_RIGHT,
			Lang.t("weaponPick.record", [best > 0 ? Std.string(best) : "-"]));
		c.record.setFormat(Lang.smallFont(), Lang.smallSize(), TEXT_DIM, LEFT);
		c.record.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		c.record.alpha = RECORD_ALPHA;
		ui(c.record);

		for (d in OUTLINE_DIRS)
		{
			var o = art(i);
			o.setColorTransform(0, 0, 0, 1, (OUTLINE_COLOR >> 16) & 0xFF, (OUTLINE_COLOR >> 8) & 0xFF, OUTLINE_COLOR & 0xFF, 0);
			o.x = x + (CARD_W - o.width) / 2 + d[0] * OUTLINE_PX;
			o.y = CARD_TOP + ICON_TOP + d[1] * OUTLINE_PX;
			c.ring.push(ui(o));
		}

		c.icon = art(i);
		c.icon.x = x + (CARD_W - c.icon.width) / 2;
		c.icon.y = CARD_TOP + ICON_TOP + (i == 0 ? HAMMER_ICON_DROP : 0);
		ui(c.icon);
		c.baseY = c.icon.y;

		c.label = new FlxText(x, CARD_TOP + LABEL_TOP, CARD_W, nameOf(i));
		c.label.setFormat(Lang.bodyFont(), Lang.bodySize(), FlxColor.WHITE, CENTER);
		c.label.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		ui(c.label);

		var blurb = new FlxText(x + 8, CARD_TOP + BLURB_TOP, CARD_W - 16, blurbOf(i));
		blurb.setFormat(Lang.smallFont(), Lang.smallSize(), TEXT_DIM, CENTER);
		ui(blurb);

		var num = new FlxText(x, CARD_TOP + 8, CARD_W - 12, "" + (slot + 1));
		num.setFormat(Lang.smallFont(), Lang.smallSize(), TEXT_DIM, RIGHT);
		ui(num);

		return c;
	}

	function art(i:Int):FlxSprite
	{
		var s = new FlxSprite(0, CARD_TOP + ICON_TOP, util.HuePalette.graphic(ART[i], util.SaveData.playerHue()));
		s.scale.set(ICON_SCALE, ICON_SCALE);
		s.updateHitbox();
		s.antialiasing = false;
		return s;
	}

	function ui<T:FlxSprite>(o:T):T
	{
		o.cameras = [camUI];
		add(o);
		return o;
	}

	function uiText(y:Float, size:Int, s:String):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, s);
		t.setFormat(Lang.fontFor(size), size, FlxColor.WHITE, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		return ui(t);
	}

	function refresh():Void
	{
		for (i in 0...cards.length)
		{
			var c = cards[i];
			var on = i == pick;
			c.edge.visible = on;
			c.bg.color = on ? CARD_ON : CARD;
			c.label.color = on ? FlxColor.WHITE : TEXT_DIM;
			c.record.color = on ? FlxColor.WHITE : TEXT_DIM;
			c.icon.alpha = on ? 1 : 0.55;
			for (o in c.ring)
				o.visible = on;
		}
	}

	function move(d:Int):Void
		set((pick + d + KEYS.length) % KEYS.length);

	function set(i:Int):Void
	{
		if (i == pick)
			return;
		pick = i;
		bob = 0;
		util.MenuSfx.hover();
		refresh();
	}

	function hovered():Int
	{
		var m = FlxG.mouse.getViewPosition(camUI);
		for (i in 0...cards.length)
		{
			var b = cards[i].bg;
			if (m.x >= b.x && m.x <= b.x + b.width && m.y >= b.y && m.y <= b.y + b.height)
				return i;
		}
		return -1;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (done)
			return;

		updateFloat(elapsed);

		updateInput();
	}

	function updateFloat(elapsed:Float):Void
	{
		bob += elapsed * FLOAT_SPEED;
		var k = 1 - Math.exp(-FLOAT_EASE * elapsed);

		for (i in 0...cards.length)
		{
			var c = cards[i];
			var want = i == pick ? Math.sin(bob) * FLOAT_AMP : 0;
			c.off += (want - c.off) * k;
			c.icon.y = c.baseY + c.off;

			if (i != pick)
				continue;
			for (n in 0...c.ring.length)
			{
				c.ring[n].x = c.icon.x + OUTLINE_DIRS[n][0] * OUTLINE_PX;
				c.ring[n].y = c.icon.y + OUTLINE_DIRS[n][1] * OUTLINE_PX;
			}
		}
	}

	function updateInput():Void
	{
		if (util.Controls.menuBack())
		{
			util.MenuSfx.cancel();
			cancelled = true;
			done = true;
			close();
			return;
		}

		if (util.Controls.menuLeftJust())
			move(-1);
		if (util.Controls.menuRightJust())
			move(1);

		if (FlxG.keys.justPressed.ONE)
			set(0);
		if (FlxG.keys.justPressed.TWO)
			set(1);
		if (FlxG.keys.justPressed.THREE)
			set(2);
		if (FlxG.keys.justPressed.FOUR)
			set(3);

		var over = hovered();
		if (over >= 0)
			MenuCursor.markHover();
		if (FlxG.mouse.x != lastMouseX || FlxG.mouse.y != lastMouseY)
		{
			lastMouseX = FlxG.mouse.x;
			lastMouseY = FlxG.mouse.y;
			if (over >= 0)
				set(over);
		}

		if (util.Controls.menuAccept() || FlxG.keys.justPressed.SPACE || (FlxG.mouse.justPressed && over >= 0))
			confirm();
	}

	function confirm():Void
	{
		util.MenuSfx.click();
		done = true;
		lastPick = ORDER[pick];
		var icon = cards[pick].icon;
		pickedX = icon.x + icon.width * 0.5;
		pickedY = icon.y + icon.height * 0.5;
		if (onPicked != null)
			onPicked(lastPick);
		close();
	}
}
