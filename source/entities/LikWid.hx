package entities;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import flixel.FlxG;

class LikWid extends Enemies
{
    public function new(x:Float=0, y:Float=0)
    {
        super(x, y);
        this.loadGraphic("assets/images/enemies/likwid.png", true, 20, 23);
        this.frames = FlxAtlasFrames.fromSparrow("assets/images/enemies/likwid.png", "assets/images/enemies/likwid.xml");
        this.animation.addByPrefix("idle", "Idle", 12, true);
        this.animation.addByPrefix("walk", "Walk", 12, true);
        this.animation.addByPrefix("hurt", "Hurt", 12, false);
        this.animation.addByPrefix("death", "Death", 12, false);
        this.height = 75;
        this.offset.set(-23, 0);
        this.scale.set(4, 4);
        this.shadowOffX = 33;
        this.shadowOffXFlip = 33;
        this.shadowOffY = 73;
        this.shadowScaleX = 7;
        this.hitOffX = 25;
        this.hitOffXFlip = 25;
    }

    override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
