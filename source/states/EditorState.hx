package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import data.ArenaData.ArenaDataRegistry;
import data.EditorData.EditorDataRegistry;
import data.ThemeData.ThemeDataRegistry;
import states.editor.EditorHud;
import states.editor.EditorMap;
import states.editor.EditorView;
import states.editor.PropPalette;
import states.editor.PropTool;
import states.editor.TilePalette;
import states.editor.TileTool;
import states.editor.WallTool;
import util.CustomArena;
import util.Paths;

class EditorState extends FlxState
{
	static inline var MODE_WALLS:Int = 0;
	static inline var MODE_TILES:Int = 1;
	static inline var MODE_PROPS:Int = 2;
	static var MODE_NAMES:Array<String> = ["WALL MODE", "TILE MODE", "PROP MODE"];

	public static var lastSlot:Int = 1;

	private var cfg = EditorDataRegistry.get();
	private var doc:EditorMap;
	private var view:EditorView;
	private var hud:EditorHud;
	private var wallTool:WallTool;
	private var tileTool:TileTool;
	private var propTool:PropTool;
	private var tilePal:TilePalette;
	private var propPal:PropPalette;

	private var uiCam:FlxCamera;
	private var bg:FlxSprite;
	private var spawnMark:FlxSprite;
	private var spawnLabel:FlxText;

	private var slot:Int;
	private var mode:Int = MODE_WALLS;
	private var leaving:Bool = false;

	private var isProps(get, never):Bool;

	function get_isProps():Bool
		return mode == MODE_PROPS;

	override public function create():Void
	{
		FlxG.mouse.visible = true;
		FlxG.camera.bgColor = 0xFF120C14;

		doc = new EditorMap(cfg.brush.undoDepth);
		slot = lastSlot;
		doc.load(slot);

		uiCam = new FlxCamera();
		uiCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(uiCam, false);

		tilePal = new TilePalette(this, uiCam, cfg.palette.width, cfg.palette.height, cfg.palette.padding, cfg.palette.maxZoom);
		propPal = new PropPalette(this, uiCam, cfg.palette.width, cfg.palette.height, cfg.palette.padding, cfg.palette.propCell);
		hud = new EditorHud(this, uiCam, cfg.flashTime);

		wallTool = new WallTool(doc, Paths.file(ArenaDataRegistry.get().tiles));
		tileTool = new TileTool(doc, wallTool, tilePal, hud.flash);
		propTool = new PropTool(doc, propPal, hud.flash);

		bg = new FlxSprite(0, 0);
		add(bg);
		add(wallTool.map);
		add(tileTool.layer);
		add(propTool.group);
		add(tileTool.ghost);
		add(wallTool.hover);
		add(wallTool.rectPreview);
		add(propTool.ghost);

		spawnMark = new FlxSprite();
		spawnMark.makeGraphic(22, 22, 0xFF7CFC00);
		spawnMark.angle = 45;
		add(spawnMark);

		spawnLabel = new FlxText(0, 0, 120, "SPAWN");
		spawnLabel.setFormat(null, 20, 0xFF7CFC00, CENTER);
		spawnLabel.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(spawnLabel);

		refreshAll();
		showPalettes();
		view = new EditorView(cfg.view, doc);
		hud.setHelp(helpLine());
		refreshStatus();
		super.create();
	}

	function refreshAll():Void
	{
		wallTool.rebuild();
		applyTheme();
		tileTool.rebuild();
		propTool.rebuild();
		tilePal.build(doc.tileset());
		tileTool.refreshGhost();
		placeSpawnMark();
	}

	function applyTheme():Void
	{
		var t = ThemeDataRegistry.get(doc.theme);
		bg.loadGraphic(Paths.image(t.background));
		bg.setGraphicSize(doc.cols * doc.cell, doc.rows * doc.cell);
		bg.updateHitbox();
		bg.alpha = 0.4;
		wallTool.setThemeColor(ThemeDataRegistry.colorOf(t));
	}

	function placeSpawnMark():Void
	{
		spawnMark.x = doc.spawnX - spawnMark.width / 2;
		spawnMark.y = doc.spawnY - spawnMark.height / 2;
		spawnLabel.x = doc.spawnX - 60;
		spawnLabel.y = doc.spawnY - 42;
	}

	function showPalettes():Void
	{
		tilePal.show(mode == MODE_TILES);
		propPal.show(mode == MODE_PROPS);
	}

	function overPanel():Bool
		return tilePal.contains() || propPal.contains();

	function hideCursors():Void
	{
		wallTool.hideCursor();
		tileTool.hideCursor();
		propTool.hideCursor();
	}

	function helpLine():String
	{
		return switch (mode)
		{
			case MODE_TILES:
				"TILES - LEFT PAINT   RIGHT ERASE   [ ] STEP   F SHEET   V SOLID   PALETTE: DRAG A PATCH, WHEEL ZOOM, RIGHT-DRAG PAN";
			case MODE_PROPS:
				"PROPS - LEFT PLACE   RIGHT DELETE   F FLIP      PALETTE - CLICK A PROP, WHEEL SCROLLS, [ ] STEPS";
			default:
				"WALLS - LEFT PAINT   RIGHT ERASE   SHIFT BOX   B BRUSH   C CLEAR   L COPY STAGE";
		};
	}

	function refreshStatus():Void
	{
		var left = "SLOT " + slot + (doc.dirty ? "  *UNSAVED*" : "  (SAVED)") + "   THEME: "
			+ ThemeDataRegistry.get(doc.theme).name;
		var right = switch (mode)
		{
			case MODE_TILES: tileTool.statusText();
			case MODE_PROPS: propTool.statusText();
			default: "WALLS   BRUSH " + wallTool.brush;
		};
		hud.setStatus(left, right);
	}

	function cycleMode():Void
	{
		mode = (mode + 1) % 3;
		hideCursors();
		showPalettes();
		if (mode == MODE_TILES)
		{
			tilePal.build(doc.tileset());
			tileTool.refreshGhost();
		}
		else if (mode == MODE_PROPS)
		{
			propPal.build();
			propTool.refreshGhost();
		}
		hud.setHelp(helpLine());
		hud.flash(MODE_NAMES[mode]);
	}

	function cycleTheme():Void
	{
		doc.theme = (doc.theme + 1) % ThemeDataRegistry.count();
		applyTheme();
		doc.dirty = true;
		hud.flash("THEME: " + ThemeDataRegistry.get(doc.theme).name);
	}

	function saveSlot():Void
	{
		doc.save(slot);
		hud.flash("SAVED TO SLOT " + slot);
	}

	function switchSlot(n:Int):Void
	{
		if (n == slot)
			return;
		if (doc.dirty)
			saveSlot();
		slot = n;
		lastSlot = n;
		doc.load(n);
		refreshAll();
		hud.flash("SLOT " + n);
	}

	function clearMap():Void
	{
		doc.pushUndo();
		doc.clearInterior();
		wallTool.rebuild();
		hud.flash("CLEARED (Z UNDOES)");
	}

	function copyStock():Void
	{
		doc.pushUndo();
		doc.copyStockStage();
		placeSpawnMark();
		wallTool.rebuild();
		hud.flash("COPIED THE STOCK STAGE");
	}

	function undo():Void
	{
		if (isProps)
			propTool.undoLast();
		else if (doc.undo())
			wallTool.rebuild();
	}

	function dropSpawn():Void
	{
		var m = EditorView.mouseWorld();
		if (m.x > doc.cell * 2 && m.y > doc.cell * 2 && m.x < (doc.cols - 2) * doc.cell && m.y < (doc.rows - 2) * doc.cell)
		{
			doc.spawnX = m.x;
			doc.spawnY = m.y;
			placeSpawnMark();
			doc.dirty = true;
			hud.flash("SPAWN MOVED");
		}
	}

	function playTest():Void
	{
		if (leaving)
			return;
		leaving = true;
		saveSlot();
		CustomArena.set(doc.wallCsv(), doc.spawnX, doc.spawnY, doc.theme, doc.props);
		var t = doc.tileset();
		CustomArena.setTiles(t == null ? null : t.name, doc.tileCsv());
		FlxG.mouse.visible = false;
		FlxG.switchState(new PlayState());
	}

	function back():Void
	{
		if (leaving)
			return;
		leaving = true;
		if (doc.dirty)
			saveSlot();
		FlxG.switchState(new MainMenuState());
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (leaving)
			return;

		hud.update(elapsed);
		view.update(elapsed, overPanel());

		if (FlxG.keys.pressed.SPACE)
			hideCursors();
		else
		{
			var cell = view.cellAt();
			switch (mode)
			{
				case MODE_TILES: tileTool.update();
				case MODE_PROPS: propTool.update();
				default: wallTool.update(cell.c, cell.r);
			}
		}

		updateKeys();
		refreshStatus();
	}

	function updateKeys():Void
	{
		if (FlxG.keys.justPressed.P)
			cycleMode();
		if (FlxG.keys.justPressed.B && mode == MODE_WALLS)
			hud.flash(wallTool.cycleBrush(cfg.brush.maxSize));
		if (FlxG.keys.justPressed.Z)
			undo();
		if (FlxG.keys.justPressed.C && !isProps)
			clearMap();
		if (FlxG.keys.justPressed.T)
			cycleTheme();
		if (FlxG.keys.justPressed.L && !isProps)
			copyStock();
		if (FlxG.keys.justPressed.S)
			saveSlot();
		if (FlxG.keys.justPressed.X)
			dropSpawn();

		if (FlxG.keys.justPressed.ONE)
			switchSlot(1);
		if (FlxG.keys.justPressed.TWO)
			switchSlot(2);
		if (FlxG.keys.justPressed.THREE)
			switchSlot(3);
		if (FlxG.keys.justPressed.FOUR)
			switchSlot(4);
		if (FlxG.keys.justPressed.FIVE)
			switchSlot(5);

		if (FlxG.keys.justPressed.ENTER)
			playTest();
		if (FlxG.keys.justPressed.ESCAPE)
			back();
	}
}
