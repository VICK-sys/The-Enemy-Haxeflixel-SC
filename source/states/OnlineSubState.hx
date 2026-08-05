package states;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import net.Net;
import ui.MenuList;
import util.Lang;

class OnlineSubState extends FlxSubState
{
	public var onHost:Void->Void;
	public var onJoin:Void->Void;

	private var camUI:FlxCamera;
	private var list:MenuList;

	public function new(camUI:FlxCamera)
	{
		super();
		this.camUI = camUI;
	}

	function canHost():Bool
		return !Net.isClient;

	function canJoin():Bool
		return Net.mode == Off;

	function noteKey():String
	{
		if (Net.isClient)
			return "lobby.onlineJoined";
		if (Net.mode != Off)
			return "lobby.onlineHosting";
		return null;
	}

	override public function create():Void
	{
		var overlay = new FlxSprite(0, 0);
		overlay.makeGraphic(FlxG.width, FlxG.height, 0x99000000);
		overlay.cameras = [camUI];
		add(overlay);

		var title = new FlxText(0, 210, FlxG.width, Lang.t("lobby.online"));
		title.setFormat(Lang.titleFont(), Lang.titleSize(), FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		title.cameras = [camUI];
		add(title);

		var note = noteKey();
		if (note != null)
		{
			var line = new FlxText(0, 276, FlxG.width, Lang.t(note));
			line.setFormat(Lang.smallFont(), Lang.smallSize(), FlxColor.WHITE, CENTER);
			line.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			line.alpha = 0.75;
			line.cameras = [camUI];
			add(line);
		}

		list = new MenuList([Lang.t("online.host"), Lang.t("online.join"), Lang.t("lobby.onlineBack")], 330, 66, Lang.bodySize());
		list.onChoose = choose;
		list.cameras = [camUI];
		list.setSkip(0, !canHost());
		list.setSkip(1, !canJoin());
		list.settle();
		add(list);

		FlxG.mouse.visible = true;
		super.create();
	}

	override public function close():Void
	{
		FlxG.mouse.visible = false;
		util.Controls.resetDevices();
		super.close();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (util.Controls.menuBack())
		{
			util.MenuSfx.cancel();
			close();
		}
	}

	function choose(i:Int):Void
	{
		var act = i == 0 ? onHost : (i == 1 ? onJoin : null);
		close();
		if (act != null)
			act();
	}
}
