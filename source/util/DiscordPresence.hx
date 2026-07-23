package util;

import data.DataLoader;

#if hxdiscord_rpc
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import lime.app.Application;
#end

class DiscordPresence
{
	#if hxdiscord_rpc
	static inline var FLUSH_INTERVAL:Float = 2.0;

	static var WEAPON_NAMES:Array<String> = ["Scythe", "Hammer", "Bow", "Hook"];
	static var WEAPON_KEYS:Array<String> = ["scythe", "hammer", "bow", "hook"];

	static var presence:DiscordRichPresence = DiscordRichPresence.create();
	static var alive:Bool = false;
	static var dirty:Bool = false;
	static var lastFlush:Float = 0;
	static var overridden:Bool = false;

	static var details:String = "";
	static var state:String = "";
	static var smallKey:String = "";
	static var smallText:String = "";
	static var startStamp:Float = 0;

	static var wave:Int = -1;
	static var boss:Bool = false;
	static var weapon:Int = -1;
	static var kills:Int = 0;
	#end

	public static function init():Void
	{
		#if hxdiscord_rpc
		var clientId:String = "";
		try
		{
			var d:Dynamic = DataLoader.load(Paths.json("discord"));
			if (d.clientId != null)
				clientId = d.clientId;
		}
		catch (_:Dynamic) {}

		if (clientId == "")
		{
			trace("Discord presence disabled: set clientId in assets/data/discord.json");
			return;
		}

		var handlers:DiscordEventHandlers = DiscordEventHandlers.create();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientId, cpp.RawPointer.addressOf(handlers), 1, null);
		alive = true;
		Application.current.window.onClose.add(shutdown);
		#end
	}

	public static function tick():Void
	{
		#if hxdiscord_rpc
		if (!alive)
			return;
		Discord.RunCallbacks();
		if (dirty && haxe.Timer.stamp() - lastFlush >= FLUSH_INTERVAL)
			flush();
		#end
	}

	public static function shutdown():Void
	{
		#if hxdiscord_rpc
		if (!alive)
			return;
		alive = false;
		Discord.Shutdown();
		#end
	}

	public static function menu():Void
	{
		#if hxdiscord_rpc
		overridden = true;
		details = "In the Menus";
		state = bestText();
		smallKey = "";
		smallText = "";
		startStamp = 0;
		flush();
		#end
	}

	public static function tutorial():Void
	{
		#if hxdiscord_rpc
		overridden = true;
		details = "Reading the Controls";
		state = bestText();
		flush();
		#end
	}

	public static function paused():Void
	{
		#if hxdiscord_rpc
		overridden = true;
		details = boss ? "Paused — Boss Fight" : (wave > 0 ? "Paused — Wave " + wave : "Paused");
		flush();
		#end
	}

	public static function beginRun():Void
	{
		#if hxdiscord_rpc
		wave = 0;
		boss = false;
		weapon = -1;
		kills = 0;
		startStamp = Date.now().getTime() / 1000;
		#end
	}

	public static function playing(curWave:Int, bossFight:Bool, curWeapon:Int, curKills:Int):Void
	{
		#if hxdiscord_rpc
		var major = curWave != wave || bossFight != boss || curWeapon != weapon || overridden;
		if (!major && curKills == kills)
			return;
		wave = curWave;
		boss = bossFight;
		weapon = curWeapon;
		kills = curKills;
		overridden = false;
		details = boss ? "Boss Fight — Rofel" : (wave > 0 ? "Fighting Wave " + wave : "Entering the Arena");
		state = weaponName() + " · " + killText();
		smallKey = weapon >= 0 ? WEAPON_KEYS[weapon] : "";
		smallText = weaponName();
		if (major)
			flush();
		else
			dirty = true;
		#end
	}

	public static function died(curWave:Int, best:Int):Void
	{
		#if hxdiscord_rpc
		overridden = true;
		details = "Defeated on Wave " + curWave;
		state = "Best: Wave " + best + " · " + killText();
		startStamp = 0;
		flush();
		#end
	}

	#if hxdiscord_rpc
	static function weaponName():String
		return weapon >= 0 && weapon < WEAPON_NAMES.length ? WEAPON_NAMES[weapon] : "Unarmed";

	static function killText():String
		return kills == 1 ? "1 kill" : kills + " kills";

	static function bestText():String
	{
		var best = SaveData.bestWave();
		return best > 0 ? "Best: Wave " + best : "First run";
	}

	static function flush():Void
	{
		dirty = false;
		lastFlush = haxe.Timer.stamp();
		if (!alive)
			return;
		presence.details = details;
		presence.state = state;
		presence.largeImageKey = "icon";
		presence.largeImageText = "THE ENEMY";
		presence.smallImageKey = smallKey;
		presence.smallImageText = smallText;
		presence.startTimestamp = startStamp > 0 ? Std.int(startStamp) : 0;
		presence.endTimestamp = 0;
		Discord.UpdatePresence(cpp.RawPointer.addressOf(presence));
	}

	static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		trace("Discord presence connected");
	}

	static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace("Discord presence disconnected (" + errorCode + ")");
	}

	static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace("Discord presence error (" + errorCode + ")");
	}
	#end
}
