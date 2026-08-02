package net;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import systems.RenderLayers;
import systems.weapons.HeldWeapon;
import util.Paths;
import util.Lang;

class RemoteAvatar
{
	static inline var LERP:Float = 12;
	static inline var SNAP_DIST:Float = 260;

	static var WEAPON_IMAGES:Array<String> = ["items/hammer", "items/revolver", "items/crossbow", "items/yoyo"];

	public var sprite:FlxSprite;
	public var held:FlxSprite;
	public var shadow:FlxSprite;
	public var tag:FlxText;
	public var note:FlxText;
	public var bubble:FlxSprite;

	private var targetX:Float = 0;
	private var targetY:Float = 0;
	private var haveTarget:Bool = false;
	private var weaponIdx:Int = -1;
	private var heldOX:Float = 10;
	private var heldOY:Float = 1;
	private var leveling:Bool = false;
	public var hue(default, null):Float = 0;
	public var skin(default, null):Int = 0;
	private var wasDead:Bool = false;
	private var burst:systems.DeathBurst;
	private var ghost:systems.CoopGhost;
	private var gear:systems.BackGear;
	private var ritual:systems.ReviveRitual;
	private var wasReviving:Bool = false;

	static inline var REVOLVER_INDEX:Int = 1;
	static inline var BOW_INDEX:Int = 2;
	static inline var OFFSET_Y:Float = 56;
	static inline var BUBBLE_UP:Float = 67;
	static inline var GHOST_ART_TOP:Float = 8;
	static inline var BUBBLE_GAP:Float = 11;
	static inline var TAG_UP:Float = 95;
	static inline var TAG_WIDTH:Float = 320;
	static inline var NOTE_UP:Float = 119;
	static inline var NOTE_COLOR:Int = 0xFFE8C860;

	public function new(layers:RenderLayers)
	{
		sprite = new FlxSprite();
		sprite.frames = Paths.sparrow(util.Skins.of(skin));
		sprite.animation.addByPrefix("idle", "Idle", 9, true);
		sprite.animation.addByPrefix("walk", "Run", 12, true);
		sprite.animation.addByPrefix("dash", "Dash", 12, false);
		sprite.animation.addByPrefix("dashBack", "Backdash", 12, false);
		sprite.animation.addByPrefix("hurt", "Hurt", 12, false);
		sprite.antialiasing = false;
		sprite.width = 42;
		sprite.height = 44;
		sprite.offset.set(2, 56);
		sprite.scale.set(4, 4);
		sprite.animation.play("idle");
		sprite.visible = false;
		layers.entityLayer.add(sprite);

		burst = new systems.DeathBurst();
		layers.host.insert(layers.host.members.indexOf(layers.entityLayer), burst.group);
		ghost = new systems.CoopGhost();
		layers.host.insert(layers.host.members.indexOf(layers.entityLayer), ghost.sprite);
		gear = new systems.BackGear();
		gear.sprite.visible = false;
		layers.entityLayer.add(gear.sprite);
		ritual = new systems.ReviveRitual(burst, ghost);

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
		tag.setFormat(Lang.font(), 18, FlxColor.WHITE, CENTER);
		tag.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		tag.visible = false;
		layers.tagLayer.add(tag);

		note = new FlxText(0, 0, TAG_WIDTH, "");
		note.setFormat(Lang.font(), 16, NOTE_COLOR, CENTER);
		note.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		note.visible = false;
		layers.tagLayer.add(note);

		bubble = new FlxSprite();
		bubble.loadGraphic(Paths.image("ui/speech_ready"));
		bubble.antialiasing = false;
		bubble.scale.set(4, 4);
		bubble.updateHitbox();
		bubble.visible = false;
		layers.tagLayer.add(bubble);
	}

	public function setReady(on:Bool):Void
		bubble.visible = on;

	public function clearDeath():Void
	{
		wasDead = false;
		wasReviving = false;
		ritual.cancel();
		burst.clear();
		ghost.hide();
	}

	public function setHue(h:Float):Void
		setLook(h, skin);

	public function setLook(h:Float, sk:Int):Void
	{
		sk = util.Skins.clamp(sk);
		if (h == hue && sk == skin)
			return;
		hue = h;
		skin = sk;
		gear.paint(h, sk);
		if (weaponIdx >= 0)
			held.loadGraphic(util.HuePalette.graphic(WEAPON_IMAGES[weaponIdx], hue));
		var was = sprite.animation.name;
		sprite.frames = util.HuePalette.sparrow(util.Skins.of(sk), h);
		sprite.animation.addByPrefix("idle", "Idle", 9, true);
		sprite.animation.addByPrefix("walk", "Run", 12, true);
		sprite.animation.addByPrefix("dash", "Dash", 12, false);
		sprite.animation.addByPrefix("dashBack", "Backdash", 12, false);
		sprite.animation.addByPrefix("hurt", "Hurt", 12, false);
		sprite.animation.play(was == null ? "idle" : was);
		sprite.width = 42;
		sprite.height = 44;
		sprite.offset.set(2, 56);
		sprite.scale.set(4, 4);
	}

	public function setLeveling(on:Bool):Void
	{
		leveling = on;
		if (on)
			note.text = Lang.t("hud.leveling");
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

		var dead:Bool = m.dd == true;
		if (dead && !wasDead)
		{
			burst.burst(sprite.x + sprite.width * 0.5, sprite.y + sprite.height * 0.5, hue, sprite.flipX, util.Skins.of(skin));
			ghost.show(sprite.x + sprite.width * 0.5, sprite.y + sprite.height * 0.5, hue);
		}
		else if (!dead && wasDead)
		{
			ritual.cancel();
			burst.clear();
			ghost.hide();
		}
		wasDead = dead;

		var rv:Bool = m.rv == true;
		if (rv && !wasReviving && dead)
			ritual.begin();
		else if (!rv && wasReviving)
			ritual.cancel();
		wasReviving = rv;

		sprite.visible = !dead;
		sprite.flipX = m.fx;
		if (m.hu != null)
			setLook(m.hu, m.sk == null ? skin : m.sk);
		if (m.an != null && sprite.animation.name != m.an && sprite.animation.getByName(m.an) != null)
			sprite.animation.play(m.an);

		var wi:Int = m.wi;
		if (wi != weaponIdx && wi >= 0 && wi < WEAPON_IMAGES.length)
		{
			weaponIdx = wi;
			held.loadGraphic(util.HuePalette.graphic(WEAPON_IMAGES[wi], hue));

			if (wi == REVOLVER_INDEX || wi == BOW_INDEX)
				held.origin.set(held.width * 0.5, held.height * 0.5);
			else
				held.origin.set(held.width * 0.5, held.height);
		}
		held.visible = m.hv;
		held.angle = m.ha;
		held.flipX = m.hf;
		held.flipY = m.hg == true;

		var ho:Array<Dynamic> = m.ho;
		if (ho != null)
		{
			heldOX = ho[0];
			heldOY = ho[1];
			var hs:Float = ho[2];
			held.scale.set(hs, hs);
			held.color = FlxColor.WHITE;
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
		if (wasDead && ghost.sprite.exists)
			ghost.track(sprite.x + sprite.width * 0.5, sprite.y + sprite.height * 0.5, sprite.flipX);
		burst.update(elapsed);
		ghost.update(elapsed);
		ritual.update(elapsed, sprite.x + sprite.width * 0.5, sprite.y + sprite.height * 0.5);
		gear.update(elapsed, sprite.x + sprite.width * 0.5, sprite.y - 21, sprite.flipX,
			systems.BackGear.leanFor(sprite.animation.name), sprite.visible,
			sprite.angle, sprite.offset.y - OFFSET_Y, sprite.y + sprite.height * 0.5,
			sprite.animation.name);
		if (!haveTarget)
			return;
		var k = Math.min(1, LERP * elapsed);
		sprite.x += (targetX - sprite.x) * k;
		sprite.y += (targetY - sprite.y) * k;

		held.x = sprite.x + heldOX;
		held.y = sprite.y + heldOY;

		shadow.x = sprite.x + 10;
		shadow.y = sprite.y + entities.Player.FEET;
		shadow.scale.set(4, 4);

		tag.visible = sprite.visible;
		tag.x = sprite.x + sprite.width * 0.5 - TAG_WIDTH * 0.5;
		tag.y = sprite.y - TAG_UP;

		note.visible = sprite.visible && leveling;
		note.x = tag.x;
		note.y = sprite.y - NOTE_UP;

		if (bubble.visible)
		{
			if (!sprite.visible && ghost.sprite.exists)
			{
				bubble.x = ghost.sprite.x + ghost.sprite.width * 0.5 - bubble.width * 0.5;
				bubble.y = ghost.sprite.y + GHOST_ART_TOP - bubble.height - BUBBLE_GAP;
			}
			else
			{
				bubble.x = sprite.x + sprite.width * 0.5 - bubble.width * 0.5;
				bubble.y = sprite.y - bubble.height - BUBBLE_UP;
			}
		}
	}
}
