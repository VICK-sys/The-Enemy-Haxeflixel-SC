package ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import systems.weapons.HeldWeapon;
import util.Paths;

class WeaponFlyIn
{
	static inline var TIME:Float = 0.55;
	static inline var SPIN:Float = 720;
	static inline var START_SCALE:Float = 3;
	static inline var END_SCALE:Float = 4;
	static inline var ARC:Float = 110;

	public var sprite:FlxSprite;
	public var flying(get, never):Bool;

	private var held:HeldWeapon;
	private var timer:Float = 0;
	private var fromX:Float = 0;
	private var fromY:Float = 0;

	public function new(camUI:FlxCamera, held:HeldWeapon)
	{
		this.held = held;
		sprite = new FlxSprite();
		sprite.antialiasing = false;
		sprite.scrollFactor.set();
		sprite.cameras = [camUI];
		sprite.kill();
	}

	function get_flying():Bool
		return sprite.exists;

	public function begin(image:String, sx:Float, sy:Float):Void
	{
		sprite.loadGraphic(Paths.image(image));
		sprite.scale.set(START_SCALE, START_SCALE);
		sprite.updateHitbox();
		sprite.revive();
		sprite.angle = 0;
		sprite.alpha = 1;
		fromX = sx;
		fromY = sy;
		timer = TIME;
		sprite.setPosition(sx - sprite.width * 0.5, sy - sprite.height * 0.5);
		held.sprite.visible = false;
	}

	public function drop():Void
		sprite.kill();

	public function land():Void
	{
		if (!sprite.exists)
			return;
		sprite.kill();
		held.sprite.visible = true;
	}

	public function update(elapsed:Float):Void
	{
		if (!sprite.exists)
			return;

		timer -= elapsed;
		var t = timer > 0 ? 1 - timer / TIME : 1;
		var e = FlxEase.cubeOut(t);

		var toX = held.handX() - FlxG.camera.scroll.x;
		var toY = held.handY() - FlxG.camera.scroll.y;
		var x = fromX + (toX - fromX) * e;
		var y = fromY + (toY - fromY) * e - Math.sin(Math.PI * t) * ARC;

		var s = START_SCALE + (END_SCALE - START_SCALE) * e;
		sprite.scale.set(s, s);
		sprite.setPosition(x - sprite.width * 0.5, y - sprite.height * 0.5);
		sprite.angle = SPIN * e;

		if (timer <= 0)
			land();
	}
}
