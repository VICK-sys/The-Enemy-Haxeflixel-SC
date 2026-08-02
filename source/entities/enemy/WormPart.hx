package entities.enemy;

class WormPart implements AttackBehavior
{
	public function new() {}

	public function update(e:Enemies, elapsed:Float, dirX:Float, dirY:Float, distance:Float):Bool
		return false;

	public function reset():Void {}
}
