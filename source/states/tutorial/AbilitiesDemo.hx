package states.tutorial;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import data.PlayerData.PlayerDataRegistry;
import util.Paths;

class AbilitiesDemo extends TutorialDemo
{
	static inline var STOP_RUN:Float = 1.6;
	static inline var STOP_HOLD:Float = 2.6;

	static var SLOT_X:Array<Float> = [505, 775, 505, 775];
	static var SLOT_Y:Array<Float> = [232, 232, 448, 448];

	private var actor:FlxSprite;
	private var enemies:Array<FlxSprite> = [];
	private var ghosts:Array<FlxSprite> = [];
	private var stopOverlay:FlxSprite;
	private var timeFactor:Float = 1;
	private var flowTime:Float = 0;
	private var stopWalk:Float = 0;
	private var ghostTimer:Float = 0;
	private var ghostIndex:Int = 0;
	private var workX:Float = 0;
	private var workY:Float = 0;
	private var avoidX:Float = 0;
	private var avoidY:Float = 0;
	private var lastPlayerX:Float = TutorialDemo.CX;
	private var keyFlash:Float = 0;
	private var tickTimer:Float = 0;
	private var tock:Bool = false;
	private var slowTime:Float = 1.2;
	private var recoverTime:Float = 0.8;
	private var cycleIndex:Int = 0;
	private var cycleTimer:Float = 0;

	public function new(cam:FlxCamera)
	{
		super(cam);
		var d = PlayerDataRegistry.get();
		slowTime = d.timestopSlow;
		recoverTime = d.timestopRecover;

		for (i in 0...SLOT_X.length)
		{
			var e = enemy();
			e.flipX = SLOT_X[i] > TutorialDemo.CX;
			enemies.push(e);
		}

		for (i in 0...12)
		{
			var g = sprite();
			g.alpha = 0;
			ghosts.push(g);
		}

		actor = player();
		actor.animation.play("idle");
		center(actor, TutorialDemo.CX, TutorialDemo.CY);

		stopOverlay = sprite();
		stopOverlay.makeGraphic(4, 4, 0xFF2B4E70);
		stopOverlay.scale.set(200, 89);
		stopOverlay.updateHitbox();
		stopOverlay.setPosition(240, 148);
		stopOverlay.alpha = 0;

		cycleTimer = STOP_RUN;
		step(0);
	}

	function enemy():FlxSprite
	{
		var e = sprite();
		e.frames = Paths.sparrow("enemies/enemy");
		e.animation.addByPrefix("walk", "Run", 12, true);
		e.scale.set(4, 4);
		e.width = 75;
		e.height = 95;
		e.offset.set(-15, -19);
		e.animation.play("walk");
		return e;
	}

	override function step(elapsed:Float):Void
	{
		cycleTimer -= elapsed;

		switch (cycleIndex)
		{
			case 0:
				timeFactor = 1;
				if (cycleTimer <= 0)
				{
					cycleIndex = 1;
					cycleTimer = slowTime;
					keyFlash = 1;
					FlxG.sound.play(Paths.sound("enemies/charge"), 0.5);
				}
			case 1:
				var t = cycleTimer / slowTime;
				if (t < 0)
					t = 0;
				timeFactor = t * t;
				if (cycleTimer <= 0)
				{
					timeFactor = 0;
					cycleIndex = 2;
					cycleTimer = STOP_HOLD;
					tickTimer = 0;
				}
			case 2:
				timeFactor = 0;
				tickTimer -= elapsed;
				if (tickTimer <= 0)
				{
					tickTimer = 1;
					tock = !tock;
					FlxG.sound.play(Paths.sound(tock ? "tick" : "tock"), 0.4);
				}
				if (cycleTimer <= 0)
				{
					cycleIndex = 3;
					cycleTimer = recoverTime;
					keyFlash = 1;
					FlxG.sound.play(Paths.sound("scythe/catch"), 0.4);
				}
			case 3:
				var t = 1 - cycleTimer / recoverTime;
				if (t > 1)
					t = 1;
				timeFactor = t * t;
				if (cycleTimer <= 0)
				{
					timeFactor = 1;
					cycleIndex = 0;
					cycleTimer = STOP_RUN;
				}
		}

		flowTime += elapsed * timeFactor;

		for (i in 0...enemies.length)
		{
			var e = enemies[i];
			e.animation.timeScale = timeFactor;
			e.setPosition(SLOT_X[i] + Math.cos(flowTime * 0.7 + i * 1.7) * 30 - e.width / 2,
				SLOT_Y[i] + Math.sin(flowTime * 0.5 + i * 2.3) * 5 - e.height / 2);
		}

		var engage = 1 - timeFactor;
		if (engage > 0.02)
		{
			stopWalk += elapsed;
			actor.animation.play("walk");
		}
		else
			actor.animation.play("idle");

		var pang = -Math.PI * 0.5 + stopWalk * 2;
		var px = TutorialDemo.CX + Math.cos(pang) * 110 * engage;
		var py = TutorialDemo.CY + Math.sin(pang) * 60 * engage;

		workX = px;
		workY = py;
		for (e in enemies)
			repel(e.x + e.width / 2, e.y + e.height / 2, 90, 112);

		var ease = 1 - Math.pow(0.4, elapsed * 60);
		avoidX += (workX - px - avoidX) * ease;
		avoidY += (workY - py - avoidY) * ease;

		px = clamp(px + avoidX, 320, 960);
		py = clamp(py + avoidY, 240, 440);

		if (Math.abs(px - lastPlayerX) > 0.4)
			actor.flipX = px < lastPlayerX;
		lastPlayerX = px;
		center(actor, px, py);

		for (g in ghosts)
			if (g.alpha > 0)
				g.alpha -= 2.2 * elapsed;

		ghostTimer -= elapsed;
		if (ghostTimer <= 0)
		{
			ghostTimer = 0.03;
			if (engage >= 0.4)
				stampGhost();
		}

		if (keyFlash > 0)
			keyFlash -= elapsed * 2.5;
		stopOverlay.alpha = engage * 0.3;
	}

	function repel(ox:Float, oy:Float, rx:Float, ry:Float):Void
	{
		var dx = workX - ox;
		var dy = workY - oy;
		var d = Math.pow(Math.abs(dx) / rx, 6) + Math.pow(Math.abs(dy) / ry, 6);
		if (d >= 1)
			return;
		if (d <= 0)
		{
			workY -= ry;
			return;
		}
		var k = Math.pow(d, -1 / 6) - 1;
		workX += dx * k;
		workY += dy * k;
	}

	static function clamp(v:Float, lo:Float, hi:Float):Float
		return v < lo ? lo : (v > hi ? hi : v);

	function stampGhost():Void
	{
		var g = ghosts[ghostIndex];
		ghostIndex = (ghostIndex + 1) % ghosts.length;
		g.frames = actor.frames;
		g.frame = actor.frame;
		g.setPosition(actor.x, actor.y);
		g.offset.set(actor.offset.x, actor.offset.y);
		g.origin.set(actor.origin.x, actor.origin.y);
		g.scale.set(actor.scale.x, actor.scale.y);
		g.flipX = actor.flipX;
		g.color = 0xFF5AA9FF;
		g.alpha = 0.45;
	}
}
