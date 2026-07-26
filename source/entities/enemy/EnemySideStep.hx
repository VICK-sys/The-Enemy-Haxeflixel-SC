package entities.enemy;

import util.SideView;

class EnemySideStep
{
	private var hopCooldown:Float = 0;
	private var attacking:Bool = false;

	public function new() {}

	public function update(e:Enemies, elapsed:Float, prevBottom:Float):Void
	{
		var grounded = SideView.settle(e, prevBottom, elapsed);
		var bottom = e.y + e.height;

		if (hopCooldown > 0)
			hopCooldown -= elapsed;

		if (e.target == null)
		{
			e.velocity.x = 0;
			attacking = false;
			if (grounded)
				e.animation.play("idle");
			return;
		}

		var dirX = e.target.x + e.target.width * 0.5 - (e.x + e.width * 0.5);
		var dirY = e.target.y + e.target.height * 0.5 - (e.y + e.height * 0.5);
		var distance = Math.sqrt(dirX * dirX + dirY * dirY);

		if (attacking)
		{
			var fallSpeed = e.velocity.y;
			if (e.attack.update(e, elapsed, dirX, dirY, distance))
				attacking = false;
			e.velocity.y = fallSpeed;
			return;
		}

		if (distance <= e.attackRange)
		{
			attacking = true;
			e.velocity.x = 0;
			return;
		}

		if (Math.abs(dirX) > e.stopThreshold * 0.6)
		{
			e.velocity.x = dirX > 0 ? e.speed : -e.speed;
			e.flipX = dirX < 0;
			if (grounded)
				e.animation.play("walk");
		}
		else
		{
			e.velocity.x = 0;
			if (grounded)
				e.animation.play("idle");
		}

		if (grounded && hopCooldown <= 0 && e.target.y + e.target.height < bottom - 100)
		{
			e.velocity.y = -SideView.ENEMY_JUMP;
			hopCooldown = 0.9 + Math.random();
		}
	}
}
