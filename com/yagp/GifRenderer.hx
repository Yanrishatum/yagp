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
package com.yagp ;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxe.io.Bytes;
import com.yagp.GifRenderer.GifMap;
import com.yagp.structs.DisposalMethod;
import com.yagp.structs.GifFrame;

typedef GifMap =
{
  /**
   * Spritesheet BitmapData
   */
  var data:BitmapData;
  /**
   * Single frame width
   */
  var width:Int;
  /**
   * Single frame height
   */
  var height:Int;
  /**
   * Delays for frames in milliseconds.
   */
  var frames:Array<Int>;
}

/**
 * Fast and dirty implementation of rendering entire Gif file to spritesheet.
 * 
 * Current status: Has some bugs, not optimized.
 */
class GifRenderer
{
  private var _restorer:BitmapData;
  private var _gif:Gif;
  private var _target:BitmapData;
  private var _drawTarget:BitmapData;
  private var _prevFrame:Int = -1;
  
  /**
   * Creates spritesheet from given Gif file.
   * @param gif Gif file.
   * @param vertical Place frames vertically?  
   * Default: false
   * @return GifMap structure.
   */
  public static function createMap(gif:Gif, vertical:Bool = false):GifMap
  {
    var renderer:GifRenderer = new GifRenderer(gif);
    var data:BitmapData = new BitmapData(gif.width * (vertical ? 1 : gif.frames.length), gif.height * (vertical ? gif.frames.length : 1), true, 0);
    renderer.setTarget(data);
    var xOffset:Int = vertical ? 0 : gif.width;
    var yOffset:Int = vertical ? gif.height : 0;
    for (i in 0...gif.frames.length) renderer.render(i, xOffset * i, yOffset * i);
    
    var result:GifMap = { data:data, width:gif.width, height:gif.height, frames:new Array<Int>() };
    for (frame in gif.frames) result.frames.push(frame.delay);
    renderer.dispose();
    return result;
  }
  
  public function new(gif:Gif) 
  {
    _gif = gif;
    _drawTarget = new BitmapData(_gif.width, _gif.height, true, 0);
  }
  
  /**
   * Sets rendering target.
   * @param target
   */
  public function setTarget(target:BitmapData):Void
  {
    _target = target;
  }
  
  /**
   * Disposes GifRenderer
   */
  public function dispose():Void
  {
    if (_restorer != null)
    {
      _restorer.dispose();
      _restorer = null;
    }
    if (_drawTarget != null)
    {
      _drawTarget.dispose();
      _drawTarget = null;
    }
    _gif = null;
    _target = null;
  }
  
  /**
   * Renders frame with given index at given position.
   * @param frame Frame index.
   * @param offsetX X render position on target BitmapData.
   * @param offsetY Y render position on target BitmapData.
   */
  public function render(frame:Int, offsetX:Int, offsetY:Int):Void
  {
    if (_gif == null || frame >= _gif.frames.length || frame < 0 || _target == null) return;
    if (_prevFrame != frame)
    {
      this.renderFrame(frame, true);
    }
    _target.copyPixels(_drawTarget, _drawTarget.rect, new Point(offsetX, offsetY));
  }
  
  private function renderFrame(frame:Int, doRestore:Bool):Void
  {
    if (doRestore && frame > 0)
    {
      if (_prevFrame + 1 != frame)
      {
        _prevFrame = -1;
        while (_prevFrame != frame - 1) renderFrame(_prevFrame, true);
      }
      var pframe:GifFrame = _gif.frames[_prevFrame];
      switch(pframe.disposalMethod)
      {
        case DisposalMethod.RENDER_PREVIOUS:
          if (_restorer != null)
          {
            _drawTarget.copyPixels(_restorer, pframe.data.rect, new Point(pframe.x, pframe.y));
            _restorer.dispose();
            _restorer = null;
          }
        case DisposalMethod.FILL_BACKGROUND:
          #if yagp_accurate_fill_background
          if (_gif.backgroundIndex == pframe.transparentIndex) this._drawTarget.fillRect(new Rectangle(pframe.x, pframe.y, pframe.width, pframe.height), 0);
          else this._drawTarget.fillRect(new Rectangle(pframe.x, pframe.y, pframe.width, pframe.height), _gif.backgroundColor);
          #else
          this._drawTarget.fillRect(new Rectangle(pframe.x, pframe.y, pframe.width, pframe.height), 0);
          #end
        default:
      }
    }
    if (frame == 0) _drawTarget.fillRect(_drawTarget.rect, 0);
    
    var gframe:GifFrame = _gif.frames[frame];
    
    if (gframe.disposalMethod == DisposalMethod.RENDER_PREVIOUS)
    {
      if (_restorer != null) _restorer.dispose();
      _restorer = new BitmapData(gframe.width, gframe.height, true, 0);
      _restorer.copyPixels(_drawTarget, new Rectangle(gframe.x, gframe.y, gframe.width, gframe.height), new Point());
    }
    
    _prevFrame = frame;
    this._drawTarget.copyPixels(gframe.data, gframe.data.rect, new Point(gframe.x, gframe.y), null, null, true);
  }
  
}