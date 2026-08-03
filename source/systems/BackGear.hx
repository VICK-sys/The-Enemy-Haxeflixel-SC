package systems;

import flixel.FlxSprite;

class BackGear
{
	static inline var SPIN:Float = 220;
	static inline var OFF_X:Float = 20;
	static inline var LEAN_IN:Float = 10;
	static inline var OFF_Y:Float = 15;
	static inline var PIVOT_X:Float = 20;
	static inline var PIVOT_Y:Float = 19;
	static inline var PLACE_X:Float = 20;
	static inline var PLACE_Y:Float = 23;
	static inline var SCALE:Float = 4;

	static inline var PACK_W:Int = 16;
	static inline var PACK_H:Int = 17;
	static inline var PACK_PIVOT_X:Float = 8;
	static inline var PACK_PIVOT_Y:Float = 8;
	static inline var PACK_PLACE_X:Float = 8;
	static inline var PACK_PLACE_Y:Float = 12;
	static inline var IDLE_FPS:Int = 9;
	static inline var MOVE_FPS:Int = 12;

	public var sprite:FlxSprite;

	private var hue:Float = -1;
	private var skin:Int = -1;
	private var gearIdx:Int = -1;
	private var pack:Bool = false;

	public function new()
	{
		sprite = new FlxSprite();
		paint(0);
		sprite.antialiasing = false;
		sprite.scale.set(SCALE, SCALE);
		sprite.width = 1;
		sprite.height = 1;
	}

	public function paint(h:Float, skinIndex:Int = -1, gearIndex:Int = -1):Void
	{
		var i = skinIndex < 0 ? util.SaveData.playerSkin() : util.Skins.clamp(skinIndex);
		var g = gearIndex < 0 ? util.SaveData.playerGear() : util.Skins.clampGear(gearIndex);
		if (h == hue && i == skin && g == gearIdx)
			return;
		hue = h;
		skin = i;
		gearIdx = g;

		var art = util.Skins.gearOf(g);
		pack = art != null;
		if (pack)
		{
			sprite.loadGraphic(util.HuePalette.graphic(art, h), true, PACK_W, PACK_H);
			sprite.animation.add("turn", [for (f in 0...sprite.animation.numFrames) f], MOVE_FPS, true);
			sprite.animation.play("turn");
			sprite.origin.set(PACK_PIVOT_X, PACK_PIVOT_Y);
		}
		else
		{
			sprite.frames = util.HuePalette.sparrow(util.Skins.of(i), h);
			sprite.frame = sprite.frames.getByName("Part00000");
			sprite.origin.set(PIVOT_X, PIVOT_Y);
		}
		sprite.scale.set(SCALE, SCALE);
	}

	public static function leanFor(anim:String):Float
	{
		if (anim == "dashBack")
			return -1;
		return anim == "walk" || anim == "dash" ? 1 : 0;
	}

	public function update(elapsed:Float, cx:Float, cy:Float, facingLeft:Bool, lean:Float, shown:Bool, spin:Float = 0, lift:Float = 0,
			spinCy:Float = 0, ?anim:String):Void
	{
		sprite.visible = shown;
		if (!shown)
			return;
		if (pack)
		{
			sprite.angle = spin;
			sprite.flipX = facingLeft;
			if (sprite.animation.curAnim != null)
				sprite.animation.curAnim.frameRate = anim == "idle" || anim == null ? IDLE_FPS : MOVE_FPS;
		}
		else
			sprite.angle += SPIN * elapsed;
		var off = OFF_X - LEAN_IN * lean;
		var ax = cx + (facingLeft ? off : -off);
		var ay = cy + OFF_Y;
		if (spin != 0)
		{
			var rad = spin * Math.PI / 180;
			var cos = Math.cos(rad);
			var sin = Math.sin(rad);
			var relX = ax - cx;
			var relY = ay - spinCy;
			ax = cx + relX * cos - relY * sin;
			ay = spinCy + relX * sin + relY * cos;
		}
		sprite.setPosition(ax - (pack ? PACK_PLACE_X : PLACE_X), ay - lift - (pack ? PACK_PLACE_Y : PLACE_Y));
	}
}
