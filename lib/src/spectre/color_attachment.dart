/*
  Copyright (C) 2013 John McCutchan

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

part of spectre;

/// Defines modes for addressing texels using texture coordinates outside of
/// the typical range of 0.0 to 1.0.
class ColorAttachment extends Enum {
  static const int Attachment0 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT0_EXT;
  static const int Attachment1 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT1_EXT;
  static const int Attachment2 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT2_EXT;
  static const int Attachment3 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT3_EXT;
  static const int Attachment4 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT4_EXT;
  static const int Attachment5 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT5_EXT;
  static const int Attachment6 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT6_EXT;
  static const int Attachment7 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT7_EXT;
  static const int Attachment8 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT8_EXT;
  static const int Attachment9 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT9_EXT;
  static const int Attachment10 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT10_EXT;
  static const int Attachment11 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT11_EXT;
  static const int Attachment12 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT12_EXT;
  static const int Attachment13 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT13_EXT;
  static const int Attachment14 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT14_EXT;
  static const int Attachment15 = WebGL.ExtDrawBuffers.COLOR_ATTACHMENT15_EXT;


  static Map<String, int> _values = {
  };

  /// Convert a [String] to a [TextureAddressMode].
  static int parse(String name) => Enum._parse(_values, name);
  /// Convert a [TextureAddressMode] to a [String].
  static String stringify(int value) => Enum._stringify(_values, value);
  /// Checks whether the value is a valid enumeration.
  static bool isValid(int value) => Enum._isValid(_values, value);
}
