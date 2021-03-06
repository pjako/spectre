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
class TextureAddressMode extends Enum {
  /// Texture coordinates outside the range [0.0, 1.0] are set to the texture
  /// color at 0.0 or 1.0, respectively.
  static const int Clamp = WebGL.CLAMP_TO_EDGE;
  /// Similar to Wrap, except that the texture is flipped at every integer
  /// junction.
  ///
  /// For values between 0 and 1, for example, the texture is addressed
  /// normally; between 1 and 2, the texture is
  /// flipped (mirrored); between 2 and 3, the texture is normal again, and so
  /// on.
  static const int Mirror = WebGL.MIRRORED_REPEAT;
  /// Tile the texture at every integer junction.
  ///
  /// For example, for u values between 0 and 3, the texture is repeated three
  /// times;
  /// no mirroring is performed.
  static const int Wrap = WebGL.REPEAT;

  static Map<String, int> _values = {
    'TextureAddressMode.Clamp' : Clamp,
    'TextureAddressMode.Mirror' : Mirror,
    'TextureAddressMode.Wrap' : Wrap
  };
  /// Convert a [String] to a [TextureAddressMode].
  static int parse(String name) => Enum._parse(_values, name);
  /// Convert a [TextureAddressMode] to a [String].
  static String stringify(int value) => Enum._stringify(_values, value);
  /// Checks whether the value is a valid enumeration.
  static bool isValid(int value) => Enum._isValid(_values, value);
}
