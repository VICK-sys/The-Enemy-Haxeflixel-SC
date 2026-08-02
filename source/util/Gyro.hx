package util;

#if (cpp && windows)
@:cppFileCode('
#include <windows.h>
#include <setupapi.h>
#include <hidsdi.h>
#include <hidpi.h>

#pragma comment(lib, "setupapi.lib")
#pragma comment(lib, "hid.lib")

static HANDLE gyH = INVALID_HANDLE_VALUE;
static OVERLAPPED gyOv;
static HANDLE gyEvt = 0;
static HANDLE gyEvt2 = 0;
static bool gyPending = false;
static unsigned char gyBuf[256];
static int gyType = 0;
static int gyInLen = 64;
static int gyOutLen = 64;
static int gyFeatLen = 64;
static int gyWait = 120;
static unsigned char gyPkt = 0;
static double gyRates[3] = {0, 0, 0};

static bool gyMatch(int vid, int pid)
{
	if (vid == 0x054C && (pid == 0x05C4 || pid == 0x09CC)) { gyType = 1; return true; }
	if (vid == 0x054C && (pid == 0x0CE6 || pid == 0x0DF2)) { gyType = 2; return true; }
	if (vid == 0x057E && pid == 0x2009) { gyType = 3; return true; }
	return false;
}

static void gyWrite(unsigned char* data, int len)
{
	if (gyH == INVALID_HANDLE_VALUE) return;
	unsigned char out[256];
	memset(out, 0, sizeof(out));
	int n = gyOutLen > 0 && gyOutLen <= 256 ? gyOutLen : 64;
	if (len > n) len = n;
	memcpy(out, data, len);
	OVERLAPPED ov;
	memset(&ov, 0, sizeof(ov));
	ov.hEvent = gyEvt2;
	ResetEvent(gyEvt2);
	DWORD wrote = 0;
	if (!WriteFile(gyH, out, n, &wrote, &ov))
		if (GetLastError() == ERROR_IO_PENDING)
			WaitForSingleObject(gyEvt2, 60);
}

static void gySub(unsigned char cmd, unsigned char arg)
{
	unsigned char b[12] = {0x01, (unsigned char)(gyPkt++ & 0x0F), 0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40, cmd, arg};
	gyWrite(b, 12);
}

static void gyKick()
{
	unsigned char f[256];
	memset(f, 0, sizeof(f));
	int fl = gyFeatLen > 0 && gyFeatLen <= 256 ? gyFeatLen : 64;
	if (gyType == 1) { f[0] = 0x02; HidD_GetFeature(gyH, f, fl); }
	if (gyType == 2) { f[0] = 0x05; HidD_GetFeature(gyH, f, fl); }
	if (gyType == 3)
	{
		unsigned char u1[2] = {0x80, 0x02};
		gyWrite(u1, 2);
		unsigned char u2[2] = {0x80, 0x04};
		gyWrite(u2, 2);
		gySub(0x40, 0x01);
		gySub(0x03, 0x30);
	}
}

static void gyClose()
{
	if (gyH != INVALID_HANDLE_VALUE) { CancelIo(gyH); CloseHandle(gyH); }
	gyH = INVALID_HANDLE_VALUE;
	gyPending = false;
	gyType = 0;
}

static void gyScan()
{
	GUID g;
	HidD_GetHidGuid(&g);
	HDEVINFO di = SetupDiGetClassDevsA(&g, 0, 0, DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
	if (di == INVALID_HANDLE_VALUE) return;
	SP_DEVICE_INTERFACE_DATA ifd;
	ifd.cbSize = sizeof(ifd);
	for (DWORD i = 0; SetupDiEnumDeviceInterfaces(di, 0, &g, i, &ifd); i++)
	{
		DWORD need = 0;
		SetupDiGetDeviceInterfaceDetailA(di, &ifd, 0, 0, &need, 0);
		if (!need || need > 2048) continue;
		unsigned char raw[2048];
		SP_DEVICE_INTERFACE_DETAIL_DATA_A* det = (SP_DEVICE_INTERFACE_DETAIL_DATA_A*)raw;
		det->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_A);
		if (!SetupDiGetDeviceInterfaceDetailA(di, &ifd, det, need, 0, 0)) continue;
		HANDLE h = CreateFileA(det->DevicePath, GENERIC_READ | GENERIC_WRITE,
			FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);
		if (h == INVALID_HANDLE_VALUE)
			h = CreateFileA(det->DevicePath, GENERIC_READ,
				FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);
		if (h == INVALID_HANDLE_VALUE) continue;
		HIDD_ATTRIBUTES at;
		at.Size = sizeof(at);
		if (HidD_GetAttributes(h, &at) && gyMatch(at.VendorID, at.ProductID))
		{
			gyH = h;
			PHIDP_PREPARSED_DATA pp;
			if (HidD_GetPreparsedData(h, &pp))
			{
				HIDP_CAPS caps;
				if (HidP_GetCaps(pp, &caps) == HIDP_STATUS_SUCCESS)
				{
					gyInLen = caps.InputReportByteLength;
					gyOutLen = caps.OutputReportByteLength;
					gyFeatLen = caps.FeatureReportByteLength;
				}
				HidD_FreePreparsedData(pp);
			}
			if (!gyEvt) gyEvt = CreateEventA(0, TRUE, FALSE, 0);
			if (!gyEvt2) gyEvt2 = CreateEventA(0, TRUE, FALSE, 0);
			gyKick();
			break;
		}
		CloseHandle(h);
	}
	SetupDiDestroyDeviceInfoList(di);
}

static bool gyParse(unsigned char* b, int n, double* out)
{
	int base = -1;
	double scale = 0.0;
	if (gyType == 1)
	{
		if (b[0] == 0x01 && n >= 19) base = 13;
		else if (b[0] == 0x11 && n >= 21) base = 15;
		scale = 1.0 / 16.4;
	}
	else if (gyType == 2)
	{
		if (b[0] == 0x01 && n >= 22) base = 16;
		else if (b[0] == 0x31 && n >= 23) base = 17;
		scale = 1.0 / 16.4;
	}
	else if (gyType == 3)
	{
		if (b[0] == 0x30 && n >= 25) base = 19;
		scale = 2000.0 / 32767.0;
	}
	if (base < 0) return false;
	for (int i = 0; i < 3; i++)
	{
		short v = (short)(b[base + i * 2] | (b[base + i * 2 + 1] << 8));
		out[i] = (double)v * scale * 0.017453292519943295;
	}
	return true;
}

static bool gyPoll()
{
	if (gyH == INVALID_HANDLE_VALUE)
	{
		if (++gyWait < 120) return false;
		gyWait = 0;
		gyScan();
		if (gyH == INVALID_HANDLE_VALUE) return false;
	}
	double sum[3] = {0, 0, 0};
	int got = 0;
	for (int spin = 0; spin < 16; spin++)
	{
		if (!gyPending)
		{
			memset(&gyOv, 0, sizeof(gyOv));
			gyOv.hEvent = gyEvt;
			ResetEvent(gyEvt);
			DWORD n = 0;
			int len = gyInLen > 0 && gyInLen <= 256 ? gyInLen : 64;
			if (ReadFile(gyH, gyBuf, len, &n, &gyOv))
			{
				double r[3];
				if (gyParse(gyBuf, (int)n, r)) { sum[0] += r[0]; sum[1] += r[1]; sum[2] += r[2]; got++; }
				continue;
			}
			if (GetLastError() != ERROR_IO_PENDING) { gyClose(); break; }
			gyPending = true;
		}
		DWORD n = 0;
		if (GetOverlappedResult(gyH, &gyOv, &n, FALSE))
		{
			gyPending = false;
			double r[3];
			if (gyParse(gyBuf, (int)n, r)) { sum[0] += r[0]; sum[1] += r[1]; sum[2] += r[2]; got++; }
			continue;
		}
		if (GetLastError() == ERROR_IO_INCOMPLETE) break;
		gyClose();
		break;
	}
	if (!got) return false;
	gyRates[0] = sum[0] / got;
	gyRates[1] = sum[1] / got;
	gyRates[2] = sum[2] / got;
	return true;
}
')
#end
class Gyro
{
	public static function available():Bool
	{
		#if (cpp && windows)
		return untyped __cpp__("gyH != INVALID_HANDLE_VALUE");
		#else
		return false;
		#end
	}

	public static function poll():Bool
	{
		#if (cpp && windows)
		return untyped __cpp__("gyPoll()");
		#else
		return false;
		#end
	}

	public static function pitchRate():Float
	{
		#if (cpp && windows)
		return untyped __cpp__("gyRates[0]");
		#else
		return 0;
		#end
	}

	public static function yawRate():Float
	{
		#if (cpp && windows)
		return untyped __cpp__("gyRates[1]");
		#else
		return 0;
		#end
	}

	public static function rollRate():Float
	{
		#if (cpp && windows)
		return untyped __cpp__("gyRates[2]");
		#else
		return 0;
		#end
	}
}
