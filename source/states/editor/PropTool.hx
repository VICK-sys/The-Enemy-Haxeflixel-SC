package states.editor;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import data.PropData.PropDataRegistry;
import systems.world.Decor;

class PropTool
{
	public var group(default, null):FlxTypedGroup<FlxSprite>;
	public var boxes(default, null):FlxTypedGroup<FlxSprite>;
	public var ghost(default, null):FlxSprite;
	public var outline(default, null):FlxSprite;
	public var held(default, null):Bool = true;
	public var picked(default, null):Int = -1;

	private var doc:EditorMap;
	private var pal:PropPalette;
	private var flash:String->Void;
	private var sprites:Array<FlxSprite> = [];

	public var flip(default, null):Bool = false;

	private var dragging:Bool = false;
	private var dragMoved:Bool = false;
	private var dragDX:Float = 0;
	private var dragDY:Float = 0;

	public function new(doc:EditorMap, pal:PropPalette, flash:String->Void)
	{
		this.doc = doc;
		this.pal = pal;
		this.flash = flash;

		group = new FlxTypedGroup<FlxSprite>();
		boxes = new FlxTypedGroup<FlxSprite>();

		ghost = new FlxSprite();
		ghost.alpha = 0.55;
		ghost.visible = false;

		outline = new FlxSprite();
		outline.makeGraphic(1, 1, 0xFF4FC3F7);
		outline.origin.set(0, 0);
		outline.alpha = 0.35;
		outline.visible = false;
	}

	public function rebuild():Void
	{
		group.clear();
		for (b in boxes.members)
			if (b != null)
				b.destroy();
		boxes.clear();
		for (b in Decor.solids(doc.props, 0xFF7CFC00).members)
			boxes.add(b);
		sprites = [];
		for (pl in doc.props)
		{
			var s = Decor.make(pl.n);
			if (s == null)
			{
				sprites.push(null);
				continue;
			}
			s.flipX = pl.f == true;
			Decor.place(s, pl.x, pl.y);
			group.add(s);
			sprites.push(s);
		}
		sortGroup();

		for (s in sprites)
		{
			if (s == null)
				continue;
			var sv = Decor.sortValue(s);
			if (Math.abs(sv) > 100000)
				continue;
			var line = new FlxSprite(s.x, sv - 1);
			line.makeGraphic(1, 1, 0xFF4FC3F7);
			line.origin.set(0, 0);
			line.scale.set(s.width, 3);
			line.alpha = 0.8;
			boxes.add(line);
		}
		if (picked >= doc.props.length)
			picked = -1;
		placeOutline();
	}

	function sortGroup():Void
	{
		group.sort(function(o, a, b) return flixel.util.FlxSort.byValues(o, Decor.sortValue(a), Decor.sortValue(b)),
			flixel.util.FlxSort.ASCENDING);
	}

	public function hideCursor():Void
		ghost.visible = false;

	public function showOverlays(on:Bool):Void
	{
		boxes.visible = on;
		if (!on)
			outline.visible = false;
	}

	public function heldName():String
	{
		var p = PropDataRegistry.get(pal.index);
		return p == null ? "NONE" : p.name;
	}

	public function selectedName():String
	{
		if (!held && picked >= 0 && picked < doc.props.length)
			return doc.props[picked].n;
		return heldName();
	}

	public function setHeld(on:Bool):Void
	{
		held = on;
		ghost.visible = false;
		dragging = false;
		pal.setHighlight(on);
		if (on)
		{
			picked = -1;
			outline.visible = false;
			refreshGhost();
			flash("HOLDING " + heldName());
		}
		else
			flash("HANDS EMPTY - CLICK A PLACED PROP");
	}

	public function refreshGhost():Void
	{
		var p = PropDataRegistry.get(pal.index);
		if (p == null)
		{
			ghost.visible = false;
			return;
		}
		var s = Decor.make(p.name);
		if (s == null)
		{
			ghost.visible = false;
			return;
		}
		ghost.loadGraphicFromSprite(s);
		ghost.scale.set(s.scale.x, s.scale.y);
		ghost.updateHitbox();
		ghost.alpha = 0.55;
		s.destroy();
	}

	public function toggleFlip():Void
	{
		flip = !flip;
		flash(flip ? "FLIPPED" : "UNFLIPPED");
	}

	public function update(blocked:Bool):Void
	{
		if (PropDataRegistry.count() == 0)
			return;

		if (FlxG.keys.justPressed.Q)
			setHeld(!held);

		if (blocked && !pal.contains())
		{
			ghost.visible = false;
			return;
		}

		if (pal.contains())
		{
			ghost.visible = false;
			if (FlxG.mouse.wheel != 0)
				pal.scroll(FlxG.mouse.wheel * pal.scrollStep());
			else if (FlxG.mouse.justPressed)
			{
				var before = pal.index;
				if (pal.pick())
				{
					if (held && pal.index == before)
						setHeld(false);
					else
						setHeld(true);
				}
			}
			return;
		}

		var m = EditorView.mouseWorld();
		if (held)
			updatePlace(m);
		else
			updateSelect(m);
	}

	function updatePlace(m:FlxPoint):Void
	{
		if (!ghost.exists || ghost.graphic == null)
			refreshGhost();
		ghost.visible = true;
		ghost.flipX = flip;
		Decor.place(ghost, m.x, m.y);

		if (FlxG.keys.justPressed.LBRACKET || FlxG.keys.justPressed.RBRACKET)
		{
			var n = PropDataRegistry.count();
			pal.select((pal.index + (FlxG.keys.justPressed.LBRACKET ? -1 : 1) + n) % n);
			refreshGhost();
			flash(PropDataRegistry.get(pal.index).name);
		}
		if (FlxG.keys.justPressed.F)
			toggleFlip();

		if (FlxG.mouse.justPressed)
			place(m.x, m.y);
		if (FlxG.mouse.justPressedRight)
			deleteAt(m.x, m.y);
	}

	function updateSelect(m:FlxPoint):Void
	{
		ghost.visible = false;

		if (FlxG.mouse.justPressed)
		{
			picked = indexAt(m.x, m.y);
			dragging = picked >= 0;
			dragMoved = false;
			if (picked >= 0)
			{
				dragDX = doc.props[picked].x - m.x;
				dragDY = doc.props[picked].y - m.y;
			}
		}

		if (dragging && picked >= 0)
		{
			if (FlxG.mouse.pressed)
			{
				var nx = m.x + dragDX;
				var ny = m.y + dragDY;
				if (nx != doc.props[picked].x || ny != doc.props[picked].y)
				{
					if (!dragMoved)
					{
						doc.pushUndo();
						dragMoved = true;
					}
					doc.props[picked].x = nx;
					doc.props[picked].y = ny;
					if (sprites[picked] != null)
					{
						Decor.place(sprites[picked], nx, ny);
						sortGroup();
					}
					doc.dirty = true;
				}
			}
			else
			{
				dragging = false;
				if (dragMoved)
					rebuild();
				dragMoved = false;
			}
		}

		if (FlxG.mouse.justPressedRight)
			deleteAt(m.x, m.y);

		if (picked >= 0 && (FlxG.keys.justPressed.DELETE || FlxG.keys.justPressed.BACKSPACE))
		{
			doc.pushUndo();
			doc.props.splice(picked, 1);
			picked = -1;
			rebuild();
			doc.dirty = true;
			flash("PROP REMOVED");
		}
		else if (picked >= 0 && FlxG.keys.justPressed.F)
		{
			doc.pushUndo();
			doc.props[picked].f = !(doc.props[picked].f == true);
			rebuild();
			doc.dirty = true;
			flash("FLIPPED");
		}

		placeOutline();
	}

	function placeOutline():Void
	{
		if (held || picked < 0 || picked >= sprites.length || sprites[picked] == null)
		{
			outline.visible = false;
			return;
		}
		var s = sprites[picked];
		outline.x = s.x;
		outline.y = s.y;
		outline.scale.set(s.width, s.height);
		outline.visible = true;
	}

	function indexAt(x:Float, y:Float):Int
	{
		var i = sprites.length;
		while (i-- > 0)
		{
			var s = sprites[i];
			if (s == null)
				continue;
			if (x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height)
				return i;
		}
		return -1;
	}

	function place(x:Float, y:Float):Void
	{
		var p = PropDataRegistry.get(pal.index);
		if (p == null)
			return;
		doc.pushUndo();
		doc.props.push({n: p.name, x: x, y: y, f: flip});
		rebuild();
		doc.dirty = true;
	}

	function deleteAt(x:Float, y:Float):Void
	{
		var i = indexAt(x, y);
		if (i < 0)
			return;
		doc.pushUndo();
		doc.props.splice(i, 1);
		if (picked == i)
			picked = -1;
		else if (picked > i)
			picked--;
		rebuild();
		doc.dirty = true;
		flash("PROP REMOVED");
	}
}
