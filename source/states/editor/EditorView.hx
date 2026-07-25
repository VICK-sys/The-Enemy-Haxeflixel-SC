package states.editor;

import flixel.FlxG;
import flixel.math.FlxPoint;
import data.EditorData.EditorViewData;

class EditorView
{
	public var zoom(default, null):Float;

	private var cfg:EditorViewData;
	private var doc:EditorMap;

	public function new(cfg:EditorViewData, doc:EditorMap)
	{
		this.cfg = cfg;
		this.doc = doc;
		zoom = cfg.startZoom;
		FlxG.camera.zoom = zoom;
		center();
	}

	public static function mouseWorld():FlxPoint
		return FlxG.mouse.getWorldPosition(FlxG.camera);

	public function cellAt():{c:Int, r:Int}
	{
		var m = mouseWorld();
		return {
			c: Math.floor(m.x / doc.cell),
			r: Math.floor(m.y / doc.cell)
		};
	}

	public function grabbing():Bool
		return FlxG.mouse.pressedMiddle || (FlxG.keys.pressed.SPACE && FlxG.mouse.pressed);

	public function update(elapsed:Float, overPanel:Bool):Void
	{
		var pan = cfg.panSpeed * elapsed / zoom;
		if (FlxG.keys.pressed.LEFT)
			FlxG.camera.scroll.x -= pan;
		if (FlxG.keys.pressed.RIGHT)
			FlxG.camera.scroll.x += pan;
		if (FlxG.keys.pressed.UP)
			FlxG.camera.scroll.y -= pan;
		if (FlxG.keys.pressed.DOWN)
			FlxG.camera.scroll.y += pan;

		if (grabbing() && !overPanel)
		{
			FlxG.camera.scroll.x -= FlxG.mouse.deltaScreenX / zoom;
			FlxG.camera.scroll.y -= FlxG.mouse.deltaScreenY / zoom;
		}

		if (FlxG.keys.justPressed.ZERO)
			setZoom(cfg.startZoom, false);

		if (!overPanel && FlxG.mouse.wheel != 0)
			setZoom(zoom * (FlxG.mouse.wheel > 0 ? cfg.zoomStep : 1 / cfg.zoomStep), true);
	}

	public function setZoom(z:Float, atCursor:Bool):Void
	{
		var before = mouseWorld();
		zoom = z < cfg.minZoom ? cfg.minZoom : (z > cfg.maxZoom ? cfg.maxZoom : z);
		FlxG.camera.zoom = zoom;
		if (atCursor)
		{
			var after = mouseWorld();
			FlxG.camera.scroll.x += before.x - after.x;
			FlxG.camera.scroll.y += before.y - after.y;
		}
		else
			center();
	}

	function center():Void
		FlxG.camera.focusOn(FlxPoint.weak(doc.cols * doc.cell / 2, doc.rows * doc.cell / 2));
}
