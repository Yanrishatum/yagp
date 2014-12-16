package com.yagp.structs ;
import haxe.io.Bytes;

/**
 * Logical Screen Descriptor
 * Represents basic information about GIF image.
 */
class LSD
{
  /**
   * Width of GIF image in pixels
   */
  public var width:Int;
  
  /**
   * Height of GIF image in pixels
   */
  public var height:Int;
  
  /**
   * Is this file uses global color table?
   */
  public var globalColorTable:Bool;
  
  /**
   * Actually not used.
   * 
   * Specification:
   * Number of bits per primary color available
     to the original image, minus 1. This value represents the size of
     the entire palette from which the colors in the graphic were
     selected, not the number of colors actually used in the graphic.
     For example, if the value in this field is 3, then the palette of
     the original image had 4 bits per primary color available to create
     the image.  This value should be set to indicate the richness of
     the original palette, even if not every color from the whole
     palette is available on the source machine.
   */
  public var colorResolution:Int;
  
  /**
   * Actually not used.
   * 
   * Specification:
   * Indicates whether the Global Color Table is sorted.
     If the flag is set, the Global Color Table is sorted, in order of
     decreasing importance. Typically, the order would be decreasing
     frequency, with most frequent color first. This assists a decoder,
     with fewer available colors, in choosing the best subset of colors;
     the decoder may use an initial segment of the table to render the
     graphic.
   */
  public var sorted:Bool;
  
  /**
   * Size of global color table.
   */
  public var globalColorTableSize:Int;
  
  /**
   * Background color index in global color table
   */
  public var backgroundColorIndex:Int;
  
  /**
   * Factor used to compute an approximation of the aspect ratio of the pixel in the original image.
   */
  public var pixelAspectRatio:Float;
  

  public function new(input:GifBytes) 
  {
    width  = input.readShort();
    height = input.readShort();
    
    var packedField:Int = input.readByte();
    globalColorTable = (packedField & 128) == 128;
    colorResolution = (packedField & 112) >>> 4;
    sorted = (packedField & 8) == 8;
    globalColorTableSize = 2 << (packedField & 7);
    
    backgroundColorIndex = input.readByte();
    
    pixelAspectRatio = input.readByte();
    if (pixelAspectRatio != 0) pixelAspectRatio = (pixelAspectRatio + 15) / 64
    else pixelAspectRatio = 1;
  }
  
}