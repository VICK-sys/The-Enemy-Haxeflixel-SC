package entities.enemy;

class ShotSpec
{
	public var dirX:Float = 1;
	public var dirY:Float = 0;
	public var damage:Float = 0.25;
	public var speed:Float = 480;
	public var range:Float = 640;
	public var sprite:String = null;
	public var sound:String = null;
	public var useOrigin:Bool = false;
	public var originX:Float = 0;
	public var originY:Float = 0;

	public function new() {}

	public function set(dirX:Float, dirY:Float, damage:Float, speed:Float, range:Float, sprite:String, sound:String):ShotSpec
	{
		this.dirX = dirX;
		this.dirY = dirY;
		this.damage = damage;
		this.speed = speed;
		this.range = range;
		this.sprite = sprite;
		this.sound = sound;
		this.useOrigin = false;
		return this;
	}

	public function at(x:Float, y:Float):ShotSpec
	{
		useOrigin = true;
		originX = x;
		originY = y;
		return this;
	}
}
