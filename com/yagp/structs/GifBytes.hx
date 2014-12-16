package com.yagp.structs ;
import haxe.io.Bytes;

/**
 * Shell for `haxe.io.Bytes`.
 */
class GifBytes
{
  /**
   * Position of data reading.
   */
  public var position:Int;
  /**
   * Source Bytes.
   */
  public var bytes:Bytes;
  
  public function new(bytes:Bytes) 
  {
    this.bytes = bytes;
    this.position = 0;
  }
  
  /**
   * Reads single byte from data stream.
   * @return 1 byte from data stream.
   */
  public inline function readByte():Int
  {
    return this.bytes.get(position++);
  }
  
  /**
   * Reads short from data stream.
   * @return 2-byte Little-Endian short from data stream.
   */
  public inline function readShort():Int
  {
    return readByte() | (readByte() << 8);
  }
  
  /**
   * Reads Int32 from data stream.
   * @return Little-Endian Int32.
   */
  public inline function readInt():Int
  {
    return readByte() | (readByte() << 8) | (readByte() << 16) | (readByte() << 24);
  }
  
  /**
   * Read Unsigned Int32 from data stream.  
   * In fact just alias for `readInt()`.
   * @return UInt32.
   */
  public inline function readUInt():UInt
  {
    return this.readInt();
  }
  
  /**
   * Reads `len` bytes from data stream as a string.
   * @param len Amount of bytes to read from data stream.
   * @return String, that contains `len` symbols.
   */
  public inline function readUTFBytes(len:Int):String
  {
    var str:String = this.bytes.getString(position, len);
    position += len;
    return str;
  }
  
  /**
   * Amount of available bytes in data stream from `position` to `length`.
   */
  public var bytesAvailable(get, never):Int;
  private inline function get_bytesAvailable():Int
  {
    return this.bytes.length - this.position;
  }
  
  /**
   * Size of data stream.
   */
  public var length(get, never):Int;
  private inline function get_length():Int
  {
    return this.bytes.length;
  }
  
}