package states.play;

import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
import net.AckQuorum;
import net.Net;
import net.NetSync;
import systems.PlayerCombat;
import systems.RenderLayers;
import systems.Shop;
import systems.enemy.EnemyDirector;
import ui.Hud;
import util.Lang;
import util.Levels;

class ShopRound
{
	static inline var WAIT_CAP:Float = 60;

	public var shop(default, null):Shop;
	public var onLostPeer:Int->Void;

	private var host:PlayState;
	private var status:PlayerCombat;
	private var director:EnemyDirector;
	private var hud:Hud;
	private var netSync:NetSync;

	private var holding:Bool = false;
	private var done:Bool = false;
	private var spentHere:Bool = false;
	private var automatedHere:Bool = false;
	private var localLeveling:Bool = false;
	private var clock:Float = 0;
	private var quorum:AckQuorum = new AckQuorum();

	public function new(host:PlayState, player:Player, layers:RenderLayers)
	{
		this.host = host;
		shop = new Shop(player, layers);
	}

	public function solids():Array<FlxSprite>
		return shop.solid();

	public function wire(status:PlayerCombat, director:EnemyDirector, hud:Hud):Void
	{
		this.status = status;
		this.director = director;
		this.hud = hud;
		shop.addTo(host);
		shop.onEnter = enter;
		shop.onClose = onShopShut;
	}

	public function useNet(sync:NetSync):Void
	{
		netSync = sync;
		sync.onLevelOpen = open;
		sync.onLevelIn = onPeerEntered;
		sync.onLevelAck = noteAck;
		sync.onLevelOut = onPeerLeft;
		sync.onLevelGo = release;
		sync.onPeerLost = function(id)
		{
			onPeerLost(id);
			if (onLostPeer != null)
				onLostPeer(id);
		};
	}

	public function updateShop(elapsed:Float):Void
	{
		shop.update(elapsed);
		if (Net.active && netSync != null)
			syncLocalLeveling(Std.isOfType(host.subState, LevelUpSubState));
	}

	function syncLocalLeveling(on:Bool):Void
	{
		netSync.leveling = on;
		if (on == localLeveling)
			return;
		localLeveling = on;
		Net.send({t: on ? "lvlin" : "lvlout"});
	}

	public function updateHold(elapsed:Float):Void
	{
		if (!holding)
			return;
		clock += elapsed;
		if (Net.isHost && (clock > WAIT_CAP || Net.dropped))
			release();
	}

	public function onWaveCleared():Void
	{
		if (director.wave <= 0 || director.wave % Shop.EVERY != 0)
			return;
		open();
		if (Net.isHost)
			Net.send({t: "lvl"});
	}

	function open():Void
	{
		shop.setOpen(true);
		hud.showBanner(Lang.t("shop.open"));
		if (!Net.active || Net.isHost)
			director.holdWave = true;
		if (!Net.active)
			return;

		holding = true;
		done = false;
		clock = 0;
		if (Net.isHost)
			quorum.arm([Net.selfId].concat(Net.guestIds()));
	}

	function enter():Void
	{
		if (!shop.open || status.dead || host.restarting || host.subState != null)
			return;
		spentHere = false;
		automatedHere = util.Controls.pilot;
		var screen = new LevelUpSubState(hud.camUI);
		screen.automated = automatedHere;
		screen.onSpent = syncScrap;
		screen.closeCallback = onScreenClosed;
		host.openPanel(screen);
	}

	function syncScrap():Void
	{
		spentHere = true;
		status.refreshMax();
		hud.setExp(Levels.exp);
	}

	public function shutShop():Void
		shop.setOpen(false);

	function onScreenClosed():Void
	{
		if (automatedHere)
		{
			automatedHere = false;
			shop.setOpen(false);
			return;
		}
		if (!spentHere)
			return;
		reportDone();
	}

	function onPeerLeft(id:Int):Void
	{
		if (netSync != null)
			netSync.setLeveling(id, false);
	}

	function onShopShut():Void
		reportDone();

	function reportDone():Void
	{
		if (!Net.active)
		{
			director.holdWave = false;
			return;
		}
		if (!holding || done)
			return;
		done = true;
		Net.send({t: "lvldone"});
		if (Net.isHost)
			noteAck(Net.selfId);
	}

	function onPeerEntered(id:Int):Void
	{
		if (netSync != null)
			netSync.setLeveling(id, true);
	}

	function noteAck(id:Int):Void
	{
		if (netSync != null)
			netSync.setLeveling(id, false);
		if (!Net.isHost || !holding)
			return;
		quorum.ack(id);
		checkAcks();
	}

	function onPeerLost(id:Int):Void
	{
		if (!Net.isHost || !holding)
			return;
		quorum.drop(id);
		checkAcks();
	}

	function checkAcks():Void
	{
		if (quorum.satisfied())
			release();
	}

	function release():Void
	{
		if (!holding)
			return;
		if (Net.isHost)
			Net.send({t: "lvlgo"});
		holding = false;
		quorum.disarm();
		director.holdWave = false;
		if (netSync != null)
			netSync.setAllLeveling(false);
	}
}
