package entities;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import flixel.FlxG;

class Enemy extends Enemies
{
    public function new(x:Float=0, y:Float=0)
    {
        super(x, y);
        this.loadGraphic("assets/images/enemies/enemy.png", true, 20, 23);
        this.frames = FlxAtlasFrames.fromSparrow("assets/images/enemies/enemy.png", "assets/images/enemies/enemy.xml");
        this.animation.addByPrefix("idle", "Idle", 12, true);
        this.animation.addByPrefix("walk", "Run", 12, true);
        this.animation.addByPrefix("hurt", "Hurt", 12, false);
        this.animation.addByPrefix("death", "Death", 12, false);
        this.height = 95;
        this.offset.set(-15, -19);
        this.scale.set(4, 4);
        this.hitOffXFlip = 10;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
    }
}
