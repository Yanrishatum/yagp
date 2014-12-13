package com.yagp.structs ;
import openfl.display.BitmapData;
import openfl.Vector;

/**
 * Single frame of gif file.
 * @author Yanrishatum
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
  
  /** Delay, before start next frame. */
  public var delay:Int;
  /** Is this frame must wait input from user, before render next frame? */
  public var userInput:Bool;
  
  public var transparentIndex:Int;
  
  /**
   * Loads data from GifDecoder and renders frame
   * @param globalColorTable Global table of colors
   * @param colorTable Local table of colors
   * @param imageDescriptor Image Descriptor of frame
   * @param graphicsDecoder Graphics Decoder of frame
   * @param graphicsControl Additional Graphics Control extension
   * @param previousGifFrame Link to previous frame
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
    
    var pixels:Vector<Int> = graphicsDecoder.pixels;
    
    // Graphic Control info
    if (graphicsControl != null)
    {
      #if yagp_accurate_delay
      delay = graphicsControl.delay * 10;
      #else
      delay = graphicsControl.delay * 10; // *10 Because in gif delay counts as 1/100 per second
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
        for (i in 0...pixels.length)
        {
          pixels[i] = colorTable[pixels[i]];
        }
      }
    }
    else
    {
      transparentIndex = -1;
      #if yagp_accurate_delay
      delay = 0;
      #else
      delay = 100;
      #end
      userInput = false;
      disposalMethod = DisposalMethod.UNSPECIFIED;
      for (i in 0...pixels.length)
      {
        pixels[i] = colorTable[pixels[i]];
      }
    }
    
    // Convert interlaced data into normal-linear
    if (imageDescriptor.interlaced)
    {
      var offset:Int = interlacedFor(pixels, 8, 0, 0     ); // Every 8 line with start at 0
          offset     = interlacedFor(pixels, 8, 4, offset); // Every 8 line with start at 4
          offset     = interlacedFor(pixels, 4, 2, offset); // Every 4 line with start at 2
                       interlacedFor(pixels, 2, 1, offset); // Every 2 line with start at 1
    }
    else // Linear copy
    {
      data.setVector(data.rect, pixels);
    }
    
    // Remove pixels vector
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
  
  public function dispose():Void
  {
    this.data.dispose();
    this.data = null;
    this.disposalMethod = null;
  }
}