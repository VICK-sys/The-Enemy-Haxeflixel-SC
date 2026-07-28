package net;

import flixel.FlxSprite;

class PeerRoster
{
	private var peers:Map<Int, Peer> = new Map();
	private var spare:Array<Peer> = [];
	private var factory:Void -> Peer;

	public function new(factory:Void -> Peer)
	{
		this.factory = factory;
	}

	public function get(id:Int):Peer
	{
		if (id < 0 || id == Net.selfId)
			return null;

		var p = peers.get(id);
		if (p != null)
			return p;

		p = spare.pop();
		if (p == null)
			p = factory();
		p.claim(id);
		peers.set(id, p);
		return p;
	}

	public function drop(id:Int):Void
	{
		var p = peers.get(id);
		if (p == null)
			return;
		p.hide();
		peers.remove(id);
		spare.push(p);
	}

	public function dropAll():Void
	{
		for (id in [for (k in peers.keys()) k])
			drop(id);
	}

	public function update(elapsed:Float):Void
	{
		for (p in peers)
			p.update(elapsed);
	}

	public function fillBodies(out:Array<FlxSprite>):Void
	{
		out.resize(0);
		for (p in peers)
			if (p.targetable())
				out.push(p.avatar.sprite);
	}

	public function eachAvatar(f:RemoteAvatar->Void):Void
	{
		for (p in peers)
			if (p != null && p.avatar != null)
				f(p.avatar);
	}

	public function count():Int
	{
		var n = 0;
		for (p in peers)
			if (p.live)
				n++;
		return n;
	}

	public function everyoneDown():Bool
	{
		for (p in peers)
			if (p.live && !p.dead)
				return false;
		return true;
	}
}
