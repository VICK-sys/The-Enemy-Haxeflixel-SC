package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.MenuList;
import util.Lang;
import util.Levels;

class LevelUpSubState extends FlxSubState
{
	static inline var ACCENT:Int = 0xFFE8C860;
	static inline var DIM:Int = 0xFFB8B8B8;

	static var KEYS:Array<String> = ["vigor", "endurance", "strength", "dexterity"];

	private var camUI:FlxCamera;
	private var list:MenuList;
	private var header:FlxText;
	private var footer:FlxText;

	public function new(camUI:FlxCamera)
	{
		super();
		this.camUI = camUI;
	}

	override public function create():Void
	{
		var shade = new FlxSprite();
		shade.makeGraphic(FlxG.width, FlxG.height, 0xE6000000);
		add(shade);

		var title = new FlxText(0, 70, FlxG.width, Lang.t("level.title"));
		title.setFormat(Lang.font(), 46, ACCENT, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		add(title);

		header = new FlxText(0, 136, FlxG.width, "");
		header.setFormat(Lang.font(), 24, FlxColor.WHITE, CENTER);
		header.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(header);

		list = new MenuList(["", "", "", "", ""], 230, 62, 30);
		list.onChoose = choose;
		add(list);

		footer = new FlxText(0, FlxG.height - 92, FlxG.width, "");
		footer.setFormat(Lang.font(), 18, DIM, CENTER);
		footer.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(footer);

		for (o in [shade, (cast title : FlxSprite), (cast header : FlxSprite), (cast footer : FlxSprite)])
			o.cameras = [camUI];
		list.cameras = [camUI];

		refresh();
		FlxG.mouse.visible = true;
		super.create();
	}

	override public function close():Void
	{
		FlxG.mouse.visible = false;
		super.close();
	}

	function refresh():Void
	{
		header.text = Lang.t("level.header", [Levels.level(), Levels.exp, Levels.costNext()]);

		for (i in 0...KEYS.length)
			list.setLabel(i, Lang.t("level.row", [Lang.t("stat." + KEYS[i]), Levels.points(i)]));
		list.setLabel(KEYS.length, Lang.t("level.done"));

		for (i in 0...KEYS.length)
			list.rowAt(i).color = Levels.canSpend() ? FlxColor.WHITE : DIM;

		footer.text = Lang.t("stat." + KEYS[list.index] + ".note");
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (list.index < KEYS.length)
			footer.text = Lang.t("stat." + KEYS[list.index] + ".note");
		if (FlxG.keys.justPressed.ESCAPE)
			close();
	}

	function choose(i:Int):Void
	{
		if (i >= KEYS.length)
		{
			close();
			return;
		}
		if (Levels.spend(i))
			FlxG.sound.play(util.Paths.sound("heal"), 0.6);
		refresh();
	}
}
