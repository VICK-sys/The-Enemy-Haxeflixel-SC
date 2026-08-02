package states.play;

import systems.weapons.Weapons;
import ui.Hud;
import ui.WeaponFlyIn;

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

	public function armForRun():Void
	{
		pick = WeaponPickSubState.lastPick;
		fromX = flixel.FlxG.width * 0.5;
		fromY = flixel.FlxG.height * 0.95;
		throwIn();
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
