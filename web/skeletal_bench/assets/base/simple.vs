//---------------------------------------------------------------------
// Vertex attributes
//---------------------------------------------------------------------

/// The vertex position.
attribute vec3 vPosition;
/// The texture coordinate.
attribute vec2 vTexCoord0;

//---------------------------------------------------------------------
// Uniform variables
//---------------------------------------------------------------------

/// The Model-View matrix.
uniform mat4 uModelViewMatrix;
/// The Model-View-Projection matrix.
uniform mat4 uModelViewProjectionMatrix;
uniform mat4 uModelMatrix;

//---------------------------------------------------------------------
// Varying variables
//
// Allows communication between vertex and fragment stages
//---------------------------------------------------------------------

/// The texture coordinate of the vertex.
varying vec2 texCoord;

void main()
{
  texCoord = vTexCoord0; 
  gl_Position = uModelViewProjectionMatrix * uModelMatrix * vec4(vPosition, 1.0);
}
