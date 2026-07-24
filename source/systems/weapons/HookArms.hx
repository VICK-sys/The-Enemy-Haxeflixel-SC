package systems.weapons;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.weapon.HookShot;
import entities.enemy.Enemies;
import systems.EnemyDirector;
import data.WeaponData.WeaponDataRegistry;

class HookArms
{
	static inline var REST_UP:Float = 78;
	static inline var REST_DX:Float = 20;
	static inline var ANCHOR_DOWN:Float = 46;
	static inline var REST_TILT_DEG:Float = 42;
	static inline var CURVE_FRAC:Float = 0.75;
	static inline var REST_EASE:Float = 9;
	static inline var HANDLE_LEN:Float = 62;
	static inline var WHIP_ARC:Float = 170;
	static inline var WHIP_RADIUS:Float = 120;
	static inline var CTRL_EASE:Float = 11;
	static inline var EXTEND_DELAY:Float = 0.35;
	static inline var RETRACT_EASE:Float = 8;

	public var backGroup:FlxGroup;
	public var frontGroup:FlxGroup;

	private var cfg = WeaponDataRegistry.get().hookArms;
	private var player:Player;
	private var director:EnemyDirector;
	private var hits:HitPipeline;
	private var arms:Array<Arm> = [];
	private var running:Bool = false;
	private var retracting:Bool = false;
	private var superTimer:Float = 0;

	public var active(get, never):Bool;

	function get_active():Bool
		return running || retracting;

	public function new(player:Player, director:EnemyDirector, hits:HitPipeline)
	{
		this.player = player;
		this.director = director;
		this.hits = hits;
		backGroup = new FlxGroup();
		frontGroup = new FlxGroup();
		arms.push(makeArm(backGroup, -REST_DX));
		arms.push(makeArm(backGroup, REST_DX));
	}

	function makeArm(group:FlxGroup, restDX:Float):Arm
	{
		var rope = new FlxTypedGroup<FlxSprite>();
		group.add(rope);
		var claw = new HookShot();
		claw.kill();
		group.add(claw);
		return new Arm(claw, rope, restDX);
	}

	public function activate():Void
	{
		running = true;
		retracting = false;
		superTimer = cfg.armsTime;
		var pcx = player.x + player.width * 0.5;
		for (arm in arms)
		{
			arm.phase = 0;
			arm.target = null;
			arm.cooldown = EXTEND_DELAY;
			arm.cx = pcx;
			arm.cy = player.y + ANCHOR_DOWN;
			arm.ctrlInit = false;
			arm.claw.revive();
		}
	}

	public function deactivate():Void
	{
		for (arm in arms)
		{
			release(arm);
			arm.claw.kill();
			Rope.clear(arm.rope);
		}
		running = false;
		retracting = false;
	}

	public function update(elapsed:Float):Void
	{
		if (!running && !retracting)
			return;

		if (running)
		{
			superTimer -= elapsed;
			if (superTimer <= 0)
			{
				running = false;
				retracting = true;
				var ax = player.x + player.width * 0.5;
				var ay = player.y + ANCHOR_DOWN;
				for (arm in arms)
				{
					release(arm);
					arm.ox = arm.cx - ax;
					arm.oy = arm.cy - ay;
				}
			}
		}

		var anchorX = player.x + player.width * 0.5;
		var anchorY = player.y + ANCHOR_DOWN;
		var allHome = true;
		for (arm in arms)
		{
			updateArm(arm, elapsed);
			if (retracting)
			{
				var ddx = arm.cx - anchorX;
				var ddy = arm.cy - anchorY;
				if (ddx * ddx + ddy * ddy > 24 * 24)
					allHome = false;
			}
		}

		if (retracting && allHome)
		{
			for (arm in arms)
			{
				arm.claw.kill();
				Rope.clear(arm.rope);
			}
			retracting = false;
		}
	}

	function updateArm(arm:Arm, elapsed:Float):Void
	{
		var pcx = player.x + player.width * 0.5;
		var pcy = player.y + player.height * 0.5;
		var anchorX = pcx;
		var anchorY = player.y + ANCHOR_DOWN;
		var facing = player.flipX ? -1.0 : 1.0;
		var restLen = REST_UP + ANCHOR_DOWN;
		var restRad = (-90 - REST_TILT_DEG * facing) * Math.PI / 180;
		var restX = anchorX + Math.cos(restRad) * restLen + arm.restDX;
		var restY = anchorY + Math.sin(restRad) * restLen;

		if (retracting)
		{
			var rk = Math.min(1, RETRACT_EASE * elapsed);
			arm.ox -= arm.ox * rk;
			arm.oy -= arm.oy * rk;
			arm.cx = anchorX + arm.ox;
			arm.cy = anchorY + arm.oy;
			arm.target = null;
			arm.phase = 0;
		}
		else if (arm.phase == 0)
		{
			if (arm.cooldown > 0)
				arm.cooldown -= elapsed;
			var k = Math.min(1, REST_EASE * elapsed);
			arm.cx += (restX - arm.cx) * k;
			arm.cy += (restY - arm.cy) * k;
			if (arm.cooldown <= 0)
			{
				var t = findTarget(anchorX, anchorY, other(arm).target);
				if (t != null)
				{
					arm.target = t;
					arm.phase = 1;
				}
			}
		}
		else if (arm.phase == 1)
		{
			if (invalid(arm.target))
			{
				arm.target = null;
				arm.phase = 0;
			}
			else
			{
				var tcx = arm.target.x + arm.target.width * 0.5;
				var tcy = arm.target.y + arm.target.height * 0.5;
				var reached = stepToward(arm, tcx, tcy, cfg.reachSpeed * elapsed);
				var dx = tcx - arm.cx;
				var dy = tcy - arm.cy;
				if (reached || dx * dx + dy * dy <= cfg.grabRadius * cfg.grabRadius)
				{
					arm.target.seized = true;
					arm.target.drag.set(0, 0);
					arm.phase = 2;
				}
			}
		}
		else if (arm.phase == 2)
		{
			if (invalid(arm.target))
			{
				arm.target = null;
				arm.phase = 0;
			}
			else
			{
				var e = arm.target;
				var ecx = e.x + e.width * 0.5;
				var ecy = e.y + e.height * 0.5;
				var dx = restX - ecx;
				var dy = restY - ecy;
				var len = Math.sqrt(dx * dx + dy * dy);
				if (len <= cfg.grabDist)
				{
					arm.phase = 3;
					arm.whipTimer = cfg.whipTime;
					arm.whipBase = Math.atan2(ecy - anchorY, ecx - anchorX) * 180 / Math.PI;
					e.seized = true;
					e.velocity.set(0, 0);
				}
				else
				{
					if (len <= 0)
						len = 1;
					e.seized = true;
					e.drag.set(0, 0);
					e.velocity.set(dx / len * cfg.reelSpeed, dy / len * cfg.reelSpeed);
					arm.cx = ecx;
					arm.cy = ecy;
				}
			}
		}
		else
		{
			if (invalid(arm.target))
			{
				arm.target = null;
				arm.phase = 0;
			}
			else
			{
				var e = arm.target;
				arm.whipTimer -= elapsed;
				var t = 1 - arm.whipTimer / cfg.whipTime;
				if (t > 1)
					t = 1;
				var deg = arm.whipBase + WHIP_ARC * facing * t;
				var rad = deg * Math.PI / 180;
				var ex = anchorX + Math.cos(rad) * WHIP_RADIUS;
				var ey = anchorY + Math.sin(rad) * WHIP_RADIUS;
				e.seized = true;
				e.velocity.set(0, 0);
				e.setPosition(ex - e.width * 0.5, ey - e.height * 0.5);
				arm.cx = ex;
				arm.cy = ey;
				if (arm.whipTimer <= 0)
				{
					e.unseize();
					throwEnemy(e, Math.cos(rad), Math.sin(rad));
					arm.target = null;
					arm.phase = 0;
					arm.cooldown = cfg.cooldown;
				}
			}
		}

		arm.claw.setPosition(arm.cx - arm.claw.width / 2, arm.cy - arm.claw.height / 2);
		arm.claw.flipX = player.flipX;

		var side = player.flipX ? 1.0 : -1.0;
		var idealCx = anchorX;
		var idealCy = anchorY;
		var mdx = arm.cx - anchorX;
		var mdy = arm.cy - anchorY;
		var mdist = Math.sqrt(mdx * mdx + mdy * mdy);
		if (mdist >= 8)
		{
			var px = -mdy / mdist;
			var py = mdx / mdist;
			var bend = mdist * CURVE_FRAC * side;
			idealCx = (anchorX + arm.cx) * 0.5 + px * bend;
			idealCy = (anchorY + arm.cy) * 0.5 + py * bend;
		}
		if (!arm.ctrlInit)
		{
			arm.ctrlX = idealCx;
			arm.ctrlY = idealCy;
			arm.ctrlInit = true;
		}
		var k = Math.min(1, CTRL_EASE * elapsed);
		arm.ctrlX += (idealCx - arm.ctrlX) * k;
		arm.ctrlY += (idealCy - arm.ctrlY) * k;

		var tangent = Math.atan2(arm.cy - arm.ctrlY, arm.cx - arm.ctrlX) * 180 / Math.PI;
		arm.claw.angle = tangent + 90;
		var tr = tangent * Math.PI / 180;
		var handleX = arm.cx - Math.cos(tr) * HANDLE_LEN;
		var handleY = arm.cy - Math.sin(tr) * HANDLE_LEN;
		Rope.curve(arm.rope, anchorX, anchorY, handleX, handleY, arm.ctrlX, arm.ctrlY);
	}

	function stepToward(arm:Arm, tx:Float, ty:Float, maxStep:Float):Bool
	{
		var dx = tx - arm.cx;
		var dy = ty - arm.cy;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len <= maxStep || len <= 0)
		{
			arm.cx = tx;
			arm.cy = ty;
			return true;
		}
		arm.cx += dx / len * maxStep;
		arm.cy += dy / len * maxStep;
		return false;
	}

	function findTarget(ax:Float, ay:Float, exclude:Enemies):Enemies
	{
		var best:Enemies = null;
		var bestD = cfg.reach * cfg.reach;
		director.eachInCircle(ax, ay, cfg.reach, function(e)
		{
			if (e == exclude || e.seized || !e.grabbable)
				return;
			var dx = e.x + e.width * 0.5 - ax;
			var dy = e.y + e.height * 0.5 - ay;
			var d = dx * dx + dy * dy;
			if (d < bestD)
			{
				bestD = d;
				best = e;
			}
		});
		return best;
	}

	function throwEnemy(e:Enemies, dx:Float, dy:Float):Void
	{
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len <= 1)
		{
			dx = FlxG.random.float() - 0.5;
			dy = FlxG.random.float() - 0.5;
			len = Math.sqrt(dx * dx + dy * dy);
			if (len <= 0)
				len = 1;
		}
		hits.damageN(e, dx / len * cfg.throwForce, dy / len * cfg.throwForce, cfg.damage);
	}

	function release(arm:Arm):Void
	{
		if (arm.target != null && arm.target.exists)
			arm.target.unseize();
		arm.target = null;
		arm.phase = 0;
	}

	function other(arm:Arm):Arm
		return arm == arms[0] ? arms[1] : arms[0];

	function invalid(e:Enemies):Bool
		return e == null || !e.exists || e.isDead;
}

class Arm
{
	public var claw:HookShot;
	public var rope:FlxTypedGroup<FlxSprite>;
	public var phase:Int = 0;
	public var target:Enemies = null;
	public var restDX:Float;
	public var cx:Float = 0;
	public var cy:Float = 0;
	public var cooldown:Float = 0;
	public var ox:Float = 0;
	public var oy:Float = 0;
	public var whipTimer:Float = 0;
	public var whipBase:Float = 0;
	public var ctrlX:Float = 0;
	public var ctrlY:Float = 0;
	public var ctrlInit:Bool = false;

	public function new(claw:HookShot, rope:FlxTypedGroup<FlxSprite>, restDX:Float)
	{
		this.claw = claw;
		this.rope = rope;
		this.restDX = restDX;
	}
}
