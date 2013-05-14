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

part of skeletal_bench;

typedef double EasingFunction(double t);

double EaseTo(double elapsed, double duration, double start, double end, EasingFunction f) {
  return start + ((end-start) * f(elapsed / duration));
}

class Ease {
  // accelerating from zero velocity
  static double InQuad(double t) => t*t;
  // decelerating to zero velocity
  static double OutQuad(double t) => t*(2.0-t);
  // acceleration until halfway, then deceleration
  static double InOutQuad(double t) => t<0.5 ? 2.0*t*t : -1.0+(4.0-2.0*t)*t;
  // accelerating from zero velocity 
  static double InCubic(double t) => t*t*t;
  // decelerating to zero velocity 
  static double OutCubic(double t) => (--t)*t*t+1.0;
  // acceleration until halfway, then deceleration 
  static double InOutCubic(double t) => t<0.5 ? 4.0*t*t*t : (t-1.0)*(2.0*t-2.0)*(2.0*t-2.0)+1.0;
  static double OutElastic(double t) => Math.pow(2,-10*t) * Math.sin((t-0.075)*(2.0*Math.PI)/0.3) + 1;
}