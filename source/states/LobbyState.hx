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
import util.Paths;
import util.SaveData;

typedef LobbySign =
{
	x:Float,
	y:Float,
	key:Null<String>,
	act:Void->Void,
	sprite:FlxSprite,
	highlight:FlxSprite,
	label:FlxText
}

class LobbyState extends FlxState
{

	static inline var REACH:Float = 130;
	static inline var SIGN_W:Int = 96;
	static inline var SIGN_H:Int = 116;
	static inline var SIGN_ART_SCALE:Float = 4;
	static inline var SEND_FRAMES:Int = 3;
	static inline var STALE:Float = 5;
	static inline var DASH_LINES:Int = 2;
	static inline var DASH_VOL:Float = 0.55;
	static inline var DASH_READY_VOL:Float = 0.4;
	static inline var ZOOM:Float = 0.75;
	static inline var CURSOR_SCALE:Float = 3;
	static inline var STEAM_BACK:Float = 34;
	static inline var STEAM_RISE:Float = 26;
	static inline var DASH_LINE_GAP:Float = 0.05;

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
	private var dashCooldown:Float = 0;
	private var backGear:systems.BackGear;
	private var fx:systems.Fx;
	private var dashGhost:systems.DashGhost;
	private var steamPuff:FlxSprite;
	private var dashLineTimer:Float = 0;
	private var guardTimer:Float = 0;
	private var puffs:Int = 0;
	private var chat:ui.ChatWindow;
	private var wasNetOn:Bool = false;

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
		layers.trackPart(backGear.sprite, player, RenderLayers.GEAR_BIAS);

		fx = new systems.Fx();
		insert(members.indexOf(layers.entityLayer), fx.dashTrail);
		insert(members.indexOf(layers.entityLayer), fx.steam);

		dashGhost = new systems.DashGhost(player, SaveData.playerHue());
		dashGhost.enabled = SaveData.dashTrail();
		insert(members.indexOf(layers.entityLayer), dashGhost.trail.group);

		camUI = new FlxCamera();
		camUI.bgColor = 0;
		FlxG.cameras.add(camUI, false);

		addSign(Lobby.width() * 0.28, Lobby.height() * 0.34, "lobby.start", startRun);
		#if !html5
		addSign(Lobby.width() * 0.55, Lobby.height() * 0.28, "lobby.online", openOnline);
		#end
		addSign(Lobby.width() * 0.40, Lobby.height() * 0.58, "lobby.player", dressUp, "ui/player_customization");
		addSign(Lobby.width() * 0.62, Lobby.height() * 0.58, "lobby.weapon", pickWeapon, "ui/weapon_box");
		addSign(Lobby.width() * 0.84, Lobby.height() * 0.58, "lobby.stats", showStats, "ui/stats");
		#if desktop
		addSign(Lobby.width() * 0.16, Lobby.height() * 0.58, null, exitImmediately, "fun/C");
		#end

		cursor = new FlxSprite();
		cursor.loadGraphic(util.HuePalette.graphic("ui/mouse", SaveData.playerHue()));
		cursor.antialiasing = false;
		cursor.scale.set(CURSOR_SCALE, CURSOR_SCALE);
		cursor.cameras = [camUI];
		add(cursor);

		prompt = new FlxText(0, 0, FlxG.width, "");
		prompt.setFormat(Lang.bodyFont(), Lang.bodySize(), FlxColor.WHITE, CENTER);
		prompt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		prompt.scrollFactor.set(0, 0);
		prompt.cameras = [camUI];
		prompt.y = FlxG.height - 92;
		add(prompt);

		status = new FlxText(0, 0, FlxG.width, "");
		status.setFormat(Lang.smallFont(), Lang.smallSize(), 0xFFB8B8B8, CENTER);
		status.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		status.scrollFactor.set(0, 0);
		status.cameras = [camUI];
		status.y = 24;
		add(status);

		chat = new ui.ChatWindow(camUI);
		add(chat);
		systems.chat.ChatLog.onCommand = chatCommand;
		remove(cursor, true);
		add(cursor);

		FlxG.camera.follow(player);
		FlxG.camera.setScrollBoundsRect(0, 0, arena.width, arena.height);
		FlxG.camera.zoom = ZOOM;

		wipe = new IrisWipe(this);
		wipe.open();
		Music.play(Music.getRunTrack(), 0.3);
		super.create();

		if (!LobbyHelpSubState.shown)
		{
			LobbyHelpSubState.shown = true;
			openSubState(new LobbyHelpSubState(camUI));
		}
	}

	function addSign(x:Float, y:Float, key:Null<String>, act:Void->Void, ?art:String):Void
	{
		var s = new FlxSprite();
		var highlight:FlxSprite = null;
		if (art == null)
		{
			s.makeGraphic(SIGN_W, SIGN_H, 0xFFF2F2F2);
			s.setPosition(x - SIGN_W * 0.5, y - SIGN_H);
		}
		else
		{
			s.loadGraphic(Paths.image(art));
			s.antialiasing = false;
			s.scale.set(SIGN_ART_SCALE, SIGN_ART_SCALE);
			s.updateHitbox();
			s.setPosition(x - s.width * 0.5, y - s.height);

			highlight = new FlxSprite();
			highlight.loadGraphic(util.Outline.graphic(art));
			highlight.antialiasing = false;
			highlight.scale.set(SIGN_ART_SCALE, SIGN_ART_SCALE);
			highlight.updateHitbox();
			highlight.setPosition(s.x - SIGN_ART_SCALE, s.y - SIGN_ART_SCALE);
			highlight.visible = false;
			layers.entityLayer.add(highlight);
		}
		layers.entityLayer.add(s);

		var t = new FlxText(0, 0, 200, key == null ? "" : Lang.t(key));
		t.setFormat(Lang.bodyFont(), Lang.bodySize(), 0xFF1A1A1A, CENTER);
		t.x = x - 100;
		t.y = y - SIGN_H * 0.62;
		t.visible = art == null;
		layers.tagLayer.add(t);

		signs.push({x: x, y: y, key: key, act: act, sprite: s, highlight: highlight, label: t});
	}

	function setSignHighlight(near:LobbySign):Void
	{
		for (sign in signs)
		{
			if (sign.highlight == null)
				continue;
			var on = sign == near;
			sign.sprite.visible = !on;
			sign.highlight.visible = on;
		}
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

	function steamX():Float
		return player.x + player.width * 0.5 - (player.flipX ? -1.0 : 1.0) * STEAM_BACK * player.sizeScale;

	function steamY():Float
		return player.y + player.height * 0.5 - STEAM_RISE * player.sizeScale;

	function trackSteam():Void
	{
		if (steamPuff == null)
			return;
		if (!steamPuff.exists)
		{
			steamPuff = null;
			return;
		}
		steamPuff.flipX = !player.flipX;
		steamPuff.setPosition(steamX() - steamPuff.width * 0.5, steamY() - steamPuff.height * 0.5);
	}

	function dashEffects(elapsed:Float):Void
	{
		trackSteam();
		fx.update();

		if (guardTimer > 0)
			guardTimer -= elapsed;
		dashGhost.enabled = SaveData.dashTrail();
		dashGhost.update(elapsed, guardTimer > 0);

		if (player.dashTimer > 0)
		{
			dashLineTimer -= elapsed;
			if (dashLineTimer <= 0)
			{
				dashLineTimer = DASH_LINE_GAP;
				var vx = player.velocity.x;
				var vy = player.velocity.y;
				var vlen = Math.sqrt(vx * vx + vy * vy);
				if (vlen > 0)
					fx.dashLine(player.x + player.width / 2, player.y + player.height / 2, vx / vlen, vy / vlen);
			}
		}
	}

	function dashTick(elapsed:Float):Void
	{
		if (dashCooldown > 0)
		{
			dashCooldown -= elapsed;
			if (dashCooldown <= 0)
			{
				FlxG.sound.play(util.Paths.sound("dash/charged"), DASH_READY_VOL);
				steamPuff = fx.steamAt(steamX(), steamY(), !player.flipX);
				puffs++;
			}
		}

		if (!util.Controls.justPressed(util.Controls.DASH) || dashCooldown > 0
			|| player.blockMovement || player.dashTimer > 0)
			return;

		var data = data.PlayerData.PlayerDataRegistry.get();
		dashCooldown = data.dashCooldown;
		guardTimer = data.dashIframes;
		player.dash();
		FlxG.sound.play(util.Paths.sound("dash/dash" + (1 + Std.random(DASH_LINES))), DASH_VOL);
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

		var netOn = Net.mode != Off;
		if (netOn && !wasNetOn)
			systems.chat.ChatLog.clear();
		wasNetOn = netOn;
		chat.show(netOn);

		backGear.update(elapsed, player.x + player.width * 0.5, player.y - 21, player.flipX,
			systems.BackGear.leanFor(player.animation.name), player.visible, player.angle,
			player.offset.y - player.baseOffsetY, player.y + player.height * 0.5,
			player.animation.name);

		for (av in peers)
			av.update(elapsed);

		cursor.setPosition(util.Controls.aimViewX(FlxG.camera) - cursor.frameWidth * 0.5,
			util.Controls.aimViewY(FlxG.camera) - cursor.frameHeight * 0.5);
		var onChat = chat.visible && chat.hovering;
		cursor.visible = subState == null && !onChat;
		if (subState == null)
			FlxG.mouse.visible = onChat;

		status.visible = subState == null;
		prompt.visible = subState == null;

		dashEffects(elapsed);

		if (subState != null)
		{
			setSignHighlight(null);
			player.velocity.set(0, 0);
			if (player.animation.name == "walk")
				player.animation.play("idle");
			return;
		}

		dashTick(elapsed);

		var near = nearest();
		setSignHighlight(near);
		prompt.text = near == null || near.key == null ? "" : Lang.t("lobby.prompt",
			[util.Controls.bindName(util.Controls.INTERACT), Lang.t(near.key)]);
		if (near != null && util.Controls.justPressed(util.Controls.INTERACT))
			near.act();

		if (util.Controls.pausePressed())
			openPause();
	}

	function statusLine():String
	{
		if (Net.rejected)
			return Lang.t("lobby.versionMismatch", [Net.hostVersion == "" ? Lang.t("lobby.versionUnknown") : Net.hostVersion, util.Version.id]);
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
				sk: SaveData.playerSkin(),
				gr: SaveData.playerGear(),
				nm: SaveData.playerName(),
				wi: WeaponPickSubState.lastPick,
				hv: false,
				ha: 0,
				hf: false,
				dg: guardTimer > 0,
				pf: puffs,
				v: util.Version.id
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
			case "hello" if (Net.isClient && msg.go == true):
				beginRun();
			default:
				systems.chat.ChatLog.receive(msg);
		}
	}

	function show(from:Dynamic, m:Dynamic):Void
	{
		if (from == null || !Std.isOfType(from, Int))
			return;
		var id:Int = from;
		if (id == Net.selfId)
			return;
		if (Net.isHost && !util.Version.matches(m.v))
		{
			Net.kick(id);
			drop(id);
			return;
		}
		var av = peers.get(id);
		if (av == null)
		{
			av = new RemoteAvatar(layers);
			av.fx = fx;
			peers.set(id, av);
			if (Net.isHost)
				sysNotice(Lang.t("chat.joined", [m.nm == null || m.nm == "" ? Lang.t("online.defaultName") : m.nm]));
		}
		seen.set(id, haxe.Timer.stamp());

		av.setName(m.nm == null || m.nm == "" ? Lang.t("online.defaultName") : m.nm);
		av.apply(m);
	}

	function drop(id:Int, quiet:Bool = false):Void
	{
		var av = peers.get(id);
		if (av != null && !quiet && Net.isHost)
			sysNotice(Lang.t("chat.left", [av.tag.text == "" ? Lang.t("online.defaultName") : av.tag.text]));
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
		util.Controls.resetDevices();
		var panel = new HostSubState(camUI);
		panel.onStopped = clearPeers;
		openSubState(panel);
	}

	function clearPeers():Void
	{
		for (id in [for (k in peers.keys()) k])
			drop(id, true);
	}

	function sysNotice(text:String):Void
	{
		systems.chat.ChatLog.notice(text);
		Net.send({t: "chatN", x: text});
	}

	function chatCommand(text:String):Void
	{
		var t = StringTools.trim(text);
		if (t.toLowerCase().indexOf("/kick") != 0)
			return;
		if (!Net.isHost)
		{
			systems.chat.ChatLog.notice(Lang.t("chat.kickDenied"));
			return;
		}
		var name = StringTools.trim(t.substr(5));
		var want = name.toLowerCase();
		for (id in [for (k in peers.keys()) k])
		{
			var av = peers.get(id);
			if (av != null && av.tag.text.toLowerCase() == want)
			{
				Net.kick(id);
				drop(id);
				return;
			}
		}
		systems.chat.ChatLog.notice(Lang.t("chat.kickMissing", [name]));
	}

	function pickWeapon():Void
	{
		prompt.text = "";
		util.Controls.resetDevices();
		openSubState(new WeaponPickSubState(camUI));
	}

	#if !html5
	function openOnline():Void
	{
		prompt.text = "";
		util.Controls.resetDevices();
		var panel = new OnlineSubState(camUI);
		panel.onHost = hostGame;
		panel.onJoin = askIp;
		openSubState(panel);
	}
	#end

	function repaint():Void
	{
		var hue = SaveData.playerHue();
		player.setHue(hue);
		player.applySkin();
		backGear.paint(hue);
		dashGhost.paint(hue);
		cursor.loadGraphic(util.HuePalette.graphic("ui/mouse", hue));
	}

	function showStats():Void
	{
		prompt.text = "";
		util.Controls.resetDevices();
		openSubState(new StatsSubState(camUI));
	}

	function dressUp():Void
	{
		prompt.text = "";
		var panel = new DressUpSubState(camUI);
		panel.onDone = repaint;
		util.Controls.resetDevices();
		openSubState(panel);
	}

	#if desktop
	function exitImmediately():Void
	{
		util.DiscordPresence.shutdown();
		lime.system.System.exit(0);
	}
	#end

	function askIp():Void
	{
		if (Net.mode != Off)
			return;
		prompt.text = "";
		util.Controls.resetDevices();
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

	function openPause():Void
	{
		prompt.text = "";
		util.Controls.resetDevices();
		var pause = new PauseSubState(camUI, true);
		pause.closeCallback = repaint;
		openSubState(pause);
	}

	override public function destroy():Void
	{
		systems.chat.ChatLog.onCommand = null;
		systems.world.PropBlock.solids = null;
		super.destroy();
	}
}
