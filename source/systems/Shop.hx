package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import entities.Player;
import systems.world.Decor;
import systems.world.PropSprite;
import systems.RenderLayers;
import util.Lang;
import util.Paths;

class Shop
{
	public static inline var EVERY:Int = 10;

	static inline var SPOT_X:Float = 1280;
	static inline var SPOT_Y:Float = 340;
	static inline var REACH:Float = 260;
	static inline var PROMPT_DROP:Float = 8;
	static inline var PROMPT_W:Float = 460;
	static inline var WIN_X:Float = 29;
	static inline var INSIDE_Y:Float = 33;
	static inline var WIN_CLOSED:Float = 34;
	static inline var WIN_OPEN:Float = 8;
	static inline var WIN_SPEED:Float = 30;
	static inline var WAIT_CAP:Float = 45;

	public var open(default, null):Bool = false;
	public var onEnter:Void->Void;
	public var onClose:Void->Void;

	private var player:Player;
	private var sprite:FlxSprite;
	private var window:FlxSprite;
	private var inside:FlxSprite;
	private var winY:Float = WIN_CLOSED;
	private var prompt:FlxText;
	private var hidden:Bool = false;
	private var clock:Float = 0;

	public function new(player:Player, layers:RenderLayers)
	{
		this.player = player;

		sprite = Decor.make("repairShop");
		if (sprite != null)
		{
			Decor.place(sprite, SPOT_X, SPOT_Y);
			var back = new PropSprite();
			back.layerMode = PropSprite.GROUND;
			inside = back;
			inside.loadGraphic(Paths.image("props/shop_inside"));
			inside.antialiasing = false;
			inside.scale.set(sprite.scale.x, sprite.scale.y);
			inside.updateHitbox();
			layers.entityLayer.add(inside);
			window = new FlxSprite();
			window.loadGraphic(Paths.image("props/shop_window"));
			window.antialiasing = false;
			window.scale.set(sprite.scale.x, sprite.scale.y);
			window.updateHitbox();
			layers.entityLayer.add(window);
			layers.entityLayer.add(sprite);
			placeWindow();
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
		clock = 0;
		shut();
	}

	function shut():Void
		prompt.visible = false;

	public function setVisible(on:Bool):Void
	{
		hidden = !on;
		if (sprite != null)
			sprite.visible = on;
		if (window != null)
			window.visible = on;
		if (inside != null)
			inside.visible = on;
		if (!on)
			prompt.visible = false;
	}

	function placeWindow():Void
	{
		window.x = sprite.x + WIN_X * sprite.scale.x;
		window.y = sprite.y + winY * sprite.scale.y;
		inside.x = window.x;
		inside.y = sprite.y + INSIDE_Y * sprite.scale.y;
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
		if (sprite == null || hidden)
			return;

		var wantY = open ? WIN_OPEN : WIN_CLOSED;
		if (winY < wantY)
		{
			winY += WIN_SPEED * elapsed;
			if (winY > wantY)
				winY = wantY;
		}
		else if (winY > wantY)
		{
			winY -= WIN_SPEED * elapsed;
			if (winY < wantY)
				winY = wantY;
		}
		placeWindow();

		if (open)
		{
			clock += elapsed;
			if (clock > WAIT_CAP)
			{
				setOpen(false);
				return;
			}
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
