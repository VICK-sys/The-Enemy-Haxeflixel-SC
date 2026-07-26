package systems;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import util.CustomArena;

class PropWorld
{
	public var solids(default, null):FlxTypedGroup<FlxSprite>;
	public var overlay(default, null):FlxTypedGroup<FlxSprite>;
	public var buried(default, null):Bool = false;

	private var player:Player;
	private var layers:RenderLayers;
	private var decor:Array<FlxSprite> = [];

	public function new(player:Player, layers:RenderLayers)
	{
		this.player = player;
		this.layers = layers;

		decor = Decor.build(CustomArena.props, layers.entityLayer);
		solids = Decor.solids(CustomArena.props);
		PropBlock.solids = solids;

		overlay = new FlxTypedGroup<FlxSprite>();
		overlay.active = false;
	}

	public function collidePlayer():Void
		FootCollide.against(player, player.feetY, solids);

	public function setDecorVisible(on:Bool):Void
	{
		for (s in decor)
			s.visible = on;
	}

	public function update():Void
	{
		overlay.clear();
		buried = false;
		var lowest = Math.POSITIVE_INFINITY;

		var feet = player.feetY;
		var cx = player.x + player.width / 2;
		for (s in decor)
		{
			if (s == null || !s.visible)
				continue;
			var base = Decor.sortValue(s);
			if (base <= feet)
				continue;
			if (base < lowest)
				lowest = base;
			if (cx >= s.x && cx <= s.x + s.width && feet >= s.y)
				buried = true;
		}

		if (lowest < Math.POSITIVE_INFINITY)
			for (m in layers.entityLayer.members)
				if (m != null && m.exists && m.visible && layers.keyOf(m) >= lowest)
					overlay.add(m);
	}
}
