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

/** A [DrawBuffers] specifies the buffers where color, depth, and stencil
 * are written to during a draw call.
 *
 * NOTE: To output into the system provided render target see
 * [RenderTarget.systemRenderTarget]
 */
class DrawBuffers extends DeviceChild {
  static const int COLOR_ATTACHMENT0 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT0_EXT;
  static const int COLOR_ATTACHMENT1 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT1_EXT;
  static const int COLOR_ATTACHMENT2 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT2_EXT;
  static const int COLOR_ATTACHMENT3 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT3_EXT;
  static const int COLOR_ATTACHMENT4 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT4_EXT;
  static const int COLOR_ATTACHMENT5 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT5_EXT;
  static const int COLOR_ATTACHMENT6 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT6_EXT;
  static const int COLOR_ATTACHMENT7 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT7_EXT;
  static const int COLOR_ATTACHMENT8 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT8_EXT;
  static const int COLOR_ATTACHMENT9 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT9_EXT;
  static const int COLOR_ATTACHMENT10 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT10_EXT;
  static const int COLOR_ATTACHMENT11 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT11_EXT;
  static const int COLOR_ATTACHMENT12 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT12_EXT;
  static const int COLOR_ATTACHMENT13 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT13_EXT;
  static const int COLOR_ATTACHMENT14 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT14_EXT;
  static const int COLOR_ATTACHMENT15 => WebGL.ExtDrawBuffers.COLOR_ATTACHMENT15_EXT;

  static const int DRAW_BUFFER0 => WebGL.ExtDrawBuffers.DRAW_BUFFER0_EXT;
  static const int DRAW_BUFFER1 => WebGL.ExtDrawBuffers.DRAW_BUFFER1_EXT;
  static const int DRAW_BUFFER2 => WebGL.ExtDrawBuffers.DRAW_BUFFER2_EXT;
  static const int DRAW_BUFFER3 => WebGL.ExtDrawBuffers.DRAW_BUFFER3_EXT;
  static const int DRAW_BUFFER4 => WebGL.ExtDrawBuffers.DRAW_BUFFER4_EXT;
  static const int DRAW_BUFFER5 => WebGL.ExtDrawBuffers.DRAW_BUFFER5_EXT;
  static const int DRAW_BUFFER6 => WebGL.ExtDrawBuffers.DRAW_BUFFER6_EXT;
  static const int DRAW_BUFFER7 => WebGL.ExtDrawBuffers.DRAW_BUFFER7_EXT;
  static const int DRAW_BUFFER8 => WebGL.ExtDrawBuffers.DRAW_BUFFER8_EXT;
  static const int DRAW_BUFFER9 => WebGL.ExtDrawBuffers.DRAW_BUFFER9_EXT;
  static const int DRAW_BUFFER10 => WebGL.ExtDrawBuffers.DRAW_BUFFER10_EXT;
  static const int DRAW_BUFFER11 => WebGL.ExtDrawBuffers.DRAW_BUFFER11_EXT;
  static const int DRAW_BUFFER12 => WebGL.ExtDrawBuffers.DRAW_BUFFER12_EXT;
  static const int DRAW_BUFFER13 => WebGL.ExtDrawBuffers.DRAW_BUFFER13_EXT;
  static const int DRAW_BUFFER14 => WebGL.ExtDrawBuffers.DRAW_BUFFER14_EXT;
  static const int DRAW_BUFFER15 => WebGL.ExtDrawBuffers.DRAW_BUFFER15_EXT;

  static const int MAX_COLOR_ATTACHMENTS => WebGL.ExtDrawBuffers.MAX_COLOR_ATTACHMENTS_EXT;
  static const int MAX_DRAW_BUFFERS => WebGL.ExtDrawBuffers.MAX_DRAW_BUFFERS_EXT;


  WebGL.ExtDrawBuffers _drawBuffers;
  DrawBuffers(String name, GraphicsDevice device) :
    super._internal(name, device) {
    _drawBuffers = GraphicsDeviceCapabilities._getExtension( device.gl, 'EXT_draw_buffers');
  }
  void finalize() {
    super.finalize();
  }
  void setDrawBuffers(List<int> buffers) {
    _drawBuffers.drawBuffersEXT(buffers);
  }
}
