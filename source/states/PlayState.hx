package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import entities.Player;
import entities.Enemies;
import systems.Arena;
import systems.Fx;
import systems.RenderLayers;
import systems.PlayerCombat;
import systems.EnemyDirector;
import systems.ScytheCombat;
import systems.Pickups;
import systems.Hud;
import util.Paths;
import util.SaveData;

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
	private var combat:ScytheCombat;
	private var hud:Hud;

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
		combat = new ScytheCombat(_player, scythe, arena, director, status, fx, pickups);

		add(combat.slashes);
		add(fx.sparks);
		add(director.shots);

		hud = new Hud(this, status);
		director.onWave = onWaveStarted;

		FlxG.sound.playMusic(Paths.music("stage/gloomDoomWoods"), 0.3, true);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
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
		hud.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE && !status.dead)
			openSubState(new PauseSubState(hud.camUI));

		debugKeys();
	}

	function onWaveStarted(n:Int):Void
	{
		SaveData.submitWave(n);
		hud.showWave(n);
	}

	function debugKeys():Void
	{
		if (FlxG.keys.justPressed.ONE)
			FlxG.sound.changeVolume(-0.1);

		if (FlxG.keys.justPressed.TWO)
			FlxG.sound.changeVolume(0.1);

		if (FlxG.keys.justPressed.NINE)
			director.spawnCenter(new Enemies("enemy"));

		if (FlxG.keys.justPressed.SEVEN)
			director.spawnCenter(new Enemies("woodster"));

		if (FlxG.keys.justPressed.EIGHT)
			director.spawnCenter(new Enemies("likwid"));

		if (FlxG.keys.justPressed.FIVE)
		{
			status.health = 0;
			status.itemBar = 0;
		}

		if (FlxG.keys.justPressed.SIX)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;

		if (FlxG.keys.justPressed.FOUR)
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
