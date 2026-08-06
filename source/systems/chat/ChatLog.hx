package systems.chat;

import net.Net;
import util.SaveData;

typedef ChatMsg =
{
	key:String,
	sender:Int,
	seq:Int,
	name:String,
	hue:Float,
	text:String,
	reply:String,
	edited:Bool,
	deleted:Bool
}

class ChatLog
{
	public static inline var CAP:Int = 60;
	public static inline var MAX_LEN:Int = 120;
	public static inline var NOTICE:Int = -2;

	public static var onCommand:String->Void;

	public static var messages:Array<ChatMsg> = [];
	public static var version(default, null):Int = 0;
	public static var changedAt(default, null):Float = 0;

	static var seq:Int = 0;

	public static function idleFor():Float
		return changedAt <= 0 ? 0 : haxe.Timer.stamp() - changedAt;

	static function bump():Void
	{
		version++;
		changedAt = haxe.Timer.stamp();
	}

	public static function clear():Void
	{
		messages = [];
		seq = 0;
		bump();
	}

	static function ownName():String
	{
		var n = SaveData.playerName();
		return n == "" ? util.Lang.t("online.defaultName") : n;
	}

	public static function notice(text:String):Void
	{
		if (text == null || text == "")
			return;
		if (text.length > MAX_LEN)
			text = text.substr(0, MAX_LEN);
		var m = make(NOTICE, seq, "", 0, text, null);
		seq++;
		push(m);
	}

	public static function send(text:String, ?replyKey:String):Void
	{
		text = StringTools.trim(text);
		if (text == "")
			return;
		if (text.charAt(0) == "/")
		{
			if (onCommand != null)
				onCommand(text);
			return;
		}
		if (text.length > MAX_LEN)
			text = text.substr(0, MAX_LEN);
		var m = make(Net.selfId, seq, ownName(), SaveData.playerHue(), text, replyKey);
		seq++;
		push(m);
		Net.send({t: "chat", i: m.seq, x: text, r: replyKey, nm: m.name, hu: m.hue});
	}

	public static function edit(key:String, text:String):Void
	{
		text = StringTools.trim(text);
		var m = get(key);
		if (m == null || m.sender != Net.selfId || text == "")
			return;
		if (text.length > MAX_LEN)
			text = text.substr(0, MAX_LEN);
		m.text = text;
		m.edited = true;
		bump();
		Net.send({t: "chatE", i: m.seq, x: text});
	}

	public static function remove(key:String):Void
	{
		var m = get(key);
		if (m == null || m.sender != Net.selfId)
			return;
		m.deleted = true;
		bump();
		Net.send({t: "chatD", i: m.seq});
	}

	public static function receive(msg:Dynamic):Bool
	{
		switch ((msg.t : String))
		{
			case "chat":
				var text:String = msg.x == null ? "" : msg.x;
				if (text.length > MAX_LEN)
					text = text.substr(0, MAX_LEN);
				push(make(msg.f, msg.i, msg.nm == null ? "?" : msg.nm, msg.hu == null ? 0.0 : msg.hu, text, msg.r));
				util.MenuSfx.hover();
				return true;
			case "chatE":
				var m = get(msg.f + ":" + msg.i);
				if (m != null && msg.x != null)
				{
					var text:String = msg.x;
					if (text.length > MAX_LEN)
						text = text.substr(0, MAX_LEN);
					m.text = text;
					m.edited = true;
					bump();
				}
				return true;
			case "chatD":
				var m = get(msg.f + ":" + msg.i);
				if (m != null)
				{
					m.deleted = true;
					bump();
				}
				return true;
			case "chatN":
				notice(msg.x == null ? "" : msg.x);
				return true;
			default:
				return false;
		}
	}

	public static function get(key:String):ChatMsg
	{
		for (m in messages)
			if (m.key == key)
				return m;
		return null;
	}

	static function make(sender:Int, sq:Int, name:String, hue:Float, text:String, reply:String):ChatMsg
	{
		return {
			key: sender + ":" + sq,
			sender: sender,
			seq: sq,
			name: name,
			hue: hue,
			text: text,
			reply: reply,
			edited: false,
			deleted: false
		};
	}

	static function push(m:ChatMsg):Void
	{
		messages.push(m);
		while (messages.length > CAP)
			messages.shift();
		bump();
	}
}
