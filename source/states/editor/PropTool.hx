package states.editor;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import data.PropData.PropDataRegistry;
import systems.Decor;

class PropTool
{
	public var group(default, null):FlxTypedGroup<FlxSprite>;
	public var ghost(default, null):FlxSprite;

	private var doc:EditorMap;
	private var pal:PropPalette;
	private var flash:String->Void;
	private var sprites:Array<FlxSprite> = [];
	private var flip:Bool = false;

	public function new(doc:EditorMap, pal:PropPalette, flash:String->Void)
	{
		this.doc = doc;
		this.pal = pal;
		this.flash = flash;

		group = new FlxTypedGroup<FlxSprite>();

		ghost = new FlxSprite();
		ghost.alpha = 0.55;
		ghost.visible = false;
	}

	public function rebuild():Void
	{
		group.clear();
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
	}

	public function hideCursor():Void
		ghost.visible = false;

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

	public function undoLast():Void
	{
		if (doc.props.length == 0)
			return;
		doc.props.pop();
		rebuild();
		doc.dirty = true;
		flash("PROP UNDONE");
	}

	public function statusText():String
	{
		var p = PropDataRegistry.get(pal.index);
		return "PROPS: " + (p == null ? "NONE" : p.name) + "  (" + doc.props.length + " PLACED)";
	}

	public function update():Void
	{
		if (PropDataRegistry.count() == 0)
			return;

		if (pal.contains())
		{
			ghost.visible = false;
			if (FlxG.mouse.wheel != 0)
				pal.scroll(FlxG.mouse.wheel * pal.scrollStep());
			else if (FlxG.mouse.justPressed && pal.pick())
			{
				refreshGhost();
				flash(PropDataRegistry.get(pal.index).name);
			}
			return;
		}

		if (!ghost.exists || ghost.graphic == null)
			refreshGhost();
		var m = EditorView.mouseWorld();
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
		{
			flip = !flip;
			flash(flip ? "FLIPPED" : "UNFLIPPED");
		}

		if (FlxG.mouse.justPressed)
			place(m.x, m.y);
		if (FlxG.mouse.justPressedRight)
			deleteAt(m.x, m.y);
	}

	function place(x:Float, y:Float):Void
	{
		var p = PropDataRegistry.get(pal.index);
		if (p == null)
			return;
		doc.props.push({n: p.name, x: x, y: y, f: flip});
		rebuild();
		doc.dirty = true;
	}

	function deleteAt(x:Float, y:Float):Void
	{
		var i = sprites.length;
		while (i-- > 0)
		{
			var s = sprites[i];
			if (s == null)
				continue;
			if (x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height)
			{
				doc.props.splice(i, 1);
				rebuild();
				doc.dirty = true;
				flash("PROP REMOVED");
				return;
			}
		}
	}
}
