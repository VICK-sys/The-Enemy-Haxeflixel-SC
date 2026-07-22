package systems;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.enemy.Enemies;
import entities.SlashProjectile;
import util.Paths;

class ScytheCombat
{
	static inline var SWING_TIME:Float = 0.2;
	static inline var SWING_ARC:Float = 300;
	static inline var SWING_SCALE:Float = 2.5;
	static inline var AIM_LERP:Float = 0.25;
	static inline var SLASH_SPAWN_DIST:Float = 110;
	static inline var FLIP_MARGIN:Float = 12;

	public var slashes:FlxTypedGroup<SlashProjectile>;
	public var throwAttack:ThrowAttack;
	public var throwMode:Bool = false;

	private var player:Player;
	private var scythe:FlxSprite;
	private var arena:Arena;
	private var director:EnemyDirector;
	private var status:PlayerCombat;
	private var fx:Fx;
	private var pickups:Pickups;
	private var swingTimer:Float = 0;
	private var swingBaseAngle:Float = 0;
	private var swingDir:Int = 1;

	public function new(player:Player, scythe:FlxSprite, arena:Arena, director:EnemyDirector, status:PlayerCombat, fx:Fx, pickups:Pickups)
	{
		this.player = player;
		this.scythe = scythe;
		this.arena = arena;
		this.director = director;
		this.status = status;
		this.fx = fx;
		this.pickups = pickups;
		slashes = new FlxTypedGroup<SlashProjectile>();
		throwAttack = new ThrowAttack(player, scythe, arena, director, status, damageEnemy);
	}

	public function update(elapsed:Float):Void
	{
		if (FlxG.keys.justPressed.Q)
			throwMode = !throwMode;
		anchorScythe();
		updateSwing(elapsed);
		updateAttackInput();
		updateSlashes();
		throwAttack.update(elapsed);
	}

	function anchorScythe():Void
	{
		scythe.x = player.x - scythe.origin.x + 30;
		scythe.y = player.y - scythe.origin.y + 65;
	}

	function updateSwing(elapsed:Float):Void
	{
		if (swingTimer > 0)
		{
			swingTimer -= elapsed;
			var t:Float = 1 - swingTimer / SWING_TIME;
			if (t > 1)
				t = 1;
			scythe.angle = swingBaseAngle + swingDir * SWING_ARC * (FlxEase.quintOut(t) - 0.5);
			var s:Float = 4 + SWING_SCALE * Math.sin(Math.PI * t);
			scythe.scale.set(s, s);
		}
		else
		{
			scythe.scale.set(4, 4);
			trackCursor(FlxG.mouse.x, FlxG.mouse.y, elapsed);
		}
	}

	function trackCursor(mouseX:Float, mouseY:Float, elapsed:Float):Void
	{
		var pmx:Float = player.x + player.width * 0.5;
		var pmy:Float = player.y + player.height * 0.5;
		var theta:Float = Math.atan2(mouseY - pmy, mouseX - pmx) * 180 / Math.PI;
		updateScytheFlip(theta);
		var target:Float = scythe.flipX ? theta - 180 : theta;
		var delta:Float = ((target - scythe.angle) % 360 + 540) % 360 - 180;
		scythe.angle += delta * (1 - Math.pow(1 - AIM_LERP, elapsed * 60));
	}

	function updateScytheFlip(deg:Float):Void
	{
		var wantFlip:Bool = scythe.flipX;
		var a:Float = Math.abs(deg);
		if (a > 90 + FLIP_MARGIN)
			wantFlip = true;
		else if (a < 90 - FLIP_MARGIN)
			wantFlip = false;
		if (wantFlip != scythe.flipX)
		{
			scythe.flipX = wantFlip;
			scythe.angle += 180;
		}
	}

	function updateAttackInput():Void
	{
		if (!FlxG.mouse.justPressed || status.dead || throwAttack.airborne)
			return;

		var pmx:Float = player.x + player.width * 0.5;
		var pmy:Float = player.y + player.height * 0.5;
		var dx:Float = FlxG.mouse.x - pmx;
		var dy:Float = FlxG.mouse.y - pmy;
		var len:Float = Math.sqrt(dx * dx + dy * dy);
		if (len < 0.001)
		{
			dx = 1;
			dy = 0;
			len = 1;
		}
		dx /= len;
		dy /= len;
		var aimDeg:Float = Math.atan2(dy, dx) * 180 / Math.PI;

		if (throwMode)
		{
			throwAttack.launch(pmx, pmy, dx, dy);
			return;
		}

		updateScytheFlip(aimDeg);
		swingDir = scythe.flipX ? -1 : 1;
		swingBaseAngle = scythe.flipX ? aimDeg - 180 : aimDeg;
		swingTimer = SWING_TIME;

		var slash = slashes.recycle(SlashProjectile);
		slash.fire(pmx + dx * SLASH_SPAWN_DIST, pmy + dy * SLASH_SPAWN_DIST, dx, dy, aimDeg);
		FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.7);
	}

	function updateSlashes():Void
	{
		for (slash in slashes.members)
		{
			if (slash == null || !slash.exists || slash.fading)
				continue;
			var scx = slash.x + slash.width / 2;
			var scy = slash.y + slash.height / 2;
			if (arena.wallAt(scx + slash.dirX * SlashProjectile.RADIUS, scy + slash.dirY * SlashProjectile.RADIUS))
			{
				slash.velocity.set(0, 0);
				slash.fading = true;
				continue;
			}
			director.forEachEnemy(function(e) slashHit(slash, e, scx, scy));
		}
	}

	function slashHit(slash:SlashProjectile, e:Enemies, scx:Float, scy:Float):Void
	{
		if (e.isDead || slash.hasHit(e))
			return;

		var nx = Math.max(e.x, Math.min(scx, e.x + e.width));
		var ny = Math.max(e.y, Math.min(scy, e.y + e.height));
		var dx = scx - nx;
		var dy = scy - ny;
		if (dx * dx + dy * dy > SlashProjectile.RADIUS * SlashProjectile.RADIUS)
			return;

		slash.markHit(e);
		damageEnemy(e, slash.dirX, slash.dirY);
	}

	function damageEnemy(e:Enemies, pushX:Float, pushY:Float):Void
	{
		e.takeHit(pushX, pushY);

		FlxG.sound.play(Paths.sound("enemies/hit"), 0.6);
		fx.sparksAt(e.x + e.width / 2, e.y + e.height / 2);

		if (e.isDead)
		{
			fx.killImpact();
			status.rewardKill();
			if (FlxG.random.float() < e.dropChance)
				pickups.drop(e.x + e.width / 2, e.y + e.height / 2);
		}
	}
}
