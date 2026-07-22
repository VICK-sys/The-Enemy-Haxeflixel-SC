package entities;

interface AttackBehavior
{
	function update(e:Enemies, elapsed:Float, dirX:Float, dirY:Float, distance:Float):Bool;
	function reset():Void;
}
