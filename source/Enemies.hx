package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import flixel.FlxG;

class Enemies extends FlxSprite
{
    static inline var SPEED:Float = 125;
    public var target:Player;
	static inline var STOP_THRESHOLD:Float = 400;
	
    public function new(x:Float=0, y:Float=0)
    {
        super(x, y);
        // Load a graphic for the Enemies (change this to your AI's image)
		this.loadGraphic("assets/images/enemies/woodster.png", true, 20, 23);
		this.frames = FlxAtlasFrames.fromSparrow("assets/images/enemies/woodster.png", "assets/images/enemies/woodster.xml");
		this.animation.addByPrefix("idle", "Idle", 12, true);
		this.animation.addByPrefix("walk", "Walk", 12, true);
		this.animation.addByPrefix("sstart", "Shoot start", 12, true);
		this.animation.addByPrefix("sloop", "Shoot loop", 12, true);
		this.animation.addByPrefix("send", "Shoot end", 12, true);
		this.animation.addByPrefix("hurt", "Hurt", 12, false);
		this.animation.addByPrefix("death", "Death.", 12, false);
		this.antialiasing = false;
		this.scale.set(4, 4);
    }

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	
		if (target == null) return;  // Ensure we have a target to follow
	
		var targetMid:FlxPoint = target.getMidpoint();
		var followerMid:FlxPoint = this.getMidpoint();
		var dir:FlxPoint = new FlxPoint(targetMid.x - followerMid.x, targetMid.y - followerMid.y);

		// Check the direction and set flipX accordingly
		if (dir.x > 0)
		{
			this.flipX = false;  // Player is to the right of the follower
		}
		else if (dir.x < 0)
		{
			this.flipX = true;   // Player is to the left of the follower
		}
	
		// Calculate the distance between Follower and Player
		var distance:Float = Math.sqrt(dir.x * dir.x + dir.y * dir.y);
	
		// Check if the distance is less than the threshold
		if (distance <= STOP_THRESHOLD)
		{
			// Stop the Follower
			velocity.set(0, 0);
			this.animation.play("idle");
		}
		else
		{
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				// Normalize the direction to get a unit vector
				var length:Float = Math.sqrt(dir.x * dir.x + dir.y * dir.y);
				// Only normalize if the length is not zero (to avoid dividing by zero)
				if (length != 0)
				{
					dir.x /= length;
					dir.y /= length;
				}
		
				// Set the velocity based on direction and speed
				velocity.set(dir.x * SPEED, dir.y * SPEED);
		
				// Play walk animation
				this.animation.play("walk");
			});
		}
	}	
}