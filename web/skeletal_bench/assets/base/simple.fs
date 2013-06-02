precision mediump float;

//---------------------------------------------------------------------
// Uniform variables
//---------------------------------------------------------------------

/// The diffuse sampler.
uniform sampler2D uDiffuse;

//---------------------------------------------------------------------
// Varying variables
//
// Allows communication between vertex and fragment stages
//---------------------------------------------------------------------

/// The texture coodinate of the vertex.
varying vec2 texCoord;

//---------------------------------------------------------------------
// Functions
//---------------------------------------------------------------------

void main()
{
  gl_FragColor = texture2D(uDiffuse, texCoord);
}
