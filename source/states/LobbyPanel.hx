package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.Lang;

class LobbyPanel extends FlxSubState
{
	static inline var DEL_FIRST:Float = 0.35;
	static inline var DEL_NEXT:Float = 0.045;

	public static inline var INK:Int = 0xFF12141A;
	public static inline var EDGE:Int = 0xFF3C4356;
	public static inline var WELL:Int = 0xFF090A0E;
	public static inline var DIM:Int = 0xFF7C8497;
	public static inline var BAD:Int = 0xFFE06060;
	public static inline var GOOD:Int = 0xFF8FD46A;

	private var camUI:FlxCamera;
	private var panelW:Int;
	private var panelH:Int;
	private var px:Float = 0;
	private var py:Float = 0;
	private var delHold:Float = 0;

	public function new(camUI:FlxCamera, panelW:Int, panelH:Int)
	{
		super();
		this.camUI = camUI;
		this.panelW = panelW;
		this.panelH = panelH;
	}

	function chrome(titleKey:String):Void
	{
		px = (FlxG.width - panelW) * 0.5;
		py = (FlxG.height - panelH) * 0.5;

		plate(0, 0, FlxG.width, FlxG.height, 0xE60A0B0F);
		plate(px - 3, py - 3, panelW + 6, panelH + 6, EDGE);
		plate(px, py, panelW, panelH, INK);

		var title = label(px, py + 26, panelW, Lang.t(titleKey), 34, FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
	}

	function hints(text:String, y:Float):FlxText
	{
		var t = label(px, y, panelW, text, 18, DIM, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		return t;
	}

	function plate(x:Float, y:Float, w:Float, h:Float, color:Int):FlxSprite
	{
		var s = new FlxSprite(x, y);
		s.makeGraphic(Std.int(w), Std.int(h), color);
		s.cameras = [camUI];
		add(s);
		return s;
	}

	function well(x:Float, y:Float, w:Float, h:Float):FlxSprite
	{
		plate(x - 3, y - 3, w + 6, h + 6, EDGE);
		return plate(x, y, w, h, WELL);
	}

	function label(x:Float, y:Float, w:Float, text:String, size:Int, color:Int, align:flixel.text.FlxTextAlign):FlxText
	{
		var t = new FlxText(x, y, w, text);
		t.setFormat(Lang.font(), size, color, align);
		t.cameras = [camUI];
		add(t);
		return t;
	}

	function eraseWanted(elapsed:Float):Bool
	{
		if (!FlxG.keys.pressed.BACKSPACE)
		{
			delHold = 0;
			return false;
		}
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			delHold = DEL_FIRST;
			return true;
		}
		delHold -= elapsed;
		if (delHold > 0)
			return false;
		delHold = DEL_NEXT;
		return true;
	}

	function armed():Bool
		return true;

	function tickArm(elapsed:Float):Void {}
}
