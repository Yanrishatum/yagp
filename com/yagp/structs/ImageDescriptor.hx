package com.yagp.structs ;

/**
 * Image descriptor block in GIF file
 * @author Yanrishatum
 */
class ImageDescriptor
{
  /**
   * X position of image on the Logical Screen
   */
  public var x:Int;
  
  /**
   * Y position of image on the Logical Screen
   */
  public var y:Int;
  
  /**
   * Width of image in pixels
   */
  public var width:Int;
  
  /**
   * Height of image in pixels
   */
  public var height:Int;
  
  /**
   * Is this image uses local color table?
   */
  public var localColorTable:Bool;
  
  /**
   * Is this image written in interlace mode?
   */
  public var interlaced:Bool;
  
  /**
   * Is local color table sorted in order of decreasing priority?
   */
  public var sorted:Bool;
  
  /**
   * Size of local color table
   */
  public var localColorTableSize:Int;
  
  /**
   * Constructor
   * @param bytes Input gif file stream
   */
  public function new(input:GifBytes) 
  {
    x      = input.readShort();
    y      = input.readShort();
    width  = input.readShort();
    height = input.readShort();
    
    var packed:Int = input.readByte();
    localColorTable = (packed & 128) == 128;
    interlaced = (packed & 64) == 64;
    sorted = (packed & 32) == 32;
    localColorTableSize = 2 << (packed & 7);
  }
  
}