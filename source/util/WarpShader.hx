package util;

import flixel.system.FlxAssets.FlxShader;

class WarpShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float uTime;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			uv.x += sin(uv.y * 16.0 + uTime * 2.2) * 0.022;
			uv.y += sin(uv.x * 16.0 + uTime * 1.7) * 0.022;
			uv.x += sin(uv.y * 5.0 - uTime * 1.1) * 0.012;
			gl_FragColor = texture2D(bitmap, uv);
		}
	')
	public function new()
	{
		super();
		uTime.value = [0.0];
	}

	public function advance(elapsed:Float):Void
	{
		uTime.value[0] += elapsed;
	}
}
