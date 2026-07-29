package states.play;

import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
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
	private var clock:Float = 0;
	private var acks:Map<Int, Bool>;
	private var need:Int = 0;

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
		sync.onLevelGo = release;
		sync.onPeerLost = function(id)
		{
			onPeerLost(id);
			if (onLostPeer != null)
				onLostPeer(id);
		};
	}

	public function updateShop(elapsed:Float):Void
		shop.update(elapsed);

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
		{
			acks = new Map();
			need = Net.guestCount + 1;
		}
	}

	function enter():Void
	{
		if (!shop.open || status.dead || host.restarting || host.subState != null)
			return;
		spentHere = false;
		var screen = new LevelUpSubState(hud.camUI);
		screen.onSpent = syncScrap;
		screen.closeCallback = onScreenClosed;
		host.openPanel(screen);
		if (Net.active)
			Net.send({t: "lvlin"});
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
		if (!spentHere)
			return;
		reportDone();
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
		if (!Net.isHost || !holding || acks == null)
			return;
		acks.set(id, true);
		checkAcks();
	}

	function onPeerLost(id:Int):Void
	{
		if (!Net.isHost || !holding || acks == null)
			return;
		acks.remove(id);
		need = Net.guestCount + 1;
		checkAcks();
	}

	function checkAcks():Void
	{
		var got = 0;
		for (v in acks)
			got++;
		if (got >= need)
			release();
	}

	function release():Void
	{
		if (!holding)
			return;
		if (Net.isHost)
			Net.send({t: "lvlgo"});
		holding = false;
		acks = null;
		director.holdWave = false;
		if (netSync != null)
			netSync.setAllLeveling(false);
	}
}
