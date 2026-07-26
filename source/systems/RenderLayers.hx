package systems;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import util.Paths;
import util.SideView;
import systems.world.Decor;

class RenderLayers
{
	public var shadowLayer:FlxTypedGroup<FlxSprite>;
	public var entityLayer:FlxTypedGroup<FlxSprite>;
	public var tagLayer:FlxTypedGroup<FlxSprite>;
	public var playerShadow:FlxSprite;

	private var player:Player;
	private var scythe:FlxSprite;

	public function new(state:FlxState, player:Player, scythe:FlxSprite)
	{
		this.player = player;
		this.scythe = scythe;

		shadowLayer = new FlxTypedGroup<FlxSprite>();
		state.add(shadowLayer);

		playerShadow = new FlxSprite(player.x + 30, player.feetY, Paths.image("effects/shadow"));
		playerShadow.scale.set(4, 4);
		shadowLayer.add(playerShadow);

		entityLayer = new FlxTypedGroup<FlxSprite>();
		state.add(entityLayer);
		entityLayer.add(player);
		entityLayer.add(scythe);

		tagLayer = new FlxTypedGroup<FlxSprite>();
		state.add(tagLayer);
	}

	public function addEnemy(e:Enemies):FlxSprite
	{
		var sh = new FlxSprite(0, 0, Paths.image("effects/shadow"));
		sh.scale.set(e.shadowScaleX, 4);
		shadowLayer.add(sh);
		entityLayer.add(e);
		return sh;
	}

	public function removeEnemy(e:Enemies, shadow:FlxSprite):Void
	{
		entityLayer.remove(e, true);
		shadowLayer.remove(shadow, true);
	}

	public function update():Void
	{
		playerShadow.x = player.shadowCenterX - playerShadow.width / 2;
		SideView.placeShadow(playerShadow, player.x, player.width, player.y + player.height, player.feetY, player.shadowScaleX, 4);
		entityLayer.sort(sortByFeet, FlxSort.ASCENDING);
	}

	function sortByFeet(order:Int, a:FlxSprite, b:FlxSprite):Int
	{
		return FlxSort.byValues(order, sortKey(a), sortKey(b));
	}

	public function keyOf(s:FlxSprite):Float
		return sortKey(s);

	function sortKey(s:FlxSprite):Float
	{
		if (s == scythe)
			return player.feetY + 1;
		if (s == player)
			return player.feetY;
		if (Std.isOfType(s, Enemies))
			return cast(s, Enemies).feetY;
		return Decor.sortValue(s);
	}
}
