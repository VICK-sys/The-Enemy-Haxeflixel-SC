package net;

import flixel.FlxG;
import haxe.Json;
#if desktop
import sys.net.Host;
import sys.net.Socket;
#end

enum abstract NetMode(Int)
{
	var Off;
	var HostMode;
	var ClientMode;
}

class Net
{
	public static inline var PORT:Int = 7777;
	public static inline var PORT_TRIES:Int = 10;
	public static inline var MAX_GUESTS:Int = 7;
	public static inline var HOST_ID:Int = 0;

	static var PRIVATE_TO_HOST:Array<String> = ["hit", "took"];

	public static var hostPort:Int = PORT;
	public static var mode:NetMode = Off;
	public static var connected:Bool = false;
	public static var dropped:Bool = false;
	public static var selfId:Int = HOST_ID;
	public static var inGame:Bool = false;

	public static var active(get, never):Bool;
	public static var isHost(get, never):Bool;
	public static var isClient(get, never):Bool;
	public static var guestCount(get, never):Int;

	#if desktop
	static var server:Socket;
	static var localEvents:Array<Dynamic> = [];
	static var peers:Array<Socket> = [];
	static var buffers:Array<String> = [];
	static var ids:Array<Int> = [];
	static var nextId:Int = 1;
	#end

	static function get_active():Bool
		return mode != Off;

	static function get_isHost():Bool
		return mode == HostMode;

	static function get_isClient():Bool
		return mode == ClientMode;

	static function get_guestCount():Int
	{
		#if desktop
		return peers.length;
		#else
		return 0;
		#end
	}

	public static function host():Bool
	{
		#if desktop
		stop();
		for (offset in 0...PORT_TRIES)
		{
			var tryPort = PORT + offset;
			try
			{
				server = new Socket();
				server.bind(new Host("0.0.0.0"), tryPort);
				server.listen(MAX_GUESTS);
				server.setBlocking(false);
				mode = HostMode;
				selfId = HOST_ID;
				nextId = 1;
				hostPort = tryPort;
				dropped = false;
				FlxG.autoPause = false;
				return true;
			}
			catch (e:Dynamic)
			{
				if (server != null)
				{
					try server.close() catch (e2:Dynamic) {}
					server = null;
				}
			}
		}
		return false;
		#else
		return false;
		#end
	}

	public static function join(address:String):Bool
	{
		#if desktop
		stop();
		try
		{
			var target = address;
			var port = PORT;
			var colon = address.indexOf(":");
			if (colon >= 0)
			{
				target = address.substr(0, colon);
				port = Std.parseInt(address.substr(colon + 1));
			}
			var sock = new Socket();
			sock.setTimeout(5);
			sock.connect(new Host(target), port);
			sock.setBlocking(false);
			sock.setFastSend(true);
			addPeer(sock, HOST_ID);
			mode = ClientMode;

			selfId = -1;
			connected = true;
			dropped = false;
			FlxG.autoPause = false;
			return true;
		}
		catch (e:Dynamic)
		{
			stop();
			return false;
		}
		#else
		return false;
		#end
	}

	public static function stop():Void
	{
		#if desktop
		for (s in peers)
		{
			try s.close() catch (e:Dynamic) {}
		}
		peers = [];
		buffers = [];
		ids = [];
		localEvents = [];
		if (server != null)
		{
			try server.close() catch (e:Dynamic) {}
			server = null;
		}
		#end
		if (mode != Off)
			FlxG.autoPause = true;
		mode = Off;
		selfId = HOST_ID;
		connected = false;
		inGame = false;
	}

	public static function send(msg:Dynamic):Void
	{
		#if desktop
		if (peers.length == 0)
			return;
		if (mode == HostMode)
		{
			msg.f = HOST_ID;
			write(Json.stringify(msg) + "\n", -1);
		}
		else
		{
			try
			{
				peers[0].output.writeString(Json.stringify(msg) + "\n");
			}
			catch (e:Dynamic)
			{
				markDropped();
			}
		}
		#end
	}

	public static function poll():Array<Dynamic>
	{
		var out:Array<Dynamic> = [];
		#if desktop
		if (mode == HostMode && server != null)
			acceptWaiting();

		var i = peers.length;
		while (i-- > 0)
		{
			if (i >= peers.length)
				continue;
			if (!drain(i))
			{
				losePeer(i);
				continue;
			}
			harvest(i, out);
		}

		while (localEvents.length > 0)
			out.push(localEvents.shift());
		#end
		return out;
	}

	#if desktop
	static function addPeer(sock:Socket, id:Int):Void
	{
		peers.push(sock);
		buffers.push("");
		ids.push(id);
	}

	static function acceptWaiting():Void
	{
		while (peers.length < MAX_GUESTS)
		{
			var incoming:Socket = null;
			try
			{
				incoming = server.accept();
			}
			catch (e:Dynamic)
			{
				return;
			}
			if (incoming == null)
				return;

			incoming.setBlocking(false);
			incoming.setFastSend(true);
			var id = nextId++;
			addPeer(incoming, id);
			connected = true;

			try incoming.output.writeString(Json.stringify({t: "hello", f: HOST_ID, id: id, go: inGame}) + "\n") catch (e:Dynamic) {}
			send({t: "join", id: id});
			localEvents.push({t: "join", f: HOST_ID, id: id});
		}
	}

	static function drain(i:Int):Bool
	{
		var bytes = haxe.io.Bytes.alloc(8192);
		while (true)
		{
			try
			{
				var n = peers[i].input.readBytes(bytes, 0, bytes.length);
				if (n <= 0)
					break;
				buffers[i] += bytes.getString(0, n);
				if (n < bytes.length)
					break;
			}
			catch (e:haxe.io.Eof)
			{
				return false;
			}
			catch (e:Dynamic)
			{
				break;
			}
		}
		return true;
	}

	static function harvest(i:Int, out:Array<Dynamic>):Void
	{
		var idx = buffers[i].indexOf("\n");
		while (idx >= 0)
		{
			var line = buffers[i].substr(0, idx);
			buffers[i] = buffers[i].substr(idx + 1);
			idx = buffers[i].indexOf("\n");
			if (line.length == 0)
				continue;

			var msg:Dynamic = null;
			try msg = Json.parse(line) catch (e:Dynamic) continue;
			if (msg == null)
				continue;

			if (mode == HostMode)
			{
				msg.f = ids[i];
				if (PRIVATE_TO_HOST.indexOf(msg.t) < 0)
					write(Json.stringify(msg) + "\n", i);
			}
			else if (msg.t == "hello")
				selfId = msg.id;

			out.push(msg);
		}
	}

	static function write(line:String, exceptIdx:Int):Void
	{
		var i = peers.length;
		while (i-- > 0)
		{
			if (i == exceptIdx)
				continue;
			try
			{
				peers[i].output.writeString(line);
			}
			catch (e:Dynamic)
			{
				losePeer(i);
			}
		}
	}

	static function losePeer(i:Int):Void
	{
		if (i < 0 || i >= peers.length)
			return;
		var id = ids[i];
		try peers[i].close() catch (e:Dynamic) {}
		peers.splice(i, 1);
		buffers.splice(i, 1);
		ids.splice(i, 1);

		if (mode == HostMode)
		{
			connected = peers.length > 0;
			send({t: "bye", id: id});
			localEvents.push({t: "bye", f: HOST_ID, id: id});
		}
		else
		{
			connected = false;
			dropped = true;
		}
	}
	#end

	static function markDropped():Void
	{
		#if desktop
		if (mode == HostMode)
			return;
		while (peers.length > 0)
			losePeer(0);
		#end
		connected = false;
		dropped = true;
	}
}
