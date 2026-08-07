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
import states.editor.EditorChrome;
import states.editor.EditorHud;
import states.editor.EditorMap;
import states.editor.EditorView;
import states.editor.LibraryPanel;
import states.editor.PropPalette;
import states.editor.PropTool;
import states.editor.TilePalette;
import states.editor.TileTool;
import states.editor.WallTool;
import util.CustomArena;
import util.Paths;

class EditorState extends FlxState
{
	static inline var MARK_ALPHA:Float = 0.75;

	static inline var MODE_TILES:Int = 0;
	static inline var MODE_PROPS:Int = 1;
	static var MODE_NAMES:Array<String> = ["TILE MODE", "PROP MODE"];

	public static var lastSlot:Int = 1;

	private var cfg = EditorDataRegistry.get();
	private var doc:EditorMap;
	private var view:EditorView;
	private var hud:EditorHud;
	private var chrome:EditorChrome;
	private var library:LibraryPanel;
	private var wallTool:WallTool;
	private var tileTool:TileTool;
	private var propTool:PropTool;
	private var tilePal:TilePalette;
	private var propPal:PropPalette;

	private var uiCam:FlxCamera;
	private var bg:FlxSprite;
	private var spawnMark:FlxSprite;
	private var spawnLabel:FlxText;
	private var shopMark:FlxSprite;
	private var shopLabel:FlxText;

	private var slot:Int;
	private var mode:Int = MODE_TILES;
	private var leaving:Bool = false;
	private var eyes:Array<Bool> = [true, true];
	private var lastHeld:Bool = true;

	private var isProps(get, never):Bool;

	function get_isProps():Bool
		return mode == MODE_PROPS;

	override public function create():Void
	{
		FlxG.mouse.visible = true;
		FlxG.camera.bgColor = 0xFF0A0A0A;

		doc = new EditorMap(cfg.brush.undoDepth);
		slot = lastSlot;
		doc.load(slot);

		uiCam = new FlxCamera();
		uiCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(uiCam, false);

		var palX = (cfg.ui.sidebar - cfg.palette.width) / 2;
		var palY = cfg.ui.topbar + 16;

		chrome = new EditorChrome(this, uiCam, cfg.ui.sidebar, cfg.ui.topbar, palX, palY, cfg.palette.width, cfg.palette.height,
			cfg.palette.padding);
		tilePal = new TilePalette(this, uiCam, palX, palY, cfg.palette.width, cfg.palette.height, cfg.palette.padding, cfg.palette.maxZoom);
		propPal = new PropPalette(this, uiCam, palX, palY, cfg.palette.width, cfg.palette.height, cfg.palette.padding, cfg.palette.propCell);
		hud = new EditorHud(this, uiCam, cfg.flashTime, cfg.ui.sidebar, cfg.ui.topbar);
		library = new LibraryPanel(this, uiCam, hud.flash, cfg.ui.sidebar, cfg.ui.topbar, EditorHud.BAR);
		hud.raiseFlash();

		wallTool = new WallTool(doc, Paths.file(ArenaDataRegistry.get().tiles));
		tileTool = new TileTool(doc, wallTool, tilePal, hud.flash);
		propTool = new PropTool(doc, propPal, hud.flash);

		bg = new FlxSprite(0, 0);
		insert(0, bg);
		insert(1, wallTool.map);
		insert(2, tileTool.layer);
		insert(3, propTool.group);
		insert(4, propTool.boxes);
		insert(5, propTool.outline);
		insert(6, tileTool.ghost);
		insert(7, propTool.ghost);
		insert(8, tileTool.marquee);

		spawnMark = makeSpawnSprite();
		insert(9, spawnMark);

		spawnLabel = new FlxText(0, 0, 120, "SPAWN");
		spawnLabel.setFormat(util.Lang.smallFont(), util.Lang.smallSize(), 0xFF7CFC00, CENTER);
		spawnLabel.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		insert(10, spawnLabel);

		shopMark = makeShopSprite();
		insert(11, shopMark);

		shopLabel = new FlxText(0, 0, 120, "SHOP");
		shopLabel.setFormat(util.Lang.smallFont(), util.Lang.smallSize(), 0xFFFFC24A, CENTER);
		shopLabel.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		insert(12, shopLabel);

		wireChrome();
		refreshAll();
		showPalettes();
		view = new EditorView(cfg.view, doc, cfg.ui.sidebar, cfg.ui.topbar, EditorHud.BAR);
		if (doc.loadDroppedFloor)
			hud.flash("CELL SIZE MOVED SINCE THIS MAP WAS SAVED - PAINTED FLOOR DROPPED");
		hud.setHint(hintLine());
		chrome.setMode(mode);
		super.create();
	}

	function wireChrome():Void
	{
		chrome.onSlot = function() switchSlot(slot % 5 + 1);
		chrome.onModeChip = modeChipAction;
		chrome.onSheet = function() if (mode == MODE_TILES) tileTool.cycleSheet();
		chrome.onMode = setMode;
		chrome.onEye = toggleEye;
		chrome.onUndo = undo;
		chrome.onClear = function() if (!isProps) clearMap();
		chrome.onSave = saveSlot;
		chrome.onPlay = playTest;
		chrome.onControls = hud.toggleSheet;
		chrome.onLibrary = library.toggle;
		library.onAdded = onLibraryChanged;
	}

	function onLibraryChanged(kind:String):Void
	{
		switch (kind)
		{
			case "tilesets":
				if (doc.syncTileGrid())
				{
					tileTool.rebuild();
					hud.flash("CELL SIZE CHANGED - PAINTED FLOOR CLEARED");
				}
				tilePal.build(doc.tileset());
				tileTool.refreshGhost();
			case "props", "hitbox":
				propPal.build();
				propTool.rebuild();
				propTool.refreshGhost();
			case "walls":
				applyTheme();
			default:
				tilePal.build(doc.tileset());
				propPal.build();
		}
	}

	function modeChipAction():Void
	{
		switch (mode)
		{
			case MODE_TILES: tileTool.toggleSolid();
			default: propTool.setHeld(!propTool.held);
		}
	}

	function toggleEye(i:Int):Void
	{
		eyes[i] = !eyes[i];
		chrome.setEye(i, eyes[i]);
		switch (i)
		{
			case 0:
				tileTool.layer.visible = eyes[i];
				wallTool.map.visible = eyes[i];
			default: propTool.group.visible = eyes[i];
		}
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
		var t = ThemeDataRegistry.get(0);
		bg.loadGraphic(Paths.image(t.background));
		bg.setGraphicSize(doc.cols * doc.cell, doc.rows * doc.cell);
		bg.updateHitbox();
		bg.alpha = 0.4;
		wallTool.setThemeColor(ThemeDataRegistry.colorOf(t));
	}

	function makeSpawnSprite():FlxSprite
	{
		var s = new FlxSprite();
		var hue = util.SaveData.playerHue();
		s.frames = util.HuePalette.sparrow(util.Skins.of(util.SaveData.playerSkin()), hue);
		s.animation.addByPrefix("idle", "Idle", 9, true);
		s.animation.play("idle");
		s.antialiasing = false;
		s.scale.set(4, 4);
		s.updateHitbox();
		s.alpha = MARK_ALPHA;
		return s;
	}

	function makeShopSprite():FlxSprite
	{
		var s = systems.world.Decor.make("repairShop");
		if (s == null)
		{
			s = new FlxSprite();
			s.makeGraphic(22, 22, 0xFFFFC24A);
			s.angle = 45;
		}
		s.alpha = MARK_ALPHA;
		return s;
	}

	function placeSpawnMark():Void
	{
		spawnMark.x = doc.spawnX - spawnMark.width / 2;
		spawnMark.y = doc.spawnY - spawnMark.height;
		spawnLabel.x = doc.spawnX - 60;
		spawnLabel.y = spawnMark.y - 34;

		shopMark.x = doc.shopX - shopMark.width / 2;
		shopMark.y = doc.shopY - shopMark.height;
		shopLabel.x = doc.shopX - 60;
		shopLabel.y = shopMark.y - 34;
	}

	function showPalettes():Void
	{
		tilePal.show(mode == MODE_TILES);
		propPal.show(mode == MODE_PROPS);
		propTool.showOverlays(mode == MODE_PROPS);
		chrome.setPaletteHint("");
	}

	function hintLine():String
	{
		return switch (mode)
		{
			case MODE_TILES:
				"LEFT PAINT   RIGHT ERASE   [ ] STEP   F SHEET   V SOLID   C CLEAR   L COPY STOCK STAGE   CTRL-DRAG SELECT";
			default:
				propTool.held ? "LEFT PLACE   RIGHT DELETE   F FLIP   [ ] STEP   Q PUT DOWN TO EDIT PLACED PROPS   H HITBOX" : "LEFT PICK A PLACED PROP   DRAG TO MOVE   F FLIP   DEL REMOVE   Q PICK BACK UP   H HITBOX";
		};
	}

	function setMode(m:Int):Void
	{
		if (m == mode)
			return;
		mode = m;
		hideCursors();
		tileTool.clearSelection();
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
		chrome.setMode(mode);
		hud.setHint(hintLine());
		hud.flash(MODE_NAMES[mode]);
	}

	function cycleMode():Void
		setMode((mode + 1) % MODE_NAMES.length);

	function hideCursors():Void
	{
		wallTool.hideCursor();
		tileTool.hideCursor();
		propTool.hideCursor();
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
		hud.flash(doc.loadDroppedFloor ? "SLOT " + n + " - CELL SIZE MOVED, PAINTED FLOOR DROPPED" : "SLOT " + n);
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
		if (!doc.undo())
			return;
		wallTool.rebuild();
		tileTool.rebuild();
		propTool.rebuild();
		hud.flash("UNDONE");
	}

	function dropSpawn():Void
	{
		var m = EditorView.mouseWorld();
		if (!insideMap(m.x, m.y))
			return;
		doc.spawnX = m.x;
		doc.spawnY = m.y;
		placeSpawnMark();
		doc.dirty = true;
		hud.flash("SPAWN MOVED");
	}

	function dropShop():Void
	{
		var m = EditorView.mouseWorld();
		if (!insideMap(m.x, m.y))
			return;
		doc.shopX = m.x;
		doc.shopY = m.y;
		placeSpawnMark();
		doc.dirty = true;
		hud.flash("SHOP MOVED");
	}

	function insideMap(x:Float, y:Float):Bool
		return x > doc.cell * 2 && y > doc.cell * 2 && x < (doc.cols - 2) * doc.cell && y < (doc.rows - 2) * doc.cell;

	function playTest():Void
	{
		if (leaving)
			return;
		leaving = true;
		saveSlot();
		CustomArena.set(doc.wallCsv(), doc.spawnX, doc.spawnY, doc.props);
		CustomArena.setShop(doc.shopX, doc.shopY);
		var t = doc.tileset();
		CustomArena.setTiles(t == null ? null : t.name, doc.tileCsv());
		CustomArena.fromEditor = true;
		CustomArena.slot = slot;
		FlxG.mouse.visible = false;
		FlxG.switchState(() -> new PlayState());
	}

	function back():Void
	{
		if (leaving)
			return;
		leaving = true;
		if (doc.dirty)
			saveSlot();
		FlxG.switchState(() -> new MainMenuState());
	}

	function syncChrome():Void
	{
		if (lastHeld != propTool.held)
		{
			lastHeld = propTool.held;
			if (isProps)
				hud.setHint(hintLine());
		}

		chrome.setSlot(slot, doc.dirty);
		chrome.setModeChip(switch (mode)
		{
			case MODE_TILES: "SOLID: " + (tileTool.solid ? "ON" : "OFF");
			case MODE_PROPS: propTool.held ? "HOLDING: " + propTool.heldName() : "HANDS EMPTY";
			default: propTool.held ? "HOLDING: " + propTool.heldName() : "HANDS EMPTY";
		});
		var t = doc.tileset();
		chrome.setSheet("SHEET: " + (t == null ? "NONE" : t.name), mode == MODE_TILES);
	}

	override public function update(elapsed:Float):Void
	{

		super.update(elapsed);

		if (leaving)
			return;

		hud.update(elapsed);
		library.update();
		if (!library.isOpen())
			chrome.update();

		var overUI = chrome.contains() || hud.modal() || library.isOpen();
		view.update(elapsed, overUI);

		if (FlxG.keys.pressed.SPACE)
			hideCursors();
		else
		{
			var cell = view.cellAt();
			switch (mode)
			{
				case MODE_TILES: tileTool.update(overUI);
				default: propTool.update(overUI);
			}
		}

		updateKeys(overUI);
		syncChrome();
	}

	function updateKeys(overUI:Bool):Void
	{
		if (library.isOpen())
		{
			if (FlxG.keys.justPressed.ESCAPE)
				library.escape();
			return;
		}

		var ctrl = FlxG.keys.pressed.CONTROL;
		var onCanvas = mode == MODE_TILES && !overUI;

		if (FlxG.keys.justPressed.P)
			cycleMode();
		if (FlxG.keys.justPressed.Z)
			undo();

		if (FlxG.keys.justPressed.C)
		{
			if (ctrl)
			{
				if (onCanvas && tileTool.copySelection())
					hud.flash("COPIED " + tileTool.clipLabel());
			}
			else if (!isProps)
				clearMap();
		}
		if (ctrl && FlxG.keys.justPressed.V && onCanvas && tileTool.paste())
			hud.flash("PASTED");

		if (FlxG.keys.justPressed.H && isProps)
			library.openHitbox(propTool.selectedName());

		if (FlxG.keys.justPressed.L && !isProps)
			copyStock();
		if (FlxG.keys.justPressed.S)
			saveSlot();
		if (FlxG.keys.justPressed.X)
			dropSpawn();
		if (FlxG.keys.justPressed.K)
			dropShop();

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
		{
			if (library.isOpen())
				library.close();
			else if (hud.modal())
				hud.toggleSheet();
			else
				back();
		}
	}
}
