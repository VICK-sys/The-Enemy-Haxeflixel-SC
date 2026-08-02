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
	static inline var CURSOR_SCALE:Float = 3;

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

	private var frame:Int = 0;

	private var cursor:FlxSprite;
	private var backGear:systems.BackGear;

	private var peers:Map<Int, RemoteAvatar> = new Map();
	private var seen:Map<Int, Float> = new Map();

	override public function create():Void
	{
		Lobby.enter();
		FlxG.mouse.visible = false;
		persistentUpdate = true;

		arena = new Arena(this);
		arena.tileBackground("stages/rock_tile");
		player = new Player(arena.spawnX, arena.spawnY);
		player.setHue(SaveData.playerHue());

		heldSprite = new FlxSprite();
		heldSprite.visible = false;

		layers = new RenderLayers(this, player, heldSprite);

		backGear = new systems.BackGear();
		backGear.paint(SaveData.playerHue());
		layers.entityLayer.add(backGear.sprite);

		camUI = new FlxCamera();
		camUI.bgColor = 0;
		FlxG.cameras.add(camUI, false);

		addSign(Lobby.width() * 0.28, Lobby.height() * 0.34, "lobby.start", startRun);
		addSign(Lobby.width() * 0.55, Lobby.height() * 0.28, "lobby.host", hostGame);
		addSign(Lobby.width() * 0.75, Lobby.height() * 0.33, "lobby.join", askIp);
		addSign(Lobby.width() * 0.40, Lobby.height() * 0.58, "lobby.player", dressUp);
		addSign(Lobby.width() * 0.62, Lobby.height() * 0.58, "lobby.weapon", pickWeapon);

		cursor = new FlxSprite();
		cursor.loadGraphic(util.HuePalette.graphic("ui/mouse", SaveData.playerHue()));
		cursor.antialiasing = false;
		cursor.scale.set(CURSOR_SCALE, CURSOR_SCALE);
		cursor.cameras = [camUI];
		add(cursor);

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
		player.blockMovement = leaving || subState != null;

		super.update(elapsed);

		CircleCollide.resolve(player, player.hitRadius, arena.map, null);
		layers.update();

		frame++;
		pump();

		backGear.update(elapsed, player.x + player.width * 0.5, player.y - 21, player.flipX,
			systems.BackGear.leanFor(player.animation.name), player.visible, player.angle,
			player.offset.y - player.baseOffsetY, player.y + player.height * 0.5);

		for (av in peers)
			av.update(elapsed);

		cursor.setPosition(util.Controls.aimViewX(FlxG.camera) - cursor.frameWidth * 0.5,
			util.Controls.aimViewY(FlxG.camera) - cursor.frameHeight * 0.5);
		cursor.visible = subState == null;

		status.visible = subState == null;
		prompt.visible = subState == null;

		if (subState != null)
			return;

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
				nm: SaveData.playerName(),
				wi: WeaponPickSubState.lastPick,
				hv: false,
				ha: 0,
				hf: false
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

		av.setName(m.nm == null || m.nm == "" ? Lang.t("online.defaultName") : m.nm);
		av.apply(m);
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
			av.tag.visible = false;
			av.note.visible = false;
			av.update(0);
		}
		peers.remove(id);
		seen.remove(id);
	}

	function hostGame():Void
	{
		if (Net.isClient)
			return;
		prompt.text = "";
		FlxG.keys.reset();
		var panel = new HostSubState(camUI);
		panel.onStopped = clearPeers;
		openSubState(panel);
	}

	function clearPeers():Void
	{
		for (id in [for (k in peers.keys()) k])
			drop(id);
	}

	function pickWeapon():Void
	{
		prompt.text = "";
		FlxG.keys.reset();
		openSubState(new WeaponPickSubState(camUI));
	}

	function dressUp():Void
	{
		prompt.text = "";
		var panel = new DressUpSubState(camUI);
		panel.onDone = function() player.setHue(SaveData.playerHue());
		FlxG.keys.reset();
		openSubState(panel);
	}

	function askIp():Void
	{
		if (Net.mode != Off)
			return;
		prompt.text = "";
		FlxG.keys.reset();
		openSubState(new JoinSubState(camUI));
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
