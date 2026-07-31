package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import util.Paths;

class Burst extends FlxSprite
{
	public var key:String = null;

	public function new()
		super();
}

class Fx
{
	static inline var DASH_LINE_FADE:Float = 3;

	public static var shakeScale:Float = 1;
	public static var freezeScale:Float = 1;

	static inline var POP_W:Int = 12;
	static inline var POP_H:Int = 12;
	static inline var POP_FPS:Int = 16;
	static inline var POP_SCALE:Int = 4;

	public var sparks:FlxEmitter;
	public var dashTrail:FlxTypedGroup<FlxSprite>;
	public var pops:FlxTypedGroup<FlxSprite>;
	public var bursts:FlxTypedGroup<Burst>;
	public var steam:FlxTypedGroup<FlxSprite>;

	static inline var STEAM_FRAME:Int = 32;
	static inline var STEAM_FPS:Int = 18;
	static inline var STEAM_SCALE:Float = 4;

	static inline var BURST_FRAME:Int = 24;
	static inline var BURST_FPS:Int = 24;
	static inline var BURST_SCALE:Float = 4;

	static inline var IMPACT:String = "bullets/bullet_impact";
	static inline var BREAK_PLAYER:String = "bullets/bullet_break_player";
	static inline var BREAK_ENEMY:String = "bullets/bullet_break_enemy";

	public function impactAt(cx:Float, cy:Float):Void
		burst(IMPACT, cx, cy);

	public function breakAt(cx:Float, cy:Float, fromPlayer:Bool):Void
		burst(fromPlayer ? BREAK_PLAYER : BREAK_ENEMY, cx, cy);

	function burst(key:String, cx:Float, cy:Float):Void
	{
		var b = bursts.recycle(Burst);
		if (b.key != key)
		{
			b.key = key;
			b.loadGraphic(Paths.image(key), true, BURST_FRAME, BURST_FRAME);
			b.animation.add("go", [0, 1, 2, 3], BURST_FPS, false);
			b.antialiasing = false;
			b.scale.set(BURST_SCALE, BURST_SCALE);
			b.updateHitbox();
		}
		b.setPosition(cx - b.width * 0.5, cy - b.height * 0.5);
		b.animation.play("go", true);
	}

	private var hitstopFrames:Int = 0;
	private var meleeHeld:Bool = false;

	public static function shake(intensity:Float, duration:Float):Void
	{
		var v = intensity * shakeScale;
		if (v <= 0)
			return;
		FlxG.camera.shake(v, duration);
	}

	public static function frames(n:Int):Int
		return Math.round(n * freezeScale * FlxG.updateFramerate / 60);

	public function new()
	{
		FlxG.timeScale = 1;

		sparks = new FlxEmitter(0, 0, 60);
		sparks.makeParticles(4, 4, FlxColor.WHITE, 60);
		sparks.speed.set(100, 400);
		sparks.lifespan.set(0.15, 0.35);

		dashTrail = new FlxTypedGroup<FlxSprite>();
		pops = new FlxTypedGroup<FlxSprite>();
		bursts = new FlxTypedGroup<Burst>();
		steam = new FlxTypedGroup<FlxSprite>();
	}

	public function steamAt(cx:Float, cy:Float, toLeft:Bool):Void
	{
		var s = steam.recycle(FlxSprite);
		if (s.graphic == null)
		{
			s.loadGraphic(Paths.image("effects/steam_dash"), true, STEAM_FRAME, STEAM_FRAME);
			s.animation.add("puff", [0, 1, 2, 3, 4], STEAM_FPS, false);
			s.antialiasing = false;
			s.scale.set(STEAM_SCALE, STEAM_SCALE);
			s.updateHitbox();
		}
		s.flipX = toLeft;
		s.setPosition(cx - s.width * 0.5, cy - s.height * 0.5);
		s.animation.play("puff", true);
	}

	public function chargePop(cx:Float, cy:Float):Void
	{
		var p = pops.recycle(FlxSprite);
		if (p.graphic == null)
		{
			p.loadGraphic(Paths.image("effects/charge_glow"), true, POP_W, POP_H);
			p.animation.add("pop", [0, 1, 2, 3], POP_FPS, false);
			p.animation.finishCallback = function(_) p.kill();
			p.antialiasing = false;
			p.scale.set(POP_SCALE, POP_SCALE);
			p.updateHitbox();
		}
		p.setPosition(cx - p.width * 0.5, cy - p.height * 0.5);
		p.animation.play("pop", true);
	}

	public function update():Void
	{
		meleeHeld = false;

		if (hitstopFrames > 0)
		{
			hitstopFrames--;
			if (hitstopFrames <= 0)
				FlxG.timeScale = 1;
		}

		for (b in bursts.members)
			if (b != null && b.exists && b.animation.finished)
				b.kill();

		for (s in steam.members)
			if (s != null && s.exists && s.animation.finished)
				s.kill();

		for (l in dashTrail.members)
		{
			if (l == null || !l.exists)
				continue;
			l.alpha -= DASH_LINE_FADE * FlxG.elapsed;
			if (l.alpha <= 0)
				l.kill();
		}
	}

	public function dashLine(cx:Float, cy:Float, dx:Float, dy:Float):Void
	{
		var l = dashTrail.recycle(FlxSprite);
		if (l.graphic == null)
		{
			l.makeGraphic(44, 4, FlxColor.WHITE);
			l.antialiasing = false;
		}
		var off = (FlxG.random.float() * 2 - 1) * 35;
		var lx = cx - dx * 50 - dy * off;
		var ly = cy - dy * 50 + dx * off;
		l.setPosition(lx - l.width / 2, ly - l.height / 2);
		l.angle = Math.atan2(dy, dx) * 180 / Math.PI;
		l.alpha = 0.7;
	}

	public function sparksAt(x:Float, y:Float):Void
	{
		sparks.setPosition(x, y);
		sparks.start(true, 0, 8);
	}

	public function killImpact():Void
	{
		if (!meleeHeld)
			hold(frames(4), 0.05);
		shake(0.004, 0.1);
	}

	public function meleeImpact(stopFrames:Int, scale:Float, shakeAmp:Float):Void
	{
		if (stopFrames <= 0)
			return;
		meleeHeld = true;
		hold(frames(stopFrames), scale);
		if (shakeAmp > 0)
			shake(shakeAmp, 0.08);
	}

	function hold(stopFrames:Int, scale:Float):Void
	{
		if (stopFrames <= 0)
			return;
		if (stopFrames > hitstopFrames)
			hitstopFrames = stopFrames;
		if (scale < FlxG.timeScale)
			FlxG.timeScale = scale;
	}

	public function clearHitstop():Void
	{
		hitstopFrames = 0;
		FlxG.timeScale = 1;
	}

	public function hurtShake():Void
	{
		shake(0.012, 0.2);
	}

	public static function bossBlast(cx:Float, cy:Float):FlxSprite
	{
		var boom = new FlxSprite();
		boom.loadGraphic(Paths.image("effects/rofel_explosion"), true, 80, 48);
		boom.animation.add("boom", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 14, false);
		boom.antialiasing = false;
		boom.scale.set(9, 9);
		boom.updateHitbox();
		boom.x = cx - boom.width / 2;
		boom.y = cy - boom.height / 2;
		boom.animation.play("boom");
		util.Sfx.at("rofel_explode", cx, cy, 0.9);
		shake(0.02, 0.5);
		return boom;
	}
}
