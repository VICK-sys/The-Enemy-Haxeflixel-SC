package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
import entities.enemy.Enemies;
import entities.enemy.EnemyNav;
import systems.Arena;
import systems.Fx;
import systems.RenderLayers;
import systems.PlayerCombat;
import systems.EnemyDirector;
import systems.Weapons;
import systems.Pickups;
import systems.Hud;
import util.Paths;
import util.SaveData;
import util.PerfLog;

class PlayState extends FlxState
{
	private var fx:Fx;
	private var arena:Arena;
	private var _player:Player;
	private var scythe:FlxSprite;
	private var layers:RenderLayers;
	private var status:PlayerCombat;
	private var pickups:Pickups;
	private var director:EnemyDirector;
	private var combat:Weapons;
	private var hud:Hud;
	private var perf:PerfLog;

	override public function create()
	{
		fx = new Fx();

		FlxG.camera.bgColor = 0xFFFFFFFF;

		arena = new Arena(this);

		_player = new Player(arena.spawnX, arena.spawnY);

		FlxG.camera.follow(_player);
		FlxG.camera.followLerp = 0.1;
		FlxG.camera.setScrollBoundsRect(0, 0, arena.width, arena.height);

		scythe = new FlxSprite(0, 0, Paths.image("items/mufu_scythe"));
		scythe.scale.set(4, 4);
		scythe.origin.set(scythe.width * 0.5, scythe.height);
		scythe.x = _player.x - scythe.origin.x + 30;
		scythe.y = _player.y - scythe.origin.y + 65;

		layers = new RenderLayers(this, _player, scythe);
		arena.addPillars(layers.entityLayer);

		status = new PlayerCombat(_player, fx);
		pickups = new Pickups(_player, status);
		insert(members.indexOf(layers.entityLayer), pickups.group);
		director = new EnemyDirector(_player, arena, layers, status);
		combat = new Weapons(_player, scythe, arena, director, status, fx, pickups);

		add(combat.swing.slashes);
		add(combat.slice.slices);
		add(combat.bow.arrows);
		insert(members.indexOf(layers.entityLayer), combat.bow.rain.markers);
		insert(members.indexOf(layers.entityLayer), combat.hammer.shock.cracks);
		insert(members.indexOf(layers.entityLayer), combat.hammer.shock.rings);
		add(combat.bow.rain.arrows);
		add(combat.hookAttack.rope);
		add(combat.hookAttack.hook);
		add(combat.throwAttack.trail);
		add(combat.throwAttack.thrown);
		insert(members.indexOf(layers.entityLayer), combat.superScythes.trail);
		insert(members.indexOf(layers.entityLayer), combat.superScythes.backLayer);
		add(combat.superScythes.frontLayer);
		add(fx.sparks);
		add(director.shots);

		hud = new Hud(this, status);
		director.onWave = onWaveStarted;
		perf = new PerfLog();

		FlxG.sound.playMusic(Paths.music("stage/gloomDoomWoods"), 0.3, true);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		EnemyNav.resetBudget();

		super.update(elapsed);

		fx.update();

		FlxG.collide(_player, arena.map);
		director.collide();

		status.update(elapsed);

		if (status.consumeJustDied())
		{
			layers.playerShadow.visible = false;
			scythe.visible = false;
			hud.showDeath(director.wave, SaveData.bestWave());
		}

		director.update(elapsed);
		pickups.update();
		layers.update();
		combat.update(elapsed);
		director.updateShots();
		hud.setMode(combat.modeName());
		hud.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE && !status.dead)
			openSubState(new PauseSubState(hud.camUI));

		debugKeys();

		var projectiles = live(combat.slice.slices.countLiving()) + live(director.shots.countLiving())
			+ live(combat.bow.arrows.countLiving()) + live(combat.bow.rain.arrows.countLiving())
			+ (combat.throwAttack.airborne ? 1 : 0) + (combat.hookAttack.hook.exists ? 1 : 0);
		perf.frame(director.enemyCount(), EnemyNav.usedBudget(), projectiles, director.wave);
	}

	function live(n:Int):Int
		return n < 0 ? 0 : n;

	function onWaveStarted(n:Int):Void
	{
		SaveData.submitWave(n);
		hud.showWave(n);
	}

	function debugKeys():Void
	{
		if (FlxG.keys.justPressed.MINUS)
			FlxG.sound.changeVolume(-0.1);

		if (FlxG.keys.justPressed.PLUS)
			FlxG.sound.changeVolume(0.1);

		if (FlxG.keys.justPressed.NINE)
			director.spawnNear(new Enemies("enemy"));

		if (FlxG.keys.justPressed.SEVEN)
			director.spawnNear(new Enemies("woodster"));

		if (FlxG.keys.justPressed.EIGHT)
			director.spawnNear(new Enemies("likwid"));

		if (FlxG.keys.justPressed.FIVE)
		{
			status.health = 0;
			status.itemBar = 0;
		}

		if (FlxG.keys.justPressed.SIX)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;

		if (FlxG.keys.justPressed.F4)
		{
			status.revive();
			layers.playerShadow.visible = true;
			scythe.visible = true;
			hud.hideDeath();
		}

		if (FlxG.keys.justPressed.R && status.dead)
			FlxG.resetState();
	}
}
