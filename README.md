YAGP
====

Yet Another Gif Parser

This library provides simple API to parse animated GIF images. In difference between haxe-gif library, this library successfully parses most of the Gif images (exclude too big images). You can check detailed comparasion results in `test/test-<platform>.txt` files.

__Html5 target supported only with OpenFL-Bitfive!__

### Quick start
#### Installation
`haxelib install yagp` - Haxelib release.  
`haxelib git yagp https://github.com/Yanrishatum/yagp.git` - GitHub version.
#### Using the library.
```haxe
import com.yagp.GifDecoder;
import com.yagp.Gif;
import com.yagp.GifPlayer;
import com.yagp.GifPlayerWrapper;
import com.yagp.GifRenderer;
import openfl.Assets;
// ...

// Parsing from haxe.io.Bytes:
var bytes:Bytes = ...;
var gif:Gif = GifDecoder.parseBytes(bytes);
// Parsing from openfl.utils.ByteArray:
var gif:Gif = GifDecoder.parseByteArray(Assets.getBytes("gif_file.gif"));
// Parsing from text:
var text:String = ...;
var gif:Gif = GifDecoder.parseText(text);

// Simple player example:
var player:GifPlayer = new GifPlayer(gif);
// openfl.display.Bitmap wrapper for GifPlayer.
// GifPlayer provides only BitmapData for further displaying and must be updated manually.
var wrapper:GifPlayerWrapper = new GifPlayerWrapper(player);
addChild(wrapper);

// Creating spritemap from Gif:
var spritemap:GifMap = GifRenderer.createMap(gif);
// This will create a horizontal spritemap from gif. GifMap contains width/height of single frame, delays for every frame and spritemap data.
```
#### Defines
`yagp_accurate_delay` - Disables browser behaviour, that delay 0 and 1 (0s and 0.01s) are forced to 10 (0.1s).  
`yagp_strict_gif_version_check` - Enables strict version check for blocks support. (In GIF87a Graphic Control extension and Application Extension not supported, and they will be ignored while parsing GIF with that version)  
`yagp_accurate_fill_background` - (GifPlayer implementation) Disables browser behaviour, where disposal method "Fill background color" will fill transparency, instead of background color, when disposing frame transparentColorIndex not equals to backgroundColorIndex.  
`yagp_faststone` - (GifPlayer implementation) When switching frames, `t` will be set to 0, instead of substracting `elapsed`. This will produce incorrect frame-delays, and will emulate FastStone Image Viewer behaviour.
#### Tested platforms
* Flash: Full support.
* Neko: Full support.
* Windows: Full support.
* HTML5: Only with OpenFL-Bitfive. Produces `?` output by OpenFL-Bitfive.
* Android: Not tested for speed and produces an warning messages, but works as reported in [#2](http://github.com/Yanrishatum/yagp/issues/2).

#### Possible future updates
- [ ] Asynchronous parsing.
- [x] HTML5 target support.
- [ ] Custom Extension/Application Extension support.
- [ ] Plain Text Extension support.
- [ ] Macro pre-compile parsing and embedding.
- [ ] Independence from OpenFL.
- [ ] On-Demand parsing (e.g. not parse entire file once, but parse next frames when it's required)

## Licension
This work is licensed under MIT license.

Copyright (C) 2014 Pavel "Yanrishatum" Alexandrov

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
