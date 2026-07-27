package systems;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import entities.Player;
import ui.DialogueBox;
import util.Lang;

class TreeMan
{
	static inline var REACH:Float = 190;
	static inline var BEHIND:Float = 44;
	static inline var PROMPT_Y:Float = 96;
	static inline var STAGES:Int = 4;

	public static var told:Int = 0;

	public var talking(get, never):Bool;

	function get_talking():Bool
		return box.open;

	public var gone(get, never):Bool;

	function get_gone():Bool
		return told >= STAGES;

	private var player:Player;
	private var box:DialogueBox;
	private var prompt:FlxText;
	private var spotX:Float;
	private var spotY:Float;
	private var here:Bool = false;

	public function new(state:FlxState, cam:FlxCamera, player:Player, treeX:Float, treeFeetY:Float)
	{
		this.player = player;
		spotX = treeX;
		spotY = treeFeetY - BEHIND;

		box = new DialogueBox(state, cam);

		prompt = new FlxText(0, FlxG.height - PROMPT_Y, FlxG.width, "");
		prompt.setFormat(Lang.font(), 20, FlxColor.WHITE, CENTER);
		prompt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		prompt.cameras = [cam];
		prompt.scrollFactor.set();
		prompt.visible = false;
		state.add(prompt);
	}

	public function update(elapsed:Float):Void
	{
		if (box.open)
		{
			player.blockMovement = true;
			prompt.visible = false;
			box.update(elapsed);
			if (!box.open)
				player.blockMovement = false;
			return;
		}

		if (gone)
		{
			prompt.visible = false;
			return;
		}

		var dx = player.x + player.width * 0.5 - spotX;
		var dy = player.feetY - spotY;
		here = dx * dx + dy * dy <= REACH * REACH;

		prompt.visible = here;
		if (!here)
			return;

		prompt.text = Lang.t("talk.prompt");
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z)
			speak();
	}

	function speak():Void
	{
		var lines = [];
		var n = 1;
		while (true)
		{
			var key = "talk.man" + told + "." + n;
			var line = Lang.t(key);
			if (line == key)
				break;
			lines.push(line);
			n++;
		}
		told++;
		if (lines.length > 0)
			box.start(lines);
	}
}
