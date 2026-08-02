package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.HuePalette;
import util.Lang;
import util.SaveData;

class DressUpSubState extends LobbyPanel
{
	public static inline var STEPS:Int = 24;

	static inline var NAME_MAX:Int = 12;
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


	public var onDone:Void->Void;

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
	private var stripX:Float = 0;
	private var stripY:Float = 0;
	private var previewCx:Float = 0;
	private var previewCy:Float = 0;

	public function new(camUI:FlxCamera)
	{
		super(camUI, 940, 490);
	}

	override public function create():Void
	{
		chrome("lobby.player");

		var boxX = px + 46;
		var boxY = py + 96;
		well(boxX, boxY, BOX_W, BOX_H);

		preview = new FlxSprite();
		preview.antialiasing = false;
		preview.cameras = [camUI];
		add(preview);
		previewCx = boxX + BOX_W * 0.5;
		previewCy = boxY + BOX_H * 0.5;
		dressPreview();

		var colX = px + 290;
		label(colX, py + 128, FIELD_W, Lang.t("lobby.nameLabel"), 20, LobbyPanel.DIM, LEFT);

		var fieldY = py + 158;
		well(colX, fieldY, FIELD_W, FIELD_H);

		ghostText = label(colX + 32, fieldY + 14, 0, Lang.t("online.defaultName"), 30, LobbyPanel.DIM, LEFT);
		ghostText.alpha = 0.35;

		nameText = label(colX + 16, fieldY + 14, 0, "", 30, FlxColor.WHITE, LEFT);

		caret = plate(colX + 16, fieldY + 13, 3, 20, FlxColor.WHITE);

		counter = label(colX, fieldY + 20, FIELD_W - 16, "", 18, LobbyPanel.DIM, RIGHT);

		stripX = px + (panelW - STEPS * CHIP_W) * 0.5;
		stripY = py + 352;
		label(stripX, py + 320, STEPS * CHIP_W, Lang.t("lobby.colorLabel"), 20, LobbyPanel.DIM, LEFT);

		plate(stripX - 3, stripY - 3, STEPS * CHIP_W + 6, CHIP_H + 6, LobbyPanel.EDGE);

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

		hints(Lang.t("lobby.dressHints"), py + 432);

		pick = Math.round(SaveData.playerHue() * STEPS) % STEPS;
		if (pick < 0)
			pick += STEPS;
		placeRing();
		refreshName();

		super.create();
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

		tickArm(elapsed);

		blink += elapsed * CARET_RATE;
		caret.visible = Math.sin(blink) > -0.2;

		var closing = armed()
			&& (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE
				|| util.Controls.justPressed(util.Controls.ACCEPT));

		colourInput(elapsed);
		if (!closing)
			nameInput(elapsed);

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

	function nameInput(elapsed:Float):Void
	{
		var n = SaveData.playerName();

		if (eraseWanted(elapsed))
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
