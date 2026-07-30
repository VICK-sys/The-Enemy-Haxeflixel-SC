package util;

#if (windows && cpp)
@:cppFileCode('
#include <windows.h>

static void theEnemyClaimDpi()
{
	HMODULE user32 = LoadLibraryA("user32.dll");
	if (user32 != NULL)
	{
		typedef BOOL (WINAPI *SetCtxFn)(void *);
		SetCtxFn setCtx = (SetCtxFn)GetProcAddress(user32, "SetProcessDpiAwarenessContext");
		if (setCtx != NULL && setCtx((void *) -4))
		{
			FreeLibrary(user32);
			return;
		}
		FreeLibrary(user32);
	}
	SetProcessDPIAware();
}
')
#end
class DpiAware
{
	public static var claimed(default, null):Bool = claim();

	static function claim():Bool
	{
		#if (windows && cpp)
		untyped __cpp__("theEnemyClaimDpi()");
		#end
		return true;
	}
}
