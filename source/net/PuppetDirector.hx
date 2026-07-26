package net;

import entities.Player;
import entities.enemy.Enemies;
import systems.world.Arena;
import systems.enemy.EnemyDirector;
import systems.PlayerCombat;
import systems.RenderLayers;

class PuppetDirector extends EnemyDirector
{
	public function new(player:Player, arena:Arena, layers:RenderLayers, status:PlayerCombat)
	{
		super(player, arena, layers, status);
	}

	public function addPuppet(e:Enemies):Void
	{
		e.puppet = true;
		register(e);
	}

	public function setWave(n:Int):Void
	{
		wave = n;
	}

	override public function collide():Void {}

	override public function update(elapsed:Float):Void
	{
		updateRigs(elapsed);
	}
}
