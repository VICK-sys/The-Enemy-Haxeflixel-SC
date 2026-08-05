package util;

import haxe.io.Bytes;
import haxe.io.BytesOutput;

class PngWriter
{
	static inline var SIG_0:Int = 0x89;
	static inline var DEFLATE_LEVEL:Int = 6;

	public static function encode(src:lime.utils.UInt8Array, width:Int, height:Int,
			rOff:Int = 0, gOff:Int = 1, bOff:Int = 2):Bytes
	{
		var out = new BytesOutput();
		out.writeByte(SIG_0);
		out.writeString("PNG");
		out.writeByte(0x0D);
		out.writeByte(0x0A);
		out.writeByte(0x1A);
		out.writeByte(0x0A);

		var ihdr = Bytes.alloc(13);
		be32(ihdr, 0, width);
		be32(ihdr, 4, height);
		ihdr.set(8, 8);
		ihdr.set(9, 6);
		ihdr.set(10, 0);
		ihdr.set(11, 0);
		ihdr.set(12, 0);
		chunk(out, "IHDR", ihdr);

		var stride = width * 4;
		var raw = Bytes.alloc((stride + 1) * height);
		var line = Bytes.alloc(stride);
		var prev = Bytes.alloc(stride);
		var at = 0;
		var from = 0;
		for (y in 0...height)
		{
			var w4 = 0;
			for (x in 0...width)
			{
				line.set(w4, src[from + rOff]);
				line.set(w4 + 1, src[from + gOff]);
				line.set(w4 + 2, src[from + bOff]);
				line.set(w4 + 3, 255);
				w4 += 4;
				from += 4;
			}
			raw.set(at, 2);
			at++;
			for (i in 0...stride)
			{
				raw.set(at + i, (line.get(i) - prev.get(i)) & 0xFF);
				prev.set(i, line.get(i));
			}
			at += stride;
		}
		chunk(out, "IDAT", haxe.zip.Compress.run(raw, DEFLATE_LEVEL));

		chunk(out, "IEND", Bytes.alloc(0));
		return out.getBytes();
	}

	static function chunk(out:BytesOutput, type:String, data:Bytes):Void
	{
		var head = Bytes.alloc(4);
		be32(head, 0, data.length);
		out.writeBytes(head, 0, 4);

		var body = Bytes.alloc(4 + data.length);
		for (i in 0...4)
			body.set(i, type.charCodeAt(i));
		body.blit(4, data, 0, data.length);
		out.writeBytes(body, 0, body.length);

		var crc = Bytes.alloc(4);
		be32(crc, 0, haxe.crypto.Crc32.make(body));
		out.writeBytes(crc, 0, 4);
	}

	static inline function be32(b:Bytes, at:Int, v:Int):Void
	{
		b.set(at, (v >> 24) & 0xFF);
		b.set(at + 1, (v >> 16) & 0xFF);
		b.set(at + 2, (v >> 8) & 0xFF);
		b.set(at + 3, v & 0xFF);
	}
}
