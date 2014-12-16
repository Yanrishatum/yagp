package com.yagp.structs ;

/**
 * Version of Gif file.  
 * The only 2 official versions is GIF87a and GIF89a. Any other version is supposed as GIF89a.
 */
enum GifVersion
{
  /**
   * First version of Gif file format from year 1987.
   * 
   * Note: The checking of unsupported blocks disabled by default to save some time. To enable supported blocks check set `yagp_strict_version_check` debug variable.
   */
  GIF87a;
  /**
   * Second and actual version of Gif file format from year 1989.
   */
  GIF89a;
  /**
   * Unknown version of Gif file.  
   * The decoder interpretatets this as GIF98a version.
   */
  Unknown(version:String);
  
}