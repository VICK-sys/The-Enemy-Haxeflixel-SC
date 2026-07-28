package systems.enemy;

import flixel.FlxObject;
import flixel.FlxSprite;
import entities.enemy.Enemies;

class EnemyRig
{
	public var enemy:Enemies;
	public var shadow:FlxSprite;
	public var hitbox:FlxObject;
	public var lastX:Float;
	public var lastY:Float;
	public var stuckTimer:Float = 0;
	public var enterTimer:Float = 0;
	public var farX:Float;
	public var farY:Float;
	public var farTimer:Float = 0;

	public function new(enemy:Enemies, shadow:FlxSprite, hitbox:FlxObject)
	{
		this.enemy = enemy;
		this.shadow = shadow;
		this.hitbox = hitbox;
		lastX = enemy.x;
		lastY = enemy.y;
		farX = enemy.x;
		farY = enemy.y;
	}
}
