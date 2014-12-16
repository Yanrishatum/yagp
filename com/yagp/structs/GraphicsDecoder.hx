package com.yagp.structs ;
import openfl.Vector;

#if (flash || display || openfl_next || js)
typedef PixelType = UInt;
#else
typedef PixelType = Int; // Used _v2 OpenFL.
#end

/**
 * Graphics block decoder. LZW decompression.
 * @author Yanrishatum
 */
class GraphicsDecoder
{
  /**
   * Pixels in graphics data
   */
  public var pixels:Vector<PixelType>;
  
  // Reading vars
  private var blockSize:Int;
  private var byte:Int;
  private var bitsCount:Int;
  
  private var _input:GifBytes;
  
  public function new(input:GifBytes, descriptor:ImageDescriptor) 
  {
    var minCodeSize:Int = input.readByte();
    
    blockSize = input.readByte() - 1;
    byte = input.readByte();
    bitsCount = 8;
    
    _input = input;
    
    pixels = new Vector<PixelType>(descriptor.width * descriptor.height, true);
    
    var clearCode:Int = 1 << minCodeSize;
    var eoiCode:Int = clearCode + 1;
    
    var codeSize:Int = minCodeSize + 1;
    var codeMask:Int = (1 << codeSize) - 1;
    
    var i:Int = 0; // Pixel write caret.
    
    var baseDict:Array<Array<PixelType>> = new Array<Array<PixelType>>();
    for (i in 0...clearCode) baseDict[i] = [i];
    baseDict[clearCode] = [];
    baseDict[eoiCode] = [];
    
    var dict:Array<Array<PixelType>> = new Array<Array<PixelType>>();
    
    var code:Int = 0;
    var last:Int = 0;
    while (true)
    {
      last = code;
      code = readCode(codeSize, codeMask);
      
      if (code == clearCode)
      {
        dict = baseDict.copy();
        codeSize = minCodeSize + 1;
        codeMask = (1 << codeSize) - 1;
        continue;
      }
      if (code == eoiCode) break;

      if (code < dict.length)
      {
        if (last != clearCode)
        {
          var newArr:Array<PixelType> = dict[last].copy();
          newArr.push(dict[code][0]);
          dict.push(newArr);
          
        }
      }
      else
      {
        if (code != dict.length) throw 'Invalid LZW code.';
        var newArr:Array<PixelType> = dict[last].copy();
        newArr.push(dict[last][0]);
        dict.push(newArr);
      }
      
      for (item in dict[code]) pixels[i++] = 0xFF000000 | item;
      
      if (dict.length == (1 << codeSize) && codeSize < 12)
      {
        codeSize++;
        codeMask = (1 << codeSize) - 1;
      }
    }
    
    while (blockSize > 0)
    {
      input.position += blockSize;
      blockSize = input.readByte();
    }
  }
  
  /**
   * Reads code from data input
   * @param size Size of code in bits
   * @return Next code or -1, if no codes to read.
   */
  private function readCode(size:Int, mask:Int):Int
  {
    while (bitsCount < size)
    {
      if (blockSize == 0) break;
      byte |= _input.readByte() << bitsCount;
      bitsCount += 8;
      blockSize--;
      if (blockSize == 0) blockSize = _input.readByte();
    }
    var code:Int = byte & mask;
    byte >>= size;
    bitsCount -= size;
    
    return code;
  }
}