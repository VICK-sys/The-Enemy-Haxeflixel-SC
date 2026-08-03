package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
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

	public static function spotX():Float
		return util.CustomArena.shopSet ? util.CustomArena.shopX : SPOT_X;

	public static function spotY():Float
		return util.CustomArena.shopSet ? util.CustomArena.shopY : SPOT_Y;
	static inline var REACH:Float = 260;
	static inline var PROMPT_DROP:Float = 8;
	static inline var PROMPT_W:Float = 460;
	static inline var WIN_X:Float = 29;
	static inline var INSIDE_Y:Float = 33;
	static inline var WIN_CLOSED:Float = 34;
	static inline var WIN_OPEN:Float = 8;
	static inline var WIN_SPEED:Float = 18;
	static inline var DOOR_FADE:Float = 0.35;
	static inline var KEEP_X:Float = 45;
	static inline var KEEP_DOWN:Float = 51;
	static inline var KEEP_UP:Float = 30;
	static inline var KEEP_SPEED:Float = 16;
	static inline var KEEP_FRAME:Int = 24;

	static inline var SORT_INSIDE:Float = -900002;
	static inline var SORT_KEEP:Float = -900001;
	static inline var SORT_WINDOW:Float = -900000;
	static inline var WAIT_CAP:Float = 45;

	public var open(default, null):Bool = false;
	public var onEnter:Void->Void;
	public var onClose:Void->Void;

	private var player:Player;
	private var sprite:FlxSprite;
	private var window:FlxSprite;
	private var inside:FlxSprite;
	private var keeper:FlxSprite;
	private var keepY:Float = KEEP_DOWN;
	private var door:FlxSound;
	private var rolling:Bool = false;
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
			Decor.place(sprite, spotX(), spotY());
			inside = pinned(SORT_INSIDE);
			inside.loadGraphic(Paths.image("props/shop_inside"));
			dress(inside);

			keeper = pinned(SORT_KEEP);
			keeper.loadGraphic(Paths.image("props/sheun"), true, KEEP_FRAME, KEEP_FRAME);
			keeper.animation.add("idle", [0, 1, 2, 3], 6, true);
			keeper.animation.play("idle");
			dress(keeper);

			window = pinned(SORT_WINDOW);
			window.loadGraphic(Paths.image("props/shop_window"));
			dress(window);

			layers.entityLayer.add(inside);
			layers.entityLayer.add(keeper);
			layers.entityLayer.add(window);
			layers.entityLayer.add(sprite);
			placeWindow();
		}

		door = FlxG.sound.create(Paths.sound("garageDoor")).setup(0.5);

		prompt = new FlxText(0, 0, PROMPT_W, "");
		prompt.setFormat(Lang.font(), 20, FlxColor.WHITE, CENTER);
		prompt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		prompt.visible = false;
	}

	public function addTo(state:flixel.FlxState):Void
		state.add(prompt);

	public function solid():Array<FlxSprite>
	{
		var list = Decor.solids([{n: "repairShop", x: spotX(), y: spotY()}]);
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
		if (!on && door != null && door.playing)
		{
			door.stop();
			rolling = false;
		}
		if (sprite != null)
			sprite.visible = on;
		if (window != null)
			window.visible = on;
		if (inside != null)
			inside.visible = on;
		if (keeper != null)
			keeper.visible = on && keepY < KEEP_DOWN;
		if (!on)
			prompt.visible = false;
	}

	function pinned(order:Float):PropSprite
	{
		var s = new PropSprite();
		s.layerMode = PropSprite.SORTED;
		s.sortY = order;
		return s;
	}

	function dress(s:FlxSprite):Void
	{
		util.PixelPerfectShader.on(s);
		s.scale.set(sprite.scale.x, sprite.scale.y);
		s.updateHitbox();
	}

	function placeWindow():Void
	{
		window.x = sprite.x + WIN_X * sprite.scale.x;
		window.y = sprite.y + winY * sprite.scale.y;
		inside.x = window.x;
		inside.y = sprite.y + INSIDE_Y * sprite.scale.y;
		keeper.x = sprite.x + KEEP_X * sprite.scale.x;
		keeper.y = sprite.y + keepY * sprite.scale.y;
		keeper.visible = !hidden && keepY < KEEP_DOWN;
	}

	public function inReach():Bool
	{
		if (!open || sprite == null)
			return false;
		var dx = player.x + player.width * 0.5 - spotX();
		var dy = player.feetY - spotY();
		return dx * dx + dy * dy <= REACH * REACH;
	}

	public function update(elapsed:Float):Void
	{
		if (sprite == null || hidden)
			return;

		var wantY = open ? WIN_OPEN : WIN_CLOSED;
		var moving = winY != wantY;

		if (moving && !rolling)
		{
			door.play(true);
			util.Sfx.tune(door, window.x + window.width * 0.5, window.y, 0.5);
		}
		else if (!moving && rolling)
			door.fadeOut(DOOR_FADE, 0, function(_) door.stop());
		rolling = moving;

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

		var keepWant = open ? KEEP_UP : KEEP_DOWN;
		if (keepY > keepWant)
		{
			keepY -= KEEP_SPEED * elapsed;
			if (keepY < keepWant)
				keepY = keepWant;
		}
		else if (keepY < keepWant)
		{
			keepY += KEEP_SPEED * elapsed;
			if (keepY > keepWant)
				keepY = keepWant;
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
			prompt.text = Lang.t("shop.enter", [util.Controls.bindName(util.Controls.INTERACT)]);
			prompt.x = spotX() - PROMPT_W * 0.5;
			prompt.y = sprite.y + sprite.height + PROMPT_DROP;
			if (util.Controls.justPressed(util.Controls.INTERACT))
			{
				if (onEnter != null)
					onEnter();
			}
		}
	}
}
