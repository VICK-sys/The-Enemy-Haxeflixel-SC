package states.play;

import net.Net;
import ui.Hud;
import util.DiscordPresence;

class RunIntro
{
	private var host:PlayState;
	private var hud:Hud;

	public function new(host:PlayState, hud:Hud)
	{
		this.host = host;
		this.hud = hud;
	}

	public function armForRun():Void
		openTutorialIfNew();

	public function openTutorialIfNew():Void
	{
		if (TutorialSubState.shown || Net.active)
			return;
		TutorialSubState.shown = true;
		var tutorial = new TutorialSubState(hud.camUI);
		host.openPanel(tutorial);
		DiscordPresence.tutorial();
	}
}
