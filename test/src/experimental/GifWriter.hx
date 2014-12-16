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
@:dox(hide)
class GifWriter
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
  
  public function lsd(width:Int, height:Int, hasGlobalColorTable:Bool, colorResolution:Int, sorted:Bool, globalColorTableSize:Int, backgroundColorIndex:Int, pixelAspectRatio:Float):Void
  {
    output.writeShort(width);
    output.writeShort(height);
    
    var packed:Int = 0;
    if (hasGlobalColorTable)
    {
      packed |= 1 << 7;
      // Too lazy
      packed |= (switch(globalColorTableSize)
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
    if (sorted) packed |= 1 << 3;
    packed |= (colorResolution - 1) << 6;
    
    output.writeByte(backgroundColorIndex);
    if (pixelAspectRatio == 0) output.writeByte(0);
    else output.writeByte(Std.int(pixelAspectRatio * 64 - 15));
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
    output.writeByte(0x21); // Extension
    output.writeByte(0xFE); // Commentary
    var i:Int = 0; // Plain data
    while (i < text.length)
    {
      var size:Int = (text.length - i);
      if (size > 255) size = 255;
      output.writeByte(size);
      output.writeUTFBytes(text.substr(i, size));
      i += size;
    }
    output.writeByte(0); // Terminator
  }
  
  public function text(text:String, gridX:Int, gridY:Int, gridWidth:Int, gridHeight:Int, charWidth:Int, charHeight:Int, foregroundColorIndex:Int, backgroundColorIndex:Int):Void
  {
    output.writeByte(0x21); // Extension
    output.writeByte(0x01); // Plain Text
    output.writeByte(12); // Block size
    output.writeShort(gridX);
    output.writeShort(gridY);
    output.writeShort(gridWidth);
    output.writeShort(gridHeight);
    output.writeByte(charWidth);
    output.writeByte(charHeight);
    output.writeByte(foregroundColorIndex);
    output.writeByte(backgroundColorIndex);
    
    var i:Int = 0; // Plain text
    while (i < text.length)
    {
      var size:Int = (text.length - i);
      if (size > 255) size = 255;
      output.writeByte(size);
      output.writeUTFBytes(text.substr(i, size));
      i += size;
    }
    output.writeByte(0); // Terminator
  }
  
  public function netscape(loops:Int):Void
  {
    output.writeByte(0x21); // Extension
    output.writeByte(0xFF); // App extension
    output.writeByte(11); // Size
    output.writeUTFBytes("NETSCAPE2.0");
    output.writeByte(0x03); // Size
    output.writeByte(0x01); // Sub-block ID?
    output.writeShort(loops);
    output.writeByte(0);
  }
  
  public function eof():Void
  {
    output.writeByte(0x3B);
  }
  
  public function trailer():Void
  {
    output.writeByte(0x3B);
  }
  
}