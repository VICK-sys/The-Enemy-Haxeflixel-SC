import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.tweens.FlxEase;


/**
 * Class to represent the player character.
 */
class Player extends FlxSprite
{
	// A constant to represent how fast the player can move.
	static inline var MOVEMENT_SPEED:Float = 450;
	var velocityTween:VarTween;


	/**
	 * Player class' constructor. Used to set the player's initial position
	 * along with a few other things we need to initialize when creating the 
	 * player.
	 * @param x The X position of the player. 
	 * @param y The Y position of the player.
	 */
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		// Give the player a temporary orange square to represent it.
		//makeGraphic(20, 20, FlxColor.ORANGE);

        // Load the sprite sheet and XML data
		//var xmlData:Xml = Xml.parse(Assets.getText("assets/images/mufu.xml"));
		this.loadGraphic("assets/images/mufu.png", true, 20, 23); // Adjust the numbers to your frame width and height.
		//mySprite.loadGraphic("assets/images/mufu.png", true);
		this.frames = FlxAtlasFrames.fromSparrow("assets/images/mufu.png", "assets/images/mufu.xml");
		this.animation.addByPrefix("idle", "Idle", 12, true);
		this.animation.addByPrefix("walk", "Run", 12, true);
		this.animation.addByPrefix("hurt", "Hurt", 12, true);
		this.animation.addByPrefix("death", "Death", 12, true);
		this.animation.play("idle", true);
		this.antialiasing = false;
		this.scale.set(3, 3);

		drag.x = drag.y = 1600;
	}

	override function update(elapsed:Float)
	{
		movement();

		super.update(elapsed);
	}

	/**
	 * Handle's player movement based on the user's input. This function is
	 * from the Haxe Flixel tutorial at https://haxeflixel.com/documentation/groundwork/
	 */
	private function movement()
	{
		// Initial variable setup to represent the direction in which the
		// player character is moving.
		var up:Bool = false;
		var down:Bool = false;
		var left:Bool = false;
		var right:Bool = false;

		// Check for user input.
		up = FlxG.keys.anyPressed([W]);
		down = FlxG.keys.anyPressed([S]);
		left = FlxG.keys.anyPressed([A]);
		right = FlxG.keys.anyPressed([D]);

		// Check to make sure that the user isn't pressing opposite keys
		// at the same time.
		if (up && down)
		{
			up = down = false;
		}

		if (right && left)
		{
			right = left = false;
		}

		if (up || down || left || right)
			{
				var newAngle:Float = 0;
		
				if (up)
				{
					newAngle = -90;
		
					if (left)
					{
						newAngle -= 45;	
					}
					else if (right)
					{
						newAngle += 45;
					}
				}
				else if (down)
				{
					newAngle = 90;
		
					if (left)
					{
						newAngle += 45;
					}
					else if (right)
					{
						newAngle -= 45;
					}
				}
				else if (left)
				{
					newAngle = 180;
					this.flipX = true;  // Flip the sprite when moving left
				}
				else if (right)
				{
					newAngle = 0;
					this.flipX = false; // Do not flip (or unflip) when moving right
				}
		
				velocity.set(MOVEMENT_SPEED, 0);
				velocity.rotate(FlxPoint.weak(0, 0), newAngle);
			}
		
			// Check if the character is moving.
			if (up || down || left || right)
			{
				// If moving, play the walk animation.
				this.animation.play("walk");
				// ... [rest of the direction calculation and velocity setting code remains the same]
			}
			else
			{
				// If not moving, revert back to the idle animation.
				this.animation.play("idle");
			}
		}
	}