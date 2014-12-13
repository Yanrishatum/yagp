package com.yagp.structs ;
import haxe.io.Bytes;

/**
 * Shell for Bytes
 * @author Yanrishatum
 */
class GifBytes
{
  public var position:Int;
  public var bytes:Bytes;
  
  public function new(bytes:Bytes) 
  {
    this.bytes = bytes;
    this.position = 0;
  }
  
  public inline function readByte():Int
  {
    return this.bytes.get(position++);
  }
  
  public inline function readShort():Int
  {
    return readByte() | (readByte() << 8);
  }
  
  public inline function readInt():Int
  {
    return readByte() | (readByte() << 8) | (readByte() << 16) | (readByte() << 24);
  }
  
  public inline function readUInt():UInt
  {
    return this.readInt();
  }
  
  public inline function readUTFBytes(len:Int):String
  {
    var str:String = this.bytes.getString(position, len);
    position += len;
    return str;
  }
  
  public var bytesAvailable(get, never):Int;
  private inline function get_bytesAvailable():Int
  {
    return this.bytes.length - this.position;
  }
  
  public var length(get, never):Int;
  private inline function get_length():Int
  {
    return this.bytes.length;
  }
  
}