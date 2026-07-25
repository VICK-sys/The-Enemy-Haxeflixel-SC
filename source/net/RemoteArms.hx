package net;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.weapon.HookShot;
import systems.weapons.HookArms;
import systems.weapons.Rope;

class RemoteArms
{
	static inline var COUNT:Int = 2;
	static inline var ROW:Int = 7;
	static inline var LERP:Float = 18;

	public var claws(default, null):Array<HookShot> = [];
	public var ropes(default, null):Array<FlxTypedGroup<FlxSprite>> = [];

	private var body:FlxSprite;
	private var cur:Array<Array<Float>> = [];
	private var tgt:Array<Array<Float>> = [];

	public function new(body:FlxSprite)
	{
		this.body = body;
		for (i in 0...COUNT)
		{
			var claw = new HookShot();
			claw.kill();
			claws.push(claw);
			ropes.push(new FlxTypedGroup<FlxSprite>());
			cur.push(null);
			tgt.push(null);
		}
	}

	public function set(rows:Array<Dynamic>):Void
	{
		for (i in 0...COUNT)
		{
			var row:Array<Dynamic> = rows != null ? rows[i] : null;
			if (row == null)
			{
				tgt[i] = null;
				continue;
			}
			var t = tgt[i];
			if (t == null)
			{
				t = [for (n in 0...ROW) 0.0];
				tgt[i] = t;
			}
			for (n in 0...ROW)
				t[n] = row[n];
		}
	}

	public function update(elapsed:Float):Void
	{
		var ax = body.x + body.width * 0.5;
		var ay = body.y + HookArms.ANCHOR_DOWN;
		var k = Math.min(1, LERP * elapsed);

		for (i in 0...COUNT)
		{
			var claw = claws[i];
			var t = tgt[i];
			if (t == null)
			{
				cur[i] = null;
				if (claw.exists)
				{
					claw.kill();
					Rope.clear(ropes[i]);
				}
				continue;
			}

			var c = cur[i];
			if (c == null)
			{
				c = t.copy();
				cur[i] = c;
				claw.revive();
			}

			for (n in 0...ROW)
			{
				if (n == 2)
				{
					var d = ((t[2] - c[2]) % 360 + 540) % 360 - 180;
					c[2] += d * k;
				}
				else
					c[n] += (t[n] - c[n]) * k;
			}

			claw.setPosition(c[0] - claw.width / 2, c[1] - claw.height / 2);
			claw.angle = c[2];
			claw.flipX = body.flipX;
			Rope.curve(ropes[i], ax, ay, c[3], c[4], c[5], c[6]);
		}
	}
}
