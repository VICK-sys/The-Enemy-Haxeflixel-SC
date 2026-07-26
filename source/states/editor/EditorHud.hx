package states.editor;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class EditorHud
{
	public static inline var BAR:Int = 34;

	static var KEYS:Array<String> = [
		"P", "WHEEL", "SPACE-DRAG", "ARROWS", "0", "X", "CTRL+Z", "CTRL-DRAG", "CTRL+C", "CTRL+V", "Q", "DEL", "H", "C", "L",
		"1-5", "S", "ENTER", "ESC"
	];
	static var ACTIONS:Array<String> = [
		"CYCLE MODE", "ZOOM IN / OUT", "PAN THE VIEW", "PAN THE VIEW", "RESET THE VIEW", "MOVE THE SPAWN POINT", "UNDO",
		"SELECT TILES ON THE MAP", "COPY THE SELECTION", "PASTE AT THE CURSOR", "HOLD / DROP THE PROP IN HAND",
		"REMOVE THE SELECTED PROP", "EDIT THAT PROP'S HITBOX", "CLEAR THE MAP", "COPY THE STOCK STAGE",
		"SWITCH SLOT", "SAVE", "PLAY THE MAP", "BACK TO MENU"
	];

	private var hintBar:FlxSprite;
	private var hint:FlxText;
	private var sheet:FlxSprite;
	private var sheetEdge:FlxSprite;
	private var sheetTitle:FlxText;
	private var sheetKeys:FlxText;
	private var sheetActions:FlxText;
	private var flashText:FlxText;
	private var flashTimer:Float = 0;
	private var flashTime:Float;
	private var state:FlxState;

	public function new(state:FlxState, cam:FlxCamera, flashTime:Float, leftInset:Float, topInset:Float)
	{
		this.flashTime = flashTime;
		this.state = state;

		var canvasW = FlxG.width - leftInset;

		hintBar = new FlxSprite(leftInset, FlxG.height - BAR);
		hintBar.makeGraphic(Std.int(canvasW), BAR, 0xFF161616);
		hintBar.cameras = [cam];
		state.add(hintBar);

		hint = new FlxText(leftInset, FlxG.height - BAR + 8, canvasW, "");
		hint.setFormat(null, 14, 0xFFB8B8B8, CENTER);
		hint.cameras = [cam];
		state.add(hint);

		flashText = new FlxText(leftInset, topInset + 22, canvasW, "");
		flashText.setFormat(null, 26, FlxColor.WHITE, CENTER);
		flashText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		flashText.cameras = [cam];
		state.add(flashText);

		var pw = 540;
		var ph = 450;
		var panelX = leftInset + (canvasW - pw) / 2;
		var panelY = topInset + (FlxG.height - topInset - BAR - ph) / 2;

		sheetEdge = new FlxSprite(panelX - 2, panelY - 2);
		sheetEdge.makeGraphic(pw + 4, ph + 4, 0xFF3D3D3D);
		sheetEdge.cameras = [cam];
		state.add(sheetEdge);

		sheet = new FlxSprite(panelX, panelY);
		sheet.makeGraphic(pw, ph, 0xFA161616);
		sheet.cameras = [cam];
		state.add(sheet);

		sheetTitle = new FlxText(panelX, panelY + 14, pw, "CONTROLS");
		sheetTitle.setFormat(null, 20, FlxColor.WHITE, CENTER);
		sheetTitle.cameras = [cam];
		state.add(sheetTitle);

		sheetKeys = new FlxText(panelX + 18, panelY + 54, 168, KEYS.join("\n"));
		sheetKeys.setFormat(null, 15, FlxColor.WHITE, RIGHT);
		sheetKeys.cameras = [cam];
		state.add(sheetKeys);

		sheetActions = new FlxText(panelX + 208, panelY + 54, pw - 222, ACTIONS.join("\n"));
		sheetActions.setFormat(null, 15, 0xFFB8B8B8, LEFT);
		sheetActions.cameras = [cam];
		state.add(sheetActions);

		showSheet(false);
	}

	public function raiseFlash():Void
	{
		state.remove(flashText);
		state.add(flashText);
	}

	public function toggleSheet():Void
		showSheet(!sheet.visible);

	function showSheet(on:Bool):Void
	{
		sheetEdge.visible = on;
		sheet.visible = on;
		sheetTitle.visible = on;
		sheetKeys.visible = on;
		sheetActions.visible = on;
	}

	public function modal():Bool
		return sheet.visible;

	public function flash(msg:String):Void
	{
		flashText.text = msg;
		flashTimer = flashTime;
	}

	public function setHint(line:String):Void
		hint.text = line;

	public function update(elapsed:Float):Void
	{
		if (flashTimer <= 0)
			return;
		flashTimer -= elapsed;
		flashText.alpha = flashTimer < 0.4 ? flashTimer / 0.4 : 1;
		if (flashTimer <= 0)
			flashText.text = "";
	}
}
