package net;

class Peer
{
	public var id:Int = -1;
	public var avatar(default, null):RemoteAvatar;
	public var fx(default, null):RemoteFx;
	public var dead:Bool = false;
	public var live:Bool = false;

	public function new(avatar:RemoteAvatar, fx:RemoteFx)
	{
		this.avatar = avatar;
		this.fx = fx;
	}

	public function claim(id:Int):Void
	{
		this.id = id;
		dead = false;
		live = true;

		avatar.setLeveling(false);
		avatar.setReady(false);
		avatar.setAfk(false);
		avatar.setName("PLAYER " + (id + 1));
	}

	public function applyAvatar(m:Dynamic):Void
	{
		avatar.apply(m);
		dead = m.dd == true;
		if (fx == null)
			return;

		var hk:Array<Dynamic> = m.hk;
		var yo:Array<Dynamic> = m.yo;
		var th:Array<Dynamic> = m.th;
		fx.setHook(hk != null, hk != null ? hk[0] : 0, hk != null ? hk[1] : 0, hk != null ? hk[2] : 0,
			hk != null ? hk[3] : 0, hk != null ? hk[4] : 0);
		fx.setYoyo(yo != null, yo != null ? yo[0] : 0, yo != null ? yo[1] : 0, yo != null ? yo[2] : 0);
		fx.setThrown(th != null, th != null ? th[0] : 0, th != null ? th[1] : 0, th != null ? th[2] : 0,
			th != null ? th[3] : 0);
	}

	public function update(elapsed:Float):Void
	{
		avatar.update(elapsed);
		if (fx != null)
			fx.update(elapsed);
	}

	public function hide():Void
	{
		live = false;
		dead = true;
		id = -1;
		avatar.setLeveling(false);
		avatar.setReady(false);
		avatar.setAfk(false);
		avatar.clearDeath();
		avatar.sprite.visible = false;
		avatar.held.visible = false;
		avatar.shadow.visible = false;
		avatar.tag.visible = false;
		avatar.note.visible = false;
		if (fx != null)
		{
			fx.setHook(false, 0, 0, 0, 0, 0);
			fx.setYoyo(false, 0, 0, 0);
			fx.setThrown(false, 0, 0, 0, 0);
		}
	}

	public function targetable():Bool
		return live && !dead && avatar.sprite.visible;
}
