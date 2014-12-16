package com.yagp.structs ;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import openfl.Vector;

/**
 * Single frame of gif file.
 */
class GifFrame
{
  /** X coordinate of frame on logical screen */
  public var x:Int;
  /** Y coordinate of frame on logical screen */
  public var y:Int;
  /** Width of frame */
  public var width:Int;
  /** Height of frame */
  public var height:Int;
  /** Disposal method of frame */ 
  public var disposalMethod:DisposalMethod;
  /** Output BitmapData of frame */
  public var data:BitmapData;
  
  /** 
   * Delay, before start rendering next frame in milliseconds.
   * 
   * Note: Most browsers forces 0 and 1 (0/10 milliseconds) delay to 10 (100ms). To disable this behaviour add a `yagp_accurate_delay` define.
   */
  public var delay:Int;
  /** Is this frame must wait input from user, before render next frame? */
  public var userInput:Bool;
  /** Index of transparent color in this frame. If frame has no transparency, value is -1 */
  public var transparentIndex:Int;
  
  /**
   * Constructs gif frame from separate data inputs.
   * @param colorTable Color table, used for this frame.
   * @param imageDescriptor The Image Descriptor information.
   * @param graphicsDecoder Output from LZW compressed data.
   * @param graphicsControl Optional Graphic Control Extension block.
   */
  public function new(colorTable:Array<Int>, 
                      imageDescriptor:ImageDescriptor, graphicsDecoder:GraphicsDecoder, 
                      graphicsControl:GraphicsControl) 
  {
    this.x = imageDescriptor.x;
    this.y = imageDescriptor.y;
    this.width = imageDescriptor.width;
    this.height = imageDescriptor.height;
    
    this.data = new BitmapData(width, height, true, 0);
    
    var pixels = graphicsDecoder.pixels;
    
    // Graphic Control info
    if (graphicsControl != null)
    {
      delay = graphicsControl.delay * 10; // Converting to milliseconds.
      #if !yagp_accurate_delay
      if (delay <= 10) delay = 100; // Imitating browsers method, that sets minimum time to 0.02s, and replace 0.01s/0s to 0.1s
      #end
      
      userInput = graphicsControl.userInput;
      disposalMethod = graphicsControl.disposalMethod;
      if (graphicsControl.transparentColor)
      {
        transparentIndex = graphicsControl.transparentIndex;
        for (i in 0...pixels.length)
        {
          if (pixels[i] == graphicsControl.transparentIndex) pixels[i] = 0;
          else pixels[i] = colorTable[pixels[i]];
        }
      }
      else
      {
        transparentIndex = -1;
        for (i in 0...pixels.length) pixels[i] = colorTable[pixels[i]];
      }
    }
    else
    {
      transparentIndex = -1;
      #if yagp_accurate_delay
      delay = 10; // Display frame only 10 milliseconds.
      #else
      delay = 100;
      #end
      userInput = false;
      disposalMethod = DisposalMethod.UNSPECIFIED;
      
      for (i in 0...pixels.length) pixels[i] = colorTable[pixels[i]];
    }
    
    // Convert interlaced data into normal-linear
    if (imageDescriptor.interlaced)
    {
      this.data.lock();
      var offset:Int = interlacedFor(pixels, 8, 0, 0     ); // Every 8 line with start at 0
          offset     = interlacedFor(pixels, 8, 4, offset); // Every 8 line with start at 4
          offset     = interlacedFor(pixels, 4, 2, offset); // Every 4 line with start at 2
                       interlacedFor(pixels, 2, 1, offset); // Every 2 line with start at 1
      this.data.unlock();
    }
    else // Linear copy
    {
      #if (js && bitfive)
      // Since OpenFL-bitfive not supports `BitmapData.setVector()`, we're converting vector to ByteArray. Kinda slow, but adding more #ifs just for bitfive will make a mess in the code.
      var bytes:ByteArray = new ByteArray();
      bytes.length = pixels.length * 4;
      for (pixel in pixels) bytes.writeUnsignedInt(pixel);
      bytes.position = 0;
      data.setPixels(data.rect, bytes);
      #else
      data.setVector(data.rect, pixels);
      #end
    }
    
    // Remove pixels vector
    // Not sure it's required, since all references to graphicsDecored will be removed after frame construction.
    graphicsDecoder.pixels = null;
  }
  
  // Used for convert interlace-coded pixels data into linear format.
  private function interlacedFor(pixels:Vector<UInt>, step:Int, startY:Int, offset:Int):Int
  {
    var y:Int = startY;
    while (startY < this.height)
    {
      for (x in 0...this.width)
      {
        this.data.setPixel32(x, y, pixels[offset++]);
      }
      y += step;
    }
    return offset;
  }
  
  /**
   * Disposes GifFrame.
   */
  public function dispose():Void
  {
    this.data.dispose();
    this.data = null;
    this.disposalMethod = null;
  }
}