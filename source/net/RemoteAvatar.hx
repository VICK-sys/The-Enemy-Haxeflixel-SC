package net;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import systems.RenderLayers;
import systems.weapons.HeldWeapon;
import util.Paths;
import util.SideView;

class RemoteAvatar
{
	static inline var LERP:Float = 12;
	static inline var SNAP_DIST:Float = 260;

	static var WEAPON_IMAGES:Array<String> = ["items/mufu_scythe", "items/mufu_hammer", "items/mufu_bow", "items/mufu_hook"];

	public var sprite:FlxSprite;
	public var held:FlxSprite;
	public var shadow:FlxSprite;
	public var tag:FlxText;

	private var targetX:Float = 0;
	private var targetY:Float = 0;
	private var haveTarget:Bool = false;
	private var weaponIdx:Int = -1;
	private var heldOX:Float = 30;
	private var heldOY:Float = 65;

	static inline var BOW_INDEX:Int = 2;
	static inline var OFFSET_Y:Float = -17;
	static inline var TAG_UP:Float = 46;
	static inline var TAG_WIDTH:Float = 320;

	public function new(layers:RenderLayers)
	{
		sprite = new FlxSprite();
		sprite.frames = Paths.sparrow("characters/mufu");
		sprite.animation.addByPrefix("idle", "Idle", 12, true);
		sprite.animation.addByPrefix("walk", "Run", 12, true);
		sprite.animation.addByPrefix("hurt", "Hurt", 12, false);
		sprite.animation.addByPrefix("death", "Death", 12, false);
		sprite.antialiasing = false;
		sprite.width = 75;
		sprite.height = 95;
		sprite.offset.set(-19, -17);
		sprite.scale.set(4, 4);
		sprite.animation.play("idle");
		sprite.visible = false;
		layers.entityLayer.add(sprite);

		held = new FlxSprite();
		held.antialiasing = false;
		held.scale.set(4, 4);
		held.visible = false;
		layers.entityLayer.add(held);

		shadow = new FlxSprite(0, 0, Paths.image("effects/shadow"));
		shadow.scale.set(4, 4);
		shadow.visible = false;
		layers.shadowLayer.add(shadow);

		tag = new FlxText(0, 0, TAG_WIDTH, "");
		tag.setFormat(null, 18, FlxColor.WHITE, CENTER);
		tag.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		tag.visible = false;
		layers.tagLayer.add(tag);
	}

	public function setName(name:String):Void
		tag.text = name;

	public function apply(m:Dynamic):Void
	{
		targetX = m.x;
		targetY = m.y;
		if (!haveTarget || Math.abs(sprite.x - targetX) + Math.abs(sprite.y - targetY) > SNAP_DIST)
		{
			sprite.x = targetX;
			sprite.y = targetY;
		}
		haveTarget = true;

		sprite.visible = true;
		sprite.flipX = m.fx;
		if (m.an != null && sprite.animation.name != m.an && sprite.animation.getByName(m.an) != null)
			sprite.animation.play(m.an);

		var wi:Int = m.wi;
		if (wi != weaponIdx && wi >= 0 && wi < WEAPON_IMAGES.length)
		{
			weaponIdx = wi;
			held.loadGraphic(Paths.image(WEAPON_IMAGES[wi]));

			if (wi == BOW_INDEX)
				held.origin.set(held.width * 0.5, held.height * 0.5);
			else
				held.origin.set(held.width * 0.5, held.height);
		}
		held.visible = m.hv;
		held.angle = m.ha;
		held.flipX = m.hf;

		var ho:Array<Dynamic> = m.ho;
		if (ho != null)
		{
			heldOX = ho[0];
			heldOY = ho[1];
			var hs:Float = ho[2];
			held.scale.set(hs, hs);
			var charge:Float = ho[3];
			held.color = charge > 0 ? FlxColor.interpolate(FlxColor.WHITE, HeldWeapon.CHARGE_TINT, charge) : FlxColor.WHITE;
		}

		var bd:Array<Dynamic> = m.bd;
		if (bd != null)
		{
			sprite.angle = bd[0];
			sprite.offset.y = OFFSET_Y + bd[1];
			sprite.scale.set(bd[2], bd[3]);
		}

		shadow.visible = sprite.visible;
	}

	public function update(elapsed:Float):Void
	{
		if (!haveTarget)
			return;
		var k = Math.min(1, LERP * elapsed);
		sprite.x += (targetX - sprite.x) * k;
		sprite.y += (targetY - sprite.y) * k;

		held.x = sprite.x + heldOX;
		held.y = sprite.y + heldOY;

		shadow.x = sprite.x + 30;
		SideView.placeShadow(shadow, sprite.x, sprite.width, sprite.y + sprite.height, sprite.y + entities.Player.FEET, 4, 4);

		tag.visible = sprite.visible;
		tag.x = sprite.x + sprite.width * 0.5 - TAG_WIDTH * 0.5;
		tag.y = sprite.y - TAG_UP;
	}
}
