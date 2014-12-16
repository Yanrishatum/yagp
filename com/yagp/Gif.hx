/*
 * This work is licensed under MIT license.
 * 
 * Copyright (C) 2014 Pavel "Yanrishatum" Alexandrov
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software, and to permit
 * persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
 * FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE. 
 */
package com.yagp;
import com.yagp.structs.GifFrame;
import com.yagp.structs.GifVersion;
import com.yagp.structs.LSD;
import com.yagp.structs.NetscapeExtension;

/**
 * The decoded Gif file.
 */
class Gif
{
  /** Version of Gif file. */
  public var version:GifVersion;
  
  /** Logical Screen Descriptor. */
  public var lsd:LSD;
  
  /** Width of the Gif image. (Alias to `lsd.width`) */
  public var width(get, never):Int;
  /** Height of the Gif image. (Alias to `lsd.height`) */
  public var height(get, never):Int;
  private inline function get_width():Int { return lsd.width; }
  private inline function get_height():Int { return lsd.height; }
  
  /** Color of the background. */
  public var backgroundColor:Int = 0;
  /** Background color index. (Alias to `lsd.backgroundColorIndex`) */
  public var backgroundIndex(get, never):Int;
  private inline function get_backgroundIndex():Int { return lsd.backgroundColorIndex; }
  
  /** Netscape extension for animation looping. */
  public var netscape:NetscapeExtension;
  
  /**
   * Amount of loops in animation.  
   * If Netscape looping extension is present, will be used value from extension, othervise value is 1.
   */
  public var loops(get, never):Int;
  private inline function get_loops():Int { return netscape != null ? netscape.iterations : 1; }
  
  /** Array of frames in Gif */
  public var frames:Array<GifFrame>;
  
  public function new() 
  {
    frames = new Array();
  }
  
  /**
   * Disposes Gif file.
   */
  public function dispose():Void
  {
    lsd = null;
    netscape = null;
    for (frame in frames) frame.dispose();
    frames = null;
  }
  
}