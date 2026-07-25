package states.editor;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class EditorHud
{
	private var slotText:FlxText;
	private var toolText:FlxText;
	private var help:FlxText;
	private var helpBar:FlxSprite;
	private var flashText:FlxText;
	private var flashTimer:Float = 0;
	private var flashTime:Float;

	public function new(state:FlxState, cam:FlxCamera, flashTime:Float)
	{
		this.flashTime = flashTime;

		slotText = text(state, cam, 12, 8, 560, LEFT, 18);
		toolText = text(state, cam, FlxG.width - 452, 8, 440, RIGHT, 18);

		helpBar = new FlxSprite(0, FlxG.height - 52);
		helpBar.makeGraphic(FlxG.width, 52, 0xBB0E0A12);
		helpBar.cameras = [cam];
		state.add(helpBar);

		help = text(state, cam, 0, FlxG.height - 46, FlxG.width, CENTER, 15);
		flashText = text(state, cam, 0, 60, FlxG.width, CENTER, 26);
	}

	static function text(state:FlxState, cam:FlxCamera, x:Float, y:Float, w:Float, align:FlxTextAlign, size:Int):FlxText
	{
		var t = new FlxText(x, y, w, "");
		t.setFormat(null, size, FlxColor.WHITE, align);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		t.cameras = [cam];
		state.add(t);
		return t;
	}

	public function flash(msg:String):Void
	{
		flashText.text = msg;
		flashTimer = flashTime;
	}

	public function setHelp(modeLine:String):Void
	{
		help.text = modeLine
			+ "\nP MODE   WHEEL ZOOM   SPACE-DRAG PAN   0 RESET VIEW   X SPAWN   Z UNDO   1-5 SLOTS   T THEME   S SAVE   ENTER PLAY   ESC BACK";
	}

	public function setStatus(left:String, right:String):Void
	{
		slotText.text = left;
		toolText.text = right;
	}

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
