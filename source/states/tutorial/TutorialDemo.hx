package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.Paths;

class TutorialDemo extends FlxGroup
{
	public static inline var CX:Float = 640;
	public static inline var CY:Float = 340;

	private var cam:FlxCamera;
	private var time:Float = 0;

	public function new(cam:FlxCamera)
	{
		super();
		this.cam = cam;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		time += elapsed;
		step(elapsed);
	}

	function step(elapsed:Float):Void {}

	function sprite():FlxSprite
	{
		var s = new FlxSprite();
		s.antialiasing = false;
		s.cameras = [cam];
		add(s);
		return s;
	}

	function label(y:Float, size:Int, str:String):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, str);
		t.setFormat(null, size, FlxColor.WHITE, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		t.cameras = [cam];
		add(t);
		return t;
	}

	function player():FlxSprite
	{
		var p = sprite();
		p.frames = Paths.sparrow("characters/mufu");
		p.animation.addByPrefix("idle", "Idle", 12, true);
		p.animation.addByPrefix("walk", "Run", 12, true);
		p.scale.set(4, 4);
		p.width = 75;
		p.height = 95;
		p.offset.set(-19, -17);
		p.animation.play("walk");
		return p;
	}

	function center(s:FlxSprite, cx:Float, cy:Float):Void
	{
		s.setPosition(cx - s.width / 2, cy - s.height / 2);
	}
}
