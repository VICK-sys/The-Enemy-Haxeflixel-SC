package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import entities.Player;
import systems.world.Decor;
import systems.RenderLayers;
import util.Lang;

class Shop
{
	public static inline var EVERY:Int = 10;

	static inline var SPOT_X:Float = 1280;
	static inline var SPOT_Y:Float = 340;
	static inline var REACH:Float = 260;
	static inline var SHUT_TINT:Int = 0xFF6E6E7A;
	static inline var PROMPT_DROP:Float = 8;
	static inline var PROMPT_W:Float = 460;
	static inline var GLOW_RATE:Float = 3.2;
	static inline var GLOW_AMP:Float = 0.22;
	static inline var WAIT_CAP:Float = 45;

	public var open(default, null):Bool = false;
	public var onEnter:Void->Void;
	public var onClose:Void->Void;

	private var player:Player;
	private var sprite:FlxSprite;
	private var prompt:FlxText;
	private var glow:Float = 0;
	private var clock:Float = 0;

	public function new(player:Player, layers:RenderLayers)
	{
		this.player = player;

		sprite = Decor.make("repairShop");
		if (sprite != null)
		{
			Decor.place(sprite, SPOT_X, SPOT_Y);
			sprite.color = SHUT_TINT;
			layers.entityLayer.add(sprite);
		}

		prompt = new FlxText(0, 0, PROMPT_W, "");
		prompt.setFormat(Lang.font(), 20, FlxColor.WHITE, CENTER);
		prompt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		prompt.visible = false;
	}

	public function addTo(state:flixel.FlxState):Void
		state.add(prompt);

	public function solid():Array<FlxSprite>
	{
		var list = Decor.solids([{n: "repairShop", x: SPOT_X, y: SPOT_Y}]);
		var out:Array<FlxSprite> = [];
		for (s in list.members)
			if (s != null)
				out.push(s);
		return out;
	}

	public function setOpen(on:Bool):Void
	{
		if (open == on)
			return;
		open = on;
		glow = 0;
		clock = 0;
		if (!on)
		{
			shut();
			if (onClose != null)
				onClose();
		}
	}

	/** Close without releasing the hold: the screen the player just opened owns it now. */
	public function dismiss():Void
	{
		if (!open)
			return;
		open = false;
		glow = 0;
		clock = 0;
		shut();
	}

	function shut():Void
	{
		if (sprite != null)
			sprite.color = SHUT_TINT;
		prompt.visible = false;
	}

	public function inReach():Bool
	{
		if (!open || sprite == null)
			return false;
		var dx = player.x + player.width * 0.5 - SPOT_X;
		var dy = player.feetY - SPOT_Y;
		return dx * dx + dy * dy <= REACH * REACH;
	}

	public function update(elapsed:Float):Void
	{
		if (sprite == null)
			return;

		if (open)
		{
			clock += elapsed;
			if (clock > WAIT_CAP)
			{
				setOpen(false);
				return;
			}
			glow += GLOW_RATE * elapsed;
			var lit = 1 - GLOW_AMP * (0.5 + 0.5 * Math.sin(glow));
			var v = Std.int(255 * lit);
			sprite.color = FlxColor.fromRGB(255, v, v);
		}

		var near = inReach();
		prompt.visible = near;
		if (near)
		{
			prompt.text = Lang.t("shop.enter");
			prompt.x = SPOT_X - PROMPT_W * 0.5;
			prompt.y = sprite.y + sprite.height + PROMPT_DROP;
			if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z)
			{
				if (onEnter != null)
					onEnter();
			}
		}
	}
}
