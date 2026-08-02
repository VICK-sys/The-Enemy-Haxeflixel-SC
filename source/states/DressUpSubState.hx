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
	static inline var SKIN_H:Int = 52;
	static inline var HALF_GAP:Int = 20;
	static inline var HALF_W:Int = (FIELD_W - HALF_GAP) >> 1;
	static inline var PREVIEW_SCALE:Float = 5;
	static inline var GEAR_DX:Float = -21.25;
	static inline var GEAR_DY:Float = 32.5;
	static inline var ROW_SKIN:Int = 0;
	static inline var ROW_GEAR:Int = 1;
	static inline var ROW_COLOR:Int = 2;
	static inline var ROWS:Int = 3;

	public var onDone:Void->Void;

	private var preview:FlxSprite;
	private var nameText:FlxText;
	private var ghostText:FlxText;
	private var caret:FlxSprite;
	private var counter:FlxText;
	private var skinText:FlxText;
	private var gearText:FlxText;
	private var skinLabel:FlxText;
	private var gearLabel:FlxText;
	private var colorLabel:FlxText;
	private var skinArrows:Array<FlxText> = [];
	private var gearArrows:Array<FlxText> = [];
	private var previewGear:systems.BackGear;
	private var ringBars:Array<FlxSprite> = [];
	private var chips:Array<FlxSprite> = [];

	private var pick:Int = 0;
	private var skin:Int = 0;
	private var gear:Int = 0;
	private var focus:Int = ROW_COLOR;
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

		skin = SaveData.playerSkin();
		gear = SaveData.playerGear();

		var boxX = px + 46;
		var boxY = py + 96;
		well(boxX, boxY, BOX_W, BOX_H);

		previewCx = boxX + BOX_W * 0.5;
		previewCy = boxY + BOX_H * 0.5;

		previewGear = new systems.BackGear();
		previewGear.sprite.cameras = [camUI];
		add(previewGear.sprite);

		preview = new FlxSprite();
		preview.antialiasing = false;
		preview.cameras = [camUI];
		add(preview);
		dressPreview();

		var colX = px + 290;
		label(colX, py + 118, FIELD_W, Lang.t("lobby.nameLabel"), 20, LobbyPanel.DIM, LEFT);

		var fieldY = py + 146;
		well(colX, fieldY, FIELD_W, FIELD_H);

		ghostText = label(colX + 32, fieldY + 14, 0, Lang.t("online.defaultName"), 30, LobbyPanel.DIM, LEFT);
		ghostText.alpha = 0.35;

		nameText = label(colX + 16, fieldY + 14, 0, "", 30, FlxColor.WHITE, LEFT);

		caret = plate(colX + 16, fieldY + 13, 3, 20, FlxColor.WHITE);

		counter = label(colX, fieldY + 20, FIELD_W - 16, "", 18, LobbyPanel.DIM, RIGHT);

		var modelY = fieldY + 108;
		var gearX = colX + HALF_W + HALF_GAP;

		skinLabel = label(colX, modelY - 30, HALF_W, Lang.t("lobby.skinLabel"), 20, LobbyPanel.DIM, LEFT);
		well(colX, modelY, HALF_W, SKIN_H);
		skinArrows.push(label(colX + 12, modelY + 14, 0, "<", 24, LobbyPanel.DIM, LEFT));
		skinArrows.push(label(colX + HALF_W - 26, modelY + 14, 0, ">", 24, LobbyPanel.DIM, LEFT));
		skinText = label(colX, modelY + 14, HALF_W, "", 24, FlxColor.WHITE, CENTER);

		gearLabel = label(gearX, modelY - 30, HALF_W, Lang.t("lobby.gearLabel"), 20, LobbyPanel.DIM, LEFT);
		well(gearX, modelY, HALF_W, SKIN_H);
		gearArrows.push(label(gearX + 12, modelY + 14, 0, "<", 24, LobbyPanel.DIM, LEFT));
		gearArrows.push(label(gearX + HALF_W - 26, modelY + 14, 0, ">", 24, LobbyPanel.DIM, LEFT));
		gearText = label(gearX, modelY + 14, HALF_W, "", 24, FlxColor.WHITE, CENTER);

		stripX = px + (panelW - STEPS * CHIP_W) * 0.5;
		stripY = py + 352;
		colorLabel = label(stripX, py + 320, STEPS * CHIP_W, Lang.t("lobby.colorLabel"), 20, LobbyPanel.DIM, LEFT);

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

		refreshSkin();
		refreshFocus();

		pick = Math.round(SaveData.playerHue() * STEPS) % STEPS;
		if (pick < 0)
			pick += STEPS;
		placeRing();
		refreshName();

		super.create();
	}

	function dressPreview():Void
	{
		previewGear.paint(SaveData.playerHue(), skin, gear);
		preview.frames = HuePalette.sparrow(util.Skins.of(skin), SaveData.playerHue());
		preview.animation.addByPrefix("idle", "Idle", 9, true);
		preview.animation.play("idle", true);
		preview.scale.set(5, 5);
		preview.setPosition(previewCx - preview.frameWidth * 0.5, previewCy - preview.frameHeight * 0.5);
	}

	function refreshSkin():Void
	{
		skinText.text = util.Skins.nameOf(skin);
		gearText.text = util.Skins.gearNameOf(gear);
	}

	function refreshFocus():Void
	{
		skinLabel.color = focus == ROW_SKIN ? FlxColor.WHITE : LobbyPanel.DIM;
		gearLabel.color = focus == ROW_GEAR ? FlxColor.WHITE : LobbyPanel.DIM;
		colorLabel.color = focus == ROW_COLOR ? FlxColor.WHITE : LobbyPanel.DIM;
		for (a in skinArrows)
			a.color = focus == ROW_SKIN ? FlxColor.WHITE : LobbyPanel.DIM;
		for (a in gearArrows)
			a.color = focus == ROW_GEAR ? FlxColor.WHITE : LobbyPanel.DIM;
		for (b in ringBars)
			b.color = focus == ROW_COLOR ? FlxColor.WHITE : LobbyPanel.DIM;
	}

	function focusInput():Void
	{
		var step = 0;
		if (FlxG.keys.justPressed.UP || util.Controls.padUpJust())
			step = -1;
		else if (FlxG.keys.justPressed.DOWN || util.Controls.padDownJust())
			step = 1;
		if (step == 0)
			return;
		focus = (focus + step + ROWS) % ROWS;
		refreshFocus();
		util.MenuSfx.hover();
	}

	function turnModel(turn:Int):Void
	{
		if (focus == ROW_SKIN)
		{
			skin = (skin + turn + util.Skins.count()) % util.Skins.count();
			SaveData.setPlayerSkin(skin);
		}
		else
		{
			gear = (gear + turn + util.Skins.gearCount()) % util.Skins.gearCount();
			SaveData.setPlayerGear(gear);
		}
		refreshSkin();
		dressPreview();
		util.MenuSfx.hover();
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

		previewGear.sprite.scale.set(PREVIEW_SCALE, PREVIEW_SCALE);
		previewGear.update(elapsed, previewCx + GEAR_DX + 20, previewCy + GEAR_DY - 11, false, 0, true, 0, 0, 0, "idle");

		if (!closing)
			focusInput();
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

		if (focus != ROW_COLOR)
		{
			turnModel(turn);
			return;
		}

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
