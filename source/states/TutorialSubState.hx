package states;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import util.Paths;

class TutorialSubState extends FlxSubState
{
	public static var shown:Bool = false;

	static inline var PAGES:Int = 6;
	static inline var DEMO_CX:Float = 640;
	static inline var DEMO_CY:Float = 340;

	static var TITLES:Array<String> = ["MOVE", "ATTACK", "WEAPONS", "MODES", "SUPER", "HEALTH"];
	static var DESCS:Array<String> = [
		"WASD — move        SPACE — dash (2s cooldown)",
		"Aim with the mouse        LEFT CLICK — attack",
		"1-4 or SCROLL WHEEL — switch weapon",
		"RIGHT CLICK — cycle the equipped weapon's mode",
		"Q — super at full AP (scythe only)\nLEFT CLICK — launch the blades",
		"Enemies drop hearts — walk into them to heal"
	];

	private var camUI:FlxCamera;
	private var titleText:FlxText;
	private var descText:FlxText;
	private var pageText:FlxText;
	private var page:Int = 0;
	private var demoTime:Float = 0;
	private var demo:Array<FlxSprite> = [];
	private var demoTexts:Array<FlxText> = [];
	private var actor:FlxSprite;
	private var held:FlxSprite;
	private var cursorIcon:FlxSprite;
	private var slash:FlxSprite;
	private var heart:FlxSprite;
	private var barFill:FlxSprite;
	private var modeIcon:FlxSprite;
	private var modeLabel:FlxText;
	private var items:Array<FlxSprite> = [];
	private var itemBase:Array<Float> = [];
	private var itemLabels:Array<FlxText> = [];
	private var blades:Array<FlxSprite> = [];
	private var lines:Array<FlxSprite> = [];
	private var swingTimer:Float = 0;
	private var swingBase:Float = 0;
	private var swingDir:Int = 1;
	private var heldAngle:Float = 0;
	private var cycleIndex:Int = 0;
	private var cycleTimer:Float = 0;
	private var switchTimer:Float = 0;
	private var lineTimer:Float = 0;

	public function new(camUI:FlxCamera)
	{
		super();
		this.camUI = camUI;
	}

	override public function create():Void
	{
		var overlay = new FlxSprite(0, 0);
		overlay.makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
		overlay.cameras = [camUI];
		add(overlay);

		var border = new FlxSprite(236, 76);
		border.makeGraphic(808, 568, 0xFFB2273A);
		border.cameras = [camUI];
		add(border);

		var panel = new FlxSprite(240, 80);
		panel.makeGraphic(800, 560, 0xFF4A4550);
		panel.cameras = [camUI];
		add(panel);

		titleText = uiText(100, 36);
		descText = uiText(524, 16);
		pageText = uiText(596, 16);

		buildPage();

		super.create();
	}

	function uiText(y:Float, size:Int):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, "");
		t.setFormat(null, size, FlxColor.WHITE, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		t.cameras = [camUI];
		add(t);
		return t;
	}

	function mkSprite():FlxSprite
	{
		var s = new FlxSprite();
		s.antialiasing = false;
		s.cameras = [camUI];
		add(s);
		demo.push(s);
		return s;
	}

	function mkText(y:Float, size:Int, str:String):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, str);
		t.setFormat(null, size, FlxColor.WHITE, CENTER);
		t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		t.cameras = [camUI];
		add(t);
		demoTexts.push(t);
		return t;
	}

	function mkPlayer():FlxSprite
	{
		var p = mkSprite();
		p.frames = Paths.sparrow("characters/mufu");
		p.animation.addByPrefix("idle", "Idle", 12, true);
		p.animation.addByPrefix("walk", "Run", 12, true);
		p.scale.set(4, 4);
		p.width = 75;
		p.height = 95;
		p.offset.set(-19, -17);
		p.animation.play("walk");
		return p;
	}

	function centerActor(cx:Float, cy:Float):Void
	{
		actor.setPosition(cx - actor.width / 2, cy - actor.height / 2);
	}

	function buildPage():Void
	{
		for (s in demo)
		{
			remove(s);
			s.destroy();
		}
		for (t in demoTexts)
		{
			remove(t);
			t.destroy();
		}
		demo = [];
		demoTexts = [];
		items = [];
		itemBase = [];
		itemLabels = [];
		blades = [];
		lines = [];
		demoTime = 0;
		swingTimer = 0;
		cycleIndex = 0;
		cycleTimer = 0;
		switchTimer = 0;
		heldAngle = 0;

		titleText.text = TITLES[page];
		descText.text = DESCS[page];
		pageText.text = "A <   " + (page + 1) + " / " + PAGES + "   > D        ENTER — PLAY";

		switch (page)
		{
			case 0: buildMove();
			case 1: buildAttack();
			case 2: buildWeapons();
			case 3: buildModes();
			case 4: buildSuper();
			case 5: buildHealth();
		}

		updateDemo(0);
	}

	function updateDemo(elapsed:Float):Void
	{
		switch (page)
		{
			case 0: updateMove(elapsed);
			case 1: updateAttack(elapsed);
			case 2: updateWeapons(elapsed);
			case 3: updateModes(elapsed);
			case 4: updateSuper(elapsed);
			case 5: updateHealth(elapsed);
		}
	}

	function buildMove():Void
	{
		actor = mkPlayer();
		for (i in 0...6)
		{
			var l = mkSprite();
			l.makeGraphic(44, 4, 0xFFFFFFFF);
			l.alpha = 0;
			lines.push(l);
		}
	}

	function buildAttack():Void
	{
		actor = mkPlayer();
		actor.animation.play("idle");
		centerActor(DEMO_CX - 60, DEMO_CY);

		slash = mkSprite();
		slash.frames = Paths.sparrow("effects/attacks_gfx");
		slash.animation.addByPrefix("slash", "Sword", 12, false);
		slash.scale.set(4, 4);
		slash.kill();

		held = mkSprite();
		held.loadGraphic(Paths.image("items/mufu_scythe"));
		held.scale.set(4, 4);
		held.origin.set(held.width * 0.5, held.height);

		cursorIcon = mkSprite();
		cursorIcon.loadGraphic(Paths.image("ui/mouse"));
		cursorIcon.scale.set(3, 3);
	}

	function buildWeapons():Void
	{
		var names = ["mufu_scythe", "mufu_hammer", "mufu_bow", "mufu_hook"];
		for (i in 0...4)
		{
			var s = mkSprite();
			s.loadGraphic(Paths.image("items/" + names[i]));
			s.setGraphicSize(0, 130);
			s.updateHitbox();
			s.setPosition(DEMO_CX + (i - 1.5) * 160 - s.width / 2, DEMO_CY - s.height / 2);
			items.push(s);
			itemBase.push(s.scale.y);
			var l = new FlxText(0, DEMO_CY + 90, 0, Std.string(i + 1));
			l.setFormat(null, 24, FlxColor.WHITE, CENTER);
			l.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			l.cameras = [camUI];
			add(l);
			demoTexts.push(l);
			l.x = DEMO_CX + (i - 1.5) * 160 - l.width / 2;
			itemLabels.push(l);
		}
	}

	function buildModes():Void
	{
		modeIcon = mkSprite();
		modeLabel = mkText(DEMO_CY + 100, 28, "");
		mkText(DEMO_CY - 160, 24, "Q");
		setModeIcon(0);
	}

	function buildSuper():Void
	{
		actor = mkPlayer();
		actor.animation.play("idle");
		for (i in 0...6)
		{
			var b = mkSprite();
			b.loadGraphic(Paths.image("items/mufu_scythe"));
			b.scale.set(3, 3);
			blades.push(b);
		}
	}

	function buildHealth():Void
	{
		actor = mkPlayer();

		heart = mkSprite();
		heart.makeGraphic(12, 12, 0xFFE04848);
		heart.scale.set(3, 3);
		heart.setPosition(770 - 6, DEMO_CY + 20 - 6);

		var barBack = mkSprite();
		barBack.makeGraphic(200, 18, 0xFF2A2A2A);
		barBack.setPosition(DEMO_CX - 100, 190);

		barFill = mkSprite();
		barFill.makeGraphic(192, 10, 0xFFD22C3C);
		barFill.origin.set(0, 5);
		barFill.setPosition(DEMO_CX - 96, 194);
		barFill.scale.x = 0.5;
	}

	function setModeIcon(i:Int):Void
	{
		var baseAngle:Float = 0;
		if (i == 2)
		{
			modeIcon.loadGraphic(Paths.image("items/mufu_scythe"));
			baseAngle = 30;
		}
		else
		{
			modeIcon.frames = Paths.sparrow("effects/attacks_gfx");
			if (modeIcon.animation.getByName("slash") == null)
				modeIcon.animation.addByPrefix("slash", "Sword", 0, false);
			var anim = modeIcon.animation.getByName("slash");
			modeIcon.animation.play("slash", true, false, i == 1 && anim.numFrames > 3 ? anim.numFrames - 3 : 0);
			modeIcon.animation.pause();
			baseAngle = i == 1 ? -35 : 0;
		}
		modeIcon.setGraphicSize(0, 130);
		modeIcon.updateHitbox();
		modeIcon.setPosition(DEMO_CX - modeIcon.width / 2, DEMO_CY - modeIcon.height / 2);
		modeIcon.angle = baseAngle;
		modeLabel.text = ["SWING", "AIR SLICE", "THROW"][i];
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		demoTime += elapsed;

		updateDemo(elapsed);

		if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT)
			flip(1);
		if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT)
			flip(-1);
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE)
			close();
	}

	function flip(dir:Int):Void
	{
		page = (page + dir + PAGES) % PAGES;
		buildPage();
		FlxG.sound.play(Paths.sound("scythe/slice"), 0.3);
	}

	function updateMove(elapsed:Float):Void
	{
		for (l in lines)
			if (l.alpha > 0)
				l.alpha -= 3 * elapsed;

		var t = demoTime % 3.0;
		var px:Float;
		if (t < 1.2)
		{
			px = 470 + t / 1.2 * 150;
			actor.flipX = false;
			actor.animation.play("walk");
		}
		else if (t < 1.5)
		{
			px = 620 + (t - 1.2) / 0.3 * 190;
			actor.flipX = false;
			lineTimer -= elapsed;
			if (lineTimer <= 0)
			{
				lineTimer = 0.05;
				for (l in lines)
					if (l.alpha <= 0)
					{
						l.alpha = 0.7;
						l.setPosition(px - 90, DEMO_CY + 10 + Math.random() * 40 - 20);
						break;
					}
			}
		}
		else
		{
			px = 810 - (t - 1.5) / 1.5 * 340;
			actor.flipX = true;
			actor.animation.play("walk");
		}
		centerActor(px, DEMO_CY);
	}

	function updateAttack(elapsed:Float):Void
	{
		var a = demoTime * 1.1;
		var tx = DEMO_CX - 60 + Math.cos(a) * 230;
		var ty = DEMO_CY + Math.sin(a) * 110;
		cursorIcon.setPosition(tx - cursorIcon.width / 2, ty - cursorIcon.height / 2);

		var pcx = actor.x + actor.width * 0.5;
		var pcy = actor.y + actor.height * 0.5;
		var theta = Math.atan2(ty - pcy, tx - pcx) * 180 / Math.PI;
		var flip = Math.abs(theta) > 90;
		held.flipX = flip;
		var target = flip ? theta - 180 : theta;

		swingTimer -= elapsed;
		if (demoTime % 1.4 < elapsed && swingTimer <= -0.5)
		{
			swingTimer = 0.2;
			swingDir = flip ? -1 : 1;
			swingBase = target;
			var dx = Math.cos(theta * Math.PI / 180);
			var dy = Math.sin(theta * Math.PI / 180);
			slash.revive();
			slash.animation.play("slash", true);
			slash.setPosition(pcx + dx * 110 - slash.width / 2, pcy + dy * 110 - slash.height / 2);
			slash.angle = theta;
			slash.alpha = 1;
			slash.velocity.set(dx * 150, dy * 150);
			FlxG.sound.play(Paths.sound("swing/swing" + (1 + Std.random(8))), 0.3);
		}

		if (swingTimer > 0)
		{
			var p = 1 - swingTimer / 0.2;
			heldAngle = swingBase + swingDir * 300 * (FlxEase.quintOut(p) - 0.5);
			var s = 4 + 2.5 * Math.sin(Math.PI * p);
			held.scale.set(s, s);
		}
		else
		{
			held.scale.set(4, 4);
			var delta = ((target - heldAngle) % 360 + 540) % 360 - 180;
			heldAngle += delta * (1 - Math.pow(0.75, elapsed * 60));
		}
		held.angle = heldAngle;
		held.x = actor.x - held.origin.x + 30;
		held.y = actor.y - held.origin.y + 65;

		if (slash.exists)
		{
			slash.alpha -= 4 * elapsed;
			if (slash.alpha <= 0)
				slash.kill();
		}
	}

	function updateWeapons(elapsed:Float):Void
	{
		cycleTimer -= elapsed;
		if (cycleTimer <= 0)
		{
			cycleTimer = 0.9;
			cycleIndex = (cycleIndex + 1) % 4;
			switchTimer = 0.3;
			FlxG.sound.play(Paths.sound("scythe/catch"), 0.25);
		}
		if (switchTimer > 0)
			switchTimer -= elapsed;

		var p = 1 - switchTimer / 0.3;
		if (p > 1)
			p = 1;
		var ease = 1 - (1 - p) * (1 - p) * (1 - p);
		for (i in 0...4)
		{
			var s = items[i];
			if (i == cycleIndex)
			{
				var mult = 1.25 + (1 - ease) * 0.5;
				s.scale.set(itemBase[i] * mult, itemBase[i] * mult);
				s.angle = -180 * (1 - ease);
				s.alpha = 1;
				itemLabels[i].alpha = 1;
			}
			else
			{
				s.scale.set(itemBase[i], itemBase[i]);
				s.angle = 0;
				s.alpha = 0.35;
				itemLabels[i].alpha = 0.35;
			}
		}
	}

	function updateModes(elapsed:Float):Void
	{
		cycleTimer -= elapsed;
		if (cycleTimer <= 0)
		{
			cycleTimer = 1.1;
			cycleIndex = (cycleIndex + 1) % 3;
			switchTimer = 0.3;
			setModeIcon(cycleIndex);
			FlxG.sound.play(Paths.sound("scythe/catch"), 0.25);
		}
		if (switchTimer > 0)
		{
			switchTimer -= elapsed;
			var p = 1 - switchTimer / 0.3;
			if (p > 1)
				p = 1;
			var ease = 1 - (1 - p) * (1 - p) * (1 - p);
			modeIcon.alpha = ease;
			modeLabel.alpha = 0.3 + 0.7 * ease;
		}
		else
		{
			modeIcon.alpha = 1;
			modeLabel.alpha = 1;
		}
	}

	function updateSuper(elapsed:Float):Void
	{
		var lift = 26 + Math.sin(demoTime * 3) * 6;
		centerActor(DEMO_CX, DEMO_CY - lift + 20);

		for (i in 0...blades.length)
		{
			var phase = (demoTime * 120 + i * 60) * Math.PI / 180;
			var depth = Math.sin(phase);
			var b = blades[i];
			var bx = DEMO_CX + Math.cos(phase) * 130;
			var by = DEMO_CY - lift + 20 + depth * 45;
			var s = 3 + depth * 0.4;
			b.scale.set(s, s);
			b.alpha = 0.85 + 0.15 * depth;
			b.setPosition(bx - b.width / 2, by - b.height / 2);
		}
	}

	function updateHealth(elapsed:Float):Void
	{
		var t = demoTime % 2.8;
		if (t < 1.4)
		{
			centerActor(480 + t / 1.4 * 230, DEMO_CY);
			actor.flipX = false;
			actor.animation.play("walk");
			heart.alpha = 1;
			heart.scale.set(3, 3);
			heart.y = DEMO_CY + 14 + Math.sin(demoTime * 4) * 4;
			barFill.scale.x = 0.5;
		}
		else if (t < 1.8)
		{
			actor.animation.play("idle");
			var p = (t - 1.4) / 0.4;
			heart.scale.set(3 + p * 3, 3 + p * 3);
			heart.alpha = 1 - p;
			barFill.scale.x = 0.5 + p * 0.5;
		}
		else
		{
			actor.animation.play("idle");
			heart.alpha = 0;
			barFill.scale.x = 1;
		}
	}
}
