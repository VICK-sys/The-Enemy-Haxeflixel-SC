package systems;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import util.Paths;
import systems.world.Decor;

class RenderLayers
{
	static inline var CORPSE_BAND:Float = -800000;
	static inline var BURIED_BAND:Float = -400000;
	static inline var AIRBORNE_BAND:Float = 400000;

	public static inline var GHOST_BAND:Float = 900000;

	public static inline var GEAR_BIAS:Float = -1;
	public static inline var HELD_BIAS:Float = 1;

	public var host(default, null):FlxState;
	public var shadowLayer:FlxTypedGroup<FlxSprite>;
	public var entityLayer:FlxTypedGroup<FlxSprite>;
	public var tagLayer:FlxTypedGroup<FlxSprite>;
	public var playerShadow:FlxSprite;

	private var player:Player;
	private var heldSprite:FlxSprite;
	private var flying:Array<FlxSprite> = [];
	private var rigOf:Map<FlxSprite, FlxSprite> = new Map();
	private var rigBias:Map<FlxSprite, Float> = new Map();

	public function new(state:FlxState, player:Player, heldSprite:FlxSprite)
	{
		this.host = state;
		this.player = player;
		this.heldSprite = heldSprite;

		shadowLayer = new FlxTypedGroup<FlxSprite>();
		state.add(shadowLayer);

		playerShadow = new FlxSprite(player.x + 10, player.feetY, Paths.image("effects/shadow"));
		playerShadow.scale.set(4, 4);
		shadowLayer.add(playerShadow);

		entityLayer = new FlxTypedGroup<FlxSprite>();
		state.add(entityLayer);
		entityLayer.add(player);
		entityLayer.add(heldSprite);

		tagLayer = new FlxTypedGroup<FlxSprite>();
		state.add(tagLayer);
	}

	public function trackPart(part:FlxSprite, anchor:FlxSprite, bias:Float):Void
	{
		if (part == null || anchor == null || part == anchor)
			return;
		rigOf.set(part, anchor);
		rigBias.set(part, bias);
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

	public function adopt(pool:FlxTypedGroup<Dynamic>):Void
	{
		for (m in pool.members)
			adoptOne(cast m);
	}

	public function adoptOne(s:FlxSprite):Void
	{
		if (s != null)
		{
			var held = flying.indexOf(s) >= 0;
			if (s.exists && !held)
			{
				flying.push(s);
				entityLayer.add(s);
			}
			else if (!s.exists && held)
			{
				flying.remove(s);
				entityLayer.remove(s, true);
			}
		}
	}

	public function update():Void
	{
		playerShadow.x = player.shadowCenterX - playerShadow.width / 2;
		playerShadow.y = player.feetY;
		playerShadow.scale.set(player.shadowScaleX, player.shadowScaleY);
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
		if (s == heldSprite)
			return player.feetY + HELD_BIAS;
		if (s == player)
			return player.feetY;

		var anchor = rigOf.get(s);
		if (anchor != null)
			return sortKey(anchor) + rigBias.get(s);

		if (Std.isOfType(s, Enemies))
		{
			var e = cast(s, Enemies);
			if (e.isDead)
				return CORPSE_BAND + e.feetY;
			if (e.buried)
				return BURIED_BAND + e.feetY;
			return e.lift > 0 ? AIRBORNE_BAND + e.feetY : e.feetY;
		}
		if (flying.indexOf(s) >= 0)
			return s.y + s.height * 0.5;
		return Decor.sortValue(s);
	}
}
