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
import com.yagp.structs.ExtensionFactory;
import haxe.io.Bytes;
import com.yagp.structs.GifBytes;
import com.yagp.structs.GifFrame;
import com.yagp.structs.GifVersion;
import com.yagp.structs.GraphicsControl;
import com.yagp.structs.GraphicsDecoder;
import com.yagp.structs.ImageDescriptor;
import com.yagp.structs.LSD;
import com.yagp.structs.NetscapeExtension;
import openfl.utils.ByteArray;

/**
 * The GIF reader
 * How to use:
 * var gif:GIF = GifDecoder.readGIF(inputGifFile);
 * @author Yanrishatum
 */
class GifDecoder
{
  // YAGP: Async parsing (at least for sys platforms).
  // YAGP: Optimize overall program.
  
  /**
   * Decodes GIF file from ByteArray and return ready GIF class
   * @param bytes Input file data stream.
   * @return GIF file.
   */
  public static function parseBytes(bytes:Bytes):Gif
  {
    var gifBytes:GifBytes = new GifBytes(bytes);
    var decoder:GifDecoder = new GifDecoder(gifBytes);
    decoder.decodeGif();
    return decoder.gif;
  }
  
  public static inline function parseByteArray(byteArray:ByteArray):Gif
  {
    #if flash
    return parseBytes(Bytes.ofData(byteArray));
    #elseif js
    
    #if (haxe_ver >= 3.2)
    return parseBytes(Bytes.ofData(byteArray.byteView)); // In newest 3.2 haxe Uint8Array is BytesData
    #else
    var bytes:Bytes = Bytes.alloc(byteArray.length);
    byteArray.position = 0;
    for (i in 0...byteArray.length) bytes.set(i, byteArray.readByte());
    return parseBytes(bytes);
    #end
    
    #else
    return parseBytes(byteArray);
    #end
  }
  
  public static inline function parseText(text:String):Gif
  {
    return parseBytes(Bytes.ofString(text));
  }
  
  /**
   * Output GIF file with all data and frames
   */
  public var gif:Gif;
  // Input stream
  private var _input:GifBytes;
  
  // Temporary data
  private var _graphicControlExtension:GraphicsControl;
  private var _globalColorTable:Array<Int>;
  
  private function new(input:GifBytes = null) 
  {
    this._input = input;
  }
  
  /**
   * Read GIF file in one stream.
   * @param input Input file stream
   */
  public function decodeGif():Void
  {
    // Init GIF
    this.gif = new Gif();
    
    if (this.readHeader())
    {
      // Logic screen descriptor
      var lsd:LSD = new LSD(_input);
      this.gif.lsd = lsd;
      
      // Global color table
      if (lsd.globalColorTable) // Global CT
      {
        _globalColorTable = this.readColorTable(lsd.globalColorTableSize);
        if (lsd.backgroundColorIndex < _globalColorTable.length)
          this.gif.backgroundColor = _globalColorTable[lsd.backgroundColorIndex];
      }
      
      readBlock();
    }
    else
    {
      throw "This is not a GIF file, or header invalid.";
    }
  }
  
  private function readBlock():Void
  {
    var id:Int;
    while (true)
    {
      id = _input.readByte();
      switch (id)
      {
        // Image descriptor / Image
        case 0x2C: 
          readImage();
        // Extension block
        case 0x21: 
          readExtension();
        // EOF
        case 0x3B:
          return;
      }
    }
  }
  
  private function readExtension():Void
  {
    var subId:Int = _input.readByte();
    switch (subId)
    {
      // Graphics control extension
      case 0xF9:
        #if yagp_strict_gif_version_check
        if (gif.version == GifVersion.GIF87a) // Yes, full specification support of 87a and 89a.
        {
          skipBlock();
          return;
        }
        #end
        _graphicControlExtension = new GraphicsControl(_input);
      /*
      // Text block extension
      case 0x01: 
        // Skip text block
        // YAGP: Read text blocks
        skipBlock();
      
      // Comment block extension
      case 0xFE: 
        // Skip comment block
        // YAGP: Read comment blocks
        skipBlock();
      */
      // Program extension block
      case 0xFF: readApplicationExtension();
      
      default: skipBlock();
    }
  }
  
  private function readApplicationExtension():Void
  {
    #if yagp_strict_gif_version_check
    if (gif.version == GifVersion.GIF87a)
    {
      skipBlock();
      return;
    }
    #end
    
    // Extension name
    _input.position++; // Skip block size (0x0B);
    var name:String = _input.readUTFBytes(8);
    var version:String = _input.readUTFBytes(3);
    
    switch (name)
    {
      // Netscape 2.0 - animation looping
      // YAGP: Make correct netscape extension reading. Currently it can be both Looping or Buffering.
      case "NETSCAPE": 
        gif.netscape = new NetscapeExtension(_input);
      
      // Make next extension reading:
      // PIANYGIF1.0
      // Netscape Buffering Application Extension
      // AnimExts Looping Application Extension (ANIMEXTS1.0) 
      default: 
        skipBlock();
    }
  }
  
  private function readImage():Void
  {
    // Reading descriptor block
    var imageDescriptor:ImageDescriptor = new ImageDescriptor(_input);
    
    // Color table set
    var table:Array<Int> = _globalColorTable;
    if (imageDescriptor.localColorTable)
      table = this.readColorTable(imageDescriptor.localColorTableSize);
    if (table == null)
    {
      throw "Image didn't have color table!";
      return;
    }
    
    // Reading graphics data;
    var decoder:GraphicsDecoder = new GraphicsDecoder(_input, imageDescriptor);
    
    // Make new GifFrame
    var gifFrame:GifFrame = new GifFrame(table, imageDescriptor, decoder, _graphicControlExtension);
    gif.frames.push(gifFrame);
    
    // And clear
    table = null;
    decoder = null;
    _graphicControlExtension = null;
  }
  
  //=======================================================
  //{ Reading not heavy-structural blocks
  //=======================================================
  
  /**
   * Reads header of GIF file.
   * @return true, if header is valid, false otherwise.
   */
  private function readHeader():Bool
  {
    // Is header valid?
    var valid:Bool = _input.readUTFBytes(3) == "GIF";
    if (valid)
    {
      var version:String = _input.readUTFBytes(3);
      if (version == "87a") this.gif.version = GifVersion.GIF87a;
      else if (version == "89a") this.gif.version = GifVersion.GIF89a;
      
      if (this.gif.version == null)
      {
        //trace("Unknown GIF version \"" + this.gif.version + "\"! Selected default (89a) version.");
        this.gif.version = GifVersion.GIF89a;
      }
    }
    return valid;
  }
  
  /**
   * Reads color table.
   * Structure of Color Tables:
   * RRGGBB RRGGBB RRGGBB
   * @param colorsCount Count of colors in color table.
   * @return Vector.<uint> with readed colors.
   */
  private function readColorTable(colorsCount:Int):Array<Int>
  {
    var result:Array<Int> = new Array<Int>();
    for (i in 0...colorsCount)
    {
      result[i] =    0xFF000000 | // A
        _input.readByte() << 16 | // R
        _input.readByte() << 8  | // G
        _input.readByte();        // B
    }
    return result;
  }
  
  //=======================================================
  //}
  //=======================================================
  
  /**
   * Utils; Skips blocks array
   */
  private function skipBlock():Void
  {
    var blockSize:Int = 0;
    do
    {
      blockSize = _input.readByte();
      _input.position += blockSize;
    } while (blockSize != 0);
  }
}