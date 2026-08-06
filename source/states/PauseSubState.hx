package states;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.MenuList;
import util.IrisWipe;
import util.Lang;
import util.Levels;
import util.Music;

class PauseSubState extends FlxSubState
{
	static inline var STATS_X:Float = 850;
	static inline var STATS_TOP:Float = 250;
	static inline var STATS_W:Float = 340;
	static inline var STATS_VALUE_W:Float = 64;
	static inline var STATS_GAP:Float = 12;
	static inline var STATS_ROW_TOP:Float = 64;
	static inline var STATS_STEP:Float = 42;
	static inline var STATS_DIM:Int = 0xFFCFCAD4;

	static var STAT_KEYS:Array<String> = ["level.level", "stat.vigor", "stat.endurance", "stat.strength", "stat.dexterity"];

	private var camUI:FlxCamera;
	private var list:MenuList;
	private var leaving:Bool = false;
	private var inLobby:Bool;
	private var afk:systems.AfkPilot;
	private var statsTitle:FlxText;
	private var statNames:Array<FlxText> = [];
	private var statValues:Array<FlxText> = [];

	public function new(camUI:FlxCamera, inLobby:Bool = false, afk:systems.AfkPilot = null)
	{
		super();
		this.camUI = camUI;
		this.inLobby = inLobby;
		this.afk = afk;
	}

	function exitKey():String
		return inLobby ? "pause.quit" : "pause.lobby";

	function rowKeys():Array<String>
	{
		var keys = ["pause.resume"];
		if (afk != null)
			keys.push("pause.afk");
		keys.push("pause.help");
		keys.push("pause.options");
		keys.push(exitKey());
		return keys;
	}

	function labelFor(key:String):String
	{
		if (key == "pause.afk")
			return Lang.t("pause.afk", [Lang.t(afk.on ? "common.on" : "common.off")]);
		return Lang.t(key);
	}

	override public function create():Void
	{
		var overlay = new FlxSprite(0, 0);
		overlay.makeGraphic(FlxG.width, FlxG.height, 0x99000000);
		overlay.cameras = [camUI];
		add(overlay);

		var title = new FlxText(0, 190, FlxG.width, Lang.t("pause.title"));
		title.setFormat(Lang.titleFont(), Lang.titleSize(), FlxColor.WHITE, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		title.cameras = [camUI];
		add(title);

		list = new MenuList([for (k in rowKeys()) labelFor(k)], afk == null ? 300 : 272, 66, Lang.bodySize());
		list.onChoose = choose;
		list.cameras = [camUI];
		add(list);
		if (!inLobby)
			addStats();

		FlxG.mouse.visible = true;
		Music.hold();

		subStateClosed.add(function(_) relabel(title));

		super.create();
	}

	function addStats():Void
	{
		statsTitle = statText(STATS_X, STATS_TOP, STATS_W, Lang.t("stats.title"), Lang.bodySize(), FlxColor.WHITE, CENTER);
		add(statsTitle);
		for (i in 0...STAT_KEYS.length)
		{
			var y = STATS_TOP + STATS_ROW_TOP + i * STATS_STEP;
			var name = statText(STATS_X, y, STATS_W - STATS_VALUE_W - STATS_GAP, "", Lang.smallSize(), STATS_DIM, LEFT);
			var value = statText(STATS_X + STATS_W - STATS_VALUE_W, y, STATS_VALUE_W, "", Lang.smallSize(), FlxColor.WHITE, RIGHT);
			statNames.push(name);
			statValues.push(value);
			add(name);
			add(value);
		}
		refreshStats();
	}

	function statText(x:Float, y:Float, width:Float, text:String, size:Int, color:Int, align:FlxTextAlign):FlxText
	{
		var out = new FlxText(x, y, width, text);
		out.setFormat(Lang.fontFor(size), size, color, align);
		out.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		out.cameras = [camUI];
		return out;
	}

	function refreshStats():Void
	{
		if (statsTitle == null)
			return;
		statsTitle.text = Lang.t("stats.title");
		statsTitle.font = Lang.bodyFont();
		for (i in 0...STAT_KEYS.length)
		{
			statNames[i].text = Lang.t(STAT_KEYS[i]);
			statNames[i].font = Lang.smallFont();
			statValues[i].text = Std.string(i == 0 ? Levels.level() : Levels.shown(i - 1));
			statValues[i].font = Lang.smallFont();
		}
	}

	override public function close():Void
	{
		FlxG.mouse.visible = false;
		Music.release();
		util.Controls.resetDevices();
		super.close();
	}

	override public function destroy():Void
	{
		Music.release();
		super.destroy();
	}

	function relabel(title:FlxText):Void
	{
		title.text = Lang.t("pause.title");
		title.font = Lang.titleFont();

		var keys = rowKeys();
		for (i in 0...keys.length)
		{
			list.rowAt(i).font = Lang.bodyFont();
			list.setLabel(i, labelFor(keys[i]));
		}
		refreshStats();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (util.Controls.menuBack() || util.Controls.pausePressed())
		{
			util.MenuSfx.cancel();
			close();
		}

	}

	function choose(i:Int):Void
	{
		if (leaving)
			return;

		switch (rowKeys()[i])
		{
			case "pause.resume":
				close();
			case "pause.afk":
				afk.set(!afk.on);
				list.setLabel(i, labelFor("pause.afk"));
			case "pause.help":
				openSubState(new TutorialSubState(camUI, true));
			case "pause.options":
				openSubState(new OptionsSubState(camUI));
			default:
				leaving = true;
				list.enabled = false;
				FlxG.mouse.visible = false;
				Music.release();
				if (util.CustomArena.fromEditor)
				{
					net.Net.stop();
					new IrisWipe(this).close(function() FlxG.switchState(() -> new EditorState()));
				}
				else if (inLobby)
				{
					net.Net.stop();
					util.Lobby.leave();
					new IrisWipe(this).close(function() FlxG.switchState(() -> new MainMenuState()));
				}
				else
				{
					if (net.Net.isHost)
					{
						net.Net.send({t: "toLobby"});
						net.Net.inGame = false;
					}
					else if (net.Net.isClient)
						net.Net.stop();
					new IrisWipe(this).close(function() FlxG.switchState(() -> new LobbyState()));
				}
		}
	}
}
