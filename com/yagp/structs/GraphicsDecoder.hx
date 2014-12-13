package com.yagp.structs ;
import openfl.Vector;

/**
 * Graphics block decoder. LZW decompression.
 * @author Yanrishatum
 */
class GraphicsDecoder
{
  /**
   * Pixels in graphics data
   */
  #if flash
  public var pixels:Vector<UInt>;
  #else
  public var pixels:Vector<Int>;
  #end
  
  // Reading vars
  private var blockSize:Int;
  private var byte:Int;
  private var bitsCount:Int;
  
  private var _input:GifBytes;
  
  public function new(input:GifBytes, descriptor:ImageDescriptor, table:Array<Int>) 
  {
    var minCodeSize:Int = input.readByte();
    
    blockSize = input.readByte() - 1;
    byte = input.readByte();
    bitsCount = 8;
    
    _input = input;
    
    #if flash
    pixels = new Vector<UInt>();
    #elseif neko
    var subPixels:Array<Int> = new Array();
    #else
    pixels = new Vector<Int>();
    #end
    
    var clearCode:Int = 1 << minCodeSize;
    var eoiCode:Int = clearCode + 1;
    
    var codeSize:Int = minCodeSize + 1;
    var codeMask:Int = (1 << codeSize) - 1;
    
    
    var baseDict:Array<Array<Int>> = new Array<Array<Int>>();
    for (i in 0...clearCode) baseDict[i] = [i];
    baseDict[clearCode] = [];
    baseDict[eoiCode] = [];
    
    var dict:Array<Array<Int>> = new Array<Array<Int>>();
    
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
          var newArr:Array<Int> = dict[last].copy();
          newArr.push(dict[code][0]);
          dict.push(newArr);
          
        }
      }
      else
      {
        if (code != dict.length) throw 'Invalid LZW code.';
        var newArr:Array<Int> = dict[last].copy();
        newArr.push(dict[last][0]);
        dict.push(newArr);
      }
      
      #if neko
      for (item in dict[code]) subPixels.push(item);
      #else
      for (item in dict[code]) pixels.push(item);
      #end
      
      if (dict.length == (1 << codeSize) && codeSize < 12)
      {
        codeSize++;
        codeMask = (1 << codeSize) - 1;
      }
    }
    // Used non-direct push to pixels vector because NekoVM on new version of Haxe produces tons of lags when I push pixels to vector. Don't know why 
    #if neko
    pixels = Vector.ofArray(subPixels);
    #end
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