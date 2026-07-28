package states.play;

import flixel.FlxG;
import entities.Player;
import systems.PlayerCombat;
import systems.TreeMan;
import systems.enemy.EnemyDirector;
import systems.weapons.Weapons;
import ui.Hud;
import util.CustomArena;
import util.Detour;

/**
 * The tree room the RUN 66 detour drops you into, and the walk back out of it.
 * `util.Detour` owns what carries across the state switch; this owns the visit.
 */
class QuietRoom
{
	static inline var PLAYER_SCALE:Float = 1.5;
	static inline var ZOOM:Float = 0.7;
	static inline var ARM_UP:Float = 240;
	static inline var BACK:Float = 40;

	public var talking(get, never):Bool;

	function get_talking():Bool
		return man != null && man.talking;

	private var host:PlayState;
	private var player:Player;
	private var man:TreeMan;
	private var watchExit:Bool = false;
	private var armed:Bool = false;
	private var from:Float = 0;

	public function new(host:PlayState, player:Player)
	{
		this.host = host;
		this.player = player;
	}

	/** Which stage track plays here. The boss return path reads this too. */
	public static function track():String
		return CustomArena.quiet ? "stage/Man_music" : "stage/gloomDoomWoods";

	/** Roll for the detour in place of a boss. True means the run is leaving. */
	public function tryDetour(bossWave:Int, director:EnemyDirector, status:PlayerCombat, combat:Weapons):Bool
	{
		if (!Detour.rolls())
			return false;
		if (!Detour.begin(director.wave, bossWave, status.health, status.superMeter, status.kills, combat.weapon))
			return false;
		host.leaveFor(function() FlxG.switchState(new PlayState()));
		return true;
	}

	/** Strip the run down to a quiet room: no weapon, no waves, bigger view. */
	public function enter(combat:Weapons, director:EnemyDirector, heldSprite:flixel.FlxSprite, hud:Hud):Void
	{
		combat.disabled = true;
		director.spawning = false;
		heldSprite.visible = false;
		player.setSizeScale(PLAYER_SCALE);
		FlxG.camera.zoom = ZOOM;
		addMan(hud);

		if (!Detour.inRoom)
			return;
		watchExit = true;
		armed = false;
		from = player.feetY;
	}

	function addMan(hud:Hud):Void
	{
		for (p in CustomArena.props)
			if (p.n == "tree")
			{
				man = new TreeMan(host, hud.camUI, player, p.x, p.y);
				return;
			}
	}

	public function update(elapsed:Float):Void
	{
		if (man != null)
			man.update(elapsed);

		if (!watchExit || host.restarting)
			return;
		if (man != null && man.talking)
			return;

		// walk far enough north to arm the exit, then come back down through it
		var up = from - player.feetY;
		if (up > ARM_UP)
			armed = true;
		if (!armed || up > BACK)
			return;

		watchExit = false;
		Detour.leave();
		host.leaveFor(function() FlxG.switchState(new PlayState()));
	}
}
