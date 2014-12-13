package com.yagp.structs ;

/**
 * Optional Graphics Control block, used for setting up disposal method, transparency, delay and user input.
 * @author Yanrishatum
 */
class GraphicsControl
{
  /**
   * Display method of next image.
   * 0 - No disposal specified. The decoder is not required to take any action. (same as 1 by default)
   * 1 - Do not dispose. The graphic is to be left in place.
   * 2 - Restore to background color. The area used by the graphic must be restored to the background color.
   * 3 - Restore to previous. The decoder is required to restore the area overwritten by the graphic with what was there prior to rendering the graphic.
   * 4-7 - To be defined.
   */
  public var disposalMethod:DisposalMethod;
  /**
   * Is image must wait for user input, before dispose?
   * This flag may be used by user-defined program.
   */
  public var userInput:Bool;
  /**
   * Is image have transparency?
   */
  public var transparentColor:Bool;
  /**
   * Delay, before next image appears. Delay is in centiseconds, e.g. 1 centisecond = 1/100 seconds.
   */
  public var delay:Int;
  /**
   * Index in color table that used as transparent.
   */
  public var transparentIndex:UInt;
  
  /**
   * Constructor
   * @param bytes Input gif file stream
   */
  public function new(input:GifBytes) 
  {
    input.position++; // Skip size
    
    var packed:Int = input.readByte();
    var method:Int = (packed & 28) >> 2;
    userInput = (packed & 2) == 2;
    transparentColor = (packed & 1) == 1;
    
    switch(method)
    {
      case 0: disposalMethod = DisposalMethod.UNSPECIFIED;
      case 1: disposalMethod = DisposalMethod.NO_ACTION;
      case 2: disposalMethod = DisposalMethod.FILL_BACKGROUND;
      case 3: disposalMethod = DisposalMethod.RENDER_PREVIOUS;
      default: disposalMethod = DisposalMethod.UNDEFINED(method);
    }
    
    delay = input.readShort();
    transparentIndex = input.readByte();
    // + terminator;
    input.position++;
  }
  
}