package systems;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.Lang;

class AfkIndicator
{
	static inline var WIDTH:Float = 320;
	static inline var BODY_UP:Float = 119;
	static inline var GHOST_ART_TOP:Float = 8;
	static inline var GHOST_GAP:Float = 11;
	static inline var TAG_BOX_OVERLAP:Float = 20;

	public var text(default, null):FlxText;
	public var on(default, set):Bool = false;

	private var anchor:FlxSprite;
	private var ghost:CoopGhost;
	private var nameTag:FlxText;

	public function new(layers:RenderLayers, anchor:FlxSprite, ghost:CoopGhost)
	{
		this.anchor = anchor;
		this.ghost = ghost;

		text = new FlxText(0, 0, WIDTH, "AFK");
		text.setFormat(Lang.smallFont(), Lang.smallSize(), FlxColor.YELLOW, CENTER);
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		text.visible = false;
		layers.tagLayer.add(text);
	}

	public function stackAbove(tag:FlxText):Void
		nameTag = tag;

	function set_on(value:Bool):Bool
	{
		on = value;
		if (!value)
			text.visible = false;
		return value;
	}

	public function update():Void
	{
		var useGhost = !anchor.visible && ghost != null && ghost.sprite.exists;
		text.visible = on && (anchor.visible || useGhost);
		if (!text.visible)
			return;

		var target = useGhost ? ghost.sprite : anchor;
		text.x = target.x + target.width * 0.5 - WIDTH * 0.5;
		text.y = useGhost ? target.y + GHOST_ART_TOP - text.height - GHOST_GAP
			: nameTag != null && nameTag.visible ? nameTag.y - text.height + TAG_BOX_OVERLAP
			: target.y - BODY_UP;
	}
}
