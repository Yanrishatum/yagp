package experimental;
import hxColorToolkit.spaces.Color;
import hxColorToolkit.spaces.Lab;
import openfl.display.BitmapData;

typedef GifFrameInfo =
{
  var delay:Int;
  var x:Int;
  var y:Int;
  var data:BitmapData;
}

/**
 * ...
 * @author Yanrishatum
 */
@:dox(hide)
class GifEncoder
{
  
  public var useLocalColorTables:Bool = true;
  private var frames:Array<GifFrameInfo>;
  private var width:Int;
  private var heigth:Int;
  
  public var colorSpace:Color = new Lab();
  
  public function new(width:Int, height:Int) 
  {
    this.width = width;
    this.heigth = heigth;
  }
  
  public function addFrame(data:BitmapData, x:Int, y:Int, delay:Int):Void
  {
    frames.push( { data:data, x:x, y:y, delay:delay } );
  }
  
  public function encode():Void
  {
    // Median cut
    // Color quantization
    // Clustering
  }
  
}