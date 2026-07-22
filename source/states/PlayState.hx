package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxBar;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.Player;
import entities.Enemies;
import entities.Enemy;
import entities.Woodster;
import entities.LikWid;
import entities.SlashProjectile;

class PlayState extends FlxState
{

	private var _player:Player;

	private var rigs:Array<EnemyRig> = [];
	private var enemyBodies:FlxTypedGroup<Enemies>;

	private var shadowLayer:FlxTypedGroup<FlxSprite>;
	private var entityLayer:FlxTypedGroup<FlxSprite>;

	private var _background:FlxSprite;

	private var _shadowPlayer:FlxSprite;

	static inline var SWING_TIME:Float = 0.2;
	static inline var SWING_ARC:Float = 300;
	static inline var SWING_SCALE:Float = 2.5;
	static inline var AIM_LERP:Float = 0.25;
	static inline var SLASH_SPAWN_DIST:Float = 110;
	static inline var FLIP_MARGIN:Float = 12;
	static inline var IFRAME_TIME:Float = 0.4;
	static inline var HURT_LOCK_TIME:Float = 0.1;
	private var scythe:FlxSprite;
	private var slashes:FlxTypedGroup<SlashProjectile>;
	private var swingTimer:Float = 0;
	private var swingBaseAngle:Float = 0;
	private var swingDir:Int = 1;
	var swingPath:String = "assets/sounds/swing/swing";

	private var barBackground:FlxSprite;
	private var playerIcon:FlxSprite;
	private var customCursor:FlxSprite;
	public var passiveRed:FlxSprite;
	public var activeRed:FlxSprite;
	public var bar:FlxBar;
	public var camUI:FlxCamera;

	private var scaleX:Int = 4;
	private var scaleY:Int = 4;

	var shadowPath:String = "assets/images/effects/shadow.png";
	var uiPaths:String = "assets/images/ui/";
	var hitPath:String = "assets/sounds/damaged/hit";
	var dotPNG:String = ".png";
	var dotOGG:String = ".ogg";

	private var iframeTimer:Float = 0;
	private var hurtLockTimer:Float = 0;
	public var health:Float = 2;
	public var itemBar:Float = 2;
	public var dead:Bool = false;

	static inline var TILE_WIDTH:Int = 16;
	static inline var TILE_HEIGHT:Int = 16;
	private var _collisionMap:FlxTilemap;

	override public function create()
	{

		FlxG.camera.bgColor = 0xFFFFFFFF;

		camUI = new FlxCamera();
		FlxG.cameras.add(camUI, false);
		camUI.bgColor.alpha = 0;

		_collisionMap = new FlxTilemap();

		_background = new FlxSprite(0, 0, "assets/images/stages/theEnemy" + dotPNG);
		add(_background);

		_collisionMap.loadMapFromCSV("assets/default_auto.txt", "assets/auto_tiles" + dotPNG, TILE_WIDTH, TILE_HEIGHT, AUTO);
		_collisionMap.visible = false;
		add(_collisionMap);

		FlxG.worldBounds.set(0, 0, _collisionMap.width, _collisionMap.height);

		_player = new Player(350, 350);

		FlxG.camera.follow(_player);
		FlxG.camera.followLerp = 0.1;
		FlxG.camera.setScrollBoundsRect(0, 0, _collisionMap.width, _collisionMap.height);

		_shadowPlayer = new FlxSprite(_player.x + 10, _player.y + 48, shadowPath);
		_shadowPlayer.scale.set(scaleX, scaleY);

		scythe = new FlxSprite(_player.x, _player.y - 50, "assets/images/items/mufu_scythe" + dotPNG);
		scythe.scale.set(scaleX, scaleY);

		shadowLayer = new FlxTypedGroup<FlxSprite>();
		add(shadowLayer);
		shadowLayer.add(_shadowPlayer);

		entityLayer = new FlxTypedGroup<FlxSprite>();
		add(entityLayer);
		entityLayer.add(_player);
		entityLayer.add(scythe);

		slashes = new FlxTypedGroup<SlashProjectile>();
		add(slashes);

		enemyBodies = new FlxTypedGroup<Enemies>();

		spawnEnemy(new Enemy(0, 0));
		spawnEnemy(new Woodster(0, 0));
		spawnEnemy(new LikWid(0, 0));

		scythe.origin.set(scythe.width * 0.5, scythe.height);

		barBackground = makeUISprite(160, 670, "bar_red");
		activeRed = makeUISprite(1060, 670, "active_red");
		passiveRed = makeUISprite(1150, 670, "pasive_red");

		bar = makeUIBar(barBackground, "bar_main_empty", "bar_red", 'health');

		playerIcon = makeUISprite(barBackground.x - 120, barBackground.y, "mufu_icon");

		add(barBackground);
		add(bar);
		add(activeRed);
		add(passiveRed);
		add(playerIcon);

		customCursor = makeUISprite(0, 0, "mouse");
		add(customCursor);

		FlxG.mouse.visible = false;

		FlxG.sound.playMusic("assets/music/stage/gloomDoomWoods" + dotOGG, 0.3, true);

		super.create();
	}

	function registerEnemy(e:Enemies):Void
	{
		e.target = _player;

		var sh = new FlxSprite(0, 0, shadowPath);
		sh.scale.set(e.shadowScaleX, scaleY);
		shadowLayer.add(sh);

		var hb = new FlxObject(0, 0, 40, 40);

		entityLayer.add(e);
		enemyBodies.add(e);
		rigs.push(new EnemyRig(e, sh, hb));
	}

	function makeUISprite(x:Float, y:Float, name:String):FlxSprite
	{
		var s = new FlxSprite(x, y, uiPaths + name + dotPNG);
		s.antialiasing = false;
		s.scale.set(scaleX, scaleY);
		s.cameras = [camUI];
		return s;
	}

	function makeUIBar(anchor:FlxSprite, emptyName:String, fillName:String, valueField:String):FlxBar
	{
		var b = new FlxBar(anchor.x, anchor.y, LEFT_TO_RIGHT, Std.int(anchor.width), Std.int(anchor.height), this, valueField, 0, 2);
		b.createImageBar(uiPaths + emptyName + dotPNG, uiPaths + fillName + dotPNG, FlxColor.TRANSPARENT, FlxColor.TRANSPARENT);
		b.updateBar();
		b.antialiasing = false;
		b.scale.set(scaleX, scaleY);
		b.cameras = [camUI];
		return b;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		FlxG.collide(_player, _collisionMap);
		FlxG.collide(enemyBodies, _collisionMap);
		FlxG.overlap(enemyBodies, enemyBodies, null, separateLiveEnemies);

		if (iframeTimer > 0)
		{
			iframeTimer -= elapsed;
			_player.visible = dead || Std.int(iframeTimer * 20) % 2 == 0;
			if (iframeTimer <= 0)
				_player.visible = true;
		}

		if (hurtLockTimer > 0)
		{
			hurtLockTimer -= elapsed;
			if (hurtLockTimer <= 0 && !dead)
				_player.blockMovement = false;
		}

		for (rig in rigs)
			rig.enemy.target = dead ? null : _player;

		if (FlxG.keys.justPressed.ONE)
		{
			decreaseVolume();
		}

		if (FlxG.keys.justPressed.TWO)
		{
			increaseVolume();
		}

		if (FlxG.keys.justPressed.NINE)
		{
			spawnEnemy(new Enemy(0, 0));
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			spawnEnemy(new Woodster(0, 0));
		}

		if (FlxG.keys.justPressed.EIGHT)
		{
			spawnEnemy(new LikWid(0, 0));
		}

		if (FlxG.keys.justPressed.FIVE)
		{
			health = 0;
			itemBar = 0;
		}

		if (FlxG.keys.justPressed.SIX)
		{
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		}

		if (FlxG.keys.justPressed.FOUR)
		{
			health = 2;
			itemBar = 2;
			dead = false;
			_player.isDead = false;
			_player.blockMovement = false;
			_shadowPlayer.visible = true;
			scythe.visible = true;
		}

		if (FlxG.keys.justPressed.R && dead)
		{
			FlxG.resetState();
		}

		customCursor.setPosition(FlxG.mouse.screenX - 5, FlxG.mouse.screenY);

		updateWeaponPositionXY(_player, scythe);

		for (rig in rigs)
		{
			var e = rig.enemy;
			var alive = e.exists && !e.isDead;

			rig.shadow.visible = alive;
			rig.shadow.x = e.x + (e.flipX ? e.shadowOffXFlip : e.shadowOffX);
			rig.shadow.y = e.y + e.shadowOffY;

			if (alive)
			{
				rig.hitbox.x = e.x + (e.flipX ? e.hitOffXFlip : e.hitOffX);
				rig.hitbox.y = e.y + e.hitOffY;
				hurtPlayer(rig.hitbox);
			}
			else
			{
				rig.hitbox.x = -100000;
			}
		}

		_shadowPlayer.x = _player.x + 30;
		_shadowPlayer.y = _player.y + 90;

		orderEntitiesByY();

		if (swingTimer > 0)
		{
			swingTimer -= elapsed;
			var t:Float = 1 - swingTimer / SWING_TIME;
			if (t > 1)
				t = 1;
			scythe.angle = swingBaseAngle + swingDir * SWING_ARC * (FlxEase.quintOut(t) - 0.5);
			var s:Float = scaleX + SWING_SCALE * Math.sin(Math.PI * t);
			scythe.scale.set(s, s);
		}
		else
		{
			scythe.scale.set(scaleX, scaleY);
			updateWeaponPosition(FlxG.mouse.x, FlxG.mouse.y, elapsed);
		}

		if (FlxG.mouse.justPressed && !dead)
		{
			var pmx:Float = _player.x + _player.width * 0.5;
			var pmy:Float = _player.y + _player.height * 0.5;
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

			updateScytheFlip(aimDeg);
			swingDir = scythe.flipX ? -1 : 1;
			swingBaseAngle = scythe.flipX ? aimDeg - 180 : aimDeg;
			swingTimer = SWING_TIME;

			var slash = slashes.recycle(SlashProjectile);
			slash.fire(pmx + dx * SLASH_SPAWN_DIST, pmy + dy * SLASH_SPAWN_DIST, dx, dy, aimDeg);

			FlxG.sound.play(swingPath + (1 + Std.random(8)) + dotOGG, 0.7);
		}

		for (slash in slashes.members)
		{
			if (slash == null || !slash.exists || slash.fading)
				continue;
			var scx = slash.x + slash.width / 2;
			var scy = slash.y + slash.height / 2;
			var noseTile = _collisionMap.getTileIndexByCoords(FlxPoint.weak(scx + slash.dirX * SlashProjectile.RADIUS, scy + slash.dirY * SlashProjectile.RADIUS));
			if (noseTile >= 0 && _collisionMap.getTileByIndex(noseTile) > 0)
			{
				slash.velocity.set(0, 0);
				slash.fading = true;
				continue;
			}
			for (rig in rigs)
				slashHit(slash, rig.enemy, scx, scy);
		}

		if(health <= 0 && !dead)
		{
			_player.animation.play("death", false);
			dead = true;
			_player.isDead = true;
		}

		if(health <= 0)
		{
			health = 0;
			_shadowPlayer.visible = false;
			scythe.visible = false;
			_player.blockMovement = true;
		}
	}

	function orderEntitiesByY():Void {
		entityLayer.sort(sortByFeet, FlxSort.ASCENDING);
	}

	function sortByFeet(order:Int, a:FlxSprite, b:FlxSprite):Int {
		var ay = a == scythe ? _player.y + 1 : a.y;
		var by = b == scythe ? _player.y + 1 : b.y;
		return FlxSort.byValues(order, ay, by);
	}

	function updateWeaponPosition(mouseX:Float, mouseY:Float, elapsed:Float):Void
	{
		var pmx:Float = _player.x + _player.width * 0.5;
		var pmy:Float = _player.y + _player.height * 0.5;
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

	function separateLiveEnemies(a:Enemies, b:Enemies):Bool
	{
		if (a.isDead || b.isDead)
			return false;
		return FlxObject.separate(a, b);
	}

	function hurtPlayer(source:FlxObject):Void
	{
		if (dead || iframeTimer > 0)
			return;
		if (source.x + source.width <= _player.x || _player.x + _player.width <= source.x
			|| source.y + source.height <= _player.y || _player.y + _player.height <= source.y)
			return;

		FlxG.sound.play(hitPath);

		var knockbackMagnitude = 300;
		_player.velocity.x = knockbackMagnitude * (_player.x > source.x ? 1 : -1);
		_player.velocity.y = knockbackMagnitude * (_player.y > source.y ? 1 : -1);

		health -= 0.25;
		_player.animation.play("hurt", false);
		_player.blockMovement = true;
		iframeTimer = IFRAME_TIME;
		hurtLockTimer = HURT_LOCK_TIME;
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
		e.takeHit(slash.dirX, slash.dirY);
	}

	function updateWeaponPositionXY(_player:Player, scythe:FlxSprite):Void
	{
		var distanceFromPlayer:Float = 0;
		scythe.x = _player.x + distanceFromPlayer - scythe.origin.x + 30;
		scythe.y = _player.y + distanceFromPlayer - scythe.origin.y + 65;
	}

    function increaseVolume():Void {
        FlxG.sound.changeVolume(0.1);
    }

    function decreaseVolume():Void {
        FlxG.sound.changeVolume(-0.1);
    }

	private function spawnEnemy(e:Enemies):Void
	{
		e.x = _collisionMap.width / 2 - e.width / 2 + Math.random() * 300 - 150;
		e.y = _collisionMap.height / 2 - e.height / 2 + Math.random() * 200 - 100;
		registerEnemy(e);
	}
}

class EnemyRig
{
	public var enemy:Enemies;
	public var shadow:FlxSprite;
	public var hitbox:FlxObject;

	public function new(enemy:Enemies, shadow:FlxSprite, hitbox:FlxObject)
	{
		this.enemy = enemy;
		this.shadow = shadow;
		this.hitbox = hitbox;
	}
}
