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
import haxe.Timer;
import openfl.display.Bitmap;
import openfl.events.Event;

/**
 * Fast and dirty Bitmap wrapper for GifPlayer
 */
class GifPlayerWrapper extends Bitmap
{
  /**
   * Timescale for all GifPlayerWrappers
   */
  public static var globalTimescale:Float = 1;
  /**
   * Timescale for this GifPlayerWrapper
   */
  public var timescale:Float = 1;
  
  private var _player:GifPlayer;
  private var _t:Float;
  
  public var player(get, set):GifPlayer;
  private inline function get_player():GifPlayer { return _player; }
  private inline function set_player(v:GifPlayer):GifPlayer
  {
    if (v != null)
    {
      _player = v;
      bitmapData = v.data;
      _t = Timer.stamp();
    }
    else
    {
      _player = null;
      bitmapData = null;
    }
    return _player;
  }
  
  /**
   * If player must play animation?
   */
  public var playing(get, set):Bool;
  private inline function get_playing():Bool { return _player == null ? false : _player.playing; }
  private inline function set_playing(v:Bool):Bool
  {
    return _player == null ? v : _player.playing = v;
  }
  
  /**
   * Handler of animation end. Note, it will be called only if animation does not have infinite amount of loops.
   */
  public var animationEndHandler(get, set):Void->Void;
  private inline function get_animationEndHandler():Void->Void { return _player == null ? null : _player.animationEndHandler; }
  private inline function set_animationEndHandler(v:Void->Void):Void->Void
  {
    return _player == null ? v : _player.animationEndHandler = v;
  }
  
  /**
   * Handler of animation loop end. Will be called on end of each loop.
   */
  public var loopEndHandler(get, set):Void->Void;
  private inline function get_loopEndHandler():Void->Void { return _player == null ? null : _player.loopEndHandler; }
  private inline function set_loopEndHandler(v:Void->Void):Void->Void
  {
    return _player == null ? v : _player.loopEndHandler = v;
  }
  
  /**
   * The gif file to play in this GifPlayer.
   */
  public var gif(get, set):Gif;
  private inline function get_gif():Gif { return _player == null ? null : _player.gif; }
  private inline function set_gif(v:Gif):Gif
  {
    return _player == null ? v : _player.gif = v;
  }
  
  /**
   * Current frame index.
   */
  public var frame(get, set):Int;
  private inline function get_frame():Int { return _player == null ? -1 : _player.frame; }
  private inline function set_frame(v:Int):Int
  {
    return _player == null ? v : _player.frame = v;
  }
  
  /**
   * Amount of frames in assigned Gif file.
   */
  public var framesCount(get, never):Int;
  private inline function get_framesCount():Int
  {
    return _player != null ? _player.framesCount : 0;
  }
  
  public function new(player:GifPlayer) 
  {
    this._player = player;
    if (player != null)
    {
      super(player.data);
      _t = Timer.stamp();
    }
    else super();
    addEventListener(Event.ENTER_FRAME, onEnterFrame);
    addEventListener(Event.ADDED_TO_STAGE, resetTimer);
  }
  
  /**
   * Disposes wrapper.  
   * Note: You can't use this wrapper anymore, if you used dispose() method!
   * @param disposePlayer Dispose assigned GifPlayer too?  
   * Default: true
   * @param disposeGif Dispose assigned to GifPlayer Gif file?  
   * Default: false
   */
  public function dispose(disposePlayer:Bool = true, disposeGif:Bool = false):Void
  {
    if (_player != null)
    {
      if (disposePlayer) _player.dispose(disposeGif);
      _player = null;
      bitmapData = null;
    }
    removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    removeEventListener(Event.ADDED_TO_STAGE, resetTimer);
  }
  
  /**
   * Resets player state. Use it foor reset loop counter.
   * @param play If set to true, will force `playing` value to true.
   */
  public function reset(play:Bool = false):Void
  {
    if (_player != null) _player.reset(play);
  }
  
  private function resetTimer(e:Event):Void
  {
    _t = Timer.stamp();
  }
  
  private function onEnterFrame(e:Event):Void 
  {
    if (_player == null || stage == null) return;
    var stamp:Float = Timer.stamp();
    _player.update((stamp - _t) * timescale * globalTimescale);
    _t = stamp;
  }
  
  
  
}