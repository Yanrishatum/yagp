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
import com.yagp.structs.DisposalMethod;
import com.yagp.structs.GifFrame;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Fast and dirty implementation of gif player. Can contain bugs, not optimized.
 */
class GifPlayer
{
  private static var rect:Rectangle;
  private static var point:Point;
  
  private static function __init__():Void
  {
    rect = new Rectangle();
    point = new Point();
  }

  /**
   * Player's output BitmapData representing current state of player.
   */
  public var data(default, null):BitmapData;
  private var _gif:Gif;
  
  private var _currFrame:Int;
  private var _currGifFrame:GifFrame;
  private var _prevData:BitmapData;
  private var _loops:Int;
  private var _maxLoops:Int;
  private var _frames:Array<GifFrame>;
  private var _t:Float;
  
  /**
   * If player must play animation?
   */
  public var playing:Bool;
  
  /**
   * Handler of animation end. Note, it will be called only if animation does not have infinite amount of loops.
   */
  public var animationEndHandler:Void->Void;
  /**
   * Handler of animation loop end. Will be called on end of each loop.
   */
  public var loopEndHandler:Void->Void;
  
  /**
   * The gif file to play in this GifPlayer.
   */
  public var gif(get, set):Null<Gif>;
  private inline function get_gif():Null<Gif> { return _gif; }
  private function set_gif(v:Null<Gif>):Null<Gif>
  {
    if (v != null)
    {
      if (_prevData != null)
      {
        _prevData.dispose();
        _prevData = null;
      }
      if (data == null || data.width != v.width || data.height != v.height)
      {
        if (data != null) data.dispose();
        data = new BitmapData(v.width, v.height, true, 0);
      }
      _gif = v;
      _frames = v.frames;
      _currFrame = 0;
      _t = 0;
      _loops = 0;
      _maxLoops = _gif.loops;
      data.fillRect(data.rect, 0);
      renderFrame(_currGifFrame = gif.frames[0]);
    }
    else _gif = null;
    return v;
  }
  
  /**
   * Current frame index.
   */
  public var frame(get, set):Int;
  private inline function get_frame():Int { return _currFrame; }
  private function set_frame(v:Int):Int
  {
    if (_gif == null) return v;
    v = cropIndex(v);
    _t = 0;
    if (_currFrame == v) return v;
    else if (cropIndex(_currFrame + 1) == v)
    {
      renderNext();
      return _currFrame;
    }
    else
    {
      data.fillRect(data.rect, 0);
      if (_prevData != null)
      {
        _prevData.dispose();
        _prevData = null;
      }
      _currFrame = 0;
      _currGifFrame = _frames[0];
      renderFrame(_currGifFrame);
      while (_currFrame != v) renderNext();
      return v;
    }
  }
  
  /**
   * Amount of frames in assigned Gif file.
   */
  public var framesCount(get, never):Int;
  private inline function get_framesCount():Int
  {
    return _gif != null ? _frames.length : 0;
  }
  
  private function cropIndex(v:Int):Int
  {
    if (v < 0)
    {
      while (v < 0) v = _frames.length - v;
      return v;
    }
    else
    {
      if (v >= _frames.length) return v % _frames.length;
      else return v;
    }
  }
  
  public function new(gif:Null<Gif>) 
  {
    this._gif = gif;
    if (gif != null)
    {
      this._frames = gif.frames;
      this.data = new BitmapData(gif.width, gif.height, true, 0);
      _currFrame = 0;
      _t = 0;
      _loops = 0;
      _maxLoops = _gif.loops;
      playing = true;
      renderFrame(_currGifFrame = gif.frames[0]);
    }
  }
  
  /**
   * Updates the animation loop.
   * @param elapsed Time elapsed since last update call in seconds.
   */
  public function update(elapsed:Float):Void
  {
    if (!playing || _gif == null) return;
    _t += elapsed * 1000; // To ms
    var startFrame:Int = _currFrame;
    var targetFrame:Int = _currFrame;
    var localLoops:Int = _loops;
    while (_frames[targetFrame].delay <= _t)
    {
      _t -= _frames[targetFrame].delay;
      targetFrame++;
      if (targetFrame == _frames.length)
      {
        if (loopEndHandler != null)
        {
          _currFrame = targetFrame - 1;
          loopEndHandler();
          if (_currFrame != targetFrame - 1) return; // Handler changed frame, so stop updating.
          _currFrame = startFrame;
        }
        if (_maxLoops != 0 && ++localLoops >= _maxLoops)
        {
          targetFrame--;
          while (_currFrame != targetFrame) renderNext();
          playing = false;
          _loops = _maxLoops;
          _t = _currGifFrame.delay;
          if (animationEndHandler != null) animationEndHandler();
          return;
        }
        targetFrame = 0;
      }
    }
    if (targetFrame == startFrame) return;
    
    #if yagp_faststone
    _t = 0; // Rest timer.
    #end
    
    if (targetFrame < _currFrame)
    {
      if (_prevData != null)
      {
        _prevData.dispose();
        _prevData = null;
      }
      // Clear
      fillBackground(_frames[0], data.rect);
      
      _currFrame = 0;
      renderFrame(_currGifFrame = _frames[0]);
    }
    while (_currFrame != targetFrame) renderNext();
  }
  
  /**
   * Disposes the player.
   * 
   * Note: You can't use this GifPlayer anymore, if you used dispose() method.
   * @param disposeGif Dispose Gif file too?
   */
  public function dispose(disposeGif:Bool = false):Void
  {
    if (disposeGif && this._gif != null) this._gif.dispose();
    this._gif = null;
    this._currGifFrame = null;
    this._frames = null;
    if (this._prevData != null)
    {
      this._prevData.dispose();
      this._prevData = null;
    }
    if (this.data != null)
    {
      this.data.dispose();
      this.data = null;
    }
  }
  
  /**
   * Resets player state. Use it foor reset loop counter.
   * @param play If set to true, will force `playing` value to true.
   */
  public function reset(play:Bool = false):Void
  {
    if (_gif == null) return;
    this._loops = 0;
    this._t = 0;
    if (play) this.playing = true;
    if (_prevData != null)
    {
      _prevData.dispose();
      _prevData = null;
    }
    // Clear
    fillBackground(_frames[0], data.rect);
    
    _currFrame = 0;
    renderFrame(_currGifFrame = _frames[0]);
  }
  
  private function disposeFrame(frame:GifFrame):Void
  {
    switch(frame.disposalMethod)
    {
      case DisposalMethod.FILL_BACKGROUND:
        rect.setTo(frame.x, frame.y, frame.width, frame.height);
        fillBackground(frame, rect);
      case DisposalMethod.RENDER_PREVIOUS:
        if (_prevData != null)
        {
          point.setTo(frame.x, frame.y);
          rect.setTo(0, 0, frame.width, frame.height);
          data.copyPixels(_prevData, rect, point);
          _prevData.dispose();
          _prevData = null;
        }
        else throw "Not implemented";
      default: // No action
    }
  }
  
  private function renderFrame(frame:GifFrame):Void
  {
    if (frame.disposalMethod.match(DisposalMethod.RENDER_PREVIOUS))
    {
      if (_prevData != null) _prevData.dispose();
      rect.setTo(frame.x, frame.y, frame.width, frame.height);
      point.setTo(0, 0);
      _prevData = new BitmapData(frame.width, frame.height, true, 0);
      _prevData.copyPixels(data, rect, point);
    }
    rect.setTo(0, 0, frame.width, frame.height);
    point.setTo(frame.x, frame.y);
    data.copyPixels(frame.data, rect, point, null, null, true);
  }
  
  private function renderNext():Void
  {
    _currFrame++;
    if (_currFrame == _frames.length)
    {
      if (_maxLoops != 0 && ++_loops >= _maxLoops)
      {
        playing = false;
        _currFrame--;
        _t = _currGifFrame.delay;
        if (animationEndHandler != null) animationEndHandler();
        return;
      }
      _currFrame = 0;
      
      if (_prevData != null)
      {
        _prevData.dispose();
        _prevData = null;
      }
      fillBackground(_frames[0], data.rect);
    }
    else disposeFrame(_currGifFrame);
    _currGifFrame = _frames[_currFrame];
    renderFrame(_currGifFrame);
  }
  
  private inline function fillBackground(frame:GifFrame, rect:Rectangle):Void
  {
    // Clear
    #if yagp_accurate_fill_background
    if (_gif.backgroundIndex == frame.transparentIndex) data.fillRect(rect, 0);
    else data.fillRect(rect, _gif.backgroundColor);
    #else
    data.fillRect(rect, 0);
    #end
  }
  
}