package ;
import com.yagp.structs.DisposalMethod;
import com.yagp.structs.GifBytes;
import com.yagp.structs.GifVersion;
import com.yagp.structs.GraphicsControl;
import com.yagp.structs.ImageDescriptor;
import com.yagp.structs.LSD;
import haxe.io.Bytes;
import openfl.utils.ByteArray;
import haxe.macro.Type;
typedef GifBlock =
{
  var name:String;
}

typedef LSDBlock =
{
  >GifBlock,
  var width:Int;
  var height:Int;
  var bgIndex:Int;
  var bgColor:String;
}

typedef ColorTableBlock =
{
  >GifBlock,
  var size:Int;
}

typedef ExtensionBlock =
{
  >GifBlock,
  var type:String;
}

typedef AppExtensionBlock =
{
  >GifBlock,
  var appName:String;
  var version:String;
}

typedef ImageBlock =
{
  >GifBlock,
  var x:Int;
  var y:Int;
  var width:Int;
  var height:Int;
  var interlaced:Bool;
  var colorTable:Bool;
}

typedef GraphicsControlBlock =
{
  >GifBlock,
  var userInput:Bool;
  var disposalMethod:DisposalMethod;
  var transparent:Bool;
  var transparentIndex:Int;
  var delay:Int;
}

/**
 * ...
 * @author Yanrishatum
 */
class StructureChecker
{

  public function new() 
  {
    
  }
  
  private var _input:GifBytes;
  
  public var version:GifVersion;
  public var frames:Int;
  public var blocks:Array<GifBlock>;
  
  public function checkBA(input:ByteArray):Array<GifBlock>
  {
    #if (flash)
    _input = new GifBytes(Bytes.ofData(input));
    #elseif js
    
    #if (haxe_ver >= 3.2)
    _input = new GifBytes(Bytes.ofData(byteArray.byteView)); // In newest 3.2 haxe Uint8Array is BytesData
    #else
    var bytes:Bytes = Bytes.alloc(input.length);
    input.position = 0;
    for (i in 0...input.length) bytes.set(i, input.readByte());
    _input = new GifBytes(bytes);
    #end
    
    #else
    _input = new GifBytes(input);
    #end
    analyze();
    return blocks;
  }
  
  public function check(input:Bytes):Array<GifBlock>
  {
    _input = new GifBytes(input);
    analyze();
    return blocks;
  }
  
  private function analyze():Void
  {
    blocks = new Array();
    frames = 0;
    var head:String = _input.readUTFBytes(3);
    if (head != "GIF") throw "Invalid header!";
    var v:String = _input.readUTFBytes(3);
    if (v == "89a") version = GifVersion.GIF89a;
    else if (v == "87a") version = GifVersion.GIF87a;
    else version = GifVersion.Unknown(v);
    
    var lsd:LSD = new LSD(_input);
    var b:LSDBlock = { name:"LSD", width: lsd.width, height: lsd.height, bgIndex: lsd.backgroundColorIndex, bgColor:"" };
    blocks.push( b );
    if (lsd.globalColorTable)
    {
      var c = ct(lsd.globalColorTableSize);
      if (lsd.backgroundColorIndex < c.length) b.bgColor = StringTools.hex(c[lsd.backgroundColorIndex], 6);
      else b.bgColor = "------";
    }
    
    var id:Int;
    do
    {
      id = _input.readByte();
      switch (id)
      {
        // Image descriptor / Image
        case 0x2C: 
          img();
        // Extension block
        case 0x21: 
          ext();
        // EOF
        case 0x3B:
          blocks.push( { name:"EOF" } );
          return;
      }
    }
    while (true);
  }
  
  private function img():Void
  {
    var id:ImageDescriptor = new ImageDescriptor(_input);
    var block:ImageBlock = { name:"Frame", x:id.x, y:id.y, width:id.width, height:id.height, interlaced:id.interlaced, colorTable:id.localColorTable };
    blocks.push(block);
    if (id.localColorTable) ct(id.localColorTableSize);
    _input.position++;
    skip();
    frames++;
  }
  
  private function ext():Void
  {
    var subId:Int = _input.readByte();
    switch (subId)
    {
      // Graphics control extension
      case 0xF9:
        var gc:GraphicsControl = new GraphicsControl(_input);
        var b:GraphicsControlBlock = { name:"Graphics control", transparent:gc.transparentColor, disposalMethod:gc.disposalMethod, delay:gc.delay, transparentIndex:gc.transparentIndex, userInput:gc.userInput };
        //var b:ExtensionBlock = { name:"Extension", type:"0xF9: Graphics Control" };
        blocks.push( b ); // YAGP: Graphic Control info
        //skip();
        //_graphicControlExtension = new GraphicsControl(_input);
      
      case 0x01:
        var b:ExtensionBlock = { name:"Extension", type:"0x01: Text" };
        blocks.push( b ); // YAGP: Actual text
        skip();
      
      case 0xFE:
        var b:ExtensionBlock = { name:"Extension", type:"0xFE: Comment" };
        blocks.push( b ); // YAGP: Actual text
        skip();
      
      // Program extension block
      case 0xFF:
        app();
      
      default:
        var b:ExtensionBlock = { name:"Extension", type:"0x" + StringTools.hex(subId, 2) + ": Unknown" };
        blocks.push( b ); // YAGP: Actual text
        skip();
    }
  }
  
  private function app():Void
  {
    // Extension name
    _input.position++; // Skip block size (0x0B);
    var name:String = _input.readUTFBytes(8);
    var version:String = _input.readUTFBytes(3);
    var b:AppExtensionBlock = { name:"App Extension", appName:name, version:version };
    blocks.push( b );
    skip();
    /*
    switch (name)
    {
      // Netscape 2.0 - animation looping
      case "NETSCAPE": 
        gif.netscape = new NetscapeExtension(_input);
      
      // Make next extension reading:
      // PIANYGIF1.0
      // Netscape Buffering Application Extension
      // AnimExts Looping Application Extension (ANIMEXTS1.0) 
      default: 
        skipBlock();
    }*/
  }
  
  private function skip():Void
  {
    var blockSize:Int = 0;
    do
    {
      blockSize = _input.readByte();
      _input.position += blockSize;
    } while (blockSize != 0);
  }
  
  private function ct(size:Int):Array<Int>
  {
    var colors:Array<Int> = new Array();
    for (i in 0...size)
    {
      colors.push(
        _input.readByte() << 16 | // R
        _input.readByte() << 8  | // G
        _input.readByte());       // B
    }
    var b:ColorTableBlock = { name:"Color table", size: size };
    blocks.push( b );
    return colors;
  }
  
}