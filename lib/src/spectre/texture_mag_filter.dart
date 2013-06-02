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

/// Defines filtering types for magnification during texture sampling.
class TextureMagFilter extends Enum {
  /// Use linear filtering for magnification.
  static const int Linear = WebGL.LINEAR;
  /// Use point filtering for magnification.
  static const int Point = WebGL.NEAREST;
  /// Use point filtering to expand, and point filtering between mipmap levels.
  static const int PointMipPoint = WebGL.NEAREST_MIPMAP_NEAREST;
  /// Use point filtering to expand, and linear filtering between mipmap levels.
  static const int PointMipLinear = WebGL.NEAREST_MIPMAP_LINEAR;
  /// Use linear filtering to expand, and point filtering between mipmap levels.
  static const int LinearMipPoint = WebGL.LINEAR_MIPMAP_NEAREST;
  /// Use linear filtering to expand, and linear filtering between mipmap levels.
  static const int LinearMipLinear = WebGL.LINEAR_MIPMAP_LINEAR;

  static Map<String, int> _values = {
    'TextureMagFilter.Linear' : Linear,
    'TextureMagFilter.Point' : Point,
    'TextureMagFilter.PointMipPoint' : PointMipPoint,
    'TextureMagFilter.PointMipLinear' : PointMipLinear,
    'TextureMagFilter.LinearMipPoint' : LinearMipPoint,
    'TextureMagFilter.LinearMipLinear' : LinearMipLinear,
  };

  /// Convert a [String] to a [TextureMagFilter].
  static int parse(String name) => Enum._parse(_values, name);
  /// Convert a [TextureMagFilter] to a [String].
  static String stringify(int value) => Enum._stringify(_values, value);
  /// Checks whether the value is a valid enumeration.
  static bool isValid(int value) => Enum._isValid(_values, value);
}
