package com.yagp.structs ;

/**
 * Disposal method of the frame
 * @author Yanrishatum
 */
enum DisposalMethod
{
  /**
   * The disposal method is unspecified. Action on demand of viewer.
   * Mostly interpreted as NO_ACTION.
   */
  UNSPECIFIED;
  /**
   * No action required. 
   */
  NO_ACTION;
  /**
   * Fill frame rectangle with background color.
   */
  FILL_BACKGROUND;
  /**
   * Render previous state of gif.
   */
  RENDER_PREVIOUS;
  /**
   * Reserved disposal methods.
   */
  UNDEFINED(index:Int);
  
}