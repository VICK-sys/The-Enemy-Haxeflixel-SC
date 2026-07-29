package systems;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import entities.Player;
import ui.DialogueBox;
import util.Lang;

class TreeMan
{
	static inline var REACH:Float = 190;
	static inline var BEHIND:Float = 44;
	static inline var STAGES:Int = 4;

	public static var told:Int = 0;

	public static function reset():Void
		told = 0;

	public var talking(get, never):Bool;

	function get_talking():Bool
		return box.open;

	public var gone(get, never):Bool;

	function get_gone():Bool
		return told >= STAGES;

	private var player:Player;
	private var box:DialogueBox;
	private var spotX:Float;
	private var spotY:Float;

	public function new(state:FlxState, cam:FlxCamera, player:Player, treeX:Float, treeFeetY:Float)
	{
		this.player = player;
		spotX = treeX;
		spotY = treeFeetY - BEHIND;
		box = new DialogueBox(state, cam);
	}

	public function update(elapsed:Float):Void
	{
		if (box.open)
		{
			player.blockMovement = true;
			box.update(elapsed);
			if (!box.open)
				player.blockMovement = false;
			return;
		}

		if (gone)
			return;

		var dx = player.x + player.width * 0.5 - spotX;
		var dy = player.feetY - spotY;
		if (dx * dx + dy * dy > REACH * REACH)
			return;

		if (util.Controls.acceptJustPressed())
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
