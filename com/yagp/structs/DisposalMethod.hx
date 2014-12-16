package com.yagp.structs ;

/**
 * Disposal method of the frame
 */
enum DisposalMethod
{
  /**
   * The disposal method is unspecified. Action on demand of viewer.
   * 
   * Mostly interpreted as NO_ACTION.
   */
  UNSPECIFIED;
  /**
   * No action required. 
   */
  NO_ACTION;
  /**
   * Fill frame rectangle with background color.
   * 
   * Note: Most renderers clears to transparency instead of filling background color, when frame's transparentIndex not equals to backgroundColorIndex. To disable this behaviour, add a `yagp_accurate_fill_background` define.
   */
  FILL_BACKGROUND;
  /**
   * Render previous state of gif as it before rendering disposing frame.
   */
  RENDER_PREVIOUS;
  /**
   * Reserved disposal methods.
   */
  UNDEFINED(index:Int);
  
}