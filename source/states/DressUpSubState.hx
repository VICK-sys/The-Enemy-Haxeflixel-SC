package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.HuePalette;
import util.Lang;
import util.SaveData;

class DressUpSubState extends FlxSubState
{
	public static inline var STEPS:Int = 24;

	static inline var NAME_MAX:Int = 12;
	static inline var PANEL_W:Int = 940;
	static inline var PANEL_H:Int = 490;
	static inline var CHIP_W:Int = 30;
	static inline var CHIP_H:Int = 46;
	static inline var RING:Int = 4;
	static inline var BOX_W:Int = 200;
	static inline var BOX_H:Int = 200;
	static inline var FIELD_W:Int = 470;
	static inline var FIELD_H:Int = 62;
	static inline var REPEAT_FIRST:Float = 0.30;
	static inline var REPEAT_NEXT:Float = 0.09;
	static inline var CARET_RATE:Float = 3.4;
	static inline var ARM:Float = 0.14;

	static inline var INK:Int = 0xFF12141A;
	static inline var EDGE:Int = 0xFF3C4356;
	static inline var WELL:Int = 0xFF090A0E;
	static inline var DIM:Int = 0xFF7C8497;

	public var onDone:Void->Void;

	private var camUI:FlxCamera;
	private var preview:FlxSprite;
	private var nameText:FlxText;
	private var ghostText:FlxText;
	private var caret:FlxSprite;
	private var counter:FlxText;
	private var ringBars:Array<FlxSprite> = [];
	private var chips:Array<FlxSprite> = [];

	private var pick:Int = 0;
	private var held:Float = 0;
	private var lastTurn:Int = 0;
	private var blink:Float = 0;
	private var arm:Float = ARM;
	private var stripX:Float = 0;
	private var stripY:Float = 0;
	private var previewCx:Float = 0;
	private var previewCy:Float = 0;

	public function new(camUI:FlxCamera)
	{
		super();
		this.camUI = camUI;
	}

	override public function create():Void
	{
		var px = (FlxG.width - PANEL_W) * 0.5;
		var py = (FlxG.height - PANEL_H) * 0.5;

		plate(0, 0, FlxG.width, FlxG.height, 0xE60A0B0F);
		plate(px - 3, py - 3, PANEL_W + 6, PANEL_H + 6, EDGE);
		plate(px, py, PANEL_W, PANEL_H, INK);

		var title = label(px, py + 26, PANEL_W, Lang.t("lobby.player"), 34, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);

		var boxX = px + 46;
		var boxY = py + 96;
		plate(boxX - 3, boxY - 3, BOX_W + 6, BOX_H + 6, EDGE);
		plate(boxX, boxY, BOX_W, BOX_H, WELL);

		preview = new FlxSprite();
		preview.antialiasing = false;
		preview.cameras = [camUI];
		add(preview);
		previewCx = boxX + BOX_W * 0.5;
		previewCy = boxY + BOX_H * 0.5;
		dressPreview();

		var colX = px + 290;
		label(colX, py + 128, FIELD_W, Lang.t("lobby.nameLabel"), 20, DIM, LEFT);

		var fieldY = py + 158;
		plate(colX - 3, fieldY - 3, FIELD_W + 6, FIELD_H + 6, EDGE);
		plate(colX, fieldY, FIELD_W, FIELD_H, WELL);

		ghostText = label(colX + 32, fieldY + 14, 0, Lang.t("online.defaultName"), 30, DIM, LEFT);
		ghostText.alpha = 0.35;

		nameText = label(colX + 16, fieldY + 14, 0, "", 30, FlxColor.WHITE, LEFT);

		caret = plate(colX + 16, fieldY + 13, 3, 20, FlxColor.WHITE);

		counter = label(colX, fieldY + 20, FIELD_W - 16, "", 18, DIM, RIGHT);

		stripX = px + (PANEL_W - STEPS * CHIP_W) * 0.5;
		stripY = py + 352;
		label(stripX, py + 320, STEPS * CHIP_W, Lang.t("lobby.colorLabel"), 20, DIM, LEFT);

		plate(stripX - 3, stripY - 3, STEPS * CHIP_W + 6, CHIP_H + 6, EDGE);

		for (i in 0...STEPS)
		{
			var c = new FlxSprite(stripX + i * CHIP_W, stripY);
			c.makeGraphic(CHIP_W, CHIP_H, FlxColor.fromHSB(i / STEPS * 360, 0.82, 0.98));
			c.cameras = [camUI];
			add(c);
			chips.push(c);
		}

		ringBars.push(plate(0, 0, CHIP_W + RING * 2, RING, FlxColor.WHITE));
		ringBars.push(plate(0, 0, CHIP_W + RING * 2, RING, FlxColor.WHITE));
		ringBars.push(plate(0, 0, RING, CHIP_H + RING * 2, FlxColor.WHITE));
		ringBars.push(plate(0, 0, RING, CHIP_H + RING * 2, FlxColor.WHITE));

		var hint = label(px, py + 432, PANEL_W, Lang.t("lobby.dressHints"), 18, DIM, CENTER);
		hint.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);

		pick = Math.round(SaveData.playerHue() * STEPS) % STEPS;
		if (pick < 0)
			pick += STEPS;
		placeRing();
		refreshName();

		super.create();
	}

	function plate(x:Float, y:Float, w:Float, h:Float, colour:Int):FlxSprite
	{
		var s = new FlxSprite(x, y);
		s.makeGraphic(Std.int(w), Std.int(h), colour);
		s.cameras = [camUI];
		add(s);
		return s;
	}

	function label(x:Float, y:Float, w:Float, text:String, size:Int, colour:Int, align:flixel.text.FlxTextAlign):FlxText
	{
		var t = new FlxText(x, y, w, text);
		t.setFormat(Lang.font(), size, colour, align);
		t.cameras = [camUI];
		add(t);
		return t;
	}

	function dressPreview():Void
	{
		preview.frames = HuePalette.sparrow("characters/mufu", SaveData.playerHue());
		preview.animation.addByPrefix("idle", "Idle", 9, true);
		preview.animation.play("idle", true);
		preview.scale.set(5, 5);
		preview.setPosition(previewCx - preview.frameWidth * 0.5, previewCy - preview.frameHeight * 0.5);
	}

	function placeRing():Void
	{
		var x = stripX + pick * CHIP_W - RING;
		var y = stripY - RING;
		ringBars[0].setPosition(x, y);
		ringBars[1].setPosition(x, stripY + CHIP_H);
		ringBars[2].setPosition(x, y);
		ringBars[3].setPosition(stripX + pick * CHIP_W + CHIP_W, y);
	}

	function refreshName():Void
	{
		var n = SaveData.playerName();
		nameText.text = n;
		ghostText.visible = n == "";
		counter.text = n.length + "/" + NAME_MAX;
		caret.x = nameText.x + (n == "" ? 0 : nameText.width);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (arm > 0)
			arm -= elapsed;

		blink += elapsed * CARET_RATE;
		caret.visible = Math.sin(blink) > -0.2;

		var closing = arm <= 0
			&& (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE
				|| util.Controls.justPressed(util.Controls.ACCEPT));

		colourInput(elapsed);
		if (!closing)
			nameInput();

		if (closing)
		{
			if (onDone != null)
				onDone();
			close();
		}
	}

	function colourInput(elapsed:Float):Void
	{
		var turn = 0;
		if (FlxG.keys.pressed.LEFT || util.Controls.padLeftHeld())
			turn = -1;
		else if (FlxG.keys.pressed.RIGHT || util.Controls.padRightHeld())
			turn = 1;

		if (turn == 0)
		{
			lastTurn = 0;
			held = 0;
			return;
		}

		var step = turn != lastTurn;
		if (!step)
		{
			held -= elapsed;
			if (held <= 0)
			{
				held = REPEAT_NEXT;
				step = true;
			}
		}
		else
			held = REPEAT_FIRST;

		lastTurn = turn;
		if (!step)
			return;

		pick = (pick + turn + STEPS) % STEPS;
		SaveData.setPlayerHue(pick / STEPS);
		placeRing();
		dressPreview();
	}

	function nameInput():Void
	{
		var n = SaveData.playerName();

		if (FlxG.keys.justPressed.BACKSPACE)
		{
			if (n.length > 0)
			{
				SaveData.setPlayerName(n.substr(0, n.length - 1));
				refreshName();
			}
			return;
		}

		if (n.length >= NAME_MAX)
			return;

		var k = FlxG.keys.firstJustPressed();
		var ok = (k >= 65 && k <= 90) || (k >= 48 && k <= 57) || (k == 32 && n.length > 0);
		if (!ok)
			return;

		SaveData.setPlayerName(n + String.fromCharCode(k));
		refreshName();
	}
}
