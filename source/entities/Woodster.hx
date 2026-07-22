package entities;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import flixel.FlxG;

class Woodster extends Enemies
{
    public function new(x:Float=0, y:Float=0)
    {
        super(x, y);

		this.loadGraphic("assets/images/enemies/woodster.png", true, 20, 23);
		this.frames = FlxAtlasFrames.fromSparrow("assets/images/enemies/woodster.png", "assets/images/enemies/woodster.xml");
		this.animation.addByPrefix("idle", "Idle", 12, true);
		this.animation.addByPrefix("walk", "Walk", 12, true);
		this.animation.addByPrefix("sstart", "Shoot start", 12, false);
		this.animation.addByPrefix("sloop", "Shoot loop", 12, false);
		this.animation.addByPrefix("send", "Shoot end", 12, false);
		this.animation.addByPrefix("hurt", "Hurt", 12, false);
		this.animation.addByPrefix("death", "Death.", 12, false);
		this.height = 105;
		this.offset.set(-23, 9);
		this.scale.set(4, 4);
		this.shadowOffX = 33;
		this.shadowOffXFlip = 33;
		this.shadowOffY = 105;
		this.shadowScaleX = 6;
    }

    override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
