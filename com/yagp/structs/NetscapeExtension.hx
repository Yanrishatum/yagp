package com.yagp.structs ;

/**
 * The Netscape2.0 extension. Used for looping gif animation;
 * @author Yanrishatum
 */
class NetscapeExtension
{
  /**
   * Number of loops before stop.
   * If set to 0 then loop infinitely
   */
  public var iterations:Int;

  public function new(input:GifBytes) 
  {
    input.position += 2; // Skip 0x03 and reserved byte;
    iterations = input.readShort();
    input.position++; // Skip terminator;
  }
  
}