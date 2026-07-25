package systems.perspective;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import systems.Arena;
import systems.RenderLayers;
import util.Paths;
import data.SideViewData.SideViewData;
import data.SideViewData.SideViewDataRegistry;

class MeteorArrival
{
	static inline var EMBER_GAP:Float = 0.02;
	static inline var EDGE_PAD:Float = 100;

	public var arrived:Bool = false;
	public var falling(get, never):Bool;
	public var onImpact:(Float, Float) -> Void;

	private var sv:SideViewData;
	private var arena:Arena;
	private var player:Player;
	private var totem:Totem;
	private var arrivalWave:Int;
	private var fallPhase:Int = 0;
	private var fallTimer:Float = 0;
	private var fallFromY:Float = 0;
	private var marker:FlxSprite;
	private var embers:Array<FlxSprite> = [];
	private var dust:Array<FlxSprite> = [];
	private var emberTimer:Float = 0;
	private var emberIndex:Int = 0;

	public function new(arena:Arena, player:Player, totem:Totem, layers:RenderLayers)
	{
		this.arena = arena;
		this.player = player;
		this.totem = totem;
		sv = SideViewDataRegistry.get();

		arrivalWave = arena.totemWaveMin + FlxG.random.int(0, arena.totemWaveRange);

		marker = new FlxSprite(0, 0, Paths.image("effects/shadow"));
		marker.color = 0xFFD01020;
		marker.alpha = 0;
		layers.shadowLayer.add(marker);

		dust = makePool(layers.shadowLayer, 16, 14, 8, 0xFF6A5340);
		embers = makePool(layers.entityLayer, 22, 10, 10, 0xFFFF9A3C);
	}

	function get_falling():Bool
		return fallPhase == 1 || fallPhase == 2;

	function makePool(layer:FlxTypedGroup<FlxSprite>, count:Int, w:Int, h:Int, color:Int):Array<FlxSprite>
	{
		var out = [];
		for (i in 0...count)
		{
			var s = new FlxSprite();
			s.makeGraphic(w, h, color);
			s.antialiasing = false;
			s.alpha = 0;
			layer.add(s);
			out.push(s);
		}
		return out;
	}

	public function tryBegin(wave:Int, locked:Bool):Void
	{
		if (arrived || fallPhase != 0 || locked || wave < arrivalWave)
			return;

		pickLanding();
		fallPhase = 1;
		fallTimer = sv.telegraphTime;
		marker.setPosition(totem.homeX + Totem.W / 2 - marker.width / 2, totem.homeY + Totem.H - marker.height / 2);
		FlxG.sound.play(Paths.sound("enemies/charge"), 0.7);
	}

	public function cancel():Void
	{
		if (arrived || fallPhase == 0)
			return;
		fallPhase = 0;
		marker.alpha = 0;
		totem.sprite.visible = false;
	}

	function pickLanding():Void
	{
		var pcx = player.x + player.width * 0.5;
		var pcy = player.y + player.height * 0.5;
		for (i in 0...32)
		{
			var ang = Math.random() * Math.PI * 2;
			var dist = sv.landMin + Math.random() * (sv.landMax - sv.landMin);
			var tx = pcx + Math.cos(ang) * dist - Totem.W / 2;
			var ty = pcy + Math.sin(ang) * dist - Totem.H;
			if (tx < EDGE_PAD || ty < EDGE_PAD
				|| tx + Totem.W > arena.width - EDGE_PAD || ty + Totem.H > arena.height - EDGE_PAD)
				continue;
			if (blockedAt(tx, ty))
				continue;
			totem.homeX = tx;
			totem.homeY = ty;
			return;
		}
		totem.homeX = clampF(pcx - Totem.W / 2, EDGE_PAD, arena.width - EDGE_PAD - Totem.W);
		totem.homeY = clampF(pcy - Totem.H, EDGE_PAD, arena.height - EDGE_PAD - Totem.H);
	}

	function blockedAt(tx:Float, ty:Float):Bool
	{
		return arena.wallAt(tx + Totem.W / 2, ty + Totem.H)
			|| arena.wallAt(tx, ty + Totem.H)
			|| arena.wallAt(tx + Totem.W, ty + Totem.H)
			|| arena.wallAt(tx + Totem.W / 2, ty + Totem.H / 2);
	}

	static function clampF(v:Float, lo:Float, hi:Float):Float
		return v < lo ? lo : (v > hi ? hi : v);

	public function update(elapsed:Float):Void
	{
		if (fallPhase == 1)
		{
			fallTimer -= elapsed;
			var p = 1 - fallTimer / sv.telegraphTime;
			marker.alpha = 0.25 + 0.45 * Math.abs(Math.sin(p * 14));
			var grow = 5 + 5 * p;
			marker.scale.set(grow, grow * 0.8);
			if (fallTimer <= 0)
			{
				fallPhase = 2;
				fallTimer = sv.fallTime;
				fallFromY = totem.homeY - sv.fallHeight;
				totem.sprite.setPosition(totem.homeX, fallFromY);
				totem.sprite.visible = true;
				emberTimer = 0;
			}
		}
		else if (fallPhase == 2)
		{
			fallTimer -= elapsed;
			var p = 1 - fallTimer / sv.fallTime;
			if (p > 1)
				p = 1;
			totem.sprite.y = fallFromY + (totem.homeY - fallFromY) * p * p;
			totem.sprite.angle = Math.sin(p * 40) * 4;
			marker.alpha = 0.35 + 0.5 * p;

			emberTimer -= elapsed;
			if (emberTimer <= 0)
			{
				emberTimer = EMBER_GAP;
				spawnEmber();
			}

			if (fallTimer <= 0)
				impact();
		}

		fadeParticles(elapsed);
	}

	function spawnEmber():Void
	{
		var s = embers[emberIndex];
		emberIndex = (emberIndex + 1) % embers.length;
		s.setPosition(totem.sprite.x + Math.random() * Totem.W - 5, totem.sprite.y + Math.random() * 40);
		s.velocity.set((Math.random() * 2 - 1) * 90, -140 - Math.random() * 160);
		s.scale.set(1 + Math.random(), 1 + Math.random());
		s.alpha = 1;
	}

	function impact():Void
	{
		fallPhase = 3;
		arrived = true;
		totem.sprite.setPosition(totem.homeX, totem.homeY);
		totem.sprite.angle = 0;
		marker.alpha = 0;
		totem.show();
		totem.flash(3);

		var cx = totem.homeX + Totem.W / 2;
		var cy = totem.homeY + Totem.H;
		for (i in 0...dust.length)
		{
			var d = dust[i];
			var ang = i / dust.length * Math.PI * 2;
			d.setPosition(cx - d.width / 2, cy - d.height / 2);
			d.velocity.set(Math.cos(ang) * (180 + Math.random() * 140), Math.sin(ang) * (90 + Math.random() * 70));
			d.scale.set(2 + Math.random() * 2, 2 + Math.random() * 2);
			d.alpha = 0.9;
		}

		FlxG.sound.play(Paths.sound("rofel_explode"), 0.9);
		FlxG.camera.shake(0.028, 0.65);

		if (onImpact != null)
			onImpact(cx, cy);
	}

	function fadeParticles(elapsed:Float):Void
	{
		for (s in embers)
			if (s.alpha > 0)
			{
				s.alpha -= 2.6 * elapsed;
				s.velocity.y += 320 * elapsed;
				if (s.alpha <= 0)
					s.velocity.set(0, 0);
			}
		for (s in dust)
			if (s.alpha > 0)
			{
				s.alpha -= 1.5 * elapsed;
				s.velocity.x *= 1 - 2.2 * elapsed;
				s.velocity.y *= 1 - 2.2 * elapsed;
				if (s.alpha <= 0)
					s.velocity.set(0, 0);
			}
	}
}
