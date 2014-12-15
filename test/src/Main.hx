package ;

import com.yagp.GifDecoder;
import com.yagp.GifPlayer;
import com.yagp.GifPlayerWrapper;
import com.yagp.structs.GifVersion;
import experimental.GifWriter;
import gif.AnimatedGif;
import haxe.io.Bytes;
import haxe.Timer;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.Lib;
import openfl.utils.ByteArray;
import StructureChecker.GifBlock;

typedef TestImage = 
{
  var path:String;
  var conditions:String;
  @:optional var structure:Array<GifBlock>;
  @:optional var yagp:String;
  @:optional var haxeGif:String;
  @:optional var speedYagp:Float;
  @:optional var speedHaxeGif:Float;
  @:optional var framesCount:Int;
  @:optional var version:String;
}

/**
 * ...
 * @author Yanrishatum
 */

class Main extends Sprite 
{
  
  private var testImages:Array<TestImage> =
  [
    { path: "img/transparent.gif", conditions: "Image transparent." },
    { path: "img/zero-frame-duration.gif", conditions: "All frames has zero-length delay. (browsers forces 0.01s and 0s to 0.1s delay. Use yagp_accurate_delay to disable this.)" },
    { path: "img/restore-previous.gif", conditions: "Image uses restore-previous disposal method. Uses local color tables. Unusual encoder." },
    { path: "img/nontransparent.gif", conditions: "Image not transparent. Contains commentary block. Frames have individual size, not the size of entire GIF. Encoder: Pro Motion" },
    { path: "img/nontransparent-iirc.gif", conditions: "Image not transparent. Uses delta-compression IIRC." },
    { path: "img/nontransparent-palettes.gif", conditions: "Image not transparent. Image has big size and large amount of frames. Uses local color tables." },
    { path: "img/framechanges.gif", conditions: "Image has big size. Individual size of the frames. Unusual encoder." },
    { path: "img/Fighter_attack.gif", conditions: "Image transparent. Encoder: Easy gif animator" },
    { path: "img/framechanges-2.gif", conditions: "Image has VERY big size and extreme amount of frames. Individual size of the frames. Unusual encoder." },
  ];
  private var caret:Int;
  private var checker:StructureChecker;
  
	public function new() 
	{
		super();
    
    #if flash
    trace("Target: flash");
    #elseif js
    trace("Target: js");
    #elseif neko
    trace("Target: neko");
    #elseif windows
    trace("Target: windows");
    #else
    trace("Target: Other");
    #end
    
    checker = new StructureChecker();
    caret = -1;
    compareNext();
    Lib.current.stage.addEventListener(MouseEvent.CLICK, click);
	}
  
  private function click(e:MouseEvent):Void
  {
    compareNext();
  }
  
  private function compareNext():Void
  {
    caret++;
    if (caret == testImages.length) return;
    while (numChildren > 0) removeChildAt(0);
    var i:TestImage = testImages[caret];
    var bytes:ByteArray = Assets.getBytes(i.path);
    i.structure = checker.checkBA(bytes);
    i.framesCount = checker.frames;
    switch(checker.version)
    {
      case GifVersion.GIF87a: i.version = "87a";
      case GifVersion.GIF89a: i.version = "89a";
      case GifVersion.Unknown(v): i.version = v;
    }
    var t:Float = Timer.stamp();
    var yagp:GifPlayerWrapper = null;
    try
    {
      yagp = new GifPlayerWrapper(new GifPlayer(GifDecoder.parseByteArray(bytes)));
      i.yagp = "PASS";
    }
    catch (e:Dynamic)
    {
      i.yagp = "FAIL: " + Std.string(e);
    }
    i.speedYagp = Timer.stamp() - t;
    if (yagp != null) addChild(yagp);
    #if (flash)
    var hbytes:Bytes = Bytes.ofData(bytes);
    #elseif js
    
    #if (haxe_ver >= 3.2)
    var hbytes:Bytes = Bytes.ofData(bytes.byteView); // In newest 3.2 haxe Uint8Array is BytesData
    #else
    var hbytes:Bytes = Bytes.alloc(bytes.length);
    bytes.position = 0;
    for (i in 0...bytes.length) hbytes.set(i, bytes.readByte());
    #end
    
    #else
    var hbytes:Bytes = bytes;
    #end
    t = Timer.stamp();
    var hg:AnimatedGif = null;
    try
    {
      hg = new AnimatedGif(hbytes);
      hg.play();
      i.haxeGif = "PASS";
    }
    catch (e:Dynamic)
    {
      i.haxeGif = "FAIL: " + Std.string(e);
    }
    i.speedHaxeGif = Timer.stamp() - t;
    if (hg != null)
    {
      if (yagp != null) hg.x = yagp.width;
      addChild(hg);
    }
    format(i);
  }
  
  private var traceStruct:Bool = false;
  private function format(i:TestImage):Void
  {
    var s:StringBuf = new StringBuf();
    s.addChar("\n".code);
    s.add("Path: "); s.add(i.path);
    s.add("\nNotes: ");
    s.add(i.conditions);
    s.add("\nVersion: ");
    s.add(i.version);
    s.add("\nFrame amount: ");
    s.add(i.framesCount);
    s.add("\nParsing test:\n  YAGP: ");
    s.add(i.yagp);
    s.add("\n  haxe-gif: ");
    s.add(i.haxeGif);
    s.add("\nSpeed test:\n  YAGP: ");
    s.add(i.speedYagp);
    s.add("\n  haxe-gif: ");
    s.add(i.speedHaxeGif);
    s.add("\n  Faster library: ");
    if (i.yagp == "PASS")
    {
      if (i.haxeGif == "PASS")
        s.add(i.speedYagp > i.speedHaxeGif ? "haxe-gif" : "YAGP");
      else s.add("YAGP (haxe-gif parsing error)");
    }
    else if (i.haxeGif == "PASS") s.add("haxe-gif (YAGP parsing error)");
    else s.add("none");
    if (traceStruct)
    {
      s.add("\nStructure:");
      for (block in i.structure)
      {
        s.add("\n  [");
        s.add(block.name);
        var fields:Array<String> = Reflect.fields(block);
        for (field in fields)
        {
          if (field == "name") continue;
          s.add(", ");
          s.add(field);
          s.add(": ");
          s.add(Reflect.field(block, field));
        }
        s.add("]");
      }
    }
    #if (sys)
    Sys.println(s.toString());
    #else
    trace(s.toString());
    #end
  }
  
}
