package states.play;

import net.Net;
import systems.weapons.Weapons;
import ui.Hud;
import ui.WeaponFlyIn;
import util.DiscordPresence;

class RunIntro
{
	static inline var INTRO_LOCK:Float = 1.0;

	public var flyIn(default, null):WeaponFlyIn;

	private var host:PlayState;
	private var combat:Weapons;
	private var hud:Hud;
	private var pick:Int = -1;
	private var fromX:Float = 0;
	private var fromY:Float = 0;

	public function new(host:PlayState, combat:Weapons, hud:Hud)
	{
		this.host = host;
		this.combat = combat;
		this.hud = hud;
		flyIn = new WeaponFlyIn(hud.camUI, combat.held);
	}

	public function openWeaponPick():Void
	{
		var picker = new WeaponPickSubState(hud.camUI);
		picker.onPicked = function(i)
		{
			combat.equip(i);
			pick = i;
			fromX = picker.pickedX;
			fromY = picker.pickedY;
		};
		picker.closeCallback = function()
		{
			if (picker.cancelled)
			{
				quitToMenu();
				return;
			}
			openTutorialIfNew();
		};
		host.openPanel(picker);
	}

	function quitToMenu():Void
	{
		Net.stop();
		host.leaveFor(function()
		{
			if (util.CustomArena.fromEditor)
				flixel.FlxG.switchState(() -> new EditorState());
			else
				flixel.FlxG.switchState(() -> new MainMenuState());
		});
	}

	public function openTutorialIfNew():Void
	{
		if (TutorialSubState.shown || Net.active)
		{
			throwIn();
			return;
		}
		TutorialSubState.shown = true;
		var tutorial = new TutorialSubState(hud.camUI);
		tutorial.closeCallback = throwIn;
		host.openPanel(tutorial);
		DiscordPresence.tutorial();
	}

	function throwIn():Void
	{
		if (pick < 0)
			return;
		flyIn.begin(WeaponPickSubState.artOf(pick), fromX, fromY);
		util.Controls.lockFire(INTRO_LOCK);
		pick = -1;
	}

	public function drop():Void
		flyIn.drop();

	public function update(elapsed:Float):Void
		flyIn.update(elapsed);
}
