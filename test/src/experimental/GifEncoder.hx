package experimental;
import com.yagp.structs.GifVersion;
import com.yagp.structs.LSD;
import haxe.io.Bytes;
import haxe.io.BytesData;
import openfl.utils.ByteArray;
import openfl.utils.Endian;

/**
 * ...
 * @author Yanrishatum
 */
class GifEncoder
{
  
  public var output:ByteArray;
  
  public function new() 
  {
    output = new ByteArray();
    output.endian = Endian.LITTLE_ENDIAN;
  }
  
  public function header(version:GifVersion):Void
  {
    output.writeUTFBytes("GIF");
    switch(version)
    {
      case GifVersion.GIF87a: output.writeUTFBytes("87a");
      case GifVersion.GIF89a: output.writeUTFBytes("89a");
      case GifVersion.Unknown(v): output.writeUTFBytes(v);
    }
  }
  
  public function lsd(lsd:LSD):Void
  {
    output.writeShort(lsd.width);
    output.writeShort(lsd.height);
    
    var packed:Int = 0;
    if (lsd.globalColorTable)
    {
      packed |= 1 << 7;
      // Too lazy
      packed |= (switch(lsd.globalColorTableSize)
      {
        case 2: 0;
        case 4: 1;
        case 8: 2;
        case 16: 3;
        case 32: 4;
        case 64: 5;
        case 128: 6;
        case 256: 7;
        default: 2;
      });
    }
    if (lsd.sorted) packed |= 1 << 3;
    packed |= (lsd.colorResolution - 1) << 6;
    
    output.writeByte(lsd.backgroundColorIndex);
    if (lsd.pixelAspectRatio == 0) output.writeByte(0);
    else output.writeByte(Std.int(lsd.pixelAspectRatio * 64 - 15));
  }
  
  public function colorPalette(cols:Array<Int>):Void
  {
    for (col in cols)
    {
      output.writeByte((col & 0xFF0000) >> 16);
      output.writeByte((col & 0x00FF00) >> 8);
      output.writeByte(col & 0xFF);
    }
  }
  
  public function commentary(text:String):Void
  {
    output.writeByte(0x21);
    output.writeByte(0xFE);
    var i:Int = 0;
    while (i < text.length)
    {
      var size:Int = (text.length - i);
      if (size > 255) size = 255;
      output.writeByte(size);
      output.writeUTFBytes(text.substr(i, size));
      i += size;
    }
    output.writeByte(0);
  }
  
  public function eof():Void
  {
    output.writeByte(0);
  }
  
}