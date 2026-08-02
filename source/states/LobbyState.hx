package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import entities.Player;
import net.Net;
import net.RemoteAvatar;
import systems.RenderLayers;
import systems.world.Arena;
import systems.world.CircleCollide;
import util.CustomArena;
import util.IrisWipe;
import util.Lang;
import util.Lobby;
import util.Music;
import util.SaveData;

typedef LobbySign =
{
	x:Float,
	y:Float,
	key:String,
	act:Void->Void,
	sprite:FlxSprite,
	label:FlxText
}

class LobbyState extends FlxState
{
	static inline var REACH:Float = 130;
	static inline var SIGN_W:Int = 96;
	static inline var SIGN_H:Int = 116;
	static inline var SEND_FRAMES:Int = 3;
	static inline var STALE:Float = 5;
	static inline var ZOOM:Float = 0.75;
	static inline var HUE_STEP:Float = 1 / 24;
	static inline var HUE_GAP:Float = 0.12;
	static inline var NAME_MAX:Int = 12;

	private var arena:Arena;
	private var player:Player;
	private var heldSprite:FlxSprite;
	private var layers:RenderLayers;
	private var camUI:FlxCamera;

	private var signs:Array<LobbySign> = [];
	private var prompt:FlxText;
	private var status:FlxText;
	private var wipe:IrisWipe;
	private var leaving:Bool = false;

	private var typing:Bool = false;
	private var dressing:Bool = false;
	private var hueClock:Float = 0;
	private var ip:String = "";
	private var frame:Int = 0;

	private var peers:Map<Int, RemoteAvatar> = new Map();
	private var seen:Map<Int, Float> = new Map();

	override public function create():Void
	{
		Lobby.enter();
		FlxG.mouse.visible = false;

		arena = new Arena(this);
		player = new Player(arena.spawnX, arena.spawnY);

		heldSprite = new FlxSprite();
		heldSprite.visible = false;

		layers = new RenderLayers(this, player, heldSprite);

		camUI = new FlxCamera();
		camUI.bgColor = 0;
		FlxG.cameras.add(camUI, false);

		addSign(Lobby.width() * 0.28, Lobby.height() * 0.34, "lobby.start", startRun);
		addSign(Lobby.width() * 0.55, Lobby.height() * 0.28, "lobby.host", hostGame);
		addSign(Lobby.width() * 0.75, Lobby.height() * 0.33, "lobby.join", askIp);
		addSign(Lobby.width() * 0.40, Lobby.height() * 0.58, "lobby.player", dressUp);

		prompt = new FlxText(0, 0, FlxG.width, "");
		prompt.setFormat(Lang.font(), 20, FlxColor.WHITE, CENTER);
		prompt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		prompt.scrollFactor.set(0, 0);
		prompt.cameras = [camUI];
		prompt.y = FlxG.height - 92;
		add(prompt);

		status = new FlxText(0, 0, FlxG.width, "");
		status.setFormat(Lang.font(), 16, 0xFFB8B8B8, CENTER);
		status.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		status.scrollFactor.set(0, 0);
		status.cameras = [camUI];
		status.y = 24;
		add(status);

		FlxG.camera.follow(player);
		FlxG.camera.setScrollBoundsRect(0, 0, arena.width, arena.height);
		FlxG.camera.zoom = ZOOM;

		wipe = new IrisWipe(this);
		wipe.open();
		Music.play(states.play.QuietRoom.track(), 0.3);
		super.create();
	}

	function addSign(x:Float, y:Float, key:String, act:Void->Void):Void
	{
		var s = new FlxSprite(x - SIGN_W * 0.5, y - SIGN_H);
		s.makeGraphic(SIGN_W, SIGN_H, 0xFFF2F2F2);
		layers.entityLayer.add(s);

		var t = new FlxText(0, 0, 200, Lang.t(key));
		t.setFormat(Lang.font(), 20, 0xFF1A1A1A, CENTER);
		t.x = x - 100;
		t.y = y - SIGN_H * 0.62;
		layers.tagLayer.add(t);

		signs.push({x: x, y: y, key: key, act: act, sprite: s, label: t});
	}

	function nearest():LobbySign
	{
		var best:LobbySign = null;
		var bestD:Float = REACH * REACH;
		var px = player.x + player.width * 0.5;
		var py = player.feetY;
		for (s in signs)
		{
			var dx = px - s.x;
			var dy = py - s.y;
			var d = dx * dx + dy * dy;
			if (d < bestD)
			{
				bestD = d;
				best = s;
			}
		}
		return best;
	}

	override public function update(elapsed:Float):Void
	{
		util.Controls.setAimAnchor(player.x + player.width * 0.5, player.y + player.height * 0.5);
		player.blockMovement = typing || dressing || leaving;

		super.update(elapsed);

		CircleCollide.resolve(player, player.hitRadius, arena.map, null);
		layers.update();

		frame++;
		pump();

		if (typing)
		{
			typeIp();
			return;
		}

		if (dressing)
		{
			dressUpTick(elapsed);
			return;
		}

		var near = nearest();
		prompt.text = near == null ? "" : Lang.t("lobby.prompt", [Lang.t(near.key)]);
		if (near != null && util.Controls.justPressed(util.Controls.INTERACT))
			near.act();

		if (FlxG.keys.justPressed.ESCAPE)
			quit();
	}

	function statusLine():String
	{
		if (Net.isHost && Net.mode != Off)
			return Lang.t("lobby.hosting", [Net.hostPort, Net.guestCount]);
		if (Net.isClient)
			return Net.connected ? Lang.t("lobby.joined") : Lang.t("hud.connectionLost");
		return "";
	}

	function pump():Void
	{
		status.text = statusLine();

		if (Net.mode == Off)
			return;

		if (Net.connected && frame % SEND_FRAMES == 0)
			Net.send({
				t: "lob",
				x: Math.round(player.x),
				y: Math.round(player.y),
				fx: player.flipX,
				an: player.animation.name,
				hu: SaveData.playerHue(),
				nm: SaveData.playerName()
			});

		for (msg in Net.poll())
			handle(msg);

		var now = haxe.Timer.stamp();
		for (id in [for (k in peers.keys()) k])
			if (now - seen.get(id) >= STALE)
				drop(id);

		if (Net.dropped)
		{
			for (id in [for (k in peers.keys()) k])
				drop(id);
			Net.stop();
		}
	}

	function handle(msg:Dynamic):Void
	{
		switch ((msg.t : String))
		{
			case "lob":
				show(msg.f, msg);
			case "go" if (Net.isClient):
				beginRun();
			default:
		}
	}

	function show(from:Dynamic, m:Dynamic):Void
	{
		if (from == null || !Std.isOfType(from, Int))
			return;
		var id:Int = from;
		if (id == Net.selfId)
			return;
		var av = peers.get(id);
		if (av == null)
		{
			av = new RemoteAvatar(layers);
			peers.set(id, av);
		}
		seen.set(id, haxe.Timer.stamp());

		av.setHue(m.hu == null ? 0 : m.hu);
		av.setName(m.nm == null || m.nm == "" ? Lang.t("online.defaultName") : m.nm);
		av.sprite.x = m.x;
		av.sprite.y = m.y;
		av.sprite.flipX = m.fx == true;
		av.sprite.visible = true;
		if (m.an != null && av.sprite.animation.getByName(m.an) != null)
			av.sprite.animation.play(m.an);
	}

	function drop(id:Int):Void
	{
		var av = peers.get(id);
		if (av != null)
		{
			av.setReady(false);
			av.clearDeath();
			av.sprite.visible = false;
			av.held.visible = false;
			av.shadow.visible = false;
		}
		peers.remove(id);
		seen.remove(id);
	}

	function hostGame():Void
	{
		if (Net.mode != Off)
			return;
		if (Net.host())
			Net.inGame = false;
	}

	function dressUp():Void
	{
		dressing = true;
		prompt.text = "";
	}

	function dressUpTick(elapsed:Float):Void
	{
		var name = SaveData.playerName();
		status.text = Lang.t("lobby.dress") + "
"
			+ Lang.t("lobby.dressColor", [Math.round(SaveData.playerHue() * 360)]) + "
"
			+ Lang.t("lobby.dressName", [name == "" ? Lang.t("online.defaultName") : name]);

		if (hueClock > 0)
			hueClock -= elapsed;

		var turn = 0;
		if (util.Controls.moveLeft())
			turn = -1;
		else if (util.Controls.moveRight())
			turn = 1;
		if (turn != 0 && hueClock <= 0)
		{
			hueClock = HUE_GAP;
			SaveData.setPlayerHue(SaveData.playerHue() + turn * HUE_STEP);
			player.setHue(SaveData.playerHue());
		}

		var k = FlxG.keys.firstJustPressed();
		if (name.length < NAME_MAX && ((k >= 65 && k <= 90) || (k >= 48 && k <= 57)))
			SaveData.setPlayerName(name + String.fromCharCode(k));
		else if (FlxG.keys.justPressed.BACKSPACE && name.length > 0)
			SaveData.setPlayerName(name.substr(0, name.length - 1));

		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE
			|| util.Controls.justPressed(util.Controls.INTERACT))
		{
			dressing = false;
			status.text = "";
		}
	}

	function askIp():Void
	{
		if (Net.mode != Off)
			return;
		typing = true;
		ip = "";
		prompt.text = "";
	}

	function typeIp():Void
	{
		status.text = Lang.t("online.typeIp") + "\n" + ip;

		for (i in 0...10)
			if (FlxG.keys.checkStatus(48 + i, JUST_PRESSED) || FlxG.keys.checkStatus(96 + i, JUST_PRESSED))
				if (ip.length < 21)
					ip += Std.string(i);
		if ((FlxG.keys.justPressed.PERIOD || FlxG.keys.justPressed.NUMPADPERIOD) && ip.length < 21)
			ip += ".";
		if (FlxG.keys.justPressed.SEMICOLON && ip.length < 21)
			ip += ":";
		if (FlxG.keys.justPressed.BACKSPACE && ip.length > 0)
			ip = ip.substr(0, ip.length - 1);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			typing = false;
			status.text = "";
			return;
		}
		if (FlxG.keys.justPressed.ENTER && ip.length >= 7)
		{
			typing = false;
			if (Net.join(ip))
				Net.inGame = false;
		}
	}

	function startRun():Void
	{
		if (Net.isClient)
			return;
		if (Net.mode != Off)
			Net.send({t: "go"});
		beginRun();
	}

	function beginRun():Void
	{
		if (leaving)
			return;
		leaving = true;
		Lobby.leave();
		wipe.close(function() FlxG.switchState(() -> new PlayState()));
	}

	function quit():Void
	{
		if (leaving)
			return;
		leaving = true;
		Net.stop();
		Lobby.leave();
		wipe.close(function() FlxG.switchState(() -> new MainMenuState()));
	}
}
