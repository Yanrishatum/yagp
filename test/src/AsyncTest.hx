package;
import com.yagp.Gif;
import com.yagp.GifDecoder;
import com.yagp.GifPlayer;
import com.yagp.GifPlayerWrapper;
import openfl.Assets;
import openfl.display.Sprite;
import openfl.utils.ByteArray;

/**
 * ...
 * @author Yanrishatum
 */
class AsyncTest extends Sprite
{

  public function new() 
  {
    super();
    var img:ByteArray = Assets.getBytes("img/nontransparent-palettes.gif");
    GifDecoder.parseByteArrayAsync(img, onComplete, null);
  }
  
  private function onComplete(gif:Gif):Void
  {
    addChild(new GifPlayerWrapper(new GifPlayer(gif)));
  }
  
}