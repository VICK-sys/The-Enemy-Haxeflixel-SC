package states.play;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import entities.Player;
import net.AckQuorum;
import net.Net;
import net.NetSync;
import systems.PlayerCombat;
import systems.RenderLayers;
import systems.enemy.EnemyDirector;
import ui.Hud;
import util.Lang;
import util.Paths;

class ReadyGate
{
	static inline var SCALE:Float = 4;
	static inline var LIFT:Float = 67;
	static inline var PROMPT_Y:Float = 150;
	static inline var WAIT_CAP:Float = 90;

	public var armed(default, null):Bool = false;
	public var blocked:Void->Bool;
	public var onCommit:Void->Void;

	private var host:PlayState;
	private var player:Player;
	private var status:PlayerCombat;
	private var director:EnemyDirector;
	private var hud:Hud;
	private var netSync:NetSync;

	private var bubble:FlxSprite;
	private var prompt:FlxText;
	private var ready:Bool = false;
	private var quorum:AckQuorum = new AckQuorum();
	private var clock:Float = 0;

	public function new(host:PlayState, player:Player, layers:RenderLayers)
	{
		this.host = host;
		this.player = player;

		bubble = new FlxSprite();
		bubble.loadGraphic(Paths.image("ui/speech_ready"));
		bubble.antialiasing = false;
		bubble.scale.set(SCALE, SCALE);
		bubble.updateHitbox();
		bubble.visible = false;
		layers.tagLayer.add(bubble);

		prompt = new FlxText(0, PROMPT_Y, FlxG.width, "");
		prompt.setFormat(Lang.font(), 24, FlxColor.WHITE, CENTER);
		prompt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		prompt.visible = false;
	}

	public function wire(status:PlayerCombat, director:EnemyDirector, hud:Hud):Void
	{
		this.status = status;
		this.director = director;
		this.hud = hud;
		prompt.cameras = [hud.camUI];
		host.add(prompt);
	}

	public function useNet(sync:NetSync):Void
	{
		netSync = sync;
		sync.onReady = noteReady;
		sync.onUnready = noteUnready;
		sync.onReadyGo = release;
		sync.onReadyArm = arm;
	}

	public function arm():Void
	{
		if (armed)
			return;
		armed = true;
		ready = false;
		clock = 0;
		director.holdReady = true;
		if (netSync != null)
			netSync.setAllReady(false);
		if (Net.isHost)
		{
			quorum.arm([Net.selfId].concat(Net.guestIds()));
			Net.send({t: "rdyarm"});
		}
	}

	public function peerLost(id:Int):Void
	{
		if (!Net.isHost || !armed)
			return;
		quorum.drop(id);
		checkAcks();
	}

	public function update(elapsed:Float):Void
	{
		placeBubble();

		if (!armed)
		{
			prompt.visible = false;
			return;
		}

		clock += elapsed;
		if (Net.isHost && (clock > WAIT_CAP || Net.dropped))
		{
			release();
			return;
		}

		if (host.subState != null)
		{
			prompt.visible = false;
			return;
		}

		prompt.visible = true;
		prompt.text = ready ? waitLabel() : Lang.t("ready.prompt");

		if (ready)
		{
			if (Net.active && !status.dead && util.Controls.acceptJustPressed())
				unready();
			return;
		}

		if (Net.active && status.dead)
		{
			markReady(true);
			return;
		}

		if (status.dead || (blocked != null && blocked()))
			return;

		if (util.Controls.acceptJustPressed())
			markReady();
	}

	function waitLabel():String
	{
		if (!Net.active)
			return "";
		if (Net.isHost)
			return Lang.t("ready.waiting", [quorum.got(), quorum.need()]);
		return Lang.t("ready.waiting", [1, Net.guestCount + 1]);
	}

	function markReady(quiet:Bool = false):Void
	{
		ready = true;
		bubble.visible = !quiet;
		if (!quiet)
			FlxG.sound.play(Paths.sound("weapon/catch"), 0.5);

		if (!Net.active)
		{
			release();
			return;
		}

		Net.send({t: "rdy"});
		if (Net.isHost)
			noteReady(Net.selfId);
	}

	function unready():Void
	{
		ready = false;
		bubble.visible = false;
		FlxG.sound.play(Paths.sound("weapon/catch"), 0.35);

		Net.send({t: "unrdy"});
		if (Net.isHost)
			noteUnready(Net.selfId);
	}

	function noteUnready(id:Int):Void
	{
		if (netSync != null)
			netSync.setReady(id, false);
		if (Net.isHost && armed)
			quorum.unack(id);
	}

	function noteReady(id:Int):Void
	{
		if (netSync != null)
			netSync.setReady(id, true);
		if (!Net.isHost || !armed)
			return;
		quorum.ack(id);
		checkAcks();
	}

	function checkAcks():Void
	{
		if (quorum.satisfied())
			release();
	}

	function release():Void
	{
		if (!armed)
			return;
		if (onCommit != null)
			onCommit();
		if (Net.isHost)
			Net.send({t: "rdygo"});
		armed = false;
		ready = false;
		quorum.disarm();
		bubble.visible = false;
		prompt.visible = false;
		director.holdReady = false;
		if (netSync != null)
			netSync.setAllReady(false);
	}

	function placeBubble():Void
	{
		if (!bubble.visible)
			return;
		bubble.x = player.x + player.width * 0.5 - bubble.width * 0.5;
		bubble.y = player.y - bubble.height - LIFT;
	}
}
