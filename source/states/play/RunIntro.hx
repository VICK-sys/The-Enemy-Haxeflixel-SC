package states.play;

import net.Net;
import systems.weapons.Weapons;
import ui.Hud;
import ui.WeaponFlyIn;
import util.DiscordPresence;

class RunIntro
{
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
		picker.closeCallback = openTutorialIfNew;
		host.openPanel(picker);
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
		pick = -1;
	}

	public function drop():Void
		flyIn.drop();

	public function update(elapsed:Float):Void
		flyIn.update(elapsed);
}
