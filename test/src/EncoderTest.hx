package;
import com.yagp.structs.GifVersion;
import com.yagp.structs.LSD;
import experimental.GifWriter;
import openfl.display.Sprite;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
 * ...
 * @author Yanrishatum
 */
class EncoderTest extends Sprite
{

  public function new() 
  {
    super();
    emptyWithCommentary();
  }
  
  private function emptyWithCommentary():Void
  {
    var enc:GifWriter = new GifWriter();
    enc.header(GifVersion.Unknown("14a"));
    var lsd:LSD = Type.createEmptyInstance(LSD);
    lsd.width = 2;
    lsd.height = 2;
    lsd.pixelAspectRatio = 0;
    lsd.sorted = false;
    lsd.globalColorTableSize = 4;
    lsd.globalColorTable = true;
    lsd.colorResolution = 0;
    lsd.backgroundColorIndex = 0;
    enc.lsd(lsd);
    enc.colorPalette([0xFF0000, 0x00FF00, 0x0000FF, 0xFF00FF]);
    enc.commentary("hello world!");
    enc.eof();
    #if sys
    
    File.saveBytes("empty_commentary.gif", enc.output);
    
    #end
  }
  
}