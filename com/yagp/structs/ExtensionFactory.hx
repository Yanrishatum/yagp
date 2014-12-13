package com.yagp.structs;
import com.yagp.structs.IExtension;

/**
 * Factory for custom extensions.
 * @author Yanrishatum
 */
class ExtensionFactory<T:IExtension>
{

  public var code:Int;
  
  public function new(code:Int) 
  {
    this.code = code;
  }
  
  public function create(input:GifBytes):T
  {
    throw "Not implemented";
    return null;
  }
  
}